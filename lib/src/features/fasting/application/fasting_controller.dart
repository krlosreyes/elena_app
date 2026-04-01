import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../authentication/application/auth_controller.dart'
    show authStateChangesProvider, authControllerProvider;
import '../../../core/services/notification_service.dart';
import '../data/fasting_repository.dart';
import 'package:elena_app/src/shared/domain/models/fasting_session.dart';
import '../../health/data/health_repository.dart';
import '../../health/domain/daily_log.dart';
import 'package:elena_app/src/features/profile/application/user_controller.dart';




// Constantes de Fase Metabólica
const String phaseFasting = 'IS_FASTING';
const String phaseFeeding = 'IS_FEEDING';

// Provider para disparar el modal de registro de comida
final mealModalTriggerProvider = StateProvider<bool>((ref) => false);
// Provider para disparar la revisión de comidas previas
final mealReviewTriggerProvider = StateProvider<bool>((ref) => false);
// Provider para mostrar advertencia de tiempo de espera entre comidas
final nextMealTimeWarningProvider = StateProvider<String?>((ref) => null);

class FastingState {
  final DateTime? startTime;
  final DateTime? feedingStartTime;
  final Duration elapsed;
  final int plannedHours;
  final int originalPlannedHours;
  final String currentPhase; // IS_FASTING, IS_FEEDING
  final double fastingPercent; // (Elapsed / 16) * 100
  final double feedingPercent; // (Elapsed / 8) * 100
  final bool isWindowClosing; // True when < 30m left in feeding window
  final bool isRestingWarning;
  final bool hasCompletedConfirmationShown;
  final bool isContinuingPastGoal;
  final bool hasInitialMealBeenLogged;
  final bool hasFeedingEndDialogShown;

  FastingState({
    this.startTime,
    this.feedingStartTime,
    this.elapsed = Duration.zero,
    required this.plannedHours,
    this.originalPlannedHours = 16,
    required this.currentPhase,
    this.fastingPercent = 0,
    this.feedingPercent = 0,
    this.isWindowClosing = false,
    this.isRestingWarning = false,
    this.hasCompletedConfirmationShown = false,
    this.isContinuingPastGoal = false,
    this.hasInitialMealBeenLogged = false,
    this.hasFeedingEndDialogShown = false,
  });

  bool get isFasting => currentPhase == phaseFasting;
  bool get isFeeding => currentPhase == phaseFeeding;

  factory FastingState.initial() {
    return FastingState(
      startTime: null,
      feedingStartTime: null,
      elapsed: Duration.zero,
      plannedHours: 16,
      originalPlannedHours: 16,
      currentPhase: phaseFeeding, // Estado por defecto
      fastingPercent: 0.0,
      feedingPercent: 0.0,
      isWindowClosing: false,
      hasInitialMealBeenLogged: false,
      hasFeedingEndDialogShown: false,
    );
  }

  FastingState copyWith({
    DateTime? startTime,
    DateTime? feedingStartTime,
    Duration? elapsed,
    int? plannedHours,
    int? originalPlannedHours,
    String? currentPhase,
    double? fastingPercent,
    double? feedingPercent,
    bool? isWindowClosing,
    bool? isRestingWarning,
    bool? hasCompletedConfirmationShown,
    bool? isContinuingPastGoal,
    bool? hasInitialMealBeenLogged,
    bool? hasFeedingEndDialogShown,
  }) {
    return FastingState(
      startTime: startTime ?? this.startTime,
      feedingStartTime: feedingStartTime ?? this.feedingStartTime,
      elapsed: elapsed ?? this.elapsed,
      plannedHours: plannedHours ?? this.plannedHours,
      originalPlannedHours: originalPlannedHours ?? this.originalPlannedHours,
      currentPhase: currentPhase ?? this.currentPhase,
      fastingPercent: fastingPercent ?? this.fastingPercent,
      feedingPercent: feedingPercent ?? this.feedingPercent,
      isWindowClosing: isWindowClosing ?? this.isWindowClosing,
      isRestingWarning: isRestingWarning ?? this.isRestingWarning,
      hasCompletedConfirmationShown:
          hasCompletedConfirmationShown ?? this.hasCompletedConfirmationShown,
      isContinuingPastGoal: isContinuingPastGoal ?? this.isContinuingPastGoal,
      hasInitialMealBeenLogged: hasInitialMealBeenLogged ?? this.hasInitialMealBeenLogged,
      hasFeedingEndDialogShown: hasFeedingEndDialogShown ?? this.hasFeedingEndDialogShown,
    );
  }
}

class FastingController extends AutoDisposeNotifier<AsyncValue<FastingState>> {
  Timer? _timer;
  StreamSubscription? _metabolicSubscription;
  bool _autoTriggerChecked = false;

  @override
  AsyncValue<FastingState> build() {
    final authState = ref.watch(authStateChangesProvider);

    ref.onDispose(() {
      _timer?.cancel();
      _metabolicSubscription?.cancel();
    });

    if (authState.isLoading) return const AsyncValue.loading();

    final user = authState.value;
    if (user == null) return AsyncValue.data(FastingState.initial());

    // Inicialización asíncrona
    Future.delayed(Duration.zero, () => _initMetabolicMachine(user.uid));

    return AsyncValue.data(FastingState.initial());
  }

  Future<void> _initMetabolicMachine(String uid) async {
    try {
      final repo = ref.read(fastingRepositoryProvider);

      // Cleanup preventivo
      await repo.forceCleanupOldActiveSessions(uid);

      // Suscripción al Estado Atómico de Firestore
      _metabolicSubscription?.cancel();
      _metabolicSubscription = repo.getMetabolicStateStream(uid).listen(
        (data) {
          // debugPrint("📡 Firestore Snapshot RAW: $data"); // Silenciado para limpiar terminal
          if (data != null) {
            final String phase = data['current_phase'] ?? phaseFeeding;
            final rawStartTime = data['start_time'] ?? data['startTime'];
            final DateTime? startTime = rawStartTime != null ? _parseDateTime(rawStartTime) : null;
            
            final rawFeedingStart = data['feeding_start_time'] ?? data['feedingStartTime'];
            final DateTime? feedingStartTime = rawFeedingStart != null ? _parseDateTime(rawFeedingStart) : null;
            final int targetHours = data['target_hours'] ?? 16;
            final int originalTargetHours =
                data['original_target_hours'] ?? targetHours;
            bool effectiveHasConfirmed =
                data['has_completed_confirmation_shown'] ?? false;
            final bool isContinuing = data['is_continuing_past_goal'] ?? false;
            final bool initialMealLogged = data['has_initial_meal_been_logged'] ?? false;
            final bool feedingEndDialogShown = data['has_feeding_end_dialog_shown'] ?? false;
            final now = DateTime.now();
            // debugPrint("🔄 Sync Snapshot: Phase=$phase, Start=$startTime, Confirmed=$effectiveHasConfirmed, Continuing=$isContinuing"); // Silenciado

            // 🧪 VALIDACIÓN DE FASE EN TIEMPO REAL
            String effectivePhase = phase;
            DateTime? effectiveFeedingStart = feedingStartTime;

            // 🛡️ GUARDIA DE CONFIRMACIÓN: Si Firestore dice que estamos alimentándonos
            // pero el usuario NUNCA confirmó el fin del ayuno (o viceversa),
            // lo revertimos localmente a fase de AYUNO para que la UI pueda disparar el diálogo.
            if ((effectivePhase == phaseFeeding && !effectiveHasConfirmed) ||
                (effectivePhase == phaseFasting &&
                    effectiveHasConfirmed &&
                    !isContinuing &&
                    startTime != null &&
                    now.isAfter(startTime.add(Duration(hours: targetHours))))) {
              effectivePhase = phaseFasting;
              // Si el flag de confirmación estaba en true pero seguimos en ayuno sin bandera de continuar, lo reseteamos.
              // Esto desbloquea el diálogo en la UI.
              if (effectiveHasConfirmed) {
                Future.delayed(Duration.zero, () {
                  repo.updateMetabolicState(
                      uid: uid,
                      phase: phaseFasting,
                      hasCompletedConfirmationShown: false);
                });
                // debugPrint("🔄 Auto-Recovery: Reseteando flag de confirmación para mostrar diálogo bloqueado.");
              } else {
                // debugPrint("🛡️ Safe Revert: Forzando fase AYUNO para mostrar confirmación pendiente.");
              }
            }

            effectiveFeedingStart ??=
                (effectivePhase == phaseFeeding && feedingStartTime == null)
                    ? (startTime?.add(Duration(hours: targetHours)) ?? now)
                    : feedingStartTime;

            // 🛡️ RECOVERY: If confirmed but phase is still FASTING and time is past goal,
            // ensure UI reflects the need for confirmation OR transition.
            if (effectivePhase == phaseFasting &&
                effectiveHasConfirmed &&
                !isContinuing) {
              final goalTime = startTime?.add(Duration(hours: targetHours));
              if (goalTime != null && now.isAfter(goalTime)) {
                // If confirmed but not continuing, it means they clicked "Terminar" and picked a time.
                // Usually Firestore will update 'phase' to Feeding, but if it's lagging,
                // we prevent a flicker back to 'meta completada' dialog.
                effectiveHasConfirmed = true;
              }
            }

            final baseTime = (effectivePhase == phaseFasting)
                ? (startTime ?? now)
                : (effectiveFeedingStart ?? now);
            final elapsed = now.isAfter(baseTime)
                ? now.difference(baseTime)
                : Duration.zero;

            state = AsyncValue.data(FastingState(
              startTime: startTime,
              feedingStartTime: effectiveFeedingStart,
              elapsed: elapsed,
              plannedHours: targetHours,
              originalPlannedHours: originalTargetHours,
              currentPhase: effectivePhase,
              fastingPercent: (elapsed.inSeconds / (targetHours * 3600)) * 100,
              feedingPercent:
                  (elapsed.inSeconds / ((24 - targetHours) * 3600)) * 100,
              hasCompletedConfirmationShown: effectiveHasConfirmed,
              isContinuingPastGoal: isContinuing,
              hasInitialMealBeenLogged: initialMealLogged,
              hasFeedingEndDialogShown: feedingEndDialogShown,
            ));

            // 🥗 TRIGGER AUTOMÁTICO DE REGISTRO
            if (effectivePhase == phaseFeeding &&
                effectiveHasConfirmed && // 🛡️ CRITICAL: Solo si el usuario confirmó fin de ayuno
                !_autoTriggerChecked &&
                ref.read(mealModalTriggerProvider) == false) {
              _autoTriggerChecked = true;
              debugPrint(
                  "🥗 FastingController: Verificando auto-trigger de comida.");

              Future.delayed(Duration.zero, () async {
                try {
                  // Solo disparamos si el perfil existe y el onboarding está completo
                  final userAsync = await ref
                      .read(currentUserStreamProvider.future)
                      .timeout(const Duration(seconds: 3));
                  if (userAsync == null || !userAsync.onboardingCompleted) {
                    debugPrint("🥗 Skip Trigger: Onboarding incompleto.");
                    return;
                  }

                  final DailyLog? log = await ref
                      .read(todayLogProvider(uid).future)
                      .timeout(const Duration(seconds: 5));

                  // Actualizar flag hasInitialMealBeenLogged si hay comidas
                  if (log != null && log.mealEntries.isNotEmpty) {
                    state = AsyncValue.data(state.value!.copyWith(hasInitialMealBeenLogged: true));
                  }

                  if (log != null && log.mealEntries.isEmpty && state.value?.hasInitialMealBeenLogged == false) {
                    debugPrint(
                        "🥗 Auto-Trigger: Abriendo registro de comida (Ventana con 0 comidas).");
                    ref.read(mealModalTriggerProvider.notifier).state = true;
                  } else if (log != null && log.mealEntries.isNotEmpty) {
                    debugPrint(
                        "🥗 Skip Trigger: Ya hay comidas registradas hoy.");
                    // En un futuro podríamos reactivar el modal si pasó suficiente tiempo, 
                    // pero por ahora el usuario quiere evitar bucles automáticos.
                    // ref.read(mealModalTriggerProvider.notifier).state = false;
                  }
                } catch (e) {
                  debugPrint("❌ Error en trigger de comida: $e");
                  _autoTriggerChecked = false; // Reset on error so we can retry
                }
              });
            } else if (effectivePhase == phaseFasting) {
                // Reset auto-trigger check for the next feeding window
                _autoTriggerChecked = false;
            } else if (effectivePhase == phaseFeeding && !effectiveHasConfirmed) {
              debugPrint(
                  "🥗 Skip Trigger: En Alimentación pero SIN CONFIRMACIÓN. Esperando diálogo.");
            }

            _startTicker();
          } else {
            // 🆕 CASO: No hay datos en Firestore. Inicializamos un estado de alimentación base.
            final now = DateTime.now();
            final defaultFeedingStart =
                now.subtract(const Duration(seconds: 1));

            state = AsyncValue.data(FastingState.initial().copyWith(
              feedingStartTime: defaultFeedingStart,
            ));

            // Persistimos para que el timer sea estable en el próximo snapshot
            Future.delayed(Duration.zero, () => repo.updateMetabolicState(
                  uid: uid,
                  phase: phaseFeeding,
                  feedingStartTime: defaultFeedingStart,
                  isActive: true,
                ));

            _startTicker();
          }
        },
        onError: (e, stack) {
          debugPrint("❌ Stream Error [MetabolicState]: $e");
          // No matamos el estado, dejamos el último conocido o initial si es el primero
          if (state is AsyncLoading) {
            state = AsyncValue.error(e, stack);
          }
        },
      );
    } catch (e, stack) {
      debugPrint("❌ Error en _initMetabolicMachine: $e");
      state = AsyncValue.error(e, stack);
    }
  }

  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final currentState = state.value;
    if (currentState == null) return;

    final now = DateTime.now();

    // Usar el tiempo de inicio correcto según la fase
    final baseTime = currentState.isFasting
        ? (currentState.startTime ?? now)
        : (currentState.feedingStartTime ?? now);

    final elapsed =
        now.isAfter(baseTime) ? now.difference(baseTime) : Duration.zero;

    final feedingGoal = (24 - currentState.plannedHours).toDouble();
    if (feedingGoal <= 0) return;

    // 🕒 Lógica de "Cierre de Ventana" (Threshold 30 min)
    bool windowClosing = false;
    if (currentState.isFeeding) {
      final totalFeedingSeconds = feedingGoal * 3600;
      final remainingSeconds = totalFeedingSeconds - elapsed.inSeconds;

      // Umbral: 30 minutos
      if (remainingSeconds > 0 && remainingSeconds <= 30 * 60) {
        windowClosing = true;

        // Ejecutar Háptico solo al entrar en el umbral (idempotente por estado)
        if (!currentState.isWindowClosing) {
          // debugPrint("🔔 Threshold Trigger: Faltan < 30m. Alerta de Cierre activada.");
          HapticFeedback.mediumImpact();
        }
      }
    }

    state = AsyncValue.data(currentState.copyWith(
      elapsed: elapsed,
      fastingPercent:
          (elapsed.inSeconds / (currentState.plannedHours * 3600)) * 100,
      feedingPercent: (elapsed.inSeconds / (feedingGoal * 3600)) * 100,
      isWindowClosing: windowClosing,
    ));

    // Debug periódico solo si es necesario para desarrollo (Silenciado para reducir ruido)
    // if (elapsed.inSeconds % 30 == 0) {
    //   debugPrint("💓 TICK [${currentState.currentPhase}]: ${elapsed.inSeconds}s (Base: $baseTime) | Closing: $windowClosing");
    // }
  }

  Future<void> startFast({required int hours, DateTime? manualStartTime}) async {
    final uid = ref.read(authControllerProvider.notifier).currentUser?.uid;
    if (uid == null) return;

    final startTime = manualStartTime ?? DateTime.now();

    await ref.read(fastingRepositoryProvider).updateMetabolicState(
          uid: uid,
          phase: phaseFasting,
          startTime: startTime,
          targetHours: hours,
          originalTargetHours: hours,
          isActive: true,
          hasCompletedConfirmationShown: false,
          isContinuingPastGoal: false,
          hasInitialMealBeenLogged: false, // Reset flag on start
          hasFeedingEndDialogShown: false,
        );

    final session = FastingSession(
      uid: uid,
      startTime: startTime,
      endTime: null,
      plannedDurationHours: hours,
      isCompleted: false,
    );
    await ref.read(fastingRepositoryProvider).startFast(uid, session);

    await NotificationService.scheduleFastingNotifications(
        startTime, Duration(hours: hours));
  }

  Future<void> endFasting({DateTime? manualEndTime}) async {
    final uid = ref.read(authControllerProvider.notifier).currentUser?.uid;
    final currentState = state.value;
    if (uid == null || currentState == null) return;

    final now = manualEndTime ?? DateTime.now();
    final startTime = currentState.startTime ?? now;

    debugPrint("🎬 [FastingController] endFasting() Invocado (Reactive Overlay)...");
    
    // 1. ACTUALIZACIÓN LOCAL INMEDIATA: Transición instantánea a FEEDING
    // para que la UI responda sin esperar a Firestore.
    state = AsyncValue.data(currentState.copyWith(
      currentPhase: phaseFeeding,
      feedingStartTime: now, // La ventana de alimentación comienza AHORA
      hasCompletedConfirmationShown: true,
      isContinuingPastGoal: false,
      hasInitialMealBeenLogged: false,
      hasFeedingEndDialogShown: false,
    ));


    try {
      final repo = ref.read(fastingRepositoryProvider);

      // 2. Transición Atómica en DB con Timeout de 5s
      await repo.performEndFastingBatch(
        uid: uid,
        endTime: now,
        startTime: startTime,
        targetHours: currentState.plannedHours,
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        throw TimeoutException("La conexión con Firestore ha tardado demasiado (5s). Reintente.");
      });

      debugPrint("✅ [FastingController] Transición Atómica en DB: EXITOSA");
      
      // 3. Reiniciamos el gatillo automático para la nueva fase de alimentación
      _autoTriggerChecked = false;

      // 4. Invalida telemetría previa para telemetría pura
      ref.invalidate(todayLogProvider(uid));


      // 4. Feedback Háptico
      HapticFeedback.vibrate();

      // 5. Notificaciones de ventana de alimentación
      await NotificationService.scheduleFeedingNotifications(
          now, 24 - currentState.plannedHours);

      debugPrint("🚀 [FastingController] endFasting() Finalizado con éxito.");

    } catch (e) {
      debugPrint("❌ [FastingController] Error crítico en endFasting: $e");
      // Restauramos el estado anterior (reaparece el overlay si es necesario)
      state = AsyncValue.data(currentState);
      rethrow;
    }
  }

  Future<void> setProtocol(int hours) async {
    final uid = ref.read(authControllerProvider.notifier).currentUser?.uid;
    final currentState = state.valueOrNull;
    if (uid == null || currentState == null) return;

    final originalPlannedHours = currentState.originalPlannedHours;

    // Si estamos en modo de "seguir ayunando", el nuevo protocolo debe ser
    // al menos igual o superior al ORIGINAL
    if (currentState.isContinuingPastGoal && hours < originalPlannedHours) {
      // debugPrint("🚫 No se puede seleccionar un protocolo inferior al original ($originalPlannedHours) mientras se extiende el ayuno.");
      return;
    }

    // Optimistic Update local
    state = AsyncValue.data(currentState.copyWith(plannedHours: hours));

    final now = DateTime.now();
    final startTime = currentState.startTime;
    String targetPhase = currentState.currentPhase;

    // Si el usuario cambia a un protocolo más largo que su tiempo actual,
    // nos aseguramos de que permanezca (o vuelva) a la fase de Ayuno.
    if (startTime != null) {
      final elapsed = now.difference(startTime);
      if (elapsed.inSeconds < (hours * 3600)) {
        targetPhase = phaseFasting;
      }
    }

    await ref.read(fastingRepositoryProvider).updateMetabolicState(
          uid: uid,
          phase: targetPhase,
          targetHours: hours,
        );
  }

  Future<void> setConfirmationShown(bool shown) async {
    final uid = ref.read(authControllerProvider.notifier).currentUser?.uid;
    final currentState = state.valueOrNull;
    if (uid == null || currentState == null) return;

    state = AsyncValue.data(
        currentState.copyWith(hasCompletedConfirmationShown: shown));

    await ref.read(fastingRepositoryProvider).updateMetabolicState(
          uid: uid,
          phase: currentState.currentPhase,
          hasCompletedConfirmationShown: shown,
        );
  }

  Future<void> setContinuingPastGoal(bool continuing) async {
    final uid = ref.read(authControllerProvider.notifier).currentUser?.uid;
    final currentState = state.valueOrNull;
    if (uid == null || currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(
      isContinuingPastGoal: continuing,
      hasCompletedConfirmationShown:
          true, // Al decir que continúa, marcamos que ya se preguntó
    ));

    await ref.read(fastingRepositoryProvider).updateMetabolicState(
          uid: uid,
          phase: currentState.currentPhase,
          isContinuingPastGoal: continuing,
          hasCompletedConfirmationShown: true,
        );
  }

  Future<void> updateStartTime(DateTime time) async {
    final uid = ref.read(authControllerProvider.notifier).currentUser?.uid;
    if (uid == null || state.valueOrNull == null) return;

    await ref.read(fastingRepositoryProvider).updateMetabolicState(
          uid: uid,
          phase: state.value!.currentPhase,
          startTime: time,
          feedingStartTime: state.value!.feedingStartTime,
          targetHours: state.value!.plannedHours,
          isActive: true,
        );
  }

  Future<bool> clearTodayTelemetry() async {
    final uid = ref.read(authControllerProvider.notifier).currentUser?.uid;
    if (uid == null) return false;

    try {
      // 1. Limpiamos en HealthRepository (recalcula IED a 0)
      await ref.read(healthRepositoryProvider).clearTodayMeals(uid);
      
      // 2. Disparamos inmediatamente el modal de registro para que inicie "desde cero"
      ref.read(mealModalTriggerProvider.notifier).state = true;
      
      debugPrint("🗑️ Telemetría del día limpiada con éxito.");
      return true;
    } catch (e) {
      debugPrint("❌ Error limpiando telemetría del día: $e");
      return false;
    }
  }

  DateTime _parseDateTime(dynamic val) {
    if (val == null) return DateTime.now();
    if (val is DateTime) return val;
    if (val is Timestamp) return val.toDate();

    try {
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();

      // Manejo robusto para Web y otros entornos donde el tipo Timestamp puede variar
      final dynamic dVal = val;
      if (dVal is Map) {
        final int? sec = dVal['seconds'] ?? dVal['_seconds'];
        final int? nano = dVal['nanoseconds'] ?? dVal['_nanoseconds'];
        if (sec != null) {
          return DateTime.fromMillisecondsSinceEpoch(
              sec * 1000 + ((nano ?? 0) ~/ 1000000));
        }
      }

      // Intentar método toDate() dinámico (común en web)
      return dVal.toDate() ?? DateTime.now();
    } catch (e) {
      // Fallback seguro: Si algo viene pero no es parseable, usamos 'now' para no romper el ticker
      return DateTime.now();
    }
  }

  Future<void> markFeedingEndDialogShown() async {
    final uid = ref.read(authControllerProvider.notifier).currentUser?.uid;
    final currentState = state.value;
    if (uid == null || currentState == null) return;

    state = AsyncValue.data(currentState.copyWith(
      hasFeedingEndDialogShown: true,
    ));

    await ref.read(fastingRepositoryProvider).updateMetabolicState(
          uid: uid,
          phase: currentState.currentPhase,
          hasFeedingEndDialogShown: true,
        );
  }
}

final fastingControllerProvider =
    AutoDisposeNotifierProvider<FastingController, AsyncValue<FastingState>>(
        FastingController.new);
