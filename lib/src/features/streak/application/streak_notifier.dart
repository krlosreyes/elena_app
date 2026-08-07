import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/streak/data/streak_repository_impl.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:elena_app/src/features/streak/domain/streak_engine.dart';
import 'package:elena_app/src/features/streak/domain/streak_repository.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/sleep/application/sleep_notifier.dart';
import 'package:elena_app/src/features/hydration/application/hydration_notifier.dart';
import 'package:elena_app/src/features/fasting/data/fasting_interval_repository_impl.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_quality_calculator.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/meal_plan_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/minuta_adherence_score.dart';
import 'package:elena_app/src/core/analytics/analytics_events.dart';
import 'package:elena_app/src/core/providers/celebration_providers.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/core/services/firestore_errors.dart';
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart'
    show currentMetabolicCycleProvider;
import 'package:elena_app/src/features/streak/data/rest_day_policy_repository.dart';
import 'package:elena_app/src/features/streak/domain/fasting_schedule.dart';
import 'package:elena_app/src/features/streak/domain/rest_day_policy.dart';
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

  /// SPEC-255 RF-02: reservas de racha disponibles (0-2). `currentStreak`
  /// ya las tiene aplicadas (es la versión "protegida" — ver
  /// [StreakEngine.computeCurrentStreakWithFreezes]).
  final int freezesAvailable;

  /// SPEC-255 RF-02: true si la racha actual incluye un día perdonado
  /// por una reserva — para mostrar un indicador sutil en la UI.
  final bool streakHasProtectedDay;

  /// Días de descanso planificado dentro de la racha actual (28-jul).
  ///
  /// Deliberadamente separado de [streakHasProtectedDay]: un día
  /// perdonado y un día descansado no son lo mismo y la UI no debe
  /// contarlos igual. "Se te pasó y te cubrimos" vs "lo planificaste y lo
  /// cumpliste" — mezclarlos convertiría el descanso en algo de lo que
  /// disculparse.
  final int streakRestDays;

  /// La política de descanso vigente. `RestDayPolicy.disabled` mientras
  /// el usuario no configure nada: la funcionalidad es opt-in y no
  /// aparece sola.
  final RestDayPolicy restPolicy;

  /// Fecha ('yyyy-MM-dd') del próximo descanso planificado, o `null` si
  /// no hay ninguno configurado. Se expone desde el estado para que la
  /// UI no tenga que recalcular semanas por su cuenta.
  final String? nextRestDate;

  /// "Racha de Calidad" (25-jul-2026, diferenciador de mercado): días
  /// consecutivos con composición real de plato ≥60% (Cociente A), no
  /// solo "registró algo". Ver `StreakEngine.computeNutritionQualityStreak`
  /// para el criterio completo y sus limitaciones sobre histórico previo
  /// al rediseño de `NutritionScoreCalculator`.
  final int nutritionQualityStreak;

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
    this.freezesAvailable = 0,
    this.streakHasProtectedDay = false,
    this.nutritionQualityStreak = 0,
    this.streakRestDays = 0,
    this.restPolicy = RestDayPolicy.disabled,
    this.nextRestDate,
  });

  /// True si HOY es el día de descanso planificado del usuario.
  bool isRestDayToday(String todayKey) => restPolicy.isRestDay(todayKey);

  StreakState copyWith({
    int? currentStreak,
    int? longestStreak,
    double? weeklyAdherence,
    double? weeklyEngagementRate,
    double? weeklyQualityScore,
    StreakEntry? todayEntry,
    List<StreakEntry>? history,
    int? freezesAvailable,
    bool? streakHasProtectedDay,
    int? nutritionQualityStreak,
    int? streakRestDays,
    RestDayPolicy? restPolicy,
    String? nextRestDate,
    bool clearNextRestDate = false,
  }) =>
      StreakState(
        currentStreak: currentStreak ?? this.currentStreak,
        longestStreak: longestStreak ?? this.longestStreak,
        weeklyAdherence: weeklyAdherence ?? this.weeklyAdherence,
        weeklyEngagementRate: weeklyEngagementRate ?? this.weeklyEngagementRate,
        weeklyQualityScore: weeklyQualityScore ?? this.weeklyQualityScore,
        todayEntry: todayEntry ?? this.todayEntry,
        history: history ?? this.history,
        freezesAvailable: freezesAvailable ?? this.freezesAvailable,
        streakHasProtectedDay:
            streakHasProtectedDay ?? this.streakHasProtectedDay,
        nutritionQualityStreak:
            nutritionQualityStreak ?? this.nutritionQualityStreak,
        streakRestDays: streakRestDays ?? this.streakRestDays,
        restPolicy: restPolicy ?? this.restPolicy,
        nextRestDate:
            clearNextRestDate ? null : (nextRestDate ?? this.nextRestDate),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// StreakNotifier
// ─────────────────────────────────────────────────────────────────────────────

class StreakNotifier extends StateNotifier<StreakState> {
  final Ref _ref;
  String? _userId;
  StreamSubscription? _historySub;

  /// 17-jul ("sistema coherente"): historial de ayunos CERRADOS,
  /// fuente de verdad de "¿el ayuno de hoy calificó?" — ver
  /// `StreakEngine.bestCompletedFastingHoursToday`. 20 cubre varios
  /// ciclos de ayuno/ventanas de alimentación intercalados de sobra
  /// para el día de hoy (el filtro `isFasting`/`endTime` es client-side
  /// en el repo, así que el límite debe cubrir intervalos mixtos).
  static const int _kFastingHistoryWindow = 20;
  StreamSubscription? _fastingHistorySub;
  List<FastingInterval> _recentCompletedFasting = const [];

  /// SPEC-230 BUG-E: flag para evitar que _evaluateToday() persista
  /// magnitudes en 0 antes de que el stream de Firestore entregue el
  /// historial real. Sin esto, un pilar que emite en cold-start crea
  /// un entry sin prev (HWM inefectivo) y puede sobreescribir datos.
  bool _historyLoaded = false;

  /// SPEC-242: flag que indica que DailyResetService está ejecutando un
  /// triggerDailyReset(). Durante este ventana, los 5 pilares se ponen
  /// transitoriamente a 0 — queremos preservar los valores previos del
  /// ciclo cerrado (para la racha del usuario). Fuera de esta ventana,
  /// usamos los valores ACTUALES sin maxMag para que el score sea dinámico:
  /// si el usuario borra vasos de agua, el score baja inmediatamente.
  bool _resetInProgress = false;

  /// SPEC-255: evita emitir celebraciones de hito/ruptura en el primer
  /// _rebuildState de la sesión (cuando el historial recién cargado ya
  /// trae una racha existente — sin esto, abrir la app con racha=10
  /// dispararía de golpe los hitos 3 y 7 de forma espuria).
  bool _celebrationBaselineSet = false;

  /// SPEC-255 RF-04: hitos nombrados de racha.
  static const List<int> _kStreakMilestones = [3, 7, 14, 30, 60, 100];

  /// Llamado por DailyResetService ANTES de resetear los pilares.
  void beginReset() => _resetInProgress = true;

  /// Llamado por DailyResetService DESPUÉS de que todos los listeners
  /// de pilares hayan tenido tiempo de disparar (con Future.delayed).
  /// Re-evalúa con el estado real post-reset.
  void endReset() {
    _resetInProgress = false;
    _evaluateToday();
  }

  /// 18-jul ("Día Metabólico: dos sistemas de día en paralelo" — hallazgo
  /// central de la auditoría): ancla de "hoy" para la racha.
  ///
  /// ANTES: `DateTime.now()` — un StreakEntry.date es un día CALENDARIO.
  /// Un día metabólico que cruza medianoche (ayuno nocturno extendido
  /// mientras el usuario duerme) partía su desempeño en DOS entradas
  /// (una por cada lado de la medianoche), cada una evaluada por separado
  /// contra el umbral de ≥3 pilares — el mismo desempeño real podía
  /// resultar en 0, 1 o 2 días acreditados según en qué lado de la
  /// medianoche cayó cada actividad. Viola METABOLIC_DAY_CONSTITUTION.md
  /// §1 ("cero referencia al reloj del calendario") y §2.1 ("crossing
  /// medianoche NO crea/cierra nada").
  ///
  /// AHORA: si hay un ciclo metabólico abierto, "hoy" es el día en que
  /// ESE CICLO empezó (`cycle.startedAt`) — el mismo ancla que ya usan
  /// los 5 pilares para su ventana de datos (`watchSince`, SPEC-149.2).
  /// Mientras el ciclo siga abierto, cada llamada a `_evaluateToday()`
  /// (cada ~10s vía el pulso metabólico, o en cada cambio de pilar)
  /// escribe SIEMPRE al mismo StreakEntry — sin importar cuántas
  /// medianoches cruce. Al abrir un ciclo nuevo, `_todayKey` cambia de
  /// inmediato al día del ciclo nuevo — la entrada anterior queda
  /// congelada con el desempeño real del día metabólico que cerró.
  ///
  /// Sin ciclo abierto (protocolo "Ninguno", o el hueco entre el cierre
  /// de un ciclo y el próximo ayuno): fallback a `DateTime.now()` — el
  /// mismo fallback documentado en METABOLIC_DAY_CONSTITUTION.md §4 para
  /// todos los providers cycle-aware.
  String get _todayKey => DayBoundaryResolver.dayKeyIso(_todayAnchor);

  /// Ancla de tiempo detrás de [_todayKey] — expuesta por separado porque
  /// `StreakEngine.computeCurrentStreak`/`computeCurrentStreakWithFreezes`
  /// necesitan el `DateTime` real (no solo la clave string) para su propio
  /// chequeo de frescura "hoy o ayer" (ver parámetro `asOf` en
  /// `streak_engine.dart`). Sin pasar esta misma ancla al engine, un
  /// ciclo abierto que empezó ayer (cruzando medianoche) se vería como
  /// "racha vieja" y se descartaría por error.
  DateTime get _todayAnchor =>
      _ref.read(currentMetabolicCycleProvider).valueOrNull?.startedAt ??
      DateTime.now();

  /// Política de descanso vigente (28-jul). `disabled` mientras el
  /// documento no exista o el stream aún no haya emitido: el descanso es
  /// opt-in y su ausencia debe comportarse EXACTAMENTE como antes de que
  /// existiera esta funcionalidad — ni un día perdonado de más.
  RestDayPolicy get _restPolicy =>
      _ref.read(restDayPolicyProvider).valueOrNull ?? RestDayPolicy.disabled;

  /// Próximo descanso planificado a partir de hoy, mirando esta semana y
  /// la siguiente.
  ///
  /// Dos semanas bastan y no es arbitrario: con un descanso por semana,
  /// si el de esta semana ya pasó, el siguiente está necesariamente en la
  /// que viene.
  String? _nextRestDateFrom(RestDayPolicy policy) {
    if (!policy.isEnabled) return null;
    final anchor = _todayAnchor;
    final todayKey = DayBoundaryResolver.dayKeyIso(anchor);

    final thisWeek = policy.restDateForWeekOf(anchor);
    if (thisWeek != null && thisWeek.compareTo(todayKey) >= 0) return thisWeek;

    return policy.restDateForWeekOf(anchor.add(const Duration(days: 7)));
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
          _fastingHistorySub?.cancel();
          _fastingHistorySub = null;
          _recentCompletedFasting = const [];
          _userId = null;
          _historyLoaded = false; // SPEC-230 BUG-E: reset en logout
          return;
        }
        if (_userId != user.id) {
          _userId = user.id;
          _subscribeToHistory();
          _subscribeToFastingHistory();
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

    // 28-jul: la política de descanso cambia la racha VISIBLE sin que
    // cambie ningún pilar — al elegir día fijo o mover el descanso de
    // esta semana. Sin este listener el número no se actualizaría hasta
    // el siguiente registro de un pilar, y el usuario vería su elección
    // "no hacer nada" durante horas.
    //
    // Se recalcula sobre el historial ya cargado (`state.history`) en vez
    // de refetchear: la política no cambia los datos, solo cómo se leen.
    _ref.listen(restDayPolicyProvider, (_, __) {
      if (state.history.isNotEmpty) _rebuildState(state.history);
    });
  }

  // ── Stream de historial Firestore ───────────────────────────────────────────

  void _subscribeToHistory() {
    _historySub?.cancel();
    if (_userId == null) return;

    // SPEC-50.3: StreakRepository (no UserRepository).
    final StreakRepository repo = _ref.read(streakRepositoryProvider);
    _historySub = repo.watchHistory(_userId!).listen(
      (history) {
        _historyLoaded = true; // SPEC-230 BUG-E: safe to evaluate now
        _rebuildState(history);
        // Trigger evaluation con el historial real como base del HWM.
        _evaluateToday();
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

  /// 17-jul ("sistema coherente"): historial de ayunos CERRADOS — fuente
  /// de verdad de "¿el ayuno de hoy calificó?" (ver
  /// `StreakEngine.bestCompletedFastingHoursToday`). Independiente del
  /// stream de `watchHistory` (racha) y del estado en vivo de
  /// `FastingNotifier` — un tercer stream, pero cada uno cubre una
  /// pregunta distinta: este es el único que sobrevive un restart de la
  /// app o la apertura de un segundo ciclo el mismo día sin depender de
  /// que la memoria del notifier se mantenga intacta.
  void _subscribeToFastingHistory() {
    _fastingHistorySub?.cancel();
    if (_userId == null) return;

    final repo = _ref.read(fastingIntervalRepositoryProvider);
    _fastingHistorySub = repo
        .watchRecentCompleted(_userId!, limit: _kFastingHistoryWindow)
        .listen(
      (intervals) {
        _recentCompletedFasting = intervals;
        // Re-evaluar con el historial de ayunos actualizado — cubre el
        // caso donde el ack de un cierre de ciclo llega DESPUÉS de que
        // el usuario ya arrancó el siguiente ayuno.
        _evaluateToday();
      },
      onError: (e) {
        if (_userId == null || FirestoreErrors.isPermissionDenied(e)) {
          AppLogger.debug(
            '[StreakNotifier] Stream de fasting_history cerrado tras logout: $e',
          );
        } else {
          AppLogger.error(
            '[StreakNotifier] Error en historial de ayunos',
            e,
          );
        }
      },
    );
  }

  // ── Evaluación de hoy ───────────────────────────────────────────────────────

  void _evaluateToday() {
    if (_userId == null) return;

    // SPEC-230 BUG-E: no evaluar hasta que el stream de Firestore entregue
    // el historial al menos una vez. Sin esto, prev = null → el HWM no
    // protege contra magnitudes en 0, y _persistToday podría sobreescribir
    // el entry real con un entry vacío.
    if (!_historyLoaded) return;

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

    // 17-jul ("sistema coherente", reemplaza el fix SPEC-208): fuente de
    // verdad de horas de ayuno de HOY = máximo entre el ciclo ACTIVO en
    // curso (progreso en vivo, no aparece en el historial hasta que se
    // cierra) y el MEJOR ciclo ya CERRADO hoy según el historial
    // persistido (`StreakEngine.bestCompletedFastingHoursToday`, ver
    // `_recentCompletedFasting`/`_subscribeToFastingHistory`).
    //
    // Antes: `completedToday`/`closedProgressToday` de `FastingNotifier`
    // — banderas que solo recuerdan el ÚLTIMO ciclo cerrado y se
    // resetean a cada apertura nueva (`startFastingManual`). Un día con
    // 2+ ciclos (Día Metabólico multi-ciclo) dependía entonces de que
    // esas banderas sobrevivieran intactas en memoria hasta el próximo
    // cierre — causa raíz de 3 bugs de racha esta sesión (16-jul y dos
    // más el 17-jul, ver `StreakEngine.reconcileTodayWithLocal`).
    // Consultar el historial persistido da la misma respuesta sin
    // importar cuántos ciclos se hayan abierto/cerrado hoy ni si la app
    // se reinició entre medio — es la fuente de verdad, no una copia en
    // memoria de ella.
    final double liveActiveFastingHours =
        fasting.isActive ? fasting.duration.inSeconds / 3600.0 : 0.0;
    final double bestClosedFastingHoursToday =
        StreakEngine.bestCompletedFastingHoursToday(
      recentCompleted: _recentCompletedFasting,
      now: DateTime.now(),
    );
    final double fastingHours =
        liveActiveFastingHours > bestClosedFastingHoursToday
            ? liveActiveFastingHours
            : bestClosedFastingHoursToday;

    // FIX: Duration.inHours trunca al entero (6:59 → 6, no 6.98).
    // Usar inSeconds/3600.0 para precisión decimal.
    final double sleepHours = sleep.lastLog == null
        ? 0.0
        : sleep.lastLog!.duration.inSeconds / 3600.0;

    // SPEC-65: magnitudes continuas. Calculadas una sola vez aquí — NO
    // duplicamos la lógica de los `evaluateX` (esos siguen siendo el
    // umbral binario). Las magnitudes son el "cuánto", no el "si o no".
    final double fastingMagnitude = _fastingTargetHours(currentProtocol) > 0
        ? fastingHours / _fastingTargetHours(currentProtocol)
        : 0.0;

    // SPEC-257 §3.1: día de descanso programado (solo protocolos Novato,
    // 12:12/14:10). En estos días NO se penaliza el pilar Ayuno — se deja
    // `fastingMagnitude` en null para que `dailyQualityScore` (SPEC-65)
    // renormalice sobre los 4 pilares restantes, exactamente el mecanismo
    // que ya usa para entradas legacy sin magnitudes. `fastingCompleted`
    // se mantiene en su valor real (false, honesto: no hubo ayuno hoy) —
    // el anillo distingue "descanso" de "incompleto" en la capa de UI
    // (`dashboard_pillars_row.dart`), re-derivando el mismo cálculo.
    final bool isFastingRestDay = FastingSchedule.isRestDay(
      date: DateTime.now(),
      protocol: currentProtocol,
      goals: _ref.read(goalsProvider),
    );
    final double? fastingMagnitudeOrNull =
        isFastingRestDay ? null : fastingMagnitude;
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
    // SPEC-274.2: la magnitud de nutrición pasa a reflejar la ADHERENCIA a
    // la Minuta cuando el usuario ya la usa (marcó ≥1 comida). Guardarraíl
    // de no-regresión: sin minuta o sin marcar, cae al nutritionScore por
    // calidad de plato de siempre (valor byte-idéntico). El gate binario de
    // racha (evaluateNutrition) NO se toca — sigue siendo "¿registró?".
    final double nutritionMagnitude = MinutaAdherenceScore.effective(
      fallbackScore: nutrition.nutritionScore,
      plan: _ref.read(mealPlanNotifierProvider).plan,
    ).clamp(0.0, 1.0);

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

    // ── SCORE DINÁMICO vs PROTECCIÓN DE RESET (SPEC-242) ────────────────
    //
    // Problema original (HWM 2026-06-17): al cerrar un ciclo metabólico,
    // triggerDailyReset() resetea los 5 pilares a 0. Los listeners
    // disparaban _evaluateToday() con 0 en todo y sobreescribían Firestore,
    // rompiendo la racha del usuario. Por eso se añadió maxMag + OR.
    //
    // Nuevo problema (2026-06-24): maxMag congela el score cuando el
    // usuario BORRA entradas (e.g., vasos de agua). Borrar 2 vasos debe
    // bajar el score, no mantenerlo en el pico del día.
    //
    // Solución: distinguir los dos casos con el flag _resetInProgress.
    //   - _resetInProgress = true (DailyResetService ejecutando reset):
    //       usar HWM (preservar prev) — los 0 son transitorios.
    //   - _resetInProgress = false (cambio normal del usuario):
    //       usar valores directos — el score refleja la realidad actual.
    final prev = state.todayEntry;

    // FIX (2026-07-16, auditoría racha/ciclos — Carlos: "la gráfica no
    // coincide con los círculos que he cerrado"): `prev` solo es una
    // base válida para "no perder progreso ya ganado hoy" si de verdad
    // es la entrada de HOY. Justo después de medianoche, antes de que
    // este método corra con la fecha nueva, `state.todayEntry` todavía
    // puede ser la entrada de AYER — usarla sin filtrar cuela el
    // cumplimiento de ayer hacia el día nuevo (o, a la inversa, un
    // `prev` de otro día nunca debería "proteger" nada de hoy). Este
    // guard aplica al resto del método.
    final StreakEntry? prevToday =
        (prev != null && prev.date == _todayKey) ? prev : null;

    // Ayuno. Desde el 17-jul, `rawFasting` (arriba, derivado de
    // `fastingHours`) YA combina el ciclo activo en curso con el mejor
    // ciclo cerrado hoy según el historial persistido — ver el
    // comentario extenso sobre `bestClosedFastingHoursToday`. Ese es
    // ahora el mecanismo PRIMARIO que resuelve el escenario multi-ciclo
    // (16-jul: `completedToday` se perdía al abrir un segundo ayuno el
    // mismo día).
    //
    // El OR con `prevToday?.fastingCompleted` que sigue abajo es una
    // red de seguridad SECUNDARIA para una ventana distinta y más
    // angosta: el instante exacto en que un ciclo se cierra y el
    // siguiente arranca, el write a `fasting_history` es asíncrono
    // (`unawaited`) y `_evaluateToday()` puede correr ANTES de que ese
    // ack vuelva por `watchRecentCompleted` — en ese hueco puntual,
    // `bestClosedFastingHoursToday` todavía no lo sabe, pero
    // `state.todayEntry` (calculado más temprano hoy, cuando el primer
    // ciclo SÍ se evaluó con el historial ya sincronizado) sigue
    // teniéndolo. Monotónico dentro del día calendario — una vez true,
    // se mantiene true.
    final bool fastingOk = rawFasting || (prevToday?.fastingCompleted ?? false);

    // Sueño/hidratación/ejercicio/nutrición: ninguno de los 4 se resetea
    // por abrir un ciclo de ayuno nuevo (solo `FastingNotifier` toca sus
    // propios flags en `startFastingManual`) — el HWM sigue acotado a la
    // ventana real de `_resetInProgress` (reset automático de
    // medianoche), ahora también con el guard `prevToday`.
    final bool sleepOk = _resetInProgress
        ? (rawSleep || (prevToday?.sleepCompleted ?? false))
        : rawSleep;
    final bool hydrationOk = _resetInProgress
        ? (rawHydration || (prevToday?.hydrationCompleted ?? false))
        : rawHydration;
    final bool exerciseOk = _resetInProgress
        ? (rawExercise || (prevToday?.exerciseLogged ?? false))
        : rawExercise;
    final bool nutritionOk = _resetInProgress
        ? (rawNutrition || (prevToday?.nutritionLogged ?? false))
        : rawNutrition;

    // SPEC-242: helper HWM solo usado cuando _resetInProgress = true.
    // Fuera de un reset, las magnitudes usan el valor actual directamente.
    double hwm(double? prev, double? current) {
      if (prev == null) return current ?? 0.0;
      if (current == null) return prev;
      return prev > current ? prev : current;
    }

    // SPEC-242 — magnitudes dinámicas.
    //
    // Durante _resetInProgress (DailyResetService vaciando pilares): usar
    // HWM para no borrar el progreso del ciclo cerrado con 0 transitorios.
    //
    // En operación normal: usar el valor ACTUAL del provider. Si el usuario
    // borra vasos de agua o sesiones de ejercicio, el score baja de inmediato.
    // Si no registró sueño, sleepQualityScore = null → CycleScoreComputer
    // lo renormaliza. Esto es correcto: el score refleja la realidad.
    final newEntry = StreakEntry(
      date: _todayKey,
      fastingCompleted: fastingOk,
      sleepCompleted: sleepOk,
      hydrationCompleted: hydrationOk,
      exerciseLogged: exerciseOk,
      nutritionLogged: nutritionOk,
      imrScore: prevToday?.imrScore ?? 0,
      // Ayuno: mismo razonamiento que `fastingOk` arriba — HWM
      // incondicional (no gateado por `_resetInProgress`) para que la
      // magnitud tampoco caiga a ~0 cuando arranca el segundo ciclo del
      // día. Sin esto, `dailyQualityScore` de hoy se hundiría igual
      // aunque `fastingCompleted` ya quedara protegido arriba.
      fastingMagnitude:
          hwm(prevToday?.fastingMagnitude, fastingMagnitudeOrNull),
      sleepQualityScore: _resetInProgress
          ? hwm(prevToday?.sleepQualityScore, sleepQualityScore)
          : sleepQualityScore,
      hydrationMagnitude: _resetInProgress
          ? hwm(prevToday?.hydrationMagnitude, hydrationMagnitude)
          : hydrationMagnitude,
      exerciseMagnitude: _resetInProgress
          ? hwm(prevToday?.exerciseMagnitude, exerciseMagnitude)
          : exerciseMagnitude,
      nutritionMagnitude: _resetInProgress
          ? hwm(prevToday?.nutritionMagnitude, nutritionMagnitude)
          : nutritionMagnitude,
    );

    // Solo actualizar si algo cambió (evita loops reactivos). Comparación
    // contra `prev` crudo (no `prevToday`): si `prev` es de ayer, el
    // `date` ya difiere de `newEntry.date` y esto nunca produce un falso
    // "sin cambios" — no necesita el guard de fecha.
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
    final prevQualified = prevToday?.qualifiesForStreak ?? false;
    final prevPillars = prevToday?.pillarsCompleted ?? 0;
    final magnitudeDeltaSignificant = prevToday != null &&
        _anyMagnitudeRose(prevToday, newEntry, threshold: 0.1);
    if (newEntry.qualifiesForStreak != prevQualified ||
        newEntry.pillarsCompleted != prevPillars ||
        magnitudeDeltaSignificant) {
      _persistToday(newEntry);
    }

    // SPEC-220: Celebración al cruzar umbral 3/5 (o subir a 4/5, 5/5).
    // Solo emitir si el pilar completado subió Y estamos en ≥3.
    //
    // FIX (2026-07-15, propuesta "racha protagonista"): antes disparaba
    // con `pillarsCompleted >= 3` sin verificar `qualifiesForStreak` — el
    // sistema podía festejar "¡Hoy cuentas para tu racha!" en un día que
    // en realidad NO calificaba (3 pilares sin ayuno ni sueño, la regla
    // de "ancla" — ver StreakEntry.qualifiesForStreak). Ahora exige
    // `qualifiesForStreak` explícitamente: la celebración solo se dispara
    // cuando el día realmente cuenta para la racha.
    if (newEntry.pillarsCompleted > prevPillars &&
        newEntry.pillarsCompleted >= 3 &&
        newEntry.qualifiesForStreak) {
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

  void _rebuildState(List<StreakEntry> rawHistory) {
    // 17-jul (Carlos: "llevaba 2, cerré el día, me devolvió a uno") —
    // ver comentario extenso en StreakEngine.reconcileTodayWithLocal.
    // El stream de Firestore puede reemitir una foto de HOY más vieja
    // que la que ya tenemos en memoria (ack desordenado tras escrituras
    // rápidas, típico al cerrar un ayuno y arrancar el siguiente el
    // mismo día). Reconciliamos ANTES de derivar todayEntry/racha para
    // que ni el display ni `computeCurrentStreakWithFreezes` (que lee
    // de `history` directo) hereden el retroceso.
    final history = StreakEngine.reconcileTodayWithLocal(
      history: rawHistory,
      localToday: state.todayEntry,
      todayKey: _todayKey,
    );

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

    // SPEC-255 RF-02: racha "protegida" (con reservas) — SOLO para el
    // número que ve el usuario. computeAdherenceTrend (IMR longitudinal)
    // sigue usando computeCurrentStreak sin protección, sin cambios aquí.
    //
    // 28-jul: entra también `restPolicy`. El descanso planificado NO se
    // mezcla con las reservas — va antes en el orden de ramas del motor,
    // porque descansar no debe gastar el colchón que existe para los
    // olvidos (ver `_forwardPassProtection`).
    final restPolicy = _restPolicy;
    final freezeState = StreakEngine.computeCurrentStreakWithFreezes(
      history,
      asOf: _todayAnchor,
      restPolicy: restPolicy,
    );
    final prevStreak = state.currentStreak;
    final prevProtected = state.streakHasProtectedDay;

    // "Racha de Calidad" (25-jul-2026): mismo historial, mismo ancla
    // cycle-aware que la racha principal — solo cambia el criterio de
    // calificación (composición real vs. 3+/5 pilares).
    final nutritionQualityStreak = StreakEngine.computeNutritionQualityStreak(
      history,
      asOf: _todayAnchor,
    );

    state = state.copyWith(
      history: history,
      todayEntry: todayEntry,
      currentStreak: freezeState.currentStreak,
      longestStreak: StreakEngine.computeLongestStreak(history),
      weeklyAdherence: newAdherence,
      weeklyEngagementRate: newEngagement,
      weeklyQualityScore: newQualityScore,
      freezesAvailable: freezeState.freezesAvailable,
      streakHasProtectedDay: freezeState.currentStreakHasProtectedDay,
      streakRestDays: freezeState.currentStreakRestDays,
      restPolicy: restPolicy,
      nextRestDate: _nextRestDateFrom(restPolicy),
      clearNextRestDate: !restPolicy.isEnabled,
      nutritionQualityStreak: nutritionQualityStreak,
    );

    // Persistir el ratio global solo si cambió (evita loops circulares)
    if (newAdherence != prevAdherence) {
      _persistAdherence(newAdherence);
      AppLogger.debug('📈 Adherencia semanal actualizada: $newAdherence');
    }

    // SPEC-255: hitos/ruptura de racha — edge-triggered, saltado en el
    // primer rebuild de la sesión (ver _celebrationBaselineSet).
    if (_celebrationBaselineSet) {
      _maybeEmitStreakCelebration(prevStreak, freezeState.currentStreak);
      if (!prevProtected && freezeState.currentStreakHasProtectedDay) {
        unawaited(AnalyticsService.logEvent(AnalyticsEvents.streakFreezeUsed));
      }
    } else {
      _celebrationBaselineSet = true;
    }
  }

  /// SPEC-255 RF-03/RF-04: detecta transiciones de racha (hito cruzado o
  /// ruptura) y emite el evento de celebración correspondiente. Edge-
  /// triggered — solo dispara en el cambio, no en cada rebuild.
  void _maybeEmitStreakCelebration(int prevStreak, int newStreak) {
    if (newStreak > prevStreak) {
      for (final milestone in _kStreakMilestones) {
        if (newStreak >= milestone && prevStreak < milestone) {
          _ref.read(celebrationEventProvider.notifier).state = CelebrationEvent(
            type: CelebrationType.streakMilestone,
            pillarsCompleted: 0,
            currentStreak: newStreak,
            timestamp: DateTime.now(),
          );
          unawaited(AnalyticsService.logEvent(
            AnalyticsEvents.streakMilestoneReached,
            params: {AnalyticsParams.milestoneDays: milestone},
          ));
          break; // un solo evento aunque se salte más de un hito
        }
      }
    } else if (newStreak == 0 && prevStreak > 0) {
      // P3 (2026-07-15): identificar el día y motivo específico de la
      // ruptura — reutiliza StreakEngine.computeProtectedDates (misma
      // fuente que ya usa computeCurrentStreakWithFreezes, ver §
      // findBreakingEntry) y StreakEntry.missReason (única fuente del
      // "por qué", compartida con el widget de HOY y el bar chart).
      //
      // 28-jul: se pasan también los descansos planificados. Culpar de la
      // ruptura a un día que el usuario declaró y cumplió sería acusarlo
      // de haber seguido su propio plan — y ese texto es justo el que
      // aparece en el momento más sensible, cuando acaba de perder la
      // racha.
      final restPolicy = _restPolicy;
      final protectedDates = StreakEngine.computeProtectedDates(
        state.history,
        restPolicy: restPolicy,
      );
      final restDates = restPolicy.isEnabled
          ? StreakEngine.computeRestDates(
              state.history,
              restPolicy: restPolicy,
            )
          : const <String>{};
      final breakingEntry = StreakEngine.findBreakingEntry(
        state.history,
        protectedDates,
        restDates: restDates,
      );
      _ref.read(celebrationEventProvider.notifier).state = CelebrationEvent(
        type: CelebrationType.streakBroken,
        pillarsCompleted: 0,
        currentStreak: prevStreak,
        timestamp: DateTime.now(),
        breakReason: breakingEntry?.missReason,
        breakDayLabel:
            breakingEntry != null ? _formatDayLabel(breakingEntry.date) : null,
      );
      unawaited(AnalyticsService.logEvent(
        AnalyticsEvents.streakBroken,
        params: {AnalyticsParams.streakLengthBucket: _bucketStreak(prevStreak)},
      ));
    }
  }

  /// P3: etiqueta legible en español para el día que rompió la racha.
  static String _formatDayLabel(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return 'ese día';
    final today = DayBoundaryResolver.startOfDay(DateTime.now());
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'hoy';
    if (d == yesterday) return 'ayer';
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    return 'el ${d.day} de ${months[d.month - 1]}';
  }

  /// SPEC-193 §2.4: bucket, no valor crudo.
  static String _bucketStreak(int days) {
    if (days >= 60) return '60+';
    if (days >= 30) return '30-59';
    if (days >= 14) return '14-29';
    if (days >= 7) return '7-13';
    if (days >= 3) return '3-6';
    return '1-2';
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
    _fastingHistorySub?.cancel();
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

// ─────────────────────────────────────────────────────────────────────────────
// Propuesta "racha protagonista" (2026-07-15, P4): aviso de racha en riesgo
// ─────────────────────────────────────────────────────────────────────────────

/// True si conviene avisar que la racha está en riesgo hoy: horario de
/// tarde/noche, el día todavía no calificó, hay una racha activa real en
/// juego, Y no hay una reserva disponible que la proteja automáticamente
/// (si `freezesAvailable > 0`, el forward-pass de
/// [StreakEngine.computeCurrentStreakWithFreezes] va a perdonar el día de
/// todos modos — avisar ahí generaría ansiedad sin motivo real).
///
/// Umbral horario (18:00): juicio de ingeniería — no hay una hora de
/// cierre única porque el Día Metabólico se ancla al usuario, no al reloj
/// (METABOLIC_DAY_CONSTITUTION §9). 18:00 da margen razonable para
/// actuar sin sentirse prematuro.
/// 28-jul: tampoco se avisa si HOY es el descanso planificado. Meter
/// prisa a alguien el día que él mismo declaró para descansar es la
/// versión más clara de lo que este trabajo viene a arreglar — sería
/// tratar su plan como un fallo.
///
/// La regla vive en [shouldWarnStreakAtRisk] (función pura) y no dentro
/// del provider a propósito: el provider depende de `streakProvider`, que
/// arrastra Firestore y los 5 pilares, y de `DateTime.now()`. Con la
/// regla dentro, un test tendría que reimplementarla para probarla — es
/// decir, fotografiaría el comportamiento en vez de exigirlo, y seguiría
/// pasando en verde si alguien rompiera el provider. Extraída, el test y
/// la app ejecutan literalmente el mismo código.
bool shouldWarnStreakAtRisk(StreakState streak, {required int hour}) {
  final todayQualifies = streak.todayEntry?.qualifiesForStreak ?? false;
  if (todayQualifies) return false;
  if (streak.currentStreak <= 0) return false;
  if (streak.freezesAvailable > 0) return false;
  final todayKey = streak.todayEntry?.date;
  if (todayKey != null && streak.restPolicy.isRestDay(todayKey)) return false;
  return hour >= 18;
}

final streakAtRiskProvider = Provider<bool>((ref) {
  return shouldWarnStreakAtRisk(
    ref.watch(streakProvider),
    hour: DateTime.now().hour,
  );
});

// ─────────────────────────────────────────────────────────────────────────────
// 22-jul: nivel de riesgo semáforo para el ring de racha del Dashboard
// ─────────────────────────────────────────────────────────────────────────────

/// Nivel semáforo de la racha, para colorear el borde del ring en
/// `DailyScoreHero` (Carlos: "verde si está activa y bien, amarillo si
/// riesgo medio, rojo si riesgo alto"). No es un concepto nuevo del
/// motor de racha — es una GRADACIÓN de las mismas señales que ya
/// existían de forma binaria en [streakAtRiskProvider] (mismo día
/// calificado, mismo umbral de 18:00, mismas reservas). Se agrega acá
/// en vez de tocar `StreakEngine`/`StreakEntry` porque es puramente de
/// PRESENTACIÓN: ninguna de las 4 señales que combina es nueva.
enum StreakRiskLevel {
  /// Sin racha activa (`currentStreak == 0`) — no hay nada que arriesgar
  /// todavía. Color neutro en el ring, no forma parte del semáforo.
  none,

  /// Racha activa y el día de hoy YA calificó — nada que hacer, verde.
  onTrack,

  /// Racha activa, hoy todavía no calificó, pero no es urgente: o queda
  /// tiempo (antes de las 18:00) o hay una reserva (`freezesAvailable`)
  /// que la protege igual — amarillo.
  atRiskMedium,

  /// Exactamente la misma condición de [streakAtRiskProvider]: sin
  /// reserva disponible y ya pasadas las 18:00 sin calificar hoy —
  /// rojo, mismo umbral que ya dispara `StreakAtRiskBanner`.
  atRiskHigh,
}

final streakRiskLevelProvider = Provider<StreakRiskLevel>((ref) {
  final streak = ref.watch(streakProvider);
  if (streak.currentStreak <= 0) return StreakRiskLevel.none;

  final todayQualifies = streak.todayEntry?.qualifiesForStreak ?? false;
  if (todayQualifies) return StreakRiskLevel.onTrack;

  // Fix (22-jul, feedback en vivo de Carlos): `qualifiesForStreak` exige
  // que el ayuno ya haya CRUZADO el 80% de su meta
  // (`StreakEngine.evaluateFasting`) — un ayuno recién arrancado o a
  // mitad de camino todavía da `fastingCompleted=false`, aunque el
  // usuario esté activamente cumpliendo su ancla en este momento. Sin
  // este chequeo, cualquiera con un ayuno EN CURSO (la señal más fuerte
  // posible de "estoy en camino") veía el ring en amarillo/rojo solo
  // por no haber cruzado todavía un umbral que de todos modos va a
  // cruzar más tarde en el mismo ayuno. "Ayuno activo" ya es evidencia
  // de que el ancla de hoy está en marcha — se trata como onTrack, no
  // como riesgo, independientemente de cuántas horas lleve.
  final fastingInProgress =
      ref.watch(fastingProvider.select((s) => s.isActive));
  if (fastingInProgress) return StreakRiskLevel.onTrack;

  // 28-jul: el día de descanso planificado no es riesgo. Va DESPUÉS de
  // `todayQualifies` a propósito: si el usuario descansaba pero aun así
  // completó sus pilares, se lleva el verde por mérito propio, no por
  // estar descansando.
  final todayKey = streak.todayEntry?.date;
  if (todayKey != null && streak.restPolicy.isRestDay(todayKey)) {
    return StreakRiskLevel.onTrack;
  }

  final noSafetyNet = streak.freezesAvailable <= 0;
  final pastThreshold = DateTime.now().hour >= 18;
  if (noSafetyNet && pastThreshold) return StreakRiskLevel.atRiskHigh;
  return StreakRiskLevel.atRiskMedium;
});
