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
import 'package:elena_app/src/features/exercise/application/exercise_state.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';

// ─────────────────────────────────────────────────────────────────────────────
// StreakState
// ─────────────────────────────────────────────────────────────────────────────

class StreakState {
  /// Racha actual: días consecutivos activos.
  final int currentStreak;

  /// Mejor racha histórica.
  final int longestStreak;

  /// Adherencia de los últimos 7 días (0.0-1.0). Métrica binaria:
  /// proporción de días que cruzaron el umbral (3 pilares + IMR≥60).
  final double weeklyAdherence;

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
    this.weeklyQualityScore = 0.0,
    this.todayEntry,
    this.history = const [],
  });

  StreakState copyWith({
    int? currentStreak,
    int? longestStreak,
    double? weeklyAdherence,
    double? weeklyQualityScore,
    StreakEntry? todayEntry,
    List<StreakEntry>? history,
  }) =>
      StreakState(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        weeklyAdherence: weeklyAdherence ?? this.weeklyAdherence,
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
  static String get _todayKey {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
  }

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
        // SPEC-87 fix: durante el logout, las queries in-flight
        // pueden fallar con permission-denied porque `request.auth`
        // se invalida antes de que el provider se desuscriba. Si ya
        // limpiamos `_userId`, el error es esperado — lo degradamos
        // a debug para no inundar logs con ruido del logout.
        if (_userId == null) {
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

    final double fastingHours = fasting.isActive
        ? fasting.duration.inSeconds / 3600.0
        : 0.0;

    final double sleepHours =
        sleep.lastLog?.duration.inHours.toDouble() ?? 0.0;

    // Obtener protocolo con fallback al estado actual si el provider está cargando (evita toggles)
    final String currentProtocol = userModel?.fastingProtocol ??
                                  (_userId != null ? '16:8' : 'Ninguno');

    // SPEC-65: magnitudes continuas. Calculadas una sola vez aquí — NO
    // duplicamos la lógica de los `evaluateX` (esos siguen siendo el
    // umbral binario). Las magnitudes son el "cuánto", no el "si o no".
    final double fastingMagnitude =
        _fastingTargetHours(currentProtocol) > 0
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
    final double nutritionMagnitude =
        nutrition.nutritionScore.clamp(0.0, 1.0);

    final newEntry = StreakEntry(
      date: _todayKey,
      fastingCompleted: StreakEngine.evaluateFasting(
        fastingHours: fastingHours,
        fastingProtocol: currentProtocol,
      ),
      sleepCompleted: StreakEngine.evaluateSleep(sleepHours: sleepHours),
      hydrationCompleted: StreakEngine.evaluateHydration(
        progressPercentage: hydration.progressPercentage,
      ),
      exerciseLogged: StreakEngine.evaluateExercise(
        exerciseMinutes: exercise.todayMinutes,
      ),
      nutritionLogged: StreakEngine.evaluateNutrition(
        mealsLogged: nutrition.mealsLoggedToday,
      ),
      imrScore: state.todayEntry?.imrScore ?? 0, // Preservar el IMR actual con null-safety
      fastingMagnitude: fastingMagnitude,
      sleepQualityScore: sleepQualityScore,
      hydrationMagnitude: hydrationMagnitude,
      exerciseMagnitude: exerciseMagnitude,
      nutritionMagnitude: nutritionMagnitude,
    );

    // Solo actualizar si algo cambió (evita loops reactivos)
    final prev = state.todayEntry;
    if (prev == newEntry) return;

    // Historial actualizado con la nueva entrada de hoy
    final updatedHistory = [
      newEntry,
      ...state.history.where((e) => e.date != _todayKey),
    ];

    _rebuildState(updatedHistory);

    // Persistir en Firestore solo cuando el día califica por primera vez
    // o cuando cambian los pilares completados (evitar writes excesivos)
    final prevQualified = prev?.qualifiesForStreak ?? false;
    final prevPillars = prev?.pillarsCompleted ?? 0;
    if (newEntry.qualifiesForStreak != prevQualified ||
        newEntry.pillarsCompleted != prevPillars) {
      _persistToday(newEntry);
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
    final newAdherence = StreakEngine.computeWeeklyAdherence(history);
    // SPEC-53: calidad continua de los últimos 7 días.
    final newQualityScore = StreakEngine.computeWeeklyQualityScore(history);

    state = state.copyWith(
      history: history,
      todayEntry: todayEntry,
      currentStreak: StreakEngine.computeCurrentStreak(history),
      longestStreak: StreakEngine.computeLongestStreak(history),
      weeklyAdherence: newAdherence,
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
    try {
      // SPEC-50.5: UserProfileRepository (no UserRepository).
      final repo = _ref.read(userProfileRepositoryProvider);
      await repo.updateWeeklyAdherence(uid, adherence);
    } catch (e) {
      if (_userId == null) {
        AppLogger.debug('[StreakNotifier] Adherence abortado por logout: $e');
      } else {
        AppLogger.error('[StreakNotifier] Error al persistir adherencia', e);
      }
    }
  }

  Future<void> _persistToday(StreakEntry entry) async {
    final uid = _userId;
    if (uid == null || uid.isEmpty) return;
    try {
      // SPEC-50.3: StreakRepository (no UserRepository).
      final StreakRepository repo = _ref.read(streakRepositoryProvider);
      await repo.save(uid, entry);
      AppLogger.debug('[StreakNotifier] Racha guardada: ${entry.date} — ${entry.pillarsCompleted}/5 pilares');
    } catch (e) {
      // SPEC-87 fix: si entre el guard y el await el usuario hizo
      // logout, la escritura falla con permission-denied. Es ruido
      // esperado del logout, no un bug.
      if (_userId == null) {
        AppLogger.debug('[StreakNotifier] Persist abortado por logout: $e');
      } else {
        AppLogger.error('[StreakNotifier] Error al persistir racha', e);
      }
    }
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
