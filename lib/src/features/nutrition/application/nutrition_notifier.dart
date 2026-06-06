// SPEC-63: NutritionNotifier consume el NutritionRepository — los logs
// ahora persisten en Firestore en lugar de vivir solo en memoria.
//
// Antes: la lista de logs vivía en `state.todayLogs` y se perdía al cerrar
// la app. Ahora: el repositorio es la fuente de verdad; el state local
// sólo es un cache reactivo del stream `watchTodayLogs`.
//
// CONSTITUTION §3.2: este archivo NO importa cloud_firestore. Solo conoce
// el contrato `NutritionRepository`.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// SPEC-194.1 (2026-06-06): day_boundary_resolver reintroducido como
// fallback exclusivo para el caso "sin ciclo abierto". Con ciclo, sigue
// cycle-aware (Constitución §1). Sin ciclo, ventana startOfDay para
// que los logs del día sean visibles en el ring.
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/core/services/notification_scheduler.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/nutrition/data/nutrition_repository_impl.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_interval_rules.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

// ─── State ────────────────────────────────────────────────────────────────────

class NutritionState {
  /// Cuántas comidas tiene como objetivo el usuario por día.
  final int targetMeals;

  /// Logs del día actual (cache reactivo del stream del repositorio).
  final List<NutritionLog> todayLogs;

  /// Score 0.0-1.0 que el ScoreEngine consume para el bloque Conducta.
  /// 60% adherencia de cantidad + 40% adherencia de ventana circadiana.
  final double nutritionScore;

  /// % de comidas registradas dentro de la ventana circadiana.
  final double windowAdherence;

  final bool isSaving;

  const NutritionState({
    this.targetMeals = 3,
    this.todayLogs = const [],
    this.nutritionScore = 0.0,
    this.windowAdherence = 0.0,
    this.isSaving = false,
  });

  int get mealsLoggedToday => todayLogs.length;

  double get progressPercentage =>
      (mealsLoggedToday / targetMeals.clamp(1, 10)).clamp(0.0, 1.0);

  String get nextMealLabel {
    switch (mealsLoggedToday) {
      case 0:
        return 'Desayuno';
      case 1:
        return targetMeals <= 2 ? 'Cena' : 'Almuerzo';
      case 2:
        return 'Cena';
      default:
        return 'Snack';
    }
  }

  NutritionState copyWith({
    int? targetMeals,
    List<NutritionLog>? todayLogs,
    double? nutritionScore,
    double? windowAdherence,
    bool? isSaving,
  }) {
    return NutritionState(
      targetMeals: targetMeals ?? this.targetMeals,
      todayLogs: todayLogs ?? this.todayLogs,
      nutritionScore: nutritionScore ?? this.nutritionScore,
      windowAdherence: windowAdherence ?? this.windowAdherence,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class NutritionNotifier extends StateNotifier<NutritionState> {
  NutritionNotifier(this._ref) : super(const NutritionState()) {
    _init();
  }

  final Ref _ref;
  CircadianProfile? _circadianProfile;
  StreamSubscription<List<NutritionLog>>? _logsSub;
  String? _activeUserId;
  DateTime? _currentCycleStartedAt;

  void _init() {
    // Escucha cambios de usuario para targetMeals, perfil circadiano y stream.
    _ref.listen<AsyncValue<UserModel?>>(
      currentUserStreamProvider,
      (previous, next) {
        next.whenData((user) {
          if (user == null) {
            _activeUserId = null;
            _logsSub?.cancel();
            _logsSub = null;
            if (mounted) state = const NutritionState();
            return;
          }
          _circadianProfile = user.profile;
          if (_activeUserId != user.id) {
            _activeUserId = user.id;
            _subscribeFor(_currentCycleStartedAt);
          }
          // Recalcula con los nuevos parámetros del usuario.
          final updated = _recalculate(state.todayLogs, user.mealsPerDay);
          state = updated.copyWith(targetMeals: user.mealsPerDay);
        });
      },
      fireImmediately: true,
    );

    // SPEC-149.2: re-suscribir cuando cambia el inicio del ciclo
    // metabólico — el conteo de comidas se ancla al Día Metabólico.
    _ref.listen<AsyncValue<MetabolicCycle?>>(
      currentMetabolicCycleProvider,
      (previous, next) {
        next.whenData((cycle) {
          final newSince = cycle?.startedAt;
          // SPEC-178.bugfix2 (2026-06-05): si el primer fire emite con
          // cycle == null, newSince == _currentCycleStartedAt (ambos null)
          // y la igualdad bloqueaba la suscripción inicial. Subscribe
          // siempre que no haya subscription activa.
          if (_logsSub == null ||
              newSince != _currentCycleStartedAt) {
            _currentCycleStartedAt = newSince;
            _subscribeFor(newSince);
          }
        });
      },
      fireImmediately: true,
    );
  }

  /// SPEC-149.2 + SPEC-189 + SPEC-194.1 (2026-06-06): suscripción al
  /// stream filtrado por la ventana del ciclo metabólico, con FALLBACK
  /// `startOfDay(now)` cuando no hay ciclo abierto.
  ///
  /// Cycle-aware (Constitución §1) con ciclo activo: ventana desde
  /// `cycle.startedAt`. SIN ciclo (primer uso, post-cierre antes del
  /// próximo ayuno, desync), ventana desde `startOfDay(now)` para que
  /// las comidas registradas hoy sean visibles en el ring. Antes el
  /// state quedaba con lista vacía y el ring en 0% aunque hubiese
  /// nutrition_logs en Firestore — bug post-SPEC-194 al quitar el
  /// placeholder. Cuando el usuario inicie el próximo ayuno, el
  /// listener al cycle re-suscribe automáticamente con la nueva ventana.
  void _subscribeFor(DateTime? cycleStartedAt) {
    final userId = _activeUserId;
    if (userId == null) return;
    _logsSub?.cancel();
    _logsSub = null;
    final since = cycleStartedAt ??
        DayBoundaryResolver.startOfDay(DateTime.now());
    final repo = _ref.read(nutritionRepositoryProvider);
    _logsSub = repo.watchSinceLogs(userId, since).listen(
      (logs) {
        if (!mounted) return;
        state = _recalculate(logs, state.targetMeals);
      },
      onError: (Object _) {
        // El repositorio puede emitir errors transitorios de red. Mantener
        // el estado anterior; el próximo evento estable corregirá.
      },
    );
  }

  // ─── API pública ─────────────────────────────────────────────────────────

  /// Registra una comida.
  ///
  /// [label]    — etiqueta semántica opcional; si no se provee se infiere.
  /// [mealTime] — timestamp opcional; si no se provee se usa `DateTime.now()`.
  ///
  /// SPEC-71.3: macros opcionales (SPEC-64). Si el usuario no los provee,
  /// quedan null y el log se persiste sin información nutricional — el
  /// ScoreEngine sigue contando la comida en el ratio meal/target sin
  /// penalizar la ausencia de macros (peso 0.12 conservador, ver
  /// IMR_BIBLIOGRAPHY.md §4.4).
  Future<void> logMeal({
    String? label,
    DateTime? mealTime,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    int? glycemicIndex,
    NutritionLogSource source = NutritionLogSource.userInput,
    // SPEC-137: clasificación A:E del plato. Default a2e1 (2x1) para
    // callers que no pasen ratio (tests existentes, código legacy).
    MealRatio ratio = MealRatio.a2e1,
    // SPEC-137: marca el log como día de permitidos. Default false.
    bool isCheatDay = false,
    // SPEC-137 E.5: si true, ignora el warning de intervalo 2-3h y
    // registra igual. NO ignora el bloqueo (<2h). UI debe pasarlo en
    // true solo después de que el usuario acepte el dialog de warning.
    bool forceLog = false,
    // SPEC-138: slots NOVA 4 del plato (numerador del % UPF).
    // Null si el caller no usa PlateBuilder (tests, código legacy).
    int? upfSlots,
    // SPEC-138: total de slots del plato (denominador).
    // Null si el caller no usa PlateBuilder.
    int? totalSlots,
  }) async {
    final userId = _activeUserId;
    if (userId == null) return;

    final timestamp = mealTime ?? DateTime.now();
    final effectiveLabel = label ?? state.nextMealLabel;
    final withinWindow = _isWithinCircadianWindow(timestamp);

    // SPEC-137 E.5: validar intervalo entre comidas. Día de permitidos
    // suspende la regla. Si el log es retroactivo (mealTime en el
    // pasado), validamos contra el timestamp ingresado, no contra now.
    final lastMealAt = MealIntervalRules.lastMealOf(state.todayLogs);
    final check = MealIntervalRules.check(
      lastMealAt: lastMealAt,
      attemptAt: timestamp,
      cheatDayActive: isCheatDay,
    );

    switch (check) {
      case MealIntervalCheck.blocked:
        throw MealTooSoonException(
          lastMealAt: lastMealAt!,
          attemptedAt: timestamp,
          canRegisterAt:
              lastMealAt.add(MealIntervalRules.minInterval),
        );
      case MealIntervalCheck.warning:
        if (!forceLog) {
          throw MealIntervalWarning(
            lastMealAt: lastMealAt!,
            attemptedAt: timestamp,
            recommendedAt:
                lastMealAt.add(MealIntervalRules.recommendedInterval),
          );
        }
      case MealIntervalCheck.ok:
      case MealIntervalCheck.firstMeal:
      case MealIntervalCheck.cheatDayBypass:
        break;
    }

    final log = NutritionLog(
      id: const Uuid().v4(),
      timestamp: timestamp,
      label: effectiveLabel,
      withinCircadianWindow: withinWindow,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      glycemicIndex: glycemicIndex,
      source: source,
      ratio: ratio,
      isCheatDay: isCheatDay,
      // SPEC-138: solo persistir si ambos vienen y son coherentes.
      // La validación dura está en el constructor de NutritionLog.
      upfSlots: upfSlots,
      totalSlots: totalSlots,
    );

    if (mounted) state = state.copyWith(isSaving: true);
    try {
      final repo = _ref.read(nutritionRepositoryProvider);
      await repo.saveMeal(userId, log);
      // El stream emitirá la nueva lista; no hay que mutar todayLogs aquí.

      // SPEC-137 E.5: agendar push del SO 30 min antes de la próxima
      // comida sugerida. Si está en cheat day, cancelar cualquier
      // notificación previa — el usuario eligió libre y no queremos
      // bombardearlo con recordatorios.
      if (isCheatDay) {
        await NotificationScheduler.cancelNextMealReminder();
      } else {
        final nextAt = timestamp.add(MealIntervalRules.recommendedInterval);
        await NotificationScheduler.scheduleNextMealReminder(
          nextMealAt: nextAt,
          leadTime: MealIntervalRules.notificationLeadTime,
        );
      }
    } finally {
      if (mounted) state = state.copyWith(isSaving: false);
    }
  }

  /// Elimina el último registro del día.
  Future<void> removeLastMeal() async {
    final userId = _activeUserId;
    if (userId == null) return;
    final repo = _ref.read(nutritionRepositoryProvider);
    await repo.removeLastMeal(userId);
    // El stream emitirá la lista actualizada.

    // SPEC-137 E.5: si después de remover queda alguna comida hoy,
    // re-agendar la notificación con la nueva "última comida". Si no
    // queda ninguna, cancelar.
    final remaining = state.todayLogs.length > 1
        ? state.todayLogs.sublist(0, state.todayLogs.length - 1)
        : <NutritionLog>[];
    final lastAt = MealIntervalRules.lastMealOf(remaining);
    if (lastAt == null) {
      await NotificationScheduler.cancelNextMealReminder();
    } else {
      final nextAt = lastAt.add(MealIntervalRules.recommendedInterval);
      await NotificationScheduler.scheduleNextMealReminder(
        nextMealAt: nextAt,
        leadTime: MealIntervalRules.notificationLeadTime,
      );
    }
  }

  /// SPEC-58 + SPEC-149.2: Reset idempotente disparado al cierre del
  /// ciclo metabólico o a medianoche calendárica (red de seguridad).
  ///
  /// Limpia el cache local y re-suscribe el stream usando el `since`
  /// del ciclo activo (anclado al Día Metabólico). Los logs persistidos
  /// quedan intactos para análisis longitudinal.
  void resetDaily() {
    if (!mounted) return;
    state = state.copyWith(
      todayLogs: const [],
      nutritionScore: 0.0,
      windowAdherence: 0.0,
    );
    _subscribeFor(_currentCycleStartedAt);
  }

  @override
  void dispose() {
    _logsSub?.cancel();
    super.dispose();
  }

  // ─── Lógica interna ──────────────────────────────────────────────────────

  bool _isWithinCircadianWindow(DateTime time) {
    final profile = _circadianProfile;
    if (profile == null) return true;
    final first = profile.firstMealGoal;
    final last = profile.lastMealGoal;
    if (first == null || last == null) return true;
    final timeMinutes = time.hour * 60 + time.minute;
    final firstMinutes = first.hour * 60 + first.minute;
    final lastMinutes = last.hour * 60 + last.minute;
    return timeMinutes >= firstMinutes && timeMinutes <= lastMinutes;
  }

  /// Recalcula nutritionScore y windowAdherence dado un conjunto de logs.
  NutritionState _recalculate(List<NutritionLog> logs, int target) {
    final int count = logs.length;
    final double mealCountScore = (count / target.clamp(1, 10)).clamp(0.0, 1.0);
    final double windowAdherence = count == 0
        ? 0.0
        : logs.where((l) => l.withinCircadianWindow).length / count;
    final double score =
        ((0.60 * mealCountScore) + (0.40 * windowAdherence)).clamp(0.0, 1.0);
    return state.copyWith(
      todayLogs: logs,
      nutritionScore: score,
      windowAdherence: windowAdherence,
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final nutritionProvider =
    StateNotifierProvider<NutritionNotifier, NutritionState>((ref) {
  return NutritionNotifier(ref);
});
