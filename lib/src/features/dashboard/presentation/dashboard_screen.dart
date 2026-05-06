import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart'; 
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/engine/metabolic_state_provider.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/core/widgets/elena_header.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/circadian_clock.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_state.dart';
import 'package:elena_app/src/features/exercise/presentation/exercise_input_sheet.dart';
import 'package:elena_app/src/features/engagement/presentation/widgets/engagement_banner.dart';
import 'package:elena_app/src/features/adaptive/presentation/widgets/adaptive_suggestion_card.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/nutrition/presentation/add_past_meal_sheet.dart';
import 'package:elena_app/src/features/dashboard/presentation/sleep_input_sheet.dart';
// SPEC-12: Composición Corporal Visible
import 'package:elena_app/src/features/profile/presentation/widgets/body_composition_card.dart';
// SPEC-14: Objetivos del Usuario
import 'package:elena_app/src/features/goals/presentation/widgets/goals_dashboard_widget.dart';
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
                              score: result.totalScore.toDouble(),
                              zone: result.zone,
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

                  // 3 indicadores horizontales: FASE / BLOQUEO INTESTINAL / ALINEACIÓN
                  _buildPhaseIndicators(
                    fastingState: fastingState,
                    alignmentPct: (result.circadianAlignment * 100).round(),
                  ),
                  const SizedBox(height: 20),

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

                  // SPEC-12: Composición corporal (conservada)
                  const BodyCompositionCard(),
                  const SizedBox(height: 20),

                  // SPEC-14: Objetivos del Usuario (conservado)
                  const GoalsDashboardWidget(),
                  const SizedBox(height: 16),

                  // SPEC-15: Road Map (conservado)
                  _buildProgressCTA(context),
                  const SizedBox(height: 30),
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

  /// Tarjeta horizontal con 3 indicadores: FASE / BLOQUEO / ALINEACIÓN.
  /// Datos derivados de `fastingState` (que ya incluye circadianPhase
  /// y timeUntilLock vía CircadianRules) y `result.circadianAlignment`.
  Widget _buildPhaseIndicators({
    required FastingState fastingState,
    required int alignmentPct,
  }) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final lock = fastingState.timeUntilLock;
    final lockText = lock <= Duration.zero
        ? 'Activo'
        : '${lock.inHours}h ${twoDigits(lock.inMinutes.remainder(60))}m';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _phaseIndicatorTile(
            icon: Icons.wb_sunny_rounded,
            iconColor: const Color(0xFFFBBF24),
            label: 'FASE ACTUAL',
            value: fastingState.circadianPhase.toUpperCase(),
            valueColor: const Color(0xFFFBBF24),
          ),
          _phaseIndicatorTile(
            icon: Icons.lock_clock_rounded,
            iconColor: AppColors.metabolicGreen,
            label: 'BLOQUEO INTESTINAL',
            value: lockText,
            valueColor: AppColors.metabolicGreen,
          ),
          _phaseIndicatorTile(
            icon: Icons.tune_rounded,
            iconColor: const Color(0xFF8B5CF6),
            label: 'ALINEACIÓN',
            value: '$alignmentPct%',
            valueColor: const Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }

  Widget _phaseIndicatorTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: iconColor, size: 22),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            color: Colors.white.withValues(alpha: 0.5),
            fontWeight: FontWeight.w900,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: valueColor,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

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
              _pillarRing(
                icon: Icons.timer_rounded,
                color: AppColors.metabolicGreen,
                progress: fastingState.progressPercentage,
                label: 'Ayuno',
                isSelected: _selectedPillar == SelectedPillar.ayuno,
                completed: fastingState.progressPercentage >= 1.0,
                onTap: () => setState(() => _selectedPillar = SelectedPillar.ayuno),
              ),
              _pillarRing(
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
              _pillarRing(
                icon: Icons.water_drop_rounded,
                color: Colors.blueAccent,
                progress: hydration.progressPercentage,
                label: 'Hidratación',
                isSelected: _selectedPillar == SelectedPillar.hidratacion,
                completed: hydration.isGoalReached,
                onTap: () =>
                    setState(() => _selectedPillar = SelectedPillar.hidratacion),
              ),
              _pillarRing(
                icon: Icons.fitness_center_rounded,
                color: Colors.tealAccent,
                progress: (exercise.todayMinutes / 60.0).clamp(0.0, 1.0),
                label: 'Ejercicio',
                isSelected: _selectedPillar == SelectedPillar.ejercicio,
                completed: exercise.todayMinutes >= 30,
                onTap: () =>
                    setState(() => _selectedPillar = SelectedPillar.ejercicio),
              ),
              _pillarRing(
                icon: Icons.restaurant_rounded,
                color: Colors.orangeAccent,
                progress: nutrition.progressPercentage,
                label: 'Comidas',
                isSelected: _selectedPillar == SelectedPillar.comidas,
                completed:
                    nutrition.mealsLoggedToday >= nutrition.targetMeals,
                onTap: () =>
                    setState(() => _selectedPillar = SelectedPillar.comidas),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pillarRing({
    required IconData icon,
    required Color color,
    required double progress,
    required String label,
    required VoidCallback onTap,
    bool isSelected = false,
    bool completed = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isSelected)
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: color.withValues(alpha: 0.45),
                          blurRadius: 18,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                SizedBox(
                  width: 56,
                  height: 56,
                  child: CircularProgressIndicator(
                    value: progress.clamp(0.0, 1.0),
                    strokeWidth: 3,
                    backgroundColor: color.withValues(alpha: 0.15),
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
                Icon(icon, color: color, size: 22),
                if (completed)
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 16,
                      height: 16,
                      decoration: const BoxDecoration(
                        color: AppColors.metabolicGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isSelected
                  ? color
                  : Colors.white.withValues(alpha: 0.6),
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

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
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final isActive = state.isActive;
    final accent = isActive ? AppColors.metabolicGreen : AppColors.metabolicGreen;
    final pct = (state.progressPercentage.clamp(0.0, 1.0) * 100).round();

    final timerText = isActive
        ? '${twoDigits(state.duration.inHours)}:'
            '${twoDigits(state.duration.inMinutes.remainder(60))}:'
            '${twoDigits(state.duration.inSeconds.remainder(60))}'
        : '— — : — — : — —';

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
          // Display de tiempo + protocolo
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                timerText,
                style: TextStyle(
                  color: accent,
                  fontFamily: 'monospace',
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  state.fastingProtocol,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
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
          // Botón principal: iniciar / finalizar
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              onPressed: state.isSaving
                  ? null
                  : () {
                      if (isActive) {
                        _showManualTimePicker(context, ref, isFeeding: false);
                      } else {
                        ref.read(fastingProvider.notifier).startFasting();
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? Colors.redAccent : accent,
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
                          : Icons.play_circle_outline,
                      color: Colors.white,
                      size: 22,
                    ),
              label: Text(
                isActive ? 'Finalizar Ayuno' : 'Iniciar Ayuno',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Botón secundario: corregir hora
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton.icon(
              onPressed: state.isSaving
                  ? null
                  : () => _showManualTimePicker(context, ref, isFeeding: false),
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
                'Corregir hora de inicio',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
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
      SelectedPillar.comidas => _buildComidasCard(context, ref, nutrition),
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
        _primaryButton(
          label: 'Actualizar Registro',
          icon: Icons.nightlight_round,
          color: accent,
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const SleepInputSheet(),
          ),
        ),
        const SizedBox(height: 10),
        _secondaryButton(
          label: 'Eliminar registro y volver a registrar',
          icon: Icons.delete_outline_rounded,
          onPressed: () => _showPendingFeatureSnack(
            context,
            'Eliminar registro de sueño',
          ),
        ),
      ],
    );
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
  Widget _buildComidasCard(
      BuildContext context, WidgetRef ref, NutritionState state) {
    const accent = Color(0xFFFB923C);
    final progress = state.progressPercentage;
    final pct = (progress * 100).round();
    final scoreNum = (state.nutritionScore.clamp(0.0, 1.0) * 100).round();

    return _pillarCardShell(
      title: 'Nutrición Científica',
      badge: '${state.mealsLoggedToday}/${state.targetMeals} comidas',
      accent: accent,
      children: [
        _progressBar(progress, accent),
        const SizedBox(height: 6),
        _completionLabel(pct),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _miniStat('Próxima', state.nextMealLabel, accent, big: true),
            _miniStat('En', _estimateNextMealIn(state), accent, big: true),
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
          onPressed: state.isSaving
              ? null
              : () =>
                  ref.read(nutritionProvider.notifier).logMeal(),
        ),
        const SizedBox(height: 10),
        _secondaryButton(
          label: 'Registrar comida pasada',
          icon: Icons.history_rounded,
          onPressed: () => showModalBottomSheet<void>(
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
          onPressed: state.todayLogs.isEmpty
              ? null
              : () => ref.read(nutritionProvider.notifier).removeLastMeal(),
        ),
      ],
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

  // ───────────────────────────────────────────────────────────────────────
  //  Componentes conservados del rediseño anterior
  // ───────────────────────────────────────────────────────────────────────

  // SPEC-15: Botón de acceso al Road Map de Avance Personal
  Widget _buildProgressCTA(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/progress'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF1ABC9C).withOpacity(0.2),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Text('📈', style: TextStyle(fontSize: 18)),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ver mi Road Map',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'Evolución IMR · Composición · Objetivos',
                    style: TextStyle(
                      fontSize: 10,
                      color: Color(0xFF1ABC9C),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFF1ABC9C).withOpacity(0.6),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

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
      decoration: BoxDecoration(color: const Color(0xFF0F172A).withOpacity(0.98), borderRadius: BorderRadius.circular(30), border: Border.all(color: iconColor, width: 2), boxShadow: [BoxShadow(color: iconColor.withOpacity(0.2), blurRadius: 15)]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        const SizedBox(height: 8),
        Text(subtitle, textAlign: TextAlign.center, style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.7))),
        const SizedBox(height: 16),
        SizedBox(width: double.infinity, height: 42, child: ElevatedButton(onPressed: isSaving ? null : onConfirm, style: ElevatedButton.styleFrom(backgroundColor: iconColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: isSaving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text(buttonLabel, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12)))),
      ]),
    );
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
    return Container(width: double.infinity, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.redAccent.withOpacity(0.2))), child: Row(children: [const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 16), const SizedBox(width: 10), Expanded(child: Text(message, style: const TextStyle(color: Colors.redAccent, fontSize: 9, fontWeight: FontWeight.bold)))]));
  }

  // SPEC-72.2: _buildEngagementBanner eliminado. Reemplazado por
  // EngagementBanner widget en features/engagement/presentation/widgets/
  // que añade dismiss por sesión.

  Widget _buildBottomNav(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith('/analysis')) currentIndex = 1;
    if (location.startsWith('/profile')) currentIndex = 2;
    return BottomNavigationBar(backgroundColor: const Color(0xFF0F172A), selectedItemColor: AppColors.metabolicGreen, unselectedItemColor: Colors.grey.withOpacity(0.5), currentIndex: currentIndex, type: BottomNavigationBarType.fixed, onTap: (index) { if (index == 0) context.go('/dashboard'); if (index == 1) context.go('/analysis'); if (index == 2) context.go('/profile'); }, items: const [BottomNavigationBarItem(icon: Icon(Icons.grid_view_rounded), label: "Dashboard"), BottomNavigationBarItem(icon: Icon(Icons.insights_rounded), label: "Análisis"), BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil")]);
  }
}