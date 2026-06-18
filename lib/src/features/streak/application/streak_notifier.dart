import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/streak/data/streak_repository_impl.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:elena_app/src/features/streak/domain/streak_engine.dart';
import 'package:elena_app/src/features/streak/domain/streak_repository.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_quality_calculator.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/core/providers/celebration_providers.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/core/services/firestore_errors.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StreakState
// ─────────────────────────────────────────────────────────────────────────────

class StreakState {
  /// Racha actual: días consecutivos activos.
  final int currentStreak;

  /// Mejor racha histórica.
  final int longestStreak;

  /// SPEC-219: Tasa de completación semanal (0.0-1.0). Métrica binaria:
  /// proporción de días con ≥3 pilares (qualifiesForStreak). SIN requisito
  /// de IMR — rompe la circularidad con el ScoreEngine.
  final double weeklyAdherence;

  /// SPEC-219: Tasa de engagement semanal (0.0-1.0). Métrica binaria:
  /// proporción de días con IMR ≥ 60 Y ≥3 pilares (isEngaged).
  /// Para analytics y display — NO alimenta al ScoreEngine.
  final double weeklyEngagementRate;

  /// SPEC-53: calidad ponderada de los últimos 7 días (0.0-1.0).
  /// Promedio del `dailyQualityScore` de las entradas en ventana —
  /// captura magnitudes continuas (no solo "cruzó/no cruzó").
  /// Es lo que el ScoreEngine consume para el bloque metabólico.
  final double weeklyQualityScore;

  /// Estado de pilares del día de hoy.
  final StreakEntry? todayEntry;

  /// Historial de los últimos 30 días (para visualización).
  final List<StreakEntry> history;

  /// Si hoy ya califica para la racha.
  bool get todayCompleted => todayEntry?.qualifiesForStreak ?? false;

  /// Pilares completados hoy (0-5).
  int get pillarsToday => todayEntry?.pillarsCompleted ?? 0;

  const StreakState({
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.weeklyAdherence = 0.0,
    this.weeklyEngagementRate = 0.0,
    this.weeklyQualityScore = 0.0,
    this.todayEntry,
    this.history = const [],
  });

  StreakState copyWith({
    int? currentStreak,
    int? longestStreak,
    double? weeklyAdherence,
    double? weeklyEngagementRate,
    double? weeklyQualityScore,
    StreakEntry? todayEntry,
    List<StreakEntry>? history,
  }) =>
      StreakState(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        weeklyAdherence: weeklyAdherence ?? this.weeklyAdherence,
        weeklyEngagementRate: weeklyEngagementRate ?? this.weeklyEngagementRate,
        weeklyQualityScore: weeklyQualityScore ?? this.weeklyQualityScore,
        todayEntry: todayEntry ?? this.todayEntry,
        history: history ?? this.history,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// StreakNotifier
// ─────────────────────────────────────────────────────────────────────────────

class StreakNotifier extends StateNotifier<StreakState> {
  final Ref _ref;
  String? _userId;
  StreamSubscription? _historySub;

  /// Clave de fecha de hoy 'yyyy-MM-dd'.
  /// SPEC-138: delega en la fuente única del día.
  static String get _todayKey =>
      DayBoundaryResolver.dayKeyIso(DateTime.now());

  StreakNotifier(this._ref) : super(const StreakState()) {
    _init();
  }

  void _init() {
    // Observar userId para conectar el stream de historial
    _ref.listen(currentUserStreamProvider, (_, AsyncValue<UserModel?> next) {
      next.whenData((user) {
        // SPEC-87 fix: al cerrar sesión, `user` se vuelve null. Antes,
        // el listener retornaba sin hacer cleanup: el stream Firestore
        // seguía suscrito con el uid anterior y los listeners de
        // pilares disparaban `_persistToday` con un uid sin `auth`
        // válido → `permission-denied`. Ahora cancelamos la
        // subscription y limpiamos `_userId` para que cualquier
        // operación posterior salga por los guards.
        if (user == null) {
          _historySub?.cancel();
          _historySub = null;
          _userId = null;
          return;
        }
        if (_userId != user.id) {
          _userId = user.id;
          _subscribeToHistory();
        }
      });
    }, fireImmediately: true);

    // Observar cada pilar para re-evaluar el cumplimiento de hoy.
    // Sin type parameter explícito: los valores prev/next no se usan,
    // solo necesitamos disparar _evaluateToday() en cada cambio.
    _ref.listen(fastingProvider, (_, __) => _evaluateToday());
    _ref.listen(sleepProvider, (_, __) => _evaluateToday());
    _ref.listen(hydrationProvider, (_, __) => _evaluateToday());
    _ref.listen(exerciseProvider, (_, __) => _evaluateToday());
    _ref.listen(nutritionProvider, (_, __) => _evaluateToday());
  }

  // ── Stream de historial Firestore ───────────────────────────────────────────

  void _subscribeToHistory() {
    _historySub?.cancel();
    if (_userId == null) return;

    // SPEC-50.3: StreakRepository (no UserRepository).
    final StreakRepository repo = _ref.read(streakRepositoryProvider);
    _historySub = repo.watchHistory(_userId!).listen(
      (history) {
        _rebuildState(history);
      },
      onError: (e) {
        // SPEC-87 fix / SPEC-107: durante el logout, las queries
        // in-flight pueden fallar con permission-denied porque
        // `request.auth` se invalida antes de que el provider se
        // desuscriba. Detectamos el caso por dos vías:
        //   1) `_userId == null` (ya recibimos la señal de logout).
        //   2) El error es directamente permission-denied (el
        //      snapshot stale llega antes que la señal de logout).
        // En ambos casos degradamos a debug para no inundar logs.
        if (_userId == null || FirestoreErrors.isPermissionDenied(e)) {
          AppLogger.debug('[StreakNotifier] Stream cerrado tras logout: $e');
        } else {
          AppLogger.error('[StreakNotifier] Error en historial', e);
        }
      },
    );
  }

  // ── Evaluación de hoy ───────────────────────────────────────────────────────

  void _evaluateToday() {
    if (_userId == null) return;

    final fasting = _ref.read(fastingProvider);
    final sleep = _ref.read(sleepProvider);
    final hydration = _ref.read(hydrationProvider);
    final exercise = _ref.read(exerciseProvider);
    final nutrition = _ref.read(nutritionProvider);
    final userModel = _ref.read(currentUserStreamProvider).valueOrNull;

    // Obtener protocolo con fallback al estado actual si el provider está cargando (evita toggles)
    // Declarado antes del bloque SPEC-208 porque fastingHours lo necesita.
    final String currentProtocol =
        userModel?.fastingProtocol ?? (_userId != null ? '16:8' : 'Ninguno');

    // SPEC-208: preservar el progreso del ayuno DESPUÉS de cerrarlo.
    // Bug previo: cuando !isActive, fastingHours = 0.0 → al registrar
    // agua/comida después de cerrar el ayuno, _evaluateToday() sobreescribía
    // fastingCompleted: true → false en Firestore.
    // Fix: usar completedToday / closedProgressToday que FastingNotifier
    // preserva al cerrar el ayuno.
    final double fastingHours;
    if (fasting.isActive) {
      // Ayuno en curso: duración real acumulada.
      fastingHours = fasting.duration.inSeconds / 3600.0;
    } else if (fasting.completedToday == true) {
      // Ayuno cerrado y completado: target completo → magnitude ≥ 1.0.
      fastingHours = _fastingTargetHours(currentProtocol);
    } else {
      // Ayuno cerrado sin completar, o sin ayuno hoy.
      fastingHours =
          (fasting.closedProgressToday ?? 0.0) *
          _fastingTargetHours(currentProtocol);
    }

    final double sleepHours = sleep.lastLog?.duration.inHours.toDouble() ?? 0.0;

    // SPEC-65: magnitudes continuas. Calculadas una sola vez aquí — NO
    // duplicamos la lógica de los `evaluateX` (esos siguen siendo el
    // umbral binario). Las magnitudes son el "cuánto", no el "si o no".
    final double fastingMagnitude = _fastingTargetHours(currentProtocol) > 0
        ? fastingHours / _fastingTargetHours(currentProtocol)
        : 0.0;
    final double? sleepQualityScore = sleep.lastLog == null
        ? null
        : SleepQualityCalculator.calculate(
            sleepHours: sleepHours,
            metabolicGapMinutes: sleep.lastLog!.metabolicGap.inMinutes,
            sleepLatencyMinutes: sleep.lastLog!.sleepLatencyMinutes,
            nightAwakenings: sleep.lastLog!.nightAwakenings,
            subjectiveQuality: sleep.lastLog!.subjectiveQuality,
          );
    final double hydrationMagnitude = hydration.progressPercentage;
    // Magnitud de ejercicio: 30 min = 1.0 (full ACSM moderate session).
    // Sesiones largas pueden superar 1.0; el calc de dailyQualityScore
    // aplica clamp en [0, 1] ahí.
    final double exerciseMagnitude = exercise.todayMinutes / 30.0;
    final double nutritionMagnitude = nutrition.nutritionScore.clamp(0.0, 1.0);

    // Evaluación cruda desde el estado actual de los providers.
    final rawFasting = StreakEngine.evaluateFasting(
      fastingHours: fastingHours,
      fastingProtocol: currentProtocol,
    );
    final rawSleep = StreakEngine.evaluateSleep(sleepHours: sleepHours);
    final rawHydration = StreakEngine.evaluateHydration(
      progressPercentage: hydration.progressPercentage,
    );
    final rawExercise = StreakEngine.evaluateExercise(
      exerciseMinutes: exercise.todayMinutes,
    );
    final rawNutrition = StreakEngine.evaluateNutrition(
      mealsLogged: nutrition.mealsLoggedToday,
    );

    // ── HIGH WATER MARK (2026-06-17) ────────────────────────────────────
    // Dentro del mismo día calendario, un pilar completado NO puede
    // degradarse a incompleto. Motivo: al cerrar un ciclo metabólico,
    // triggerDailyReset() resetea los notifiers in-memory a cero. Los
    // listeners del StreakNotifier disparan _evaluateToday() con datos
    // vacíos y SOBREESCRIBEN la entrada en Firestore con 0 pilares,
    // rompiendo la racha del usuario.
    //
    // Un ejercicio que ya se hizo no se "deshace". Un sueño que ya se
    // registró no desaparece. La lógica OR garantiza que la entrada
    // solo puede MEJORAR dentro del mismo día.
    //
    // Para magnitudes: MAX del valor previo y el nuevo. Misma lógica:
    // si el usuario logró hydrationMagnitude=0.85 antes del reset,
    // no debe bajar a 0.0 por el reset transitorio.
    final prev = state.todayEntry;
    final bool fastingOk = rawFasting || (prev?.fastingCompleted ?? false);
    final bool sleepOk = rawSleep || (prev?.sleepCompleted ?? false);
    final bool hydrationOk = rawHydration || (prev?.hydrationCompleted ?? false);
    final bool exerciseOk = rawExercise || (prev?.exerciseLogged ?? false);
    final bool nutritionOk = rawNutrition || (prev?.nutritionLogged ?? false);

    double maxMag(double? a, double? b) {
      if (a == null) return b ?? 0.0;
      if (b == null) return a;
      return a > b ? a : b;
    }

    final newEntry = StreakEntry(
      date: _todayKey,
      fastingCompleted: fastingOk,
      sleepCompleted: sleepOk,
      hydrationCompleted: hydrationOk,
      exerciseLogged: exerciseOk,
      nutritionLogged: nutritionOk,
      imrScore: state.todayEntry?.imrScore ??
          0, // Preservar el IMR actual con null-safety
      fastingMagnitude: maxMag(prev?.fastingMagnitude, fastingMagnitude),
      sleepQualityScore: sleepQualityScore ?? prev?.sleepQualityScore,
      hydrationMagnitude: maxMag(prev?.hydrationMagnitude, hydrationMagnitude),
      exerciseMagnitude: maxMag(prev?.exerciseMagnitude, exerciseMagnitude),
      nutritionMagnitude: maxMag(prev?.nutritionMagnitude, nutritionMagnitude),
    );

    // Solo actualizar si algo cambió (evita loops reactivos)
    if (prev == newEntry) return;

    // Historial actualizado con la nueva entrada de hoy
    final updatedHistory = [
      newEntry,
      ...state.history.where((e) => e.date != _todayKey),
    ];

    _rebuildState(updatedHistory);

    // Persistir en Firestore cuando:
    //   1. El día califica/descalifica por primera vez
    //   2. Los pilares completados cambian
    //   3. SPEC-229 BUG-D: alguna magnitud subió significativamente (> 0.1)
    //      Sin esto, si la app se mata mid-day las magnitudes in-memory se
    //      pierden y el evaluador lee valores stale al reiniciar.
    final prevQualified = prev?.qualifiesForStreak ?? false;
    final prevPillars = prev?.pillarsCompleted ?? 0;
    final magnitudeDeltaSignificant = prev != null &&
        _anyMagnitudeRose(prev, newEntry, threshold: 0.1);
    if (newEntry.qualifiesForStreak != prevQualified ||
        newEntry.pillarsCompleted != prevPillars ||
        magnitudeDeltaSignificant) {
      _persistToday(newEntry);
    }

    // SPEC-220: Celebración al cruzar umbral 3/5 (o subir a 4/5, 5/5).
    // Solo emitir si el pilar completado subió Y estamos en ≥3.
    if (newEntry.pillarsCompleted >= 3 &&
        newEntry.pillarsCompleted > prevPillars) {
      _ref.read(celebrationEventProvider.notifier).state = CelebrationEvent(
        type: CelebrationType.streakThreshold,
        pillarsCompleted: newEntry.pillarsCompleted,
        currentStreak: state.currentStreak,
        timestamp: DateTime.now(),
      );
    }
  }

  /// Actualiza el IMR en el entry de hoy (llamado desde AnalysisScreen).
  void updateTodayImr(int imrScore) {
    final current = state.todayEntry;
    if (current == null || current.imrScore == imrScore) return;
    final updated = current.copyWith(imrScore: imrScore);
    final updatedHistory = [
      updated,
      ...state.history.where((e) => e.date != _todayKey),
    ];
    _rebuildState(updatedHistory);
    _persistToday(updated);
  }

  // ── Estado derivado ─────────────────────────────────────────────────────────

  void _rebuildState(List<StreakEntry> history) {
    final todayEntry = history.firstWhere(
      (e) => e.date == _todayKey,
      orElse: () => StreakEntry(
        date: _todayKey,
        fastingCompleted: false,
        sleepCompleted: false,
        hydrationCompleted: false,
        exerciseLogged: false,
        nutritionLogged: false,
        imrScore: 0,
      ),
    );

    final prevAdherence = state.weeklyAdherence;
    // SPEC-219: completionRate (sin IMR) para ScoreEngine,
    // engagementRate (con IMR) para analytics/display.
    final newAdherence = StreakEngine.computeWeeklyCompletionRate(history);
    final newEngagement = StreakEngine.computeWeeklyEngagementRate(history);
    // SPEC-53: calidad continua de los últimos 7 días.
    final newQualityScore = StreakEngine.computeWeeklyQualityScore(history);

    state = state.copyWith(
      history: history,
      todayEntry: todayEntry,
      currentStreak: StreakEngine.computeCurrentStreak(history),
      longestStreak: StreakEngine.computeLongestStreak(history),
      weeklyAdherence: newAdherence,
      weeklyEngagementRate: newEngagement,
      weeklyQualityScore: newQualityScore,
    );

    // Persistir el ratio global solo si cambió (evita loops circulares)
    if (newAdherence != prevAdherence) {
      _persistAdherence(newAdherence);
      AppLogger.debug('📈 Adherencia semanal actualizada: $newAdherence');
    }
  }

  // ── Persistencia ────────────────────────────────────────────────────────────

  Future<void> _persistAdherence(double adherence) async {
    // SPEC-87 defensa: tanto null como "" producen un path inválido en
    // Firestore (`users//...`) que retorna permission-denied. Saltamos
    // la escritura hasta tener un uid real.
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    // SPEC-206 (offline-first): write no bloqueante (offline el await no
    // resuelve). El catch preserva el manejo logout-aware (SPEC-87).
    final repo = _ref.read(userProfileRepositoryProvider);
    unawaited(repo.updateWeeklyAdherence(uid, adherence).catchError((Object e) {
      if (_userId == null) {
        AppLogger.debug('[StreakNotifier] Adherence abortado por logout: $e');
      } else {
        AppLogger.error('[StreakNotifier] Error al persistir adherencia', e);
      }
    }));
  }

  /// SPEC-229 BUG-D: detecta si alguna magnitud subió más de [threshold].
  /// Solo miramos incrementos (high water mark en _evaluateToday ya impide
  /// decrementos), así que comparamos `new > old + threshold`.
  static bool _anyMagnitudeRose(
    StreakEntry old,
    StreakEntry current, {
    required double threshold,
  }) {
    bool rose(double? oldVal, double? newVal) =>
        (newVal ?? 0) - (oldVal ?? 0) > threshold;
    return rose(old.fastingMagnitude, current.fastingMagnitude) ||
        rose(old.sleepQualityScore, current.sleepQualityScore) ||
        rose(old.hydrationMagnitude, current.hydrationMagnitude) ||
        rose(old.exerciseMagnitude, current.exerciseMagnitude) ||
        rose(old.nutritionMagnitude, current.nutritionMagnitude);
  }

  Future<void> _persistToday(StreakEntry entry) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    // SPEC-206 (offline-first): write no bloqueante. El stream de racha refleja
    // la entrada desde la caché; el ack sincroniza al reconectar.
    final StreakRepository repo = _ref.read(streakRepositoryProvider);
    unawaited(repo.save(uid, entry).then((_) {
      AppLogger.debug(
          '[StreakNotifier] Racha guardada: ${entry.date} — ${entry.pillarsCompleted}/5 pilares');
    }).catchError((Object e) {
      // SPEC-87 fix: tras logout la escritura falla con permission-denied
      // (ruido esperado, no bug).
      if (_userId == null) {
        AppLogger.debug('[StreakNotifier] Persist abortado por logout: $e');
      } else {
        AppLogger.error('[StreakNotifier] Error al persistir racha', e);
      }
    }));
  }

  @override
  void dispose() {
    _historySub?.cancel();
    super.dispose();
  }

  // ── Helpers privados (SPEC-65) ──────────────────────────────────────────────

  /// Horas objetivo del protocolo. Espejo de la lógica de
  /// `StreakEngine.evaluateFasting` pero retorna el valor crudo (no el
  /// 80% del umbral), para que `fastingMagnitude` sea verdaderamente
  /// proporcional al protocolo.
  ///
  /// - 'Ninguno' → 10h (umbral natural de ayuno nocturno).
  /// - 'HH:MM' (e.g. '16:8') → primer número (16).
  /// - Cualquier otra cosa → 16 como default seguro.
  static double _fastingTargetHours(String protocol) {
    if (protocol == 'Ninguno') return 10.0;
    final parts = protocol.split(':');
    return double.tryParse(parts.first) ?? 16.0;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final streakProvider =
    StateNotifierProvider<StreakNotifier, StreakState>((ref) {
  return StreakNotifier(ref);
});
