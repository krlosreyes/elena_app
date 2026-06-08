import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/engine/imr_persistence_provider.dart';
import 'package:elena_app/src/core/engine/metabolic_state_provider.dart';
import 'package:elena_app/src/core/widgets/elena_header.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/dashboard/application/eating_window_provider.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
import 'package:elena_app/src/features/auth/application/profile_controller.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_history_provider.dart';
import 'package:elena_app/src/features/dashboard/domain/relative_day_label.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/circadian_clock.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/early_fasting_end_dialog.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/meals_locked_dialog.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/sleep_existing_log_dialog.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/pillar_ring.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/dual_score_ring.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/protocol_selector_sheet.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_state.dart';
import 'package:elena_app/src/features/exercise/presentation/exercise_input_sheet.dart';
import 'package:elena_app/src/features/engagement/presentation/widgets/engagement_banner.dart';
import 'package:elena_app/src/features/adaptive/presentation/widgets/adaptive_suggestion_card.dart';
import 'package:elena_app/src/features/coaching/presentation/widgets/next_best_action_card.dart';
import 'package:elena_app/src/features/goals/application/pillar_goal_providers.dart';
import 'package:elena_app/src/features/nutrition/application/cociente_a_service.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/progress/application/biometric_backfill_provider.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/daily_score_explainer_sheet.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_bootstrap_provider.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_evaluator_provider.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/presentation/widgets/cycle_closure_card.dart';
import 'package:elena_app/src/features/streak/application/daily_score_provider.dart';
// SPEC-137 E.5: regla del intervalo 3h (lastMealAt + 3h) para "Próxima En".
import 'package:elena_app/src/features/nutrition/domain/meal_interval_rules.dart';
// SPEC-137 E.4: registro unificado con TimePicker. AddPastMealSheet
// eliminado — el PlateRatioSheet ahora cubre comida actual y pasada.
import 'package:elena_app/src/features/nutrition/presentation/plate_ratio_sheet.dart';
// SPEC-137 E.5: banner countdown 30 min antes de la próxima comida.
import 'package:elena_app/src/features/nutrition/presentation/widgets/next_meal_banner.dart';
import 'package:elena_app/src/features/dashboard/presentation/sleep_input_sheet.dart';

// SPEC-88 fix: BodyCompositionCard y GoalsDashboardWidget se retiraron
// del Dashboard. La primera vive ahora en Profile; la segunda queda
// accesible vía `/goals/setup`. Los imports se mantuvieron eliminados
// para evitar dependencias huérfanas.
/// SPEC-72.4: pilar seleccionado en la fila "PILARES HOY".
/// Determina qué tarjeta de soporte se renderiza debajo.
enum SelectedPillar { ayuno, sueno, hidratacion, ejercicio, comidas }

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  SelectedPillar _selectedPillar = SelectedPillar.ayuno;

  /// SPEC-116: si la URL trae `?pillar=xxx` la primera vez que se
  /// renderiza la pantalla, forzamos esa selección. Útil cuando el
  /// usuario llega desde otra pantalla (ej. Perfil → "Cambiar
  /// protocolo" abre con la card de Ayuno).
  ///
  /// El flag se resetea cuando la ruta cambia (query param distinto)
  /// para permitir que sucesivas navegaciones con pilar específico
  /// vuelvan a aplicar la selección.
  String? _appliedPillarQuery;

  SelectedPillar? _parsePillarKey(String key) {
    switch (key) {
      case 'ayuno':
        return SelectedPillar.ayuno;
      case 'sueno':
      case 'sueño':
        return SelectedPillar.sueno;
      case 'hidratacion':
      case 'hidratación':
        return SelectedPillar.hidratacion;
      case 'ejercicio':
        return SelectedPillar.ejercicio;
      case 'comidas':
        return SelectedPillar.comidas;
    }
    return null;
  }

  void _maybeApplyPillarFromQuery(BuildContext ctx) {
    final route = GoRouterState.of(ctx);
    final pillar = route.uri.queryParameters['pillar'];
    // Solo aplicamos cuando hay nuevo query distinto al ya aplicado.
    if (pillar == null || pillar == _appliedPillarQuery) return;
    final selected = _parsePillarKey(pillar);
    if (selected == null) return;
    // Aplicar en el frame siguiente para evitar setState durante build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {
        _selectedPillar = selected;
        _appliedPillarQuery = pillar;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    _maybeApplyPillarFromQuery(context);
    final userAsync = ref.watch(currentUserStreamProvider);
    final fastingState = ref.watch(fastingProvider);
    final sleepState = ref.watch(sleepProvider);
    final hydrationState = ref.watch(hydrationProvider);
    final exerciseState = ref.watch(exerciseProvider);
    final nutritionState = ref.watch(nutritionProvider);

    // SPEC-52 + SPEC-115: el IMR sigue siendo la métrica central de
    // Análisis. En "Hoy" mantenemos el watch como side-effect (el
    // motor central recomputa al cambiar pilares) pero ya no se
    // renderiza al centro del reloj — el centro lo ocupa
    // FastingHeroDisplay.
    ref.watch(imrProvider);

    // SPEC-82: mantener vivo el sink debounced que persiste imr.current
    // al doc raíz `users/{uid}.imr.current` (consumido por el sitio web
    // Metamorfosis Real). El provider es side-effect-only — el watch
    // sólo lo monta; no se usa su retorno.
    ref.watch(imrPersistenceProvider);

    // SPEC-143 §RF-143-07: backfill client-side de biometric_history.
    // Si el usuario abre la app sin ninguna entrada histórica, dispara
    // una escritura inicial con los valores actuales. One-shot por sesión.
    // Mismo patrón side-effect-only que imrPersistenceProvider.
    ref.watch(biometricBackfillProvider);

    // SPEC-149: bootstrap del Día Metabólico. Si el usuario no tiene
    // ciclo abierto al login, crea uno retroactivo. One-shot.
    ref.watch(metabolicCycleBootstrapProvider);

    // SPEC-179 (2026-06-05): escuchar errores de persistencia del
    // hydrationProvider y mostrar SnackBar visible al usuario. Antes
    // los errores quedaban en un catch silencioso → el usuario veía
    // el +250ml en pantalla pero el log no llegaba a Firestore.
    ref.listen<HydrationState>(hydrationProvider, (previous, next) {
      final err = next.lastWriteError;
      if (err != null && err != previous?.lastWriteError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(err),
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'OK',
              onPressed: () {
                ref.read(hydrationProvider.notifier).clearWriteError();
              },
            ),
          ),
        );
        // Auto-clear tras mostrar para no repetir.
        Future.delayed(const Duration(milliseconds: 100), () {
          if (context.mounted) {
            ref.read(hydrationProvider.notifier).clearWriteError();
          }
        });
      }
    });

    // SPEC-149: evaluador continuo del ciclo.
    // SPEC-174 (2026-06-04): el evaluator se movió a `app.dart` (nivel
    // root) para que evalúe aunque el usuario no esté en este tab.
    // Antes, salir de Hoy a Análisis/Perfil podía desmontar el provider
    // y el ciclo dejaba de evaluarse. Ya no se requiere watch aquí.

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) =>
          Scaffold(body: Center(child: Text('Fallo de Hardware: $err'))),
      data: (user) {
        if (user == null) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(sleepProvider.notifier).updateSleepConsciousness();
        });

        return Scaffold(
          body: SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  const ElenaHeader(title: "Metamorfosis Real"),
                  const SizedBox(height: 10),

                  // BANNER DE ENGAGEMENT (SPEC-07 + SPEC-72.2 dismiss por sesión)
                  const EngagementBanner(),
                  const SizedBox(height: 16),

                  // SPEC-194: "Tu siguiente paso" — acción de coaching
                  // priorizada por el motor de decisión. Se oculta sola en
                  // período de gracia o si no hay candidato.
                  const NextBestActionCard(),

                  // SPEC-149: card de cierre del Día Metabólico. Aparece
                  // cuando hay un ciclo cerrado reciente que el usuario
                  // aún no descartó. Es el "coaching moment" — score del
                  // ciclo + lo que logró + faltó + insight científico +
                  // CTA para iniciar el siguiente ayuno. Se oculta sola
                  // cuando no aplica.
                  CycleClosureCard(
                    // SPEC-149.1 Bug 1c: si el ayuno ya está activo
                    // (caso típico cuando la card aparece tras un trigger
                    // manualNextFasting), el botón "Empezar mi siguiente
                    // ayuno" sobra. Solo lo renderizamos cuando el ayuno
                    // no está activo (cierre por fallback sleep/3h/etc).
                    onStartNextFasting: fastingState.isActive
                        ? null
                        : () async {
                            await ref
                                .read(fastingProvider.notifier)
                                .startFasting();
                          },
                  ),

                  // SPEC-137 E.5: banner "próxima comida en X min" cuando
                  // estamos dentro de los 30 min previos al horario
                  // sugerido (última comida + 3h). Se auto-oculta si no
                  // aplica o si hay día de permitidos activo.
                  const NextMealBanner(),

                  // MOTOR ADAPTATIVO (SPEC-08)
                  const AdaptiveSuggestionCard(),
                  const SizedBox(height: 16),

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.78,
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            child: CircadianClock(
                              user: user,
                              fastingState: fastingState,
                              // SPEC-115: ya no pasamos `score` (IMR).
                              // El centro lo ocupa FastingHeroDisplay con
                              // estado del ayuno + próximo hito. El IMR
                              // sigue en Análisis.
                              eatingWindow: ref.watch(eatingWindowProvider),
                            ),
                          ),
                        ),
                      ),
                      if (sleepState.isWaitingForWakeUp)
                        _buildWakeUpOverlay(context, ref, sleepState.isSaving),
                      if (fastingState.isWaitingForFastingEnd)
                        _buildFastingEndOverlay(context, ref, fastingState),
                      if (fastingState.isWaitingForFeedingEnd)
                        _buildFeedingEndOverlay(context, ref, fastingState),
                    ],
                  ),

                  const SizedBox(height: 16),

                  if (fastingState.metabolicAlert != null) ...[
                    _buildMetabolicAlertBanner(fastingState.metabolicAlert!),
                    const SizedBox(height: 12),
                  ],

                  // SPEC-104: card de FASE / BLOQUEO INTESTINAL / ALINEACIÓN
                  // eliminada. Razones:
                  //   - FASE ya se comunica en el anillo del reloj.
                  //   - BLOQUEO INTESTINAL pasivo no es accionable —
                  //     futura SPEC convertirlo en alerta condicional <3h.
                  //   - ALINEACIÓN al 100% sin desglose contradecía un
                  //     IMR bajo (confuso para el usuario).
                  // El reloj central ya cumple el rol comunicativo
                  // primario del dashboard.

                  // SPEC-140 + SPEC-140.1: Score del Día integrado al
                  // header de PILARES HOY como agregado del módulo.
                  // El % por pilar y el score van en _buildPillarsRow.
                  // El card separado anterior se eliminó por redundancia
                  // visual con los anillos de cada pilar.
                  _buildPillarsRow(
                    context: context,
                    ref: ref,
                    fastingState: fastingState,
                    sleep: sleepState,
                    hydration: hydrationState,
                    exercise: exerciseState,
                    nutrition: nutritionState,
                  ),
                  // SPEC-140.3: gap reducido de 24 → 14 para que la card
                  // del pilar seleccionado se sienta como continuación
                  // visual del card de "Tu Día", no como otra sección.
                  const SizedBox(height: 14),

                  // Tarjeta de soporte del pilar seleccionado.
                  // Cambia dinámicamente al tocar un anillo de la fila "PILARES HOY".
                  _buildSelectedPillarCard(
                    context: context,
                    ref: ref,
                    fastingState: fastingState,
                    sleep: sleepState,
                    hydration: hydrationState,
                    exercise: exerciseState,
                    nutrition: nutritionState,
                    user: user,
                  ),
                  const SizedBox(height: 20),

                  // SPEC-88 fix: BodyCompositionCard, GoalsDashboardWidget
                  // y _buildProgressCTA se removieron del Dashboard a
                  // pedido del líder de proyecto. La composición
                  // corporal vive ahora en Profile (SPEC-88). Objetivos
                  // y Road Map quedan accesibles desde sus pantallas
                  // dedicadas (/goals/setup y /progress) — el atajo en
                  // Dashboard se considera ruido visual.
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomNav(context),
        );
      },
    );
  }

  // --- COMPONENTES PRIVADOS DEL REDISEÑO ---
  //
  // Los antiguos _buildMetabolicControlConsole y _buildFirstTimerWelcome
  // (consola de "Ventana Nutricional" + countdown + botón "Iniciar Ayuno")
  // fueron reemplazados por _buildFastingConsciousnessCard, que ofrece
  // la misma capacidad de control con estado, beneficios y dos CTAs.
  //
  // Los antiguos _buildSectionLabel, _buildMetricsGrid y los 4 cards por
  // pilar (sueño, hidratación, ejercicio, nutrición) fueron reemplazados
  // por _buildPillarsRow, una fila compacta de anillos circulares.
  //
  // Toda la lógica de negocio (start/stop fasting, abrir sheets, registrar
  // hidratación) se mantiene intacta en los notifiers; solo cambió la UI.

  // ───────────────────────────────────────────────────────────────────────
  //  Nuevos componentes del rediseño
  // ───────────────────────────────────────────────────────────────────────

  // SPEC-104: `_buildPhaseIndicators` y `_phaseIndicatorTile` eliminados
  // junto con la card que renderizaban. Ver razones en el callsite.

  /// Fila horizontal de 5 anillos circulares — uno por pilar.
  /// Cada anillo es interactivo y abre su sheet de input correspondiente.
  /// El pilar de Ayuno está visualmente destacado cuando está activo.
  ///
  /// SPEC-140.1: el header ahora incluye el Score del Día (agregado de
  /// los 5 pilares), el delta vs ayer y el icono ⓘ que abre el
  /// explainer educativo. Cada PillarRing muestra su % bajo el label.
  Widget _buildPillarsRow({
    required BuildContext context,
    required WidgetRef ref,
    required FastingState fastingState,
    required SleepState sleep,
    required HydrationState hydration,
    required ExerciseState exercise,
    required NutritionState nutrition,
  }) {
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
                'TU DÍA',
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
          // SPEC-170 (2026-06-04): dos rings adyacentes HOY + IMR
          // reemplazan el número grande 36pt. Cada uno con score, label
          // y sub-label propio. Tap en cualquiera abre el ExplainerSheet
          // único que cubre ambos.
          DualScoreRing(
            dailyScore: dailyScore,
            dailyDelta: delta,
            imrScore: ref.watch(displayedImrProvider).score,
            onTap: () => showDailyScoreExplainerSheet(context),
          ),
          const SizedBox(height: 12),
          // Frase motivacional centrada bajo los rings (SPEC-140.3).
          Center(
            child: Text(
              _dailyScoreMotivation(dailyScore),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              PillarRing(
                icon: Icons.timer_rounded,
                color: AppColors.metabolicGreen,
                progress: fastingState.progressPercentage,
                label: 'Ayuno',
                isSelected: _selectedPillar == SelectedPillar.ayuno,
                completed: fastingState.progressPercentage >= 1.0,
                showPercent: true,
                onTap: () =>
                    setState(() => _selectedPillar = SelectedPillar.ayuno),
              ),
              PillarRing(
                icon: Icons.nightlight_round,
                color: const Color(0xFF818CF8),
                progress: sleepProgress,
                label: 'Sueño',
                isSelected: _selectedPillar == SelectedPillar.sueno,
                completed: sleepCompleted,
                showPercent: true,
                onTap: () =>
                    setState(() => _selectedPillar = SelectedPillar.sueno),
              ),
              PillarRing(
                icon: Icons.water_drop_rounded,
                color: Colors.blueAccent,
                progress: hydration.progressPercentage,
                label: 'Hidratación',
                isSelected: _selectedPillar == SelectedPillar.hidratacion,
                completed: hydration.isGoalReached,
                showPercent: true,
                onTap: () => setState(
                    () => _selectedPillar = SelectedPillar.hidratacion),
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
                    (exercise.todayMinutes / goal.toDouble()).clamp(0.0, 1.0);
                return PillarRing(
                  icon: Icons.fitness_center_rounded,
                  color: Colors.tealAccent,
                  progress: progress,
                  label: 'Ejercicio',
                  isSelected: _selectedPillar == SelectedPillar.ejercicio,
                  completed: exercise.todayMinutes >= goal,
                  showPercent: true,
                  onTap: () => setState(
                      () => _selectedPillar = SelectedPillar.ejercicio),
                );
              }),
              // SPEC-105: si hay ayuno activo, el PillarRing de Comidas
              // se ve tenue (opacity 0.5) para señal visual consistente
              // con el bloqueo. Sigue tappable — el usuario puede entrar
              // a la card y ver el banner explicativo.
              Opacity(
                opacity: fastingState.isActive ? 0.5 : 1.0,
                child: PillarRing(
                  icon: Icons.restaurant_rounded,
                  color: Colors.orangeAccent,
                  progress: nutrition.progressPercentage,
                  label: 'Comidas',
                  isSelected: _selectedPillar == SelectedPillar.comidas,
                  completed:
                      nutrition.mealsLoggedToday >= nutrition.targetMeals,
                  showPercent: true,
                  onTap: () =>
                      setState(() => _selectedPillar = SelectedPillar.comidas),
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
  String _dailyScoreMotivation(int score) {
    if (score >= 100) return 'Día perfecto';
    if (score >= 85) return 'Casi al tope';
    if (score >= 70) return 'Excelente día';
    if (score >= 50) return 'Buen avance';
    if (score >= 30) return 'Sumando';
    return 'Vas empezando';
  }

  // SPEC-170 (2026-06-04): _buildDailyScoreDelta retirado. El delta del
  // Score del Día ahora vive como sub-label dentro del DualScoreRing
  // ("↑5 vs ayer"). Si vuelve a hacer falta, recuperar de git history.

  // SPEC-66 v2: _pillarRing extraído a widgets/pillar_ring.dart como
  // PillarRing público para hacerlo testeable con widget tests.

  // SPEC-194 (2026-06-06): _buildNoCyclePlaceholder eliminado. El
  // placeholder bloqueaba la UI en escenarios de desync (ayuno activo
  // + ciclo cerrado) y al primer login antes de que el bootstrap
  // retroactivo (SPEC-193) creara el ciclo. Los rings vuelven a
  // mostrarse siempre, con valores legacy si no hay ciclo abierto.

  /// Tarjeta extendida de control de Ayuno con beneficios y 2 CTAs.
  /// Reemplaza la antigua "VENTANA NUTRICIONAL" + IMRScoreCard.
  ///
  /// Lógica intacta: el botón principal ejecuta el mismo flujo de
  /// `fastingProvider.startFasting()` / `confirmManualFastingEnd`. El
  /// botón secundario abre el time picker existente.
  Widget _buildFastingConsciousnessCard(
    BuildContext context,
    WidgetRef ref,
    FastingState state,
  ) {
    final isActive = state.isActive;
    final accent =
        isActive ? AppColors.metabolicGreen : AppColors.metabolicGreen;
    final pct = (state.progressPercentage.clamp(0.0, 1.0) * 100).round();

    // SPEC-113.feat: cuando NO hay ayuno activo, calculamos el próximo
    // momento de cierre de ventana de alimentación basado en el
    // `lastMealGoal` del usuario. Si esa hora ya pasó hoy → mañana.
    // `lastMealGoal` es nullable: si el perfil aún no lo definió, el
    // countdown no aplica y el clock cae al placeholder.
    final user = ref.watch(currentUserStreamProvider).value;
    DateTime? nextFastingTime;
    if (!isActive && user != null) {
      final lastMeal = user.profile.lastMealGoal;
      if (lastMeal != null) {
        final now = DateTime.now();
        var candidate = DateTime(
          now.year,
          now.month,
          now.day,
          lastMeal.hour,
          lastMeal.minute,
        );
        if (!candidate.isAfter(now)) {
          candidate = candidate.add(const Duration(days: 1));
        }
        nextFastingTime = candidate;
      }
    }

    final stateLabel = isActive
        ? 'En curso'
        : (nextFastingTime != null ? 'Próximo ayuno' : 'En espera');

    final benefits = isActive
        ? const [
            'Estás reduciendo glucosa y mejorando sensibilidad a la insulina.',
            'A partir de 12h se activa la cetosis y la autofagia inicial.',
          ]
        : const [
            'Reduce resistencia a la insulina desde la 1ª hora',
            'Regula glucosa en ayunas y mejora sensibilidad metabólica',
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera: título + estado
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ayuno Consciente',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.6)),
                ),
                child: Text(
                  stateLabel,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // SPEC-119: fila de metadatos del protocolo. El cronómetro
          // vivo HH:MM:SS ya está en el hero (FastingHeroDisplay del
          // CircadianClock), no duplicamos aquí. La tarjeta se
          // identifica como "panel de control y contexto": qué
          // protocolo está activo y qué hito viene a continuación.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Columna izquierda: PROTOCOLO (chip clickable).
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PROTOCOLO',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.45),
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _buildProtocolChip(
                        context: context,
                        ref: ref,
                        protocol: state.fastingProtocol,
                        isActive: isActive,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Columna derecha: HITO SIGUIENTE (solo visible si activo).
              if (isActive)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'HITO SIGUIENTE',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.45),
                          fontSize: 10,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _formatNextMilestone(state),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Barra de progreso fina
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: state.progressPercentage.clamp(0.0, 1.0),
              minHeight: 4,
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: AlwaysStoppedAnimation<Color>(accent),
            ),
          ),
          // SPEC-102: etiquetas sutiles en los extremos de la barra
          // con la hora de inicio y la hora estimada de fin del
          // ayuno. Patrón Apple Health / Oura — informa de un vistazo
          // el rango temporal sin invadir la jerarquía visual.
          if (isActive && state.startTime != null) ...[
            const SizedBox(height: 4),
            _buildFastingTimeline(
              start: state.startTime!,
              targetHours: state.targetHours,
            ),
          ],
          const SizedBox(height: 6),
          Text(
            // SPEC-113.feat: el texto debajo se adapta al estado.
            // SPEC-119: cuando hay ayuno activo, agregamos el residual
            // temporal "faltan Xh Ym" — alto valor accionable: el usuario
            // sabe cuánto le queda sin tener que hacer la resta mental.
            isActive
                ? '$pct% completado${_formatTargetRemaining(state)}'
                : (nextFastingTime != null
                    ? 'Inicia ${nextFastingTime.hour.toString().padLeft(2, '0')}:${nextFastingTime.minute.toString().padLeft(2, '0')}'
                    : 'Listo para iniciar tu ayuno'),
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 18),
          // Beneficios
          Text(
            isActive ? 'BENEFICIOS ACTUALES' : 'BENEFICIOS AL INICIAR',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 10,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...benefits.map(
            (b) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_rounded, color: accent, size: 16),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      b,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          // Botón principal: iniciar / finalizar.
          //
          // SPEC-101:
          // - Si el usuario ya completó ayuno hoy y NO hay uno activo,
          //   el botón "Iniciar Ayuno" queda deshabilitado.
          // - Si está activo y progress < 100%, "Finalizar Ayuno" abre
          //   un diálogo de confirmación con beneficios obtenidos.
          // - Si está activo y progress >= 100%, flow actual (picker).
          _buildFastingPrimaryButton(
            context: context,
            ref: ref,
            state: state,
            isActive: isActive,
            accent: accent,
          ),
          // SPEC-97: el botón "Corregir hora de inicio" SOLO aparece
          // cuando hay ayuno activo. Antes aparecía siempre y al
          // tocarlo en estado "En espera" iniciaba ventana de comida
          // por error (confirmManualFastingEnd con isFeeding=false).
          if (isActive) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                onPressed: state.isSaving
                    ? null
                    : () => _showCorrectStartTimePicker(context, ref, state),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: Icon(
                  Icons.access_time_rounded,
                  color: Colors.white.withValues(alpha: 0.7),
                  size: 18,
                ),
                label: Text(
                  'Corregir hora de inicio del ayuno',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────────────
  //  Tarjetas por pilar — SPEC-72.4
  //  El dispatcher elige cuál renderizar según _selectedPillar.
  //  Cada tarjeta tiene su propia paleta y CTAs específicas.
  // ───────────────────────────────────────────────────────────────────────

  Widget _buildSelectedPillarCard({
    required BuildContext context,
    required WidgetRef ref,
    required FastingState fastingState,
    required SleepState sleep,
    required HydrationState hydration,
    required ExerciseState exercise,
    required NutritionState nutrition,
    required user,
  }) {
    return switch (_selectedPillar) {
      SelectedPillar.ayuno =>
        _buildFastingConsciousnessCard(context, ref, fastingState),
      SelectedPillar.sueno => _buildSuenoCard(context, ref, sleep),
      SelectedPillar.hidratacion =>
        _buildHidratacionCard(context, ref, hydration),
      SelectedPillar.ejercicio =>
        _buildEjercicioCard(context, ref, exercise, user),
      SelectedPillar.comidas => _buildComidasCard(
          context,
          ref,
          nutrition,
          isFastingActive: fastingState.isActive,
        ),
    };
  }

  // ─── SUEÑO: "Soporte Metabólico" ──────────────────────────────────────
  Widget _buildSuenoCard(
      BuildContext context, WidgetRef ref, SleepState state) {
    const accent = Color(0xFF818CF8);
    final log = state.lastLog;
    final hasLog = log != null;
    final hours = hasLog ? log.duration.inHours : 0;
    final minutes = hasLog ? log.duration.inMinutes.remainder(60) : 0;
    final progress =
        hasLog ? (log.duration.inMinutes / (8 * 60)).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();

    String fmt(DateTime? dt) {
      if (dt == null) return '—';
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    return _pillarCardShell(
      title: 'Soporte Metabólico',
      badge: 'Sueño',
      accent: accent,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _miniStat(
                'Dormiste', hasLog ? '${hours}h ${minutes}m' : '—', accent,
                big: true),
            _miniStat('Acostado', fmt(log?.fellAsleep), Colors.white),
            _miniStat('Despertaste', fmt(log?.wokeUp), Colors.white),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Text('🚩', style: TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(
              'Meta: 7-9 horas',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _progressBar(progress, accent),
        const SizedBox(height: 6),
        _completionLabel(pct),
        const SizedBox(height: 16),
        _benefitChip(
          accent: accent,
          text: hasLog && hours >= 7
              ? '✓ Sueño reparador — GH pulsátil activa durante ciclos REM'
              : 'Buscas sueño reparador: 7-9h activan la GH pulsátil que repara músculo y reduce inflamación.',
        ),
        const SizedBox(height: 18),
        // SPEC-106 / SPEC-108: el sheet precarga el último log si
        // existe. Si ya hay registro de HOY, primero pasa por un
        // diálogo donde el usuario elige editar o eliminar y
        // recrear. Si no hay log, abre sheet limpio directo.
        _primaryButton(
          label: hasLog ? 'Actualizar Registro' : 'Registrar Sueño',
          icon: Icons.nightlight_round,
          color: accent,
          onPressed: () => _onTapUpdateSleep(context, ref, state),
        ),
        const SizedBox(height: 10),
        // SPEC-106: eliminar registro existente. Solo aparece si hay
        // un log para borrar; abre diálogo de confirmación.
        if (hasLog)
          _secondaryButton(
            label: 'Eliminar registro y volver a registrar',
            icon: Icons.delete_outline_rounded,
            onPressed: state.isSaving
                ? null
                : () => _confirmDeleteSleepLog(context, ref),
          ),
      ],
    );
  }

  /// SPEC-108: handler unificado del botón "Actualizar Registro".
  ///
  /// Si NO hay log o el log NO es de hoy → abre sheet limpio para
  /// crear nuevo. Si hay log de hoy → muestra `SleepExistingLogDialog`
  /// para que el usuario decida entre editar, eliminar y recrear, o
  /// cancelar.
  Future<void> _onTapUpdateSleep(
      BuildContext context, WidgetRef ref, SleepState state) async {
    final log = state.lastLog;
    final now = DateTime.now();

    final bool hasTodayLog = log != null &&
        log.wokeUp.year == now.year &&
        log.wokeUp.month == now.month &&
        log.wokeUp.day == now.day;

    if (!hasTodayLog) {
      // Sin log de hoy → abrir sheet limpio (sin diálogo).
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => SleepInputSheet(initial: log),
      );
      return;
    }

    // Ya hay log de hoy → diálogo con bedtime/waketime/duración/calidad
    // y tres opciones.
    final choice = await SleepExistingLogDialog.show(context, log: log);

    if (!context.mounted) return;

    switch (choice) {
      case SleepExistingLogChoice.edit:
        await showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => SleepInputSheet(initial: log),
        );
        break;
      case SleepExistingLogChoice.replace:
        // Reutilizamos el flujo de eliminación con confirmación que
        // ya abre el sheet limpio después.
        await _confirmDeleteSleepLog(context, ref);
        break;
      case SleepExistingLogChoice.cancel:
        // no-op
        break;
    }
  }

  /// SPEC-106: confirmación previa a eliminar el registro de sueño.
  /// Tras confirmar, llama a `sleepProvider.deleteLastLog()` y abre
  /// el sheet en modo limpio (`initial: null`) para que el usuario
  /// pueda registrar de nuevo.
  Future<void> _confirmDeleteSleepLog(
      BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Text(
          '¿Eliminar registro de sueño?',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 17,
          ),
        ),
        content: const Text(
          'Esta acción borra el registro actual de Firestore. '
          'Después podrás capturar uno nuevo desde cero.',
          style: TextStyle(
            color: Color(0xFFB6C3D1),
            fontSize: 13,
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancelar',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text(
              'Sí, eliminar',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await ref.read(sleepProvider.notifier).deleteLastLog();
      if (!context.mounted) return;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => const SleepInputSheet(),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo eliminar: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // ─── HIDRATACIÓN: "Soporte Metabólico" ────────────────────────────────
  Widget _buildHidratacionCard(
      BuildContext context, WidgetRef ref, HydrationState state) {
    const accent = Color(0xFF38BDF8);
    final progress = state.progressPercentage;
    final pct = (progress * 100).round();

    return _pillarCardShell(
      title: 'Soporte Metabólico',
      badge: 'Hidratación',
      accent: accent,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${state.currentFormatted} L',
              style: TextStyle(
                color: accent,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '/ ${state.goalFormatted} L',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _progressBar(progress, accent),
        const SizedBox(height: 6),
        _completionLabel(pct),
        const SizedBox(height: 16),
        _benefitChip(
          accent: accent,
          text:
              'Cada 250ml mejora el flujo linfático y la eliminación de metabolitos',
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _outlinedActionButton(
                label: '+250 ml',
                accent: accent,
                onPressed: state.isSaving
                    ? null
                    : () =>
                        ref.read(hydrationProvider.notifier).addWater(0.250),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _outlinedActionButton(
                label: '+500 ml',
                accent: accent,
                onPressed: state.isSaving
                    ? null
                    : () =>
                        ref.read(hydrationProvider.notifier).addWater(0.500),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _secondaryButton(
          label: 'Descontar último vaso (-250 ml)',
          icon: Icons.remove_circle_outline_rounded,
          onPressed: () => _showPendingFeatureSnack(
            context,
            'Descontar último vaso',
          ),
        ),
      ],
    );
  }

  // ─── EJERCICIO: "Sarcopenia & Resistencia" ────────────────────────────
  Widget _buildEjercicioCard(
      BuildContext context, WidgetRef ref, ExerciseState state, dynamic user) {
    const accent = Color(0xFF2DD4BF);
    // BUGFIX objetivos: meta desde "Mis objetivos" (SoT) con fallback.
    final goal = ref.watch(effectiveExerciseGoalProvider);
    final minutes = state.todayMinutes;
    final progress = goal > 0 ? (minutes / goal).clamp(0.0, 1.0) : 0.0;
    final pct = (progress * 100).round();
    final achieved = minutes >= goal;

    return _pillarCardShell(
      title: 'Sarcopenia & Resistencia',
      badge: achieved ? 'ACTIVO' : 'Ejercicio',
      accent: accent,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$minutes min',
              style: TextStyle(
                color: accent,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text(
                '/ $goal min meta',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _progressBar(progress, accent),
        const SizedBox(height: 6),
        _completionLabel(pct),
        const SizedBox(height: 16),
        _benefitChip(
          accent: accent,
          text: achieved
              ? '✓ Meta cumplida — síntesis proteica muscular activa 24-48h post sesión'
              : 'Acumula minutos para activar la síntesis proteica muscular post-ejercicio.',
        ),
        const SizedBox(height: 18),
        _primaryButton(
          label: 'Agregar Sesión',
          icon: Icons.fitness_center_rounded,
          color: accent,
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const ExerciseInputSheet(),
          ),
        ),
        const SizedBox(height: 10),
        _secondaryButton(
          label: 'Eliminar última sesión',
          icon: Icons.delete_outline_rounded,
          onPressed: () => _showPendingFeatureSnack(
            context,
            'Eliminar última sesión de ejercicio',
          ),
        ),
      ],
    );
  }

  // ─── COMIDAS: "Nutrición Científica" ──────────────────────────────────
  //
  // SPEC-105: cuando hay ayuno activo, la card se renderea en estado
  // bloqueado: banner visible arriba, contenido con opacity 0.5,
  // botones disabled, y tap en cualquier parte abre diálogo educativo.
  Widget _buildComidasCard(
    BuildContext context,
    WidgetRef ref,
    NutritionState state, {
    required bool isFastingActive,
  }) {
    const accent = Color(0xFFFB923C);
    final progress = state.progressPercentage;
    final pct = (progress * 100).round();
    // SPEC-137: el mini-stat "Score nutricional" pasa a ser el
    // Cociente A — porcentaje de platos A-dominantes registrados hoy.
    // Es la métrica que el usuario MR entiende sin tutorial (Frank
    // Suárez Tipo A/E). Ver NUTRITION_BIBLIOGRAPHY.md §1.
    const cocienteService = CocienteAService();
    final cocienteA = cocienteService.calculate(state.todayLogs);
    final cocientePct = (cocienteA * 100).round();
    final aDominantCount = cocienteService.aDominantCount(state.todayLogs);

    final card = _pillarCardShell(
      title: 'Nutrición Científica',
      badge: '${state.mealsLoggedToday}/${state.targetMeals} comidas',
      accent: accent,
      children: [
        if (isFastingActive) ...[
          _buildMealsLockedBanner(),
          const SizedBox(height: 14),
        ],
        Opacity(
          opacity: isFastingActive ? 0.45 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _progressBar(progress, accent),
              const SizedBox(height: 6),
              _completionLabel(pct),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _miniStat('Próxima', state.nextMealLabel, accent, big: true),
                  _miniStat('En', _estimateNextMealIn(state), accent,
                      big: true),
                  // SPEC-137: Cociente A reemplaza el "Score nutricional"
                  // numérico (que no era accionable).
                  _miniStat('Cociente A', '$cocientePct%',
                      _cocienteAColor(cocienteA),
                      big: true),
                ],
              ),
              const SizedBox(height: 16),
              _benefitChip(
                accent: accent,
                text: state.windowAdherence >= 0.5
                    ? '✓ Comidas dentro de ventana circadiana — alineación con ritmo metabólico óptima'
                    : 'Mantén tus comidas dentro de la ventana circadiana para alinear tu ritmo metabólico.',
              ),
              const SizedBox(height: 18),
              // SPEC-137: el botón principal abre `PlateRatioSheet` —
              // el usuario clasifica el plato por proporción A:E y
              // confirma. Reemplaza el `logMeal()` directo que dejaba
              // el plato sin clasificación (default a2e1).
              _primaryButton(
                label: 'Registrar ${state.nextMealLabel}',
                icon: Icons.restaurant_rounded,
                color: accent,
                onPressed: isFastingActive || state.isSaving
                    ? null
                    : () => PlateRatioSheet.show(context),
              ),
              const SizedBox(height: 10),
              // SPEC-137 E.4: el botón "Registrar comida pasada" se
              // eliminó. El TimePicker del PlateRatioSheet permite
              // ajustar la hora del plato actual o pasado en el mismo
              // flujo, sin segundo sheet.
              _secondaryButton(
                label: 'Deshacer última comida registrada',
                icon: Icons.undo_rounded,
                onPressed: isFastingActive || state.todayLogs.isEmpty
                    ? null
                    : () =>
                        ref.read(nutritionProvider.notifier).removeLastMeal(),
              ),
              const SizedBox(height: 10),
              // SPEC-137 §RF-137-12: link a la vista semanal del pilar.
              _secondaryButton(
                label: aDominantCount == 0
                    ? 'Ver semana →'
                    : 'Ver semana → · $aDominantCount A-dominantes hoy',
                icon: Icons.calendar_view_week_rounded,
                onPressed: () => context.push('/nutrition/weekly'),
              ),
            ],
          ),
        ),
      ],
    );

    // Cuando hay ayuno activo, envolver con GestureDetector que
    // captura el tap (los botones internos están `onPressed: null` y
    // no consumen el evento) y dispara el diálogo educativo. Si el
    // usuario confirma "Ir a Ayuno", cambiamos el pilar seleccionado.
    if (!isFastingActive) return card;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        final goToFasting = await MealsLockedDuringFastingDialog.show(context);
        if (goToFasting == true && mounted) {
          setState(() => _selectedPillar = SelectedPillar.ayuno);
        }
      },
      child: card,
    );
  }

  /// SPEC-105: banner siempre opaco encima de la card de Comidas
  /// cuando hay ayuno activo. Comunica el motivo del bloqueo sin
  /// requerir tap.
  Widget _buildMealsLockedBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.metabolicGreen.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.metabolicGreen.withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.lock_clock_rounded,
            color: AppColors.metabolicGreen,
            size: 18,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Pausado durante ayuno activo — termina tu ayuno '
              'para registrar comidas.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 12,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Estimador simple para "Próxima comida en X" ──────────────────────
  // Solo UI: usa horarios estándar (Desayuno 8:00, Almuerzo 13:00, Cena
  // 19:00, Snack 16:00) y devuelve la diferencia hasta now. Es un placeholder
  // hasta que SPEC-64 introduzca la lógica de ventana real.
  /// SPEC-137: color del Cociente A para el mini-stat de Hoy.
  /// Sigue los mismos thresholds de la pantalla semanal.
  Color _cocienteAColor(double cociente) {
    if (cociente >= 0.75) return AppColors.statusGood;
    if (cociente >= 0.50) return AppColors.accent;
    if (cociente >= 0.25) return AppColors.statusWarn;
    return AppColors.statusBad;
  }

  /// SPEC-137 E.5: tiempo hasta la próxima comida sugerida.
  ///
  /// Antes calculaba contra horarios fijos del día (Desayuno=8h,
  /// Almuerzo=13h, etc.), lo cual chocaba con la regla del intervalo
  /// 3h documentada en NUTRITION_BIBLIOGRAPHY §15. Ahora usa el mismo
  /// sistema: `lastMealAt + 3h`.
  ///
  /// Devuelve:
  /// - "—" si no hay comidas hoy o se llegó al target.
  /// - "Ahora" si ya pasó el momento sugerido.
  /// - "Xh Ym" o "Xm" según corresponda.
  String _estimateNextMealIn(NutritionState state) {
    if (state.mealsLoggedToday >= state.targetMeals) return '—';
    final lastMealAt = MealIntervalRules.lastMealOf(state.todayLogs);
    final nextAt = MealIntervalRules.nextSuggestedAt(lastMealAt);
    if (nextAt == null) return '—';
    final diff = nextAt.difference(DateTime.now());
    if (diff.isNegative) return 'Ahora';
    if (diff.inHours >= 1) {
      return '${diff.inHours}h ${diff.inMinutes.remainder(60)}m';
    }
    return '${diff.inMinutes}m';
  }

  // ─── Helpers visuales reutilizables ───────────────────────────────────
  Widget _pillarCardShell({
    required String title,
    required String badge,
    required Color accent,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: accent.withValues(alpha: 0.6)),
                ),
                child: Text(
                  badge,
                  style: TextStyle(
                    color: accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value, Color valueColor,
      {bool big = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: valueColor,
            fontSize: big ? 22 : 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _progressBar(double progress, Color accent) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 6,
        backgroundColor: Colors.white.withValues(alpha: 0.08),
        valueColor: AlwaysStoppedAnimation<Color>(accent),
      ),
    );
  }

  Widget _completionLabel(int pct) {
    return Text(
      '$pct% completado',
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.5),
        fontSize: 11,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _benefitChip({required Color accent, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.5,
          fontWeight: FontWeight.w500,
          height: 1.4,
        ),
      ),
    );
  }

  Widget _primaryButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        icon: Icon(icon, color: Colors.white, size: 20),
        label: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        icon: Icon(
          icon,
          color: Colors.white.withValues(alpha: 0.7),
          size: 18,
        ),
        label: Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.8),
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ),
    );
  }

  Widget _outlinedActionButton({
    required String label,
    required Color accent,
    required VoidCallback? onPressed,
  }) {
    return SizedBox(
      height: 48,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          side: BorderSide(color: accent.withValues(alpha: 0.6), width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: accent.withValues(alpha: 0.08),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: accent,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  void _showPendingFeatureSnack(BuildContext context, String featureName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$featureName: función disponible próximamente'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // _buildProgressCTA eliminado en SPEC-88 fix. El acceso al Road Map
  // queda disponible vía la ruta `/progress` (futuro entry point en
  // navegación principal o desde Profile).

  // _buildSectionLabel, _buildMetricsGrid, _buildSleepCard, _buildHydrationCard,
  // _buildExerciseCard y _buildNutritionCard eliminados en el rediseño:
  // su rol lo absorbió _buildPillarsRow (más arriba), una fila compacta de
  // anillos circulares interactivos. La lógica de tap (abrir sheets, sumar
  // agua) se preservó intacta dentro de _pillarRing.onTap.

  // --- OVERLAYS Y PICKERS SE MANTIENEN ---

  Widget _buildFastingEndOverlay(
      BuildContext context, WidgetRef ref, FastingState state) {
    // SPEC-151: dos opciones legítimas. Terminar abre el flujo de cierre
    // (time picker + persistir + abrir ventana). Continuar silencia el
    // overlay y deja el ayuno activo en overtime — el usuario cerrará
    // desde la card normal del dashboard cuando decida.
    return _buildBaseOverlay(
      context: context,
      icon: Icons.emoji_events_rounded,
      iconColor: AppColors.metabolicGreen,
      title: "¡META ALCANZADA!",
      subtitle: "Has completado tus ${state.targetHours}h de ayuno.",
      buttonLabel: "TERMINAR AYUNO",
      isSaving: state.isSaving,
      onConfirm: () => _showManualTimePicker(context, ref, isFeeding: false),
      secondaryButtonLabel: "CONTINUAR AYUNANDO",
      onSecondary: () =>
          ref.read(fastingProvider.notifier).continueFastingPastTarget(),
    );
  }

  Widget _buildFeedingEndOverlay(
      BuildContext context, WidgetRef ref, FastingState state) {
    return _buildBaseOverlay(
      context: context,
      icon: Icons.timer_off_rounded,
      iconColor: Colors.orangeAccent,
      title: "FIN DE VENTANA",
      subtitle: "Tu ventana de alimentación ha terminado.",
      buttonLabel: "CONFIRMAR CIERRE",
      isSaving: state.isSaving,
      onConfirm: () => _showManualTimePicker(context, ref, isFeeding: true),
    );
  }

  Widget _buildWakeUpOverlay(
      BuildContext context, WidgetRef ref, bool isSaving) {
    return _buildBaseOverlay(
      context: context,
      icon: Icons.wb_sunny_rounded,
      iconColor: Colors.orangeAccent,
      title: "¿YA DESPERTASTE?",
      subtitle: "Elena detecta actividad matutina.",
      buttonLabel: "SÍ, DESPERTÉ",
      isSaving: isSaving,
      onConfirm: () => ref.read(sleepProvider.notifier).confirmManualWakeUp(),
    );
  }

  Widget _buildBaseOverlay({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String buttonLabel,
    required bool isSaving,
    required VoidCallback onConfirm,
    // SPEC-151: botón secundario opcional. Si ambos labels y callbacks
    // son provistos, se renderiza debajo del primario con estilo
    // outlined para indicar acción alternativa.
    String? secondaryButtonLabel,
    VoidCallback? onSecondary,
  }) {
    final hasSecondary =
        secondaryButtonLabel != null && onSecondary != null;
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: iconColor, width: 2),
          boxShadow: [
            BoxShadow(color: iconColor.withValues(alpha: 0.2), blurRadius: 15)
          ]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        const SizedBox(height: 8),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 16),
        SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
                onPressed: isSaving ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(buttonLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12)))),
        if (hasSecondary) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: isSaving ? null : onSecondary,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: iconColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                secondaryButtonLabel,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }

  /// SPEC-102 / SPEC-102.1: fila sutil con hora de inicio (izquierda)
  /// y hora estimada de fin (derecha) del ayuno activo.
  ///
  /// Cada endpoint puede llevar un sufijo `·ayer` / `·mañana` /
  /// `·hace N días` / `·en N días` calculado SIEMPRE respecto a "hoy"
  /// (DateTime.now()), no al otro endpoint. Esto evita el bug de
  /// mostrar "·mañana" en un ayuno que comenzó ayer y termina hoy.
  /// SPEC-119: texto compacto del próximo hito metabólico para la
  /// columna "HITO SIGUIENTE" de la tarjeta de ayuno. Formato:
  /// `Quema de grasa en 7h 48m` o `Fase final` si ya pasamos el último.
  String _formatNextMilestone(FastingState state) {
    final remaining = state.timeRemainingForNextMilestone;
    if (remaining == Duration.zero) {
      // Estamos en autofagia o fase final — no hay próximo hito.
      return state.metabolicMilestone;
    }
    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);
    final timeText = hours == 0 ? '${minutes}m' : '${hours}h ${minutes}m';
    // Texto del hito en minúsculas estilo "Quema de grasa".
    String milestone;
    if (state.duration.inHours < 12) {
      milestone = 'Descenso de insulina';
    } else if (state.duration.inHours < 18) {
      milestone = 'Quema de grasa';
    } else if (state.duration.inHours < 24) {
      milestone = 'Autofagia';
    } else {
      milestone = 'Regeneración';
    }
    return '$milestone en $timeText';
  }

  /// SPEC-119: residual hasta cerrar el target (`targetHours`).
  /// Devuelve `' · faltan Xh Ym'` o `' · objetivo cumplido'`.
  /// El prefijo con ` · ` permite concatenar tras `$pct% completado`.
  String _formatTargetRemaining(FastingState state) {
    if (state.startTime == null) return '';
    final targetSeconds = state.targetHours * 3600;
    final elapsedSeconds = state.duration.inSeconds;
    final remainingSeconds = targetSeconds - elapsedSeconds;
    if (remainingSeconds <= 0) return ' · objetivo cumplido';
    final remaining = Duration(seconds: remainingSeconds);
    final h = remaining.inHours;
    final m = remaining.inMinutes.remainder(60);
    final t = h == 0 ? '${m}m' : '${h}h ${m}m';
    return ' · faltan $t';
  }

  Widget _buildFastingTimeline({
    required DateTime start,
    required int targetHours,
  }) {
    final DateTime now = DateTime.now();
    final DateTime estimatedEnd = start.add(Duration(hours: targetHours));

    final mutedStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.45),
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.4,
    );
    final dimmerStyle = mutedStyle.copyWith(
      color: Colors.white.withValues(alpha: 0.30),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _timelineEndpoint(
          dateTime: start,
          now: now,
          baseStyle: mutedStyle,
          qualifierStyle: dimmerStyle,
        ),
        _timelineEndpoint(
          dateTime: estimatedEnd,
          now: now,
          baseStyle: mutedStyle,
          qualifierStyle: dimmerStyle,
        ),
      ],
    );
  }

  Widget _timelineEndpoint({
    required DateTime dateTime,
    required DateTime now,
    required TextStyle baseStyle,
    required TextStyle qualifierStyle,
  }) {
    final qualifier = RelativeDayLabel.qualifier(dateTime, now);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(_formatHHmm(dateTime), style: baseStyle),
        if (qualifier.isNotEmpty) ...[
          const SizedBox(width: 4),
          Text('·$qualifier', style: qualifierStyle),
        ],
      ],
    );
  }

  static String _formatHHmm(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  /// SPEC-101: botón principal del card de Ayuno.
  ///
  /// - Estado "activo": label rojo "Finalizar Ayuno". Si progress<100%
  ///   muestra diálogo de confirmación con beneficios. Si >=100%, va
  ///   directo al picker (flow actual).
  /// - Estado "inactivo": label verde "Iniciar Ayuno". Si el usuario
  ///   ya completó un ayuno hoy, queda deshabilitado y al tocar
  ///   muestra snackbar.
  Widget _buildFastingPrimaryButton({
    required BuildContext context,
    required WidgetRef ref,
    required FastingState state,
    required bool isActive,
    required Color accent,
  }) {
    final bool completedToday =
        !isActive && ref.watch(hasCompletedFastingTodayProvider);
    final bool disabled = state.isSaving || (completedToday && !isActive);

    final Color bgColor;
    if (disabled && !isActive) {
      bgColor = Colors.white.withValues(alpha: 0.08);
    } else if (isActive) {
      bgColor = Colors.redAccent;
    } else {
      bgColor = accent;
    }

    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: disabled
            ? () {
                // En estado deshabilitado por completedToday queremos
                // explicar por qué no se puede tocar.
                if (completedToday && !isActive) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Ya completaste tu ayuno de hoy. '
                        'Vuelve mañana para iniciar el siguiente.',
                      ),
                      backgroundColor: Colors.orange,
                      duration: Duration(seconds: 4),
                    ),
                  );
                }
              }
            : () => _handleFastingPrimaryTap(context, ref, state, isActive),
        style: ElevatedButton.styleFrom(
          backgroundColor: bgColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        icon: state.isSaving
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                isActive
                    ? Icons.stop_circle_outlined
                    : (completedToday
                        ? Icons.check_circle_outline
                        : Icons.play_circle_outline),
                color: Colors.white
                    .withValues(alpha: (disabled && !isActive) ? 0.5 : 1.0),
                size: 22,
              ),
        label: Text(
          isActive
              ? 'Finalizar Ayuno'
              : (completedToday ? 'Ayuno de hoy completado' : 'Iniciar Ayuno'),
          style: TextStyle(
            color: Colors.white
                .withValues(alpha: (disabled && !isActive) ? 0.5 : 1.0),
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Future<void> _handleFastingPrimaryTap(
    BuildContext context,
    WidgetRef ref,
    FastingState state,
    bool isActive,
  ) async {
    if (isActive) {
      // Si llegó al 100%, flow actual (picker de hora de fin).
      if (state.progressPercentage >= 1.0) {
        await _showManualTimePicker(context, ref, isFeeding: false);
        return;
      }
      // SPEC-101: confirmación temprana con beneficios obtenidos.
      final confirm = await EarlyFastingEndDialog.show(
        context,
        elapsed: state.duration,
        targetHours: state.targetHours,
        phase: state.phase,
      );
      if (confirm == true) {
        await ref
            .read(fastingProvider.notifier)
            .confirmManualFastingEnd(DateTime.now());
      }
      return;
    }

    // No activo: iniciar.
    await ref.read(fastingProvider.notifier).startFasting();
  }

  /// SPEC-98: chip clickable que muestra el protocolo activo y abre
  /// el selector. Si el ayuno está en curso, el chip queda
  /// deshabilitado (cambiar protocolo a mitad de ayuno corrompería
  /// el cómputo de progreso y de fase).
  Widget _buildProtocolChip({
    required BuildContext context,
    required WidgetRef ref,
    required String protocol,
    required bool isActive,
  }) {
    final double alpha = isActive ? 0.35 : 0.85;
    return InkWell(
      onTap: () => _onProtocolChipTap(context, ref, protocol, isActive),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.10),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              protocol,
              style: TextStyle(
                color: Colors.white.withValues(alpha: alpha),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              isActive ? Icons.lock_outline_rounded : Icons.expand_more_rounded,
              size: 14,
              color: Colors.white.withValues(alpha: alpha),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _onProtocolChipTap(
    BuildContext context,
    WidgetRef ref,
    String currentProtocol,
    bool isActive,
  ) async {
    if (isActive) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No puedes cambiar protocolo durante un ayuno activo. '
            'Finaliza primero.',
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final selected = await ProtocolSelectorSheet.show(
      context,
      currentProtocol: currentProtocol,
    );
    if (selected == null || selected == currentProtocol) return;

    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null) return;

    await ref.read(profileControllerProvider.notifier).updateFastingProtocol(
          currentUser: user,
          protocol: selected,
        );
  }

  /// SPEC-97: picker dedicado para corregir la hora de inicio del
  /// ayuno activo. Distinto de `_showManualTimePicker`, que finaliza
  /// el ayuno (crea ventana de comida) y NO debe usarse para corregir.
  Future<void> _showCorrectStartTimePicker(
    BuildContext context,
    WidgetRef ref,
    FastingState state,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime currentStart = state.startTime ?? now;
    final DateTime earliest = now.subtract(const Duration(hours: 24));

    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentStart.isBefore(earliest) ? earliest : currentStart,
      firstDate: earliest,
      lastDate: now,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.metabolicGreen,
          ),
          dialogTheme:
              DialogThemeData(backgroundColor: const Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );
    if (pickedDate == null) return;

    final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(currentStart),
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AppColors.metabolicGreen,
          ),
          dialogTheme:
              DialogThemeData(backgroundColor: const Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );
    if (pickedTime == null) return;

    final DateTime finalDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    // Validación defensiva (también vive en el notifier).
    if (finalDateTime.isAfter(now)) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La hora de inicio no puede ser futura.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    if (now.difference(finalDateTime).inHours > 24) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La corrección no puede ser más de 24h atrás.',
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    await ref
        .read(fastingProvider.notifier)
        .correctFastingStartTime(finalDateTime);
  }

  Future<void> _showManualTimePicker(BuildContext context, WidgetRef ref,
      {required bool isFeeding}) async {
    final DateTime now = DateTime.now();
    final fastingState = ref.read(fastingProvider);
    final Color primaryColor =
        isFeeding ? Colors.orangeAccent : AppColors.metabolicGreen;
    final DateTime? pickedDate = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: now.subtract(const Duration(days: 7)),
        lastDate: now.add(const Duration(days: 1)),
        builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(primary: primaryColor),
                dialogTheme:
                    DialogThemeData(backgroundColor: const Color(0xFF1E293B))),
            child: child!));
    if (pickedDate == null) return;
    final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(now),
        builder: (context, child) => Theme(
            data: ThemeData.dark().copyWith(
                colorScheme: ColorScheme.dark(primary: primaryColor),
                dialogTheme:
                    DialogThemeData(backgroundColor: const Color(0xFF1E293B))),
            child: child!));
    if (pickedTime == null) return;
    final DateTime finalDateTime = DateTime(pickedDate.year, pickedDate.month,
        pickedDate.day, pickedTime.hour, pickedTime.minute);
    if (isFeeding) {
      ref.read(fastingProvider.notifier).confirmFeedingEnd(finalDateTime);
    } else {
      if (fastingState.isActive) {
        ref
            .read(fastingProvider.notifier)
            .confirmManualFastingEnd(finalDateTime);
      } else {
        ref.read(fastingProvider.notifier).startFastingManual(finalDateTime);
      }
    }
  }

  Widget _buildMetabolicAlertBanner(String message) {
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
            color: Colors.redAccent.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2))),
        child: Row(children: [
          const Icon(Icons.warning_amber_rounded,
              color: Colors.redAccent, size: 16),
          const SizedBox(width: 10),
          Expanded(
              child: Text(message,
                  style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 9,
                      fontWeight: FontWeight.bold)))
        ]));
  }

  // SPEC-72.2: _buildEngagementBanner eliminado. Reemplazado por
  // EngagementBanner widget en features/engagement/presentation/widgets/
  // que añade dismiss por sesión.

  Widget _buildBottomNav(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith('/analysis')) currentIndex = 1;
    if (location.startsWith('/profile')) currentIndex = 2;
    return BottomNavigationBar(
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: AppColors.metabolicGreen,
        unselectedItemColor: Colors.grey.withValues(alpha: 0.5),
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) context.go('/dashboard');
          if (index == 1) context.go('/analysis');
          if (index == 2) context.go('/profile');
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), label: "Hoy"),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights_rounded), label: "Análisis"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil")
        ]);
  }
}
