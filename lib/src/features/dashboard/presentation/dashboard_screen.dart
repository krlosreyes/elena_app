import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; 
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/engine/imr_persistence_provider.dart';
import 'package:elena_app/src/core/engine/metabolic_state_provider.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
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
import 'package:elena_app/src/features/dashboard/presentation/widgets/live_fasting_clock.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/pillar_ring.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/protocol_selector_sheet.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_state.dart';
import 'package:elena_app/src/features/exercise/presentation/exercise_input_sheet.dart';
import 'package:elena_app/src/features/engagement/presentation/widgets/engagement_banner.dart';
import 'package:elena_app/src/features/adaptive/presentation/widgets/adaptive_suggestion_card.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/presentation/add_past_meal_sheet.dart';
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

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final fastingState = ref.watch(fastingProvider);
    final sleepState = ref.watch(sleepProvider);
    final hydrationState = ref.watch(hydrationProvider);
    final exerciseState = ref.watch(exerciseProvider);
    final nutritionState = ref.watch(nutritionProvider);

    // SPEC-52: el IMR viene del provider central — una sola fuente de verdad.
    final result = ref.watch(imrProvider);

    // SPEC-86: para el "score grande" del Reloj Circadiano, preferimos
    // el persistido cuando el cálculo local solo tiene baseline (caso
    // de usuario MR sin data behavioral en la app). Las tarjetas de
    // detalle siguen leyendo `result` directamente.
    final displayedImr = ref.watch(displayedImrProvider);

    // SPEC-82: mantener vivo el sink debounced que persiste imr.current
    // al doc raíz `users/{uid}.imr.current` (consumido por el sitio web
    // Metamorfosis Real). El provider es side-effect-only — el watch
    // sólo lo monta; no se usa su retorno.
    ref.watch(imrPersistenceProvider);

    return userAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (err, stack) => Scaffold(body: Center(child: Text('Fallo de Hardware: $err'))),
      data: (user) {
        if (user == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

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
                              // SPEC-86: usar displayed (puede preferir
                              // el persistido del sitio sobre baseline).
                              // SPEC-91: el badge de zona quedó fuera del
                              // círculo; ya no se pasa `zone`.
                              score: displayedImr.score.toDouble(),
                              // SPEC-95: ventana de alimentación como
                              // concepto propio (windowStart/windowEnd
                              // derivados del protocolo del usuario).
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

                  // PILARES HOY (5 anillos circulares interactivos)
                  _buildPillarsRow(
                    context: context,
                    ref: ref,
                    fastingState: fastingState,
                    sleep: sleepState,
                    hydration: hydrationState,
                    exercise: exerciseState,
                    nutrition: nutritionState,
                  ),
                  const SizedBox(height: 24),

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
  Widget _buildPillarsRow({
    required BuildContext context,
    required WidgetRef ref,
    required FastingState fastingState,
    required SleepState sleep,
    required HydrationState hydration,
    required ExerciseState exercise,
    required NutritionState nutrition,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PILARES HOY',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.4),
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              PillarRing(
                icon: Icons.timer_rounded,
                color: AppColors.metabolicGreen,
                progress: fastingState.progressPercentage,
                label: 'Ayuno',
                isSelected: _selectedPillar == SelectedPillar.ayuno,
                completed: fastingState.progressPercentage >= 1.0,
                onTap: () => setState(() => _selectedPillar = SelectedPillar.ayuno),
              ),
              PillarRing(
                icon: Icons.nightlight_round,
                color: const Color(0xFF818CF8),
                progress: sleep.lastLog == null
                    ? 0.0
                    : (sleep.lastLog!.duration.inMinutes / (8 * 60))
                        .clamp(0.0, 1.0),
                label: 'Sueño',
                isSelected: _selectedPillar == SelectedPillar.sueno,
                completed: sleep.lastLog != null &&
                    sleep.lastLog!.duration.inHours >= 7,
                onTap: () => setState(() => _selectedPillar = SelectedPillar.sueno),
              ),
              PillarRing(
                icon: Icons.water_drop_rounded,
                color: Colors.blueAccent,
                progress: hydration.progressPercentage,
                label: 'Hidratación',
                isSelected: _selectedPillar == SelectedPillar.hidratacion,
                completed: hydration.isGoalReached,
                onTap: () =>
                    setState(() => _selectedPillar = SelectedPillar.hidratacion),
              ),
              Builder(builder: (_) {
                // SPEC-113.bugfix: usar `user.exerciseGoalMinutes`
                // (default 20) como meta diaria. Antes el progress se
                // dividía por 60 y el "completed" se gatillaba en 30
                // — ambos hardcoded y desalineados con el objetivo
                // real sugerido al usuario.
                final user = ref.watch(currentUserStreamProvider).value;
                final goal =
                    (user?.exerciseGoalMinutes ?? 20).clamp(1, 240);
                final progress = (exercise.todayMinutes / goal.toDouble())
                    .clamp(0.0, 1.0);
                return PillarRing(
                  icon: Icons.fitness_center_rounded,
                  color: Colors.tealAccent,
                  progress: progress,
                  label: 'Ejercicio',
                  isSelected:
                      _selectedPillar == SelectedPillar.ejercicio,
                  completed: exercise.todayMinutes >= goal,
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
                  onTap: () => setState(
                      () => _selectedPillar = SelectedPillar.comidas),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // SPEC-66 v2: _pillarRing extraído a widgets/pillar_ring.dart como
  // PillarRing público para hacerlo testeable con widget tests.

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
    final accent = isActive ? AppColors.metabolicGreen : AppColors.metabolicGreen;
    final pct = (state.progressPercentage.clamp(0.0, 1.0) * 100).round();

    // SPEC-61: el display HH:MM:SS lo renderiza LiveFastingClock con su
    // propio Timer local, sin disparar rebuilds del fastingProvider.

    final stateLabel = isActive ? 'En curso' : 'En espera';

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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
          // Display de tiempo + protocolo. El reloj corre con su propio
          // Timer local de 1s (SPEC-61) y no muta fastingProvider.
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              LiveFastingClock(
                startTime: state.startTime,
                isActive: isActive,
                color: accent,
              ),
              const SizedBox(width: 10),
              // SPEC-98: chip clickable que abre el ProtocolSelectorSheet.
              // Si el ayuno está activo, el chip se deshabilita
              // visualmente y el tap muestra un snackbar explicativo.
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: _buildProtocolChip(
                  context: context,
                  ref: ref,
                  protocol: state.fastingProtocol,
                  isActive: isActive,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
            '$pct% completado',
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
          context, ref, nutrition,
          isFastingActive: fastingState.isActive,
        ),
    };
  }

  // ─── SUEÑO: "Soporte Metabólico" ──────────────────────────────────────
  Widget _buildSuenoCard(BuildContext context, WidgetRef ref, SleepState state) {
    const accent = Color(0xFF818CF8);
    final log = state.lastLog;
    final hasLog = log != null;
    final hours = hasLog ? log.duration.inHours : 0;
    final minutes = hasLog ? log.duration.inMinutes.remainder(60) : 0;
    final progress = hasLog
        ? (log.duration.inMinutes / (8 * 60)).clamp(0.0, 1.0)
        : 0.0;
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
            _miniStat('Dormiste', hasLog ? '${hours}h ${minutes}m' : '—',
                accent, big: true),
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
    final choice =
        await SleepExistingLogDialog.show(context, log: log);

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
          text: 'Cada 250ml mejora el flujo linfático y la eliminación de metabolitos',
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
                    : () => ref
                        .read(hydrationProvider.notifier)
                        .addWater(0.250),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _outlinedActionButton(
                label: '+500 ml',
                accent: accent,
                onPressed: state.isSaving
                    ? null
                    : () => ref
                        .read(hydrationProvider.notifier)
                        .addWater(0.500),
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
  Widget _buildEjercicioCard(BuildContext context, WidgetRef ref,
      ExerciseState state, dynamic user) {
    const accent = Color(0xFF2DD4BF);
    final goal = (user?.exerciseGoalMinutes ?? 30) as int;
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
    final scoreNum = (state.nutritionScore.clamp(0.0, 1.0) * 100).round();

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
                  _miniStat('Score nutricional', '$scoreNum', Colors.white,
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
              _primaryButton(
                label: 'Registrar ${state.nextMealLabel}',
                icon: Icons.restaurant_rounded,
                color: accent,
                onPressed: isFastingActive || state.isSaving
                    ? null
                    : () => ref.read(nutritionProvider.notifier).logMeal(),
              ),
              const SizedBox(height: 10),
              _secondaryButton(
                label: 'Registrar comida pasada',
                icon: Icons.history_rounded,
                onPressed: isFastingActive
                    ? null
                    : () => showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          backgroundColor: Colors.transparent,
                          builder: (_) => const AddPastMealSheet(),
                        ),
              ),
              const SizedBox(height: 10),
              _secondaryButton(
                label: 'Deshacer última comida registrada',
                icon: Icons.undo_rounded,
                onPressed: isFastingActive || state.todayLogs.isEmpty
                    ? null
                    : () => ref
                        .read(nutritionProvider.notifier)
                        .removeLastMeal(),
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
        final goToFasting =
            await MealsLockedDuringFastingDialog.show(context);
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
  String _estimateNextMealIn(NutritionState state) {
    if (state.mealsLoggedToday >= state.targetMeals) return '—';
    const targets = {
      'Desayuno': 8,
      'Almuerzo': 13,
      'Cena': 19,
      'Snack': 16,
    };
    final hour = targets[state.nextMealLabel];
    if (hour == null) return '—';
    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day, hour);
    final diff = target.difference(now);
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
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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

  Widget _buildFastingEndOverlay(BuildContext context, WidgetRef ref, FastingState state) {
    return _buildBaseOverlay(
      context: context, icon: Icons.emoji_events_rounded, iconColor: AppColors.metabolicGreen,
      title: "¡META ALCANZADA!", subtitle: "Has completado tus ${state.targetHours}h de ayuno.",
      buttonLabel: "CONFIRMAR HITO REAL", isSaving: state.isSaving,
      onConfirm: () => _showManualTimePicker(context, ref, isFeeding: false),
    );
  }

  Widget _buildFeedingEndOverlay(BuildContext context, WidgetRef ref, FastingState state) {
    return _buildBaseOverlay(
      context: context, icon: Icons.timer_off_rounded, iconColor: Colors.orangeAccent,
      title: "FIN DE VENTANA", subtitle: "Tu ventana de alimentación ha terminado.",
      buttonLabel: "CONFIRMAR CIERRE", isSaving: state.isSaving,
      onConfirm: () => _showManualTimePicker(context, ref, isFeeding: true),
    );
  }

  Widget _buildWakeUpOverlay(BuildContext context, WidgetRef ref, bool isSaving) {
    return _buildBaseOverlay(
      context: context, icon: Icons.wb_sunny_rounded, iconColor: Colors.orangeAccent,
      title: "¿YA DESPERTASTE?", subtitle: "Elena detecta actividad matutina.",
      buttonLabel: "SÍ, DESPERTÉ", isSaving: isSaving,
      onConfirm: () => ref.read(sleepProvider.notifier).confirmManualWakeUp(),
    );
  }

  Widget _buildBaseOverlay({required BuildContext context, required IconData icon, required Color iconColor, required String title, required String subtitle, required String buttonLabel, required bool isSaving, required VoidCallback onConfirm}) {
    return Container(
      padding: const EdgeInsets.all(20), margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(color: const Color(0xFF0F172A).withValues(alpha: 0.98), borderRadius: BorderRadius.circular(30), border: Border.all(color: iconColor, width: 2), boxShadow: [BoxShadow(color: iconColor.withValues(alpha: 0.2), blurRadius: 15)]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 42, child: ElevatedButton(onPressed: isSaving ? null : onConfirm, style: ElevatedButton.styleFrom(backgroundColor: iconColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)))),
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
                color: Colors.white.withValues(
                    alpha: (disabled && !isActive) ? 0.5 : 1.0),
                size: 22,
              ),
        label: Text(
          isActive
              ? 'Finalizar Ayuno'
              : (completedToday
                  ? 'Ayuno de hoy completado'
                  : 'Iniciar Ayuno'),
          style: TextStyle(
            color: Colors.white.withValues(
                alpha: (disabled && !isActive) ? 0.5 : 1.0),
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
              isActive
                  ? Icons.lock_outline_rounded
                  : Icons.expand_more_rounded,
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
          dialogBackgroundColor: const Color(0xFF1E293B),
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
          dialogBackgroundColor: const Color(0xFF1E293B),
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

  Future<void> _showManualTimePicker(BuildContext context, WidgetRef ref, {required bool isFeeding}) async {
    final DateTime now = DateTime.now();
    final fastingState = ref.read(fastingProvider);
    final Color primaryColor = isFeeding ? Colors.orangeAccent : AppColors.metabolicGreen;
    final DateTime? pickedDate = await showDatePicker(context: context, initialDate: now, firstDate: now.subtract(const Duration(days: 7)), lastDate: now.add(const Duration(days: 1)), builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: primaryColor), dialogBackgroundColor: const Color(0xFF1E293B)), child: child!));
    if (pickedDate == null) return;
    final TimeOfDay? pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now), builder: (context, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: primaryColor), dialogBackgroundColor: const Color(0xFF1E293B)), child: child!));
    if (pickedTime == null) return;
    final DateTime finalDateTime = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
    if (isFeeding) { ref.read(fastingProvider.notifier).confirmFeedingEnd(finalDateTime); } else { if (fastingState.isActive) { ref.read(fastingProvider.notifier).confirmManualFastingEnd(finalDateTime); } else { ref.read(fastingProvider.notifier).startFastingManual(finalDateTime); } }
  }

  Widget _buildMetabolicAlertBanner(String message) {
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent.withValues(alpha: 0.2))), child: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16), const SizedBox(width: 10), Expanded(child: Text(message, style: const TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)))]));
  }

  // SPEC-72.2: _buildEngagementBanner eliminado. Reemplazado por
  // EngagementBanner widget en features/engagement/presentation/widgets/
  // que añade dismiss por sesión.

  Widget _buildBottomNav(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith('/analysis')) currentIndex = 1;
    if (location.startsWith('/profile')) currentIndex = 2;
    return BottomNavigationBar(backgroundColor: const Color(0xFF0F172A), selectedItemColor: AppColors.metabolicGreen, unselectedItemColor: Colors.grey.withValues(alpha: 0.5), currentIndex: currentIndex, type: BottomNavigationBarType.fixed, onTap: (index) { if (index == 0) context.go('/dashboard'); if (index == 1) context.go('/analysis'); if (index == 2) context.go('/profile'); }, items: const [BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Dashboard"), BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: "Análisis"), BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil")]);
  }
}