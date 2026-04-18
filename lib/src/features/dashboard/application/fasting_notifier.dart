import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/rules/circadian_rules.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:elena_app/src/core/services/notification_scheduler.dart';
import '../domain/fasting_status.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

final lastFastingIntervalProvider = StreamProvider<FastingInterval?>((ref) {
  final userRepo = ref.watch(userRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.id;

  if (uid == null) return Stream.value(null);
  return userRepo.watchLastInterval(uid);
});

class FastingNotifier extends StateNotifier<FastingState> {
  final Ref _ref;
  Timer? _timer;
  bool _fastingEndConfirmedToday = false;

  FastingNotifier(this._ref) : super(FastingState.initial()) {
    _init();
  }

  void _init() {
    _ref.listen(currentUserStreamProvider, (previous, next) {
      final user = next.value;
      if (user != null && state.fastingProtocol != user.fastingProtocol) {
        state = state.copyWith(fastingProtocol: user.fastingProtocol);
      }
    }, fireImmediately: true);

    _ref.listen(lastFastingIntervalProvider, (previous, next) {
      next.when(
        data: (interval) {
          if (interval == null) {
            state = state.copyWith(
              startTime: null,
              isActive: false,
              duration: Duration.zero,
              phase: FastingPhase.none,
            );
          } else {
            final now = DateTime.now();
            final duration = now.difference(interval.startTime);

            state = state.copyWith(
              startTime: interval.startTime,
              isActive: interval.isFasting,
              duration: duration,
              phase: interval.isFasting 
                  ? FastingState.determinePhase(duration) 
                  : FastingPhase.none,
            );
          }
        },
        loading: () => debugPrint("⏳ Sincronizando coordenadas metabólicas..."),
        error: (err, stack) => debugPrint("⚠️ Error en historial: $err"),
      );
    }, fireImmediately: true);

    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// INICIO MANUAL (Viaje en el tiempo para pruebas)
  Future<void> startFastingManual(DateTime startTime) async {
    final uid = _ref.read(authStateProvider).value?.id;
    if (uid == null) return;
    
    state = state.copyWith(isSaving: true);
    final userRepo = _ref.read(userRepositoryProvider);
    
    try {
      await userRepo.startNewInterval(uid, true, startTime: startTime);
      _fastingEndConfirmedToday = false; 
      
      // Actualización optimista inmediata para reflejar el viaje en el tiempo
      final now = DateTime.now();
      final duration = now.difference(startTime);
      
      state = state.copyWith(
        isSaving: false,
        startTime: startTime,
        isActive: true,
        duration: duration,
        phase: FastingState.determinePhase(duration),
      );

      // SPEC-05: Programar hitos de ayuno (12h, 18h, 24h) desde el inicio real.
      await NotificationScheduler.scheduleFastingMilestones(startTime);

      debugPrint("🚀 Ayuno iniciado manualmente a las $startTime (Duración inicial: ${duration.inHours}h)");
    } catch (e) {
      state = state.copyWith(isSaving: false);
    }
  }

  Future<void> startFasting() async {
    await startFastingManual(DateTime.now());
  }

  /// CIERRE MANUAL (Viaje en el tiempo para pruebas)
  Future<void> confirmManualFastingEnd(DateTime manualTime) async {
    final uid = _ref.read(authStateProvider).value?.id;
    if (uid == null || state.isSaving) return;

    state = state.copyWith(isSaving: true);
    final userRepo = _ref.read(userRepositoryProvider);

    // 1. Persistencia en Firestore (Bloque Crítico)
    try {
      await userRepo.startNewInterval(uid, false, startTime: manualTime);
      _fastingEndConfirmedToday = true;
      debugPrint("✅ Ayuno cerrado y guardado exitosamente.");
    } catch (e) {
      debugPrint("❌ Error crítico en persistencia: $e");
      state = state.copyWith(isSaving: false);
      return; // Si la persistencia falla, no seguimos
    }

    // 2. Gestión de Notificaciones (Bloque Secundario - No debe bloquear)
    try {
      await NotificationService.cancelFasting();
      final parts = state.fastingProtocol.split(':');
      final feedingHours = parts.length > 1 ? int.tryParse(parts[1]) ?? 8 : 8;
      final feedingEndTime = manualTime.add(Duration(hours: feedingHours));

      await NotificationService.scheduleAt(
        id: NotificationIds.lastMealWarning,
        title: '⏰ Cierre de ventana en 30 min',
        body: 'Última comida dentro del protocolo ${state.fastingProtocol}.',
        scheduledTime: feedingEndTime.subtract(const Duration(minutes: 30)),
        repeatsDaily: false,
      );
    } catch (e) {
      debugPrint("⚠️ Error no crítico en notificaciones: $e");
    }

    // 3. Actualización de UI
    state = state.copyWith(
      isSaving: false,
      isWaitingForFastingEnd: false,
      isActive: false,
      startTime: manualTime,
      duration: DateTime.now().difference(manualTime),
    );
  }

  Future<void> stopFasting() async {
    await confirmManualFastingEnd(DateTime.now());
  }

  /// CONFIRMACIÓN MANUAL ALIMENTACIÓN
  Future<void> confirmFeedingEnd(DateTime manualTime) async {
    final uid = _ref.read(authStateProvider).value?.id;
    if (uid == null || state.isSaving) return;

    state = state.copyWith(isSaving: true);
    final userRepo = _ref.read(userRepositoryProvider);
    
    try {
      // Al cerrar ventana, iniciamos un "intervalo" que no es ayuno
      await userRepo.startNewInterval(uid, false, startTime: manualTime);
      
      state = state.copyWith(
        isSaving: false,
        isWaitingForFeedingEnd: false,
        isActive: false,
      );
      debugPrint("🍎 Ventana de alimentación cerrada a las $manualTime");
    } catch (e) {
      state = state.copyWith(isSaving: false);
    }
  }

  void _tick() {
    if (!mounted) return;
    final now = DateTime.now();
    final user = _ref.read(currentUserStreamProvider).value;

    // 1. Alerta Pre-Sueño
    bool shouldShowPreSleepWarning = false;
    if (user != null && !state.isActive) {
      final sleepToday = DateTime(now.year, now.month, now.day, 
          user.profile.sleepTime.hour, user.profile.sleepTime.minute);
      final diffToSleep = sleepToday.difference(now);
      if (diffToSleep.inHours >= 0 && diffToSleep.inHours < 3) {
        shouldShowPreSleepWarning = true;
      }
    }

    // 2. Control de Overlays Proactivos
    bool waitingForEnd = state.isWaitingForFastingEnd;
    if (state.isActive && !waitingForEnd && !_fastingEndConfirmedToday) {
      if (state.progressPercentage >= 1.0) {
        waitingForEnd = true;
      }
    }

    // 3. Sincronización de Tiempos
    if (state.startTime == null) {
      state = state.copyWith(
        circadianPhase: CircadianRules.getPhaseName(now),
        timeUntilLock: CircadianRules.timeUntilLock(now),
        nearSleepWarning: shouldShowPreSleepWarning,
        isWaitingForFastingEnd: waitingForEnd,
      );
      return;
    }

    final duration = now.difference(state.startTime!);
    
    state = state.copyWith(
      duration: duration,
      circadianPhase: CircadianRules.getPhaseName(now),
      timeUntilLock: CircadianRules.timeUntilLock(now),
      nearSleepWarning: shouldShowPreSleepWarning,
      isWaitingForFastingEnd: waitingForEnd,
      phase: state.isActive 
          ? FastingState.determinePhase(duration) 
          : FastingPhase.none,
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final fastingProvider = StateNotifierProvider<FastingNotifier, FastingState>((ref) {
  return FastingNotifier(ref);
});