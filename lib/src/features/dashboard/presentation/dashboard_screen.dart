import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/engine/imr_persistence_provider.dart';
import 'package:elena_app/src/core/engine/metabolic_state_provider.dart';
import 'package:elena_app/src/core/widgets/elena_header.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/fasting/application/eating_window_provider.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/sleep/application/sleep_notifier.dart';
import 'package:elena_app/src/features/hydration/application/hydration_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/selected_pillar.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/circadian_clock.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/dashboard_fasting_overlays.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/dashboard_pillars_row.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/dashboard_selected_pillar_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/metabolic_alert_banner.dart';
import 'package:elena_app/src/features/engagement/presentation/widgets/engagement_banner.dart';
import 'package:elena_app/src/features/adaptive/presentation/widgets/adaptive_suggestion_card.dart';
import 'package:elena_app/src/features/billing/presentation/paywall_auto_trigger.dart';
import 'package:elena_app/src/features/billing/presentation/trial_banner.dart';
// 17-jul: "Para ti" se colapsó en una card de entrada renombrada
// "Aprende con Elena" — ver comentario junto a su uso más abajo.
import 'package:elena_app/src/features/content/presentation/widgets/aprende_entry_card.dart';
import 'package:elena_app/src/features/coaching/presentation/widgets/cycle_coaching_feedback_card.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/interactive_coaching_card.dart';
import 'package:elena_app/src/features/coaching/presentation/widgets/check_in_card.dart';
import 'package:elena_app/src/features/coaching/presentation/widgets/wake_up_quality_overlay.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/new_cycle_meals_warning_dialog.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/celebration_overlay.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/clock_explainer_sheet.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/progress/application/biometric_backfill_provider.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_bootstrap_provider.dart';
import 'package:elena_app/src/features/metabolic_cycle/presentation/widgets/cycle_closure_card.dart';
import 'package:elena_app/src/features/metabolic_cycle/presentation/widgets/cycle_detail_sheet.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
// SPEC-137 E.5: banner countdown 30 min antes de la próxima comida.
import 'package:elena_app/src/features/nutrition/presentation/widgets/next_meal_banner.dart';
import 'package:elena_app/src/features/onboarding/application/app_tour_notifier.dart';
import 'package:elena_app/src/features/onboarding/application/tour_targets_provider.dart';
import 'package:elena_app/src/features/progress/presentation/widgets/biometric_reminder_banner.dart';
import 'package:elena_app/src/features/badges/application/badge_notifier.dart';
import 'package:elena_app/src/features/streak/presentation/widgets/streak_at_risk_banner.dart';
// Módulo "Tu Glucosa" (23-jul): tarjeta de registro matutino + gancho
// de consentimiento automático (ver ref.listen más abajo).
import 'package:elena_app/src/features/dashboard/application/ui_interaction_notifier.dart';
import 'package:elena_app/src/features/glucose/application/glucose_providers.dart';
import 'package:elena_app/src/features/glucose/presentation/widgets/glucose_consent_sheet.dart';
import 'package:elena_app/src/features/glucose/presentation/widgets/glucose_morning_reminder_card.dart';
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
    ref.listen<MetabolicCycle?>(cycleClosureMomentProvider, (prev, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        CycleDetailSheet.show(context, next);
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
                      const SizedBox(height: 10),
                      ElenaHeader(
                        // SPEC-263: acceso directo a Retos de constancia.
                        actions: IconButton(
                          icon: const Icon(Icons.emoji_events_rounded,
                              color: AppColors.accent, size: 24),
                          tooltip: 'Retos',
                          onPressed: () => context.push('/retos'),
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Propuesta "racha protagonista" (2026-07-15, P1): la
                      // racha vive en el Dashboard, no solo en Análisis —
                      // mismo lugar donde Duolingo muestra su llama en cada
                      // apertura de la app.
                      //
                      // 17-jul: StreakTodayWidget (card "X días de racha" que
                      // iba acá) se quitó — duplicaba el badge de ElenaHeader
                      // (mismo dato, mismo tap-target hacia el sheet de
                      // reglas). El badge del header absorbió su texto y ahora
                      // es el único punto de entrada, con tap directo al
                      // detalle (/analysis/racha) en vez del sheet de reglas.
                      // Archivo streak_today_widget.dart queda sin uso, no se
                      // borra por si se retoma.

                      // P4: aviso de racha en riesgo — solo aparece en horario
                      // de tarde/noche si hoy todavía no calificó y hay una
                      // racha activa en juego. Se oculta sola el resto del día.
                      const StreakAtRiskBanner(),

                      // Módulo "Tu Glucosa" (23-jul): tarjeta de registro
                      // matutino — se autooculta si la ventana no está
                      // abierta (GlucoseWindowState.isOpen == false), mismo
                      // criterio "widget autocontenido" que StreakAtRiskBanner.
                      const GlucoseMorningReminderCard(),

                      // SPEC-261: Protocolo de Consumo Consciente — SUSPENDIDO
                      // (2026-08-01). La tarjeta de acceso se retiró del feed
                      // mientras la funcionalidad está en pausa. El resto del
                      // código del protocolo queda intacto para retomarlo.
                      // const AlcoholProtocolCard(),

                      // BANNER DE ENGAGEMENT (SPEC-07 + SPEC-72.2 dismiss por sesión)
                      const EngagementBanner(),
                      const SizedBox(height: 16),

                      // SPEC-240: banner de periodo de prueba. Visible días 1–14
                      // para usuarios no-premium. Se oculta solo al vencer o suscribir.
                      const TrialBanner(),

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
                                // SPEC-254: avisar si iniciar el ayuno va a
                                // sacar de la vista comidas ya registradas
                                // en el ciclo actual (ver
                                // new_cycle_meals_warning_dialog.dart).
                                final mealsCount = ref
                                    .read(nutritionProvider)
                                    .todayLogs
                                    .length;
                                if (mealsCount > 0) {
                                  final confirm =
                                      await NewCycleMealsWarningDialog.show(
                                    context,
                                    mealsCount: mealsCount,
                                  );
                                  if (confirm != true) return;
                                }
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

                      // Carlos (2026-07-13): recordatorio de actualizar peso/
                      // medidas — 7 días desde el último check-in biométrico.
                      // Se oculta sola si no aplica o si ya se descartó hoy.
                      const BiometricReminderBanner(),
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
                                    eatingWindow:
                                        ref.watch(eatingWindowProvider),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (sleepState.isWaitingForWakeUp)
                            const WakeUpQualityOverlay(),
                          if (fastingState.isWaitingForFastingEnd)
                            FastingEndOverlay(state: fastingState),
                          if (fastingState.isWaitingForFeedingEnd)
                            FeedingEndOverlay(state: fastingState),
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
                            foregroundColor:
                                Colors.white.withValues(alpha: 0.55),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          icon:
                              const Icon(Icons.help_outline_rounded, size: 15),
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
                        MetabolicAlertBanner(
                            message: fastingState.metabolicAlert!),
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
                      DashboardPillarsRow(
                        selectedPillar: _selectedPillar,
                        onSelectPillar: (p) =>
                            setState(() => _selectedPillar = p),
                      ),
                      // SPEC-140.3: gap reducido de 24 → 14 para que la card
                      // del pilar seleccionado se sienta como continuación
                      // visual del card de "Tu Día", no como otra sección.
                      const SizedBox(height: 14),

                      // Tarjeta de soporte del pilar seleccionado.
                      // Cambia dinámicamente al tocar un anillo de la fila "PILARES HOY".
                      DashboardSelectedPillarCard(
                        selectedPillar: _selectedPillar,
                        onSelectPillar: (p) {
                          if (mounted) {
                            setState(() => _selectedPillar = p);
                          }
                        },
                      ),
                      const SizedBox(height: 14),

                      // GAP-2 → retirado (22-jul, a pedido del líder de
                      // proyecto: "esta card no aporta nada"). El widget
                      // `ImrLongitudinalCard` (widgets/imr_longitudinal_card.dart)
                      // queda sin consumidores tras este cambio — no se borra el
                      // archivo (restricción del sandbox), pero si en el futuro
                      // se quiere recuperar la métrica en algún lado, este era
                      // el único punto de montaje.

                      // SPEC-88 fix: BodyCompositionCard, GoalsDashboardWidget
                      // y _buildProgressCTA se removieron del Dashboard a
                      // pedido del líder de proyecto. La composición
                      // corporal vive ahora en Profile (SPEC-88). Objetivos
                      // y Road Map quedan accesibles desde sus pantallas
                      // dedicadas (/goals/setup y /progress) — el atajo en
                      // Dashboard se considera ruido visual.
                      const SizedBox(height: 10),

                      // SPEC-114-app (2026-07-12, hallazgo A2 del informe de
                      // producto): el feed "Para ti" (SPEC-205) es el
                      // diferencial científico más defendible frente a la
                      // competencia, pero vivía únicamente enterrado dentro
                      // de la pantalla de Análisis — invisible para un
                      // usuario en su primera semana. Se promueve al
                      // Dashboard, después del IMR, como cierre natural del
                      // scroll (no compite por atención con el ayuno/pilares
                      // que van arriba).
                      //
                      // 17-jul: Carlos pidió colapsarlo en una card de entrada
                      // (mismo patrón que Progreso) y renombrarlo — "Para ti"
                      // no comunicaba qué había adentro. "Aprende con Elena"
                      // ata el contenido educativo a la voz de la app. El
                      // detalle completo (línea de contexto + artículos) vive
                      // ahora en AprendeDetailScreen (/aprende).
                      const AprendeEntryCard(),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              // SPEC-220: overlay de celebración 3/5 pilares.
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
