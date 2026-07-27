import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/providers/ticker_providers.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/hydration/application/hydration_notifier.dart';
import 'package:elena_app/src/features/sleep/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/selected_pillar.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/daily_score_explainer_sheet.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/daily_score_hero.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/pillar_ring.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/goals/application/pillar_goal_providers.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/onboarding/application/tour_targets_provider.dart';
import 'package:elena_app/src/features/streak/application/daily_score_provider.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/streak/domain/fasting_schedule.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// Fila horizontal de 5 anillos circulares — uno por pilar.
/// Cada anillo es interactivo y abre su sheet de input correspondiente.
/// El pilar de Ayuno está visualmente destacado cuando está activo.
///
/// SPEC-140.1: el header ahora incluye el Score del Día (agregado de
/// los 5 pilares), el delta vs ayer y el icono ⓘ que abre el
/// explainer educativo. Cada PillarRing muestra su % bajo el label.
///
/// SPEC-119: extraído de `_buildPillarsRow` en `dashboard_screen.dart`
/// (ARCH-03). `_selectedPillar` y el `setState` del State original se
/// reemplazaron por los parámetros `selectedPillar` + `onSelectPillar`
/// — la única diferencia mecánica necesaria para vivir fuera del State.
/// El resto del cuerpo es idéntico al método original.
class DashboardPillarsRow extends ConsumerWidget {
  const DashboardPillarsRow({
    super.key,
    required this.selectedPillar,
    required this.onSelectPillar,
  });

  // STATE-01 (auditoría técnica 21-jul): antes este widget recibía
  // fastingState/sleep/hydration/exercise/nutrition completos como
  // parámetros del constructor, resueltos por DashboardScreen con un
  // `ref.watch` amplio a nivel raíz. Cualquier cambio en CUALQUIERA de
  // los 5 pilares reconstruía DashboardScreen entero, que a su vez
  // reconstruía este widget con objetos nuevos aunque el campo que
  // realmente usa no hubiera cambiado. `sleep` ni siquiera se leía acá
  // (dead prop: el sueño de esta fila sale de `currentCycleSleepProvider`
  // más abajo). Ahora cada pilar se lee acá mismo con `.select()` sobre
  // solo los campos que este widget efectivamente pinta — mismo patrón
  // ya usado en este archivo para `streakProvider` (ver también
  // `.select()` sobre `fastingProvider`/`hydrationProvider`/etc. más abajo).
  final SelectedPillar selectedPillar;
  final ValueChanged<SelectedPillar> onSelectPillar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // SPEC-194 (2026-06-06): se eliminó el placeholder "Tu día
    // metabólico aún no empezó". Bloqueaba la app cuando había
    // desync entre ayuno activo y ciclo cerrado, y el bootstrap
    // retroactivo (SPEC-193) ya repara esos casos sin bloquear la UI.
    // Los rings vuelven a estar siempre visibles, alimentados por
    // los providers DISPLAY cycle-aware con fallback a legacy.

    // SPEC-171 (2026-06-04): usa los providers DISPLAY anclados al ciclo
    // metabólico. Cuando hay ciclo abierto con protocolo conocido, el
    // score y el delta reflejan el ciclo en vivo, no el día calendárico.
    // Fallback al legacy cuando no hay ciclo o protocolo == 'Ninguno'.
    final dailyScore = ref.watch(displayDailyScoreProvider);
    final delta = ref.watch(displayDailyScoreDeltaProvider);

    // STATE-01: solo los campos que este widget pinta, no los objetos
    // completos — un cambio en otro campo de FastingState/HydrationState/
    // etc. ya no reconstruye esta fila.
    final (fastingProgress, fastingIsActive) = ref.watch(
      fastingProvider.select((s) => (s.progressPercentage, s.isActive)),
    );
    final (hydrationProgress, hydrationGoalReached) = ref.watch(
      hydrationProvider.select((s) => (s.progressPercentage, s.isGoalReached)),
    );
    final exerciseTodayMinutes =
        ref.watch(exerciseProvider.select((s) => s.todayMinutes));
    // FIX (25-jul-2026, Carlos con evidencia de pantalla: "pesa más la
    // cantidad de comidas que el tipo de comida"): el anillo de Comidas
    // mostraba `progressPercentage` (mealsLoggedToday/targetMeals) — puro
    // conteo, ciego a calidad. Un plato "1 a 1" (Cociente A 0%) y un
    // Desayuno perfecto se veían IGUAL acá (33% con 1/3 comidas) aunque
    // la card de abajo mostrara "Cociente A: 0%" al lado — la misma
    // contradicción visual que motivó el rediseño de `nutritionScore`
    // (ver nutrition_score_calculator.dart). Ahora el anillo usa
    // `nutritionScore` (ya calidad-ponderado desde ese fix) en vez de
    // `progressPercentage`. `nutritionMealsLogged`/`nutritionTargetMeals`
    // se conservan solo para el check verde de "completado" — eso sigue
    // siendo, a propósito, "¿registraste tus comidas planeadas de hoy?",
    // una pregunta distinta de "¿qué tan bien comiste?".
    final (nutritionScore, nutritionMealsLogged, nutritionTargetMeals) =
        ref.watch(nutritionProvider.select(
      (s) => (s.nutritionScore, s.mealsLoggedToday, s.targetMeals),
    ));

    // SPEC-175 (2026-06-04): la regla "el sleep pertenece al ciclo"
    // vive en `currentCycleSleepProvider`. Si no pertenece, devuelve
    // null y el ring queda en 0. La regla canónica es:
    //   wokeUp ∈ [startedAt - 18h, startedAt)
    // Histórico: SPEC-149.2.bugfix2 introdujo la ventana 18h previas;
    // SPEC-149.2.bugfix3 agregó el límite superior `< startedAt` para
    // que el sleep post-startedAt no contara al ciclo recién abierto;
    // SPEC-175 movió la lógica a un provider derivado limpio.
    final cycleSleep = ref.watch(currentCycleSleepProvider);
    // BUGFIX objetivos: meta de sueño desde "Mis objetivos" (SoT) con
    // fallback a 8h. Antes el progreso usaba 8h y el completado 7h hardcoded;
    // ahora ambos siguen el objetivo del usuario.
    final sleepTargetH = ref.watch(effectiveSleepGoalProvider);
    final sleepProgress = cycleSleep == null
        ? 0.0
        : (cycleSleep.duration.inMinutes / (sleepTargetH * 60)).clamp(0.0, 1.0);
    final sleepCompleted =
        cycleSleep != null && cycleSleep.duration.inHours >= sleepTargetH;

    // SPEC-255 RF-07: pista de pilar-ancla. Ayuno/Sueño son los únicos
    // pilares que desbloquean la vía "3/5 con ancla" — se resalta el que
    // aún falta mientras el día no califique todavía por esa vía (una
    // vez alguno de los dos se completa, o el día ya calificó por la vía
    // "4+/5", la pista deja de mostrarse en ambos).
    final todayEntry = ref.watch(streakProvider.select((s) => s.todayEntry));
    final todayQualifies = todayEntry?.qualifiesForStreak ?? false;
    final fastingAnchorDone = todayEntry?.fastingCompleted ?? false;
    final sleepAnchorDone = todayEntry?.sleepCompleted ?? false;
    final showAnchorHint =
        !todayQualifies && !fastingAnchorDone && !sleepAnchorDone;

    // 22-jul: la racha se muestra ahora dentro de `DailyScoreHero` (ver
    // doc en daily_score_hero.dart) — reemplaza al badge que antes vivía
    // en `ElenaHeader` (quitado en el mismo commit, "un solo indicador").
    // v3 (mismo día): ring con semáforo — se agrega streakRisk desde
    // streakRiskLevelProvider (gradación verde/amarillo/rojo de señales
    // que ya existían de forma binaria en streakAtRiskProvider).
    final (streakDays, streakProtected) = ref.watch(
      streakProvider.select((s) => (s.currentStreak, s.streakHasProtectedDay)),
    );
    final streakRisk = ref.watch(streakRiskLevelProvider);

    // SPEC-257 §3.1: re-deriva el mismo cálculo que `StreakNotifier` usa
    // para decidir si hoy es un día de descanso PROGRAMADO (nivel Novato,
    // 12:12/14:10 con frecuencia semanal reducida). Es intencional que
    // no se lea de `todayEntry` — el ring necesita el estado de HOY en
    // tiempo real, no el último valor persistido, igual que el resto de
    // esta fila re-deriva `fastingState`/`sleep`/etc. desde sus notifiers.
    final currentProtocol =
        ref.watch(currentUserStreamProvider).valueOrNull?.fastingProtocol ??
            'Ninguno';
    final isFastingRestDay = FastingSchedule.isRestDay(
      date: DateTime.now(),
      protocol: currentProtocol,
      goals: ref.watch(goalsProvider),
    );

    // SPEC-140.2: el Score del Día vive como HEADLINE dentro del card
    // de pilares. El label "PILARES HOY" se elimina (los 5 rings con
    // sus iconos son autodescriptivos). El divider separa visualmente
    // el agregado (TU DÍA) del desglose (5 pilares).
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fila 1: label TU DÍA + ⓘ alineados a los extremos.
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                // SPEC-230: renombrado a "PROGRESO HOY" para distinguir
                // claramente el Score del Día (cambio diario) del IMR
                // (Índice Metabólico Real, cambio semanal/mensual).
                'PROGRESO HOY',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 10,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                key: const Key('daily_score_info_button'),
                behavior: HitTestBehavior.opaque,
                onTap: () => showDailyScoreExplainerSheet(context),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 2,
                  ),
                  child: Icon(
                    Icons.info_outline,
                    color: Colors.white.withValues(alpha: 0.50),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Decisión de producto (22-jul): el IMR longitudinal se saca del
          // Dashboard (vive en Perfil + gráfica de Resultados de Progreso).
          // `DailyScoreHero` reemplaza a `DualScoreRing` (SPEC-170) — ring
          // único de HOY, agrandado, con la racha como puente visual (ver
          // daily_score_hero.dart — v2 del mismo día, reemplazó a un
          // primer intento con íconos de pilares que Carlos marcó como
          // redundante con la fila de abajo).
          // SPEC-243 fix: key compartida con AppTourOverlay para calcular
          // posición real del spotlight "Progreso Hoy" (scoreCard).
          // I-03 / I-04 (auditoría 2026-07-27): el hero recibe además la
          // fracción del día transcurrida —para no comparar un día de 17
          // minutos contra uno completo— y el récord de racha, para no
          // tratar al usuario que se le rompió la racha como si acabara de
          // registrarse. Ver la doc de ambos campos en daily_score_hero.dart.
          DailyScoreHero(
            key: ref.read(dualScoreRingKeyProvider),
            dailyScore: dailyScore,
            dailyDelta: delta,
            onTap: () => showDailyScoreExplainerSheet(context),
            streakDays: streakDays,
            streakRisk: streakRisk,
            streakProtected: streakProtected,
            dayElapsedFraction: _fraccionDelDiaTranscurrida(
              ref.watch(metabolicPulseProvider).valueOrNull ?? DateTime.now(),
            ),
            longestStreak:
                ref.watch(streakProvider.select((s) => s.longestStreak)),
          ),
          const SizedBox(height: 12),
          // Frase motivacional centrada bajo los rings (SPEC-140.3).
          // SPEC-114-app (2026-07-12, P1-B/C del informe de producto):
          // el copy de score bajo ahora es condicional a la antigüedad
          // de la cuenta — ver `_dailyScoreMotivation`.
          Center(
            child: Text(
              _dailyScoreMotivation(
                dailyScore,
                ref.watch(streakProvider.select((s) => s.history.length)),
              ),
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.70),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Divider sutil entre headline y rings.
          Container(
            height: 1,
            color: Colors.white.withValues(alpha: 0.08),
          ),
          const SizedBox(height: 14),
          // Fila de los 5 pilares con % bajo cada label.
          // SPEC-243 fix: key compartida con AppTourOverlay para calcular
          // posición real del spotlight de cada pilar (localToGlobal).
          Row(
            key: ref.read(pillarRowKeyProvider),
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              PillarRing(
                icon: Icons.timer_rounded,
                color: AppColors.metabolicGreen,
                // SPEC-257 §3.1: en día de descanso programado el anillo
                // se muestra cubierto (100%) — no hay ventana de ayuno
                // que cumplir hoy, así que el 0% real confundiría más
                // que ayudaría. `completed` se deja en false a propósito:
                // la insignia de "descanso" (isRestDay) toma precedencia
                // visual sobre el check verde dentro de `PillarRing`.
                progress: isFastingRestDay ? 1.0 : fastingProgress,
                label: 'Ayuno',
                isSelected: selectedPillar == SelectedPillar.ayuno,
                completed: !isFastingRestDay && fastingProgress >= 1.0,
                showPercent: !isFastingRestDay,
                isStreakAnchor: showAnchorHint && !isFastingRestDay,
                isRestDay: isFastingRestDay,
                onTap: () => onSelectPillar(SelectedPillar.ayuno),
              ),
              PillarRing(
                icon: Icons.nightlight_round,
                color: const Color(0xFF818CF8),
                progress: sleepProgress,
                label: 'Sueño',
                isSelected: selectedPillar == SelectedPillar.sueno,
                completed: sleepCompleted,
                showPercent: true,
                isStreakAnchor: showAnchorHint,
                onTap: () => onSelectPillar(SelectedPillar.sueno),
              ),
              PillarRing(
                icon: Icons.water_drop_rounded,
                color: Colors.blueAccent,
                progress: hydrationProgress,
                label: 'Hidratación',
                isSelected: selectedPillar == SelectedPillar.hidratacion,
                completed: hydrationGoalReached,
                showPercent: true,
                onTap: () => onSelectPillar(SelectedPillar.hidratacion),
              ),
              Builder(builder: (_) {
                // SPEC-113.bugfix: usar `user.exerciseGoalMinutes`
                // (default 20) como meta diaria. Antes el progress se
                // dividía por 60 y el "completed" se gatillaba en 30
                // — ambos hardcoded y desalineados con el objetivo
                // real sugerido al usuario.
                // BUGFIX objetivos: meta desde "Mis objetivos" (SoT) con
                // fallback a UserModel/default.
                final goal =
                    ref.watch(effectiveExerciseGoalProvider).clamp(1, 240);
                final progress =
                    (exerciseTodayMinutes / goal.toDouble()).clamp(0.0, 1.0);
                return PillarRing(
                  icon: Icons.fitness_center_rounded,
                  color: Colors.tealAccent,
                  progress: progress,
                  label: 'Ejercicio',
                  isSelected: selectedPillar == SelectedPillar.ejercicio,
                  completed: exerciseTodayMinutes >= goal,
                  showPercent: true,
                  onTap: () => onSelectPillar(SelectedPillar.ejercicio),
                );
              }),
              // SPEC-105: si hay ayuno activo, el PillarRing de Comidas
              // se ve tenue (opacity 0.5) para señal visual consistente
              // con el bloqueo. Sigue tappable — el usuario puede entrar
              // a la card y ver el banner explicativo.
              Opacity(
                opacity: fastingIsActive ? 0.5 : 1.0,
                child: PillarRing(
                  icon: Icons.restaurant_rounded,
                  color: Colors.orangeAccent,
                  progress: nutritionScore,
                  label: 'Comidas',
                  isSelected: selectedPillar == SelectedPillar.comidas,
                  completed: nutritionMealsLogged >= nutritionTargetMeals,
                  showPercent: true,
                  onTap: () => onSelectPillar(SelectedPillar.comidas),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// SPEC-140.3: frase motivacional adaptativa según el Score del Día.
  /// 6 rangos calibrados para tono ElenaApp (encouraging, no
  /// infantilizing, brand voice metabólica). El usuario ve un mensaje
  /// que ancla el número en sentido emocional.
  ///
  /// SPEC-114-app (2026-07-12): el informe de producto (C2, causa
  /// crítica de activación) identificó que el rango score<30 mostraba
  /// siempre "Vas empezando" — un copy neutro que un usuario en su
  /// primer día lee como "estoy fallando", cuando en realidad un score
  /// bajo a las 2h de su primer ayuno es matemáticamente esperado (el
  /// score promedia 5 pilares que aún no puede completar). El fix es
  /// una capa de presentación: no toca el cálculo del score, solo hace
  /// el copy condicional a cuántos días de historial de streak tiene
  /// la cuenta (`historyDays` = `streakProvider.history.length`).
  ///   - historyDays == 0 (día 0, sin ningún registro previo): mensaje
  ///     directivo que apunta a la primera acción (arrancar el ayuno).
  ///   - historyDays 1-3 (pocos datos): mensaje que dirige a sumar los
  ///     pilares de menor fricción (sueño, hidratación) hoy.
  ///   - historyDays >= 4 (patrón visible, score sigue bajo): se
  ///     mantiene el copy original — ahí sí es una señal real de baja
  ///     adherencia, no un artefacto de cold-start.
  String _dailyScoreMotivation(int score, int historyDays) {
    if (score >= 100) return 'Día perfecto';
    if (score >= 85) return 'Casi al tope';
    if (score >= 70) return 'Excelente día';
    if (score >= 50) return 'Buen avance';
    if (score >= 30) return 'Sumando';
    if (historyDays == 0) return 'Tu primer día: arranca el ayuno';
    if (historyDays < 4) return 'En camino: suma sueño e hidratación';
    return 'Vas empezando';
  }

  /// Fracción [0..1] del día natural ya transcurrida.
  ///
  /// I-03 (auditoría 2026-07-27): la usa `DailyScoreHero` para decidir si
  /// el delta contra ayer es una comparación justa. Se calcula sobre el
  /// reloj de pared y no sobre el ancla del ciclo metabólico a propósito:
  /// la pregunta que responde no es "¿en qué punto de tu ciclo estás?"
  /// sino "¿te queda día por delante para acumular?", y para eso la hora
  /// local es la referencia correcta y la más barata de calcular.
  static double _fraccionDelDiaTranscurrida(DateTime ahora) {
    const minutosPorDia = 24 * 60;
    return ((ahora.hour * 60 + ahora.minute) / minutosPorDia).clamp(0.0, 1.0);
  }
}
