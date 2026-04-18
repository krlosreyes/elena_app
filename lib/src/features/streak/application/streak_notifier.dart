import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:elena_app/src/features/streak/domain/streak_engine.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
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

  /// Adherencia de los últimos 7 días (0.0-1.0).
  /// Reemplaza el `weeklyAdherence: 0.85` hardcodeado en el ScoreEngine.
  final double weeklyAdherence;

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
    this.todayEntry,
    this.history = const [],
  });

  StreakState copyWith({
    int? currentStreak,
    int? longestStreak,
    double? weeklyAdherence,
    StreakEntry? todayEntry,
    List<StreakEntry>? history,
  }) =>
      StreakState(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        weeklyAdherence: weeklyAdherence ?? this.weeklyAdherence,
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
        if (user == null) return;
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

    final repo = _ref.read(userRepositoryProvider);
    _historySub = repo.watchStreakHistory(_userId!).listen(
      (history) {
        _rebuildState(history);
      },
      onError: (e) {
        AppLogger.error('[StreakNotifier] Error en historial', e);
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

    state = state.copyWith(
      history: history,
      todayEntry: todayEntry,
      currentStreak: StreakEngine.computeCurrentStreak(history),
      longestStreak: StreakEngine.computeLongestStreak(history),
      weeklyAdherence: newAdherence,
    );

    // Persistir el ratio global solo si cambió (evita loops circulares)
    if (newAdherence != prevAdherence) {
      _persistAdherence(newAdherence);
      AppLogger.debug('📈 Adherencia semanal actualizada: $newAdherence');
    }
  }

  // ── Persistencia ────────────────────────────────────────────────────────────

  Future<void> _persistAdherence(double adherence) async {
    if (_userId == null) return;
    try {
      final repo = _ref.read(userRepositoryProvider);
      await repo.updateWeeklyAdherence(_userId!, adherence);
    } catch (e) {
      AppLogger.error('[StreakNotifier] Error al persistir adherencia', e);
    }
  }

  Future<void> _persistToday(StreakEntry entry) async {
    if (_userId == null) return;
    try {
      final repo = _ref.read(userRepositoryProvider);
      await repo.saveStreakEntry(_userId!, entry);
      AppLogger.debug('[StreakNotifier] Racha guardada: ${entry.date} — ${entry.pillarsCompleted}/5 pilares');
    } catch (e) {
      AppLogger.error('[StreakNotifier] Error al persistir racha', e);
    }
  }

  @override
  void dispose() {
    _historySub?.cancel();
    super.dispose();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────

final streakProvider =
    StateNotifierProvider<StreakNotifier, StreakState>((ref) {
  return StreakNotifier(ref);
});
