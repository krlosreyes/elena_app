import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/engine/imr_persistence_provider.dart';
import 'package:elena_app/src/core/engine/metabolic_state_provider.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/sleep/application/sleep_notifier.dart';
import 'package:elena_app/src/features/hydration/application/hydration_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/selected_pillar.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/dashboard_fasting_overlays.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/dashboard_pillars_row.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/fasting_consciousness_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/hoy_header.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/metabolic_day_widgets.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/today_focus_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/dashboard_selected_pillar_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/metabolic_alert_banner.dart';
// 17-jul: "Para ti" se colapsó en una card de entrada renombrada
// "Aprende con Elena" — ver comentario junto a su uso más abajo.
import 'package:elena_app/src/features/coaching/presentation/widgets/wake_up_quality_overlay.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/celebration_overlay.dart';
import 'package:elena_app/src/features/progress/application/biometric_backfill_provider.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_bootstrap_provider.dart';
import 'package:elena_app/src/features/metabolic_cycle/presentation/widgets/cycle_detail_sheet.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
// SPEC-137 E.5: banner countdown 30 min antes de la próxima comida.
import 'package:elena_app/src/features/onboarding/application/app_tour_notifier.dart';
import 'package:elena_app/src/features/onboarding/application/tour_targets_provider.dart';
import 'package:elena_app/src/features/badges/application/badge_notifier.dart';
// Módulo "Tu Glucosa" (23-jul): tarjeta de registro matutino + gancho
// de consentimiento automático (ver ref.listen más abajo).
import 'package:elena_app/src/features/dashboard/application/ui_interaction_notifier.dart';
import 'package:elena_app/src/features/glucose/application/glucose_providers.dart';
import 'package:elena_app/src/features/glucose/presentation/widgets/glucose_consent_sheet.dart';
// SPEC-261: card de entrada al Protocolo de Consumo Consciente (alcohol).

// SPEC-88 fix: BodyCompositionCard y GoalsDashboardWidget se retiraron
// del Dashboard. La primera vive ahora en Profile; la segunda queda
// accesible vía `/goals/setup`. Los imports se mantuvieron eliminados
// para evitar dependencias huérfanas.

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  // Rediseño Hoy (2026-10-30): ningún pilar abierto por defecto. El ayuno
  // ya es la acción principal de arriba; los demás se abren al tocarlos.
  SelectedPillar? _selectedPillar;

  void _onSelectPillar(SelectedPillar p) {
    if (!mounted) return;
    if (p == SelectedPillar.ayuno) {
      // El ayuno es la card principal: subir hasta ella.
      setState(() => _selectedPillar = null);
      final c = ref.read(dashboardScrollControllerProvider);
      if (c.hasClients) {
        c.animateTo(0,
            duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
      }
      return;
    }
    setState(() => _selectedPillar = _selectedPillar == p ? null : p);
  }

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
    // STATE-01 (auditoría técnica 21-jul): hydrationState/exerciseState/
    // nutritionState se watcheaban acá solo para pasarlos por
    // constructor a DashboardPillarsRow/DashboardSelectedPillarCard.
    // Esos dos widgets ahora leen su propio provider internamente
    // (ver sus archivos), así que este build ya no los necesita — cada
    // cambio en hidratación/ejercicio/comidas dejó de reconstruir todo
    // DashboardScreen.

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

    // Sistema de insignias (2026-07-15): BadgeNotifier evalúa en vivo si
    // corresponde alguna insignia nueva cada vez que cambia el historial
    // de racha o biométrico. Side-effect-only, mismo patrón que
    // imrPersistenceProvider/biometricBackfillProvider — el watch solo lo
    // mantiene vivo, no se usa su valor de retorno acá (la UI que sí lo
    // necesita, como la galería en Perfil, hace su propio watch).
    ref.watch(badgeProvider);

    // SPEC-202.2: el "momento" de cierre del día. Cuando inicias tu próximo
    // ayuno y eso cierra el ciclo anterior, presentamos su feedback de
    // inmediato como sheet (ligado al gesto), y descartamos el cierre para
    // que la tarjeta pasiva no lo repita después.
    // Mantiene vivo el historial reciente para el "Cerraste tú X de 7".
    ref.watch(last7ClosedCyclesProvider);
    ref.listen<MetabolicCycle?>(cycleClosureMomentProvider, (prev, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        // Recompensa del gesto: cuántos de tus últimos 7 días cerraste tú.
        final recent =
            ref.read(last7ClosedCyclesProvider).valueOrNull ?? const [];
        final ids = {for (final c in recent) c.cycleId};
        final pool = [
          if (!ids.contains(next.cycleId)) next,
          ...recent,
        ].take(7).toList();
        final byYou = pool
            .where((c) => c.closureReason == ClosureReason.manualNextFasting)
            .length;
        CycleDetailSheet.show(context, next,
            closedByYou: byYou, closedOutOf: pool.length);
        ref.read(cycleClosureMomentProvider.notifier).state = null;
        ref.read(cycleClosureDismissalProvider.notifier).dismiss(next.cycleId);
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

    // Módulo "Tu Glucosa" (23-jul): dispara el sheet de consentimiento
    // UNA vez por día cuando `glucoseShouldPromptConsentProvider` pasa a
    // true (elegible por pathologies, sin consentimiento aceptado, no
    // descartado hoy) — mismo patrón `ref.listen` + postFrameCallback
    // que `cycleClosureMomentProvider` más arriba. Si el usuario toca
    // "Ahora no", el sheet mismo no lo descarta — lo hace explícito acá
    // para no acoplar la UI del sheet a esta lógica de "una vez por día".
    ref.listen<bool>(glucoseShouldPromptConsentProvider, (prev, next) {
      if (next != true) return;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        await showGlucoseConsentSheet(
          context,
          welcomeReason: ref.read(glucoseProtocolEligibilityProvider).reason,
        );
        if (!mounted) return;
        final stillNotAccepted = ref
                .read(glucoseProtocolStateProvider)
                .valueOrNull
                ?.consentAccepted !=
            true;
        if (stillNotAccepted) {
          ref.read(uiInteractionProvider.notifier).dismissGlucoseConsent();
        }
      });
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
                      // Rediseño Hoy (2026-10-30): la pantalla responde una
                      // sola pregunta — qué hago ahora. Orden:
                      //   1. Saludo + racha
                      //   2. Acción principal (ayuno: iniciar / en curso)
                      //   3. Tu foco de hoy (una recomendación)
                      //   4. Tu día (puntaje + 5 pilares; tocar abre detalle)
                      // Se quitaron del feed: reloj circadiano (vive en
                      // Progreso), banners de racha/glucosa/engagement/
                      // prueba/muro de pago, cierre de ciclo, coach,
                      // sugerencias, check-in, recordatorio de peso y
                      // "Aprende". Su código sigue en el repo.
                      const SizedBox(height: 10),
                      const HoyHeader(),
                      const SizedBox(height: 14),
                      // Día metabólico (2026-11-04): siempre visible.
                      const MetabolicDayStrip(),
                      const SizedBox(height: 14),
                      if (fastingState.metabolicAlert != null) ...[
                        MetabolicAlertBanner(
                            message: fastingState.metabolicAlert!),
                        const SizedBox(height: 12),
                      ],
                      // Confirmaciones que el flujo necesita (despertar,
                      // fin de ayuno, fin de ventana). Antes flotaban sobre
                      // el reloj; ahora van en línea, arriba de la acción.
                      if (sleepState.isWaitingForWakeUp) ...[
                        const WakeUpQualityOverlay(),
                        const SizedBox(height: 14),
                      ],
                      if (fastingState.isWaitingForFastingEnd) ...[
                        FastingEndOverlay(state: fastingState),
                        const SizedBox(height: 14),
                      ],
                      if (fastingState.isWaitingForFeedingEnd) ...[
                        FeedingEndOverlay(state: fastingState),
                        const SizedBox(height: 14),
                      ],
                      // Día metabólico: si la ventana terminó y no
                      // iniciaste el ayuno, "¿a qué hora fue tu última
                      // comida?" — repara el olvido sin perder el día.
                      const CloseDayPrompt(),
                      FastingConsciousnessCard(state: fastingState),
                      const SizedBox(height: 14),
                      const TodayFocusCard(),
                      const SizedBox(height: 22),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Tu día metabólico',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Toca un pilar para ver más',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DashboardPillarsRow(
                        selectedPillar: _selectedPillar,
                        onSelectPillar: _onSelectPillar,
                      ),
                      // En ayuno, el detalle de Comida no se muestra (no se
                      // pueden registrar comidas hasta terminar).
                      if (_selectedPillar != null &&
                          _selectedPillar != SelectedPillar.ayuno &&
                          !(fastingState.isActive &&
                              _selectedPillar == SelectedPillar.comidas)) ...[
                        const SizedBox(height: 14),
                        DashboardSelectedPillarCard(
                          selectedPillar: _selectedPillar!,
                          onSelectPillar: _onSelectPillar,
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              const CelebrationOverlay(),
            ],
          ),
          bottomNavigationBar: const DashboardBottomNav(),
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

  // SPEC-119: fila de anillos por pilar → DashboardPillarsRow
  // (widgets/dashboard_pillars_row.dart). Extraído en ARCH-03/PERF-01.

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

  // SPEC-119: dispatcher del pilar seleccionado → DashboardSelectedPillarCard
  // (widgets/dashboard_selected_pillar_card.dart). Extraído en ARCH-03/PERF-01.

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

  // SPEC-119: overlays de fin de ayuno/ventana + time picker →
  // widgets/dashboard_fasting_overlays.dart (FastingEndOverlay,
  // FeedingEndOverlay, showManualTimePicker). Extraído en ARCH-03.

  // SPEC-234: _buildWakeUpOverlay reemplazado por WakeUpQualityOverlay
  // (widget stateful con flujo "¿Ya despertaste?" → "¿Cómo dormiste?").

  // SPEC-72.2: _buildEngagementBanner eliminado. Reemplazado por
  // EngagementBanner widget en features/engagement/presentation/widgets/
  // que añade dismiss por sesión.

  // SPEC-119: banner de alerta metabólica → MetabolicAlertBanner
  // (widgets/metabolic_alert_banner.dart). Extraído en ARCH-03.

  // SPEC-119: card "IMR Longitudinal" → ImrLongitudinalCard
  // (widgets/imr_longitudinal_card.dart). Extraído en ARCH-03/PERF-01.

  // SPEC-119: bottom nav → DashboardBottomNav
  // (widgets/dashboard_bottom_nav.dart). Extraído en ARCH-03.
}
