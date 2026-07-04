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
import 'package:elena_app/src/features/dashboard/presentation/widgets/circadian_clock.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/pillar_ring.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/dual_score_ring.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_state.dart';
import 'package:elena_app/src/features/engagement/presentation/widgets/engagement_banner.dart';
import 'package:elena_app/src/features/adaptive/presentation/widgets/adaptive_suggestion_card.dart';
import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/billing/presentation/paywall_auto_trigger.dart';
import 'package:elena_app/src/features/billing/presentation/paywall_launcher.dart';
import 'package:elena_app/src/features/billing/presentation/premium_lock.dart';
import 'package:elena_app/src/features/coaching/presentation/widgets/cycle_coaching_feedback_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/interactive_coaching_card.dart';
import 'package:elena_app/src/features/coaching/presentation/widgets/check_in_card.dart';
import 'package:elena_app/src/features/coaching/presentation/widgets/wake_up_quality_overlay.dart';
import 'package:elena_app/src/features/goals/application/pillar_goal_providers.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/exercise_pillar_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/hydration_pillar_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/sleep_pillar_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/comidas_pillar_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/fasting_consciousness_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/celebration_overlay.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/clock_explainer_sheet.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/progress/application/biometric_backfill_provider.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/daily_score_explainer_sheet.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_bootstrap_provider.dart';
import 'package:elena_app/src/features/metabolic_cycle/presentation/widgets/cycle_closure_card.dart';
import 'package:elena_app/src/features/metabolic_cycle/presentation/widgets/cycle_detail_sheet.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/streak/application/daily_score_provider.dart';
// SPEC-137 E.5: banner countdown 30 min antes de la próxima comida.
import 'package:elena_app/src/features/nutrition/presentation/widgets/next_meal_banner.dart';
import 'package:elena_app/src/features/onboarding/application/app_tour_notifier.dart';
import 'package:elena_app/src/features/onboarding/application/tour_targets_provider.dart';

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

  // SPEC-243 BUILD-2 FIX: el tour solo se llamaba desde _finalSubmit() en
  // onboarding. Usuarios con perfil ya creado llegan al dashboard sin pasar
  // por ese método → tour nunca aparecía. Al verificar aquí con tryActivate()
  // garantizamos que cualquier usuario que llegue por primera vez al dashboard
  // vea el tour, independientemente del camino de onboarding que tomó.
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appTourProvider.notifier).tryActivate();
    });
  }

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

    // SPEC-202.2: el "momento" de cierre del día. Cuando inicias tu próximo
    // ayuno y eso cierra el ciclo anterior, presentamos su feedback de
    // inmediato como sheet (ligado al gesto), y descartamos el cierre para
    // que la tarjeta pasiva no lo repita después.
    ref.listen<MetabolicCycle?>(cycleClosureMomentProvider, (prev, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        CycleDetailSheet.show(context, next);
        ref.read(cycleClosureMomentProvider.notifier).state = null;
        ref
            .read(cycleClosureDismissalProvider.notifier)
            .dismiss(next.cycleId);
      });
    });

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
          body: Stack(
            children: [
          SafeArea(
            child: SingleChildScrollView(
              // SPEC-243 fix: el controller compartido permite que AppTourOverlay
              // haga scroll para centrar los PillarRings durante el tour.
              controller: ref.read(dashboardScrollControllerProvider),
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

                  // SPEC-198: orquestador invisible del paywall proactivo +
                  // nudges día 5/12. No dibuja nada.
                  const PaywallAutoTrigger(),

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

                  // SPEC-194 RF-05: feedback del coach sobre el ciclo que
                  // cerró ("ayer priorizaste X…"). Se oculta solo si no hay
                  // cierre sin leer o no había recomendación activa.
                  const CycleCoachingFeedbackCard(),

                  // SPEC-137 E.5: banner "próxima comida en X min" cuando
                  // estamos dentro de los 30 min previos al horario
                  // sugerido (última comida + 3h). Se auto-oculta si no
                  // aplica o si hay día de permitidos activo.
                  const NextMealBanner(),

                  // MOTOR ADAPTATIVO (SPEC-08)
                  const AdaptiveSuggestionCard(),

                  // SPEC-199 Fase A: coach INTERACTIVO de hidratación. Pregunta
                  // accionable (registrar vaso de un toque) decidida por el
                  // motor predictivo según contexto. Se oculta sola si no aplica.
                  const InteractiveCoachingCard(),

                  // SPEC-232: check-in emocional durante el ayuno. Aparece
                  // en hitos 4/8/12/16h con 6 opciones de sentimiento. Se
                  // oculta sola si no hay hito activo o si ya respondió.
                  const CheckInCard(),
                  const SizedBox(height: 16),

                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Center(
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.78,
                          child: AspectRatio(
                            aspectRatio: 1.0,
                            // SPEC-202: tocar el reloj abre el explainer con la
                            // leyenda de cada elemento (qué es el punto azul,
                            // el arco, el anillo de fase, los hitos).
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => showClockExplainerSheet(context),
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
                      ),
                      if (sleepState.isWaitingForWakeUp)
                        const WakeUpQualityOverlay(),
                      if (fastingState.isWaitingForFastingEnd)
                        _buildFastingEndOverlay(context, ref, fastingState),
                      if (fastingState.isWaitingForFeedingEnd)
                        _buildFeedingEndOverlay(context, ref, fastingState),
                    ],
                  ),

                  // SPEC-202: separación amplia para que el "12" del borde
                  // inferior del reloj no quede pegado a la pista de abajo.
                  const SizedBox(height: 28),

                  // SPEC-202: pista de descubrimiento — invita a tocar el reloj
                  // para entenderlo. Centrada y discreta, fuera del círculo
                  // (no se solapa con ningún elemento del reloj).
                  Center(
                    child: TextButton.icon(
                      onPressed: () => showClockExplainerSheet(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withValues(alpha: 0.55),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      icon: const Icon(Icons.help_outline_rounded, size: 15),
                      label: const Text(
                        '¿Qué significan los anillos?',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

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
                  const SizedBox(height: 14),

                  // GAP-2: bloqueo visible del IMR longitudinal en el Dashboard.
                  // Free: ve el card atenuado con candado + CTA "Desbloquear".
                  // Premium: ve el IMR actual + zona + enlace a Análisis.
                  _buildImrLongitudinalCard(context, ref),
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
          // SPEC-220: overlay de celebración 3/5 pilares.
          const CelebrationOverlay(),
          ],
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
          // SPEC-170 (2026-06-04): dos rings adyacentes HOY + IMR
          // reemplazan el número grande 36pt. Cada uno con score, label
          // y sub-label propio. Tap en cualquiera abre el ExplainerSheet
          // único que cubre ambos.
          // SPEC-243 fix: key compartida con AppTourOverlay para calcular
          // posición real del spotlight "Progreso Hoy" (scoreCard).
          DualScoreRing(
            key: ref.read(dualScoreRingKeyProvider),
            dailyScore: dailyScore,
            dailyDelta: delta,
            imrScore: ref.watch(displayedImrProvider).score,
            imrZone: ref.watch(displayedImrProvider).zone,
            // SPEC-229: biometrías parciales → sublabel "estimado" en el IMR ring.
            imrIsPartial:
                ref.watch(displayedImrProvider).localFull?.isPartialBiometrics ??
                    false,
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
          // SPEC-243 fix: key compartida con AppTourOverlay para calcular
          // posición real del spotlight de cada pilar (localToGlobal).
          Row(
            key: ref.read(pillarRowKeyProvider),
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
      SelectedPillar.ayuno => FastingConsciousnessCard(state: fastingState),
      SelectedPillar.sueno => SleepPillarCard(state: sleep),
      SelectedPillar.hidratacion => HydrationPillarCard(state: hydration),
      SelectedPillar.ejercicio => ExercisePillarCard(state: exercise),
      SelectedPillar.comidas => ComidasPillarCard(
          state: nutrition,
          isFastingActive: fastingState.isActive,
          onGoToFasting: () {
            if (mounted) {
              setState(() => _selectedPillar = SelectedPillar.ayuno);
            }
          },
        ),
    };
  }

  // ─── SUEÑO: "Soporte Metabólico" ──────────────────────────────────────
  // SPEC-119: card de Sueño → SleepPillarCard (widgets/sleep_pillar_card.dart).


  // ─── HIDRATACIÓN: "Soporte Metabólico" ────────────────────────────────
  // SPEC-119: card de Hidratación → HydrationPillarCard (widgets/hydration_pillar_card.dart).

  // ─── EJERCICIO: "Sarcopenia & Resistencia" ────────────────────────────
  // SPEC-119: card de Ejercicio → ExercisePillarCard (widgets/exercise_pillar_card.dart).

  // ─── COMIDAS: "Nutrición Científica" ──────────────────────────────────
  //
  // SPEC-105: cuando hay ayuno activo, la card se renderea en estado
  // bloqueado: banner visible arriba, contenido con opacity 0.5,
  // botones disabled, y tap en cualquier parte abre diálogo educativo.
  // SPEC-119: card de Comidas → ComidasPillarCard (widgets/comidas_pillar_card.dart).

  // SPEC-119: banner de bloqueo + helpers de comidas (_cocienteAColor,
  // _estimateNextMealIn) → ComidasPillarCard (widgets/comidas_pillar_card.dart).

  // SPEC-119: `_pillarCardShell` → `PillarCardUi.shell` (widgets/pillar_card_ui.dart).
  // SPEC-119: helpers de presentación puros extraídos a `PillarCardUi.*`.
  // SPEC-119: `_showPendingFeatureSnack` se movió con las cards (cada
  // *PillarCard tiene su propio `_pendingSnack`).

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

  // SPEC-234: _buildWakeUpOverlay reemplazado por WakeUpQualityOverlay
  // (widget stateful con flujo "¿Ya despertaste?" → "¿Cómo dormiste?").

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

  /// GAP-2: card "IMR Longitudinal" visible en el Dashboard principal.
  ///
  /// Free → atenuado con candado + "Desbloquear" que abre el paywall.
  /// Premium → muestra IMR actual + zona + acceso directo a Análisis.
  ///
  /// Objetivo: el usuario Free ve inmediatamente que hay valor adicional
  /// bloqueado y puede convertirse en ese momento sin salir del flujo.
  Widget _buildImrLongitudinalCard(BuildContext context, WidgetRef ref) {
    final gate = ref.watch(featureGateProvider);
    final imr = ref.watch(displayedImrProvider);

    final content = Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.trending_up_rounded,
                    color: AppColors.metabolicGreen,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'IMR LONGITUDINAL',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 10,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (gate.analyticsHistoryAllowed)
                GestureDetector(
                  onTap: () => context.go('/analysis'),
                  child: Text(
                    'Ver detalle →',
                    style: TextStyle(
                      color: AppColors.metabolicGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _ImrStatColumn(
                label: 'IMR Actual',
                value: imr.score.toString(),
                accent: AppColors.metabolicGreen,
              ),
              _ImrStatColumn(
                label: 'Zona',
                value: imr.zone.isNotEmpty ? imr.zone : '—',
                accent: Colors.white,
              ),
              _ImrStatColumn(
                label: 'Tendencia',
                value: '7 días',
                accent: Colors.white,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Tu IMR longitudinal refleja tu estado metabólico real. '
            'Sube con ciclos bien ejecutados, semana a semana.',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.50),
              height: 1.45,
            ),
          ),
        ],
      ),
    );

    return PremiumLock(
      isLocked: !gate.analyticsHistoryAllowed,
      label: 'IMR Longitudinal',
      onUpgrade: () => openPaywall(
        context,
        ref,
        feature: GatedFeature.analyticsHistory,
      ),
      child: content,
    );
  }

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
              icon: Icon(Icons.insights_rounded), label: "Progreso"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil")
        ]);
  }
}

/// Columna de stat para el card IMR Longitudinal.
class _ImrStatColumn extends StatelessWidget {
  const _ImrStatColumn({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            color: accent,
            fontSize: 22,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }
}
