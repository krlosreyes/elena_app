import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/core/rules/circadian_rules.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/engagement/application/engagement_service.dart';
import 'widgets/imr_breakdown_card.dart';
import 'widgets/pillar_summary_row.dart';
import 'widgets/trend_chart.dart';
import 'widgets/insight_card.dart';
import 'widgets/weekly_report_card.dart';
import 'providers/analysis_providers.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Actualiza el tiempo hasta el bloqueo cada segundo (CA-01-05)
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final fastingState = ref.watch(fastingProvider);
    final sleepState = ref.watch(sleepProvider);
    final hydrationState = ref.watch(hydrationProvider);
    final exerciseState = ref.watch(exerciseProvider);    // SPEC-03
    final nutritionState = ref.watch(nutritionProvider);  // SPEC-04
    final streakState = ref.watch(streakProvider);         // SPEC-06
    final engine = ref.watch(scoreEngineProvider);

    return Scaffold(
      body: SafeArea(
        child: userAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (err, _) =>
              Center(child: Text('Error al cargar datos: $err')),
          data: (user) {
            if (user == null) {
              return const Center(child: CircularProgressIndicator());
            }

            // ── Datos reales de cada pilar ──────────────────────────────
            final double fastingHours = fastingState.isActive
                ? fastingState.duration.inSeconds / 3600.0
                : 0.0;

            final double sleepHours =
                sleepState.lastLog?.duration.inHours.toDouble() ?? 0.0;

            final double hydrationLiters = hydrationState.currentAmountLiters;

            // Minutos de ejercicio reales desde ExerciseNotifier (SPEC-03)
            final double exerciseMin = exerciseState.todayMinutes.toDouble();

            final DateTime lastMealTime =
                fastingState.startTime ??
                user.profile.lastMealGoal ??
                _now;

            // ── Cálculo IMR con datos reales del día ────────────────────
            final IMRv2Result result = engine.calculateIMR(
              user,
              fastingHours: fastingHours,
              weeklyAdherence: streakState.weeklyAdherence, // SPEC-06: real desde StreakEngine
              exerciseMin: exerciseMin,
              sleepHours: sleepHours > 0 ? sleepHours : 7.0,
              lastMealTime: lastMealTime,
              nutritionScore: nutritionState.nutritionScore, // SPEC-04
            );

            // SPEC-06: Registrar IMR del día en el historial de racha
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ref.read(streakProvider.notifier).updateTodayImr(result.totalScore);
            });

            // ── Circadiano en tiempo real (CA-01-05) ────────────────────
            final Duration timeUntilLock =
                CircadianRules.timeUntilLock(_now);
            final String circadianPhase =
                CircadianRules.getPhaseName(_now);
            final bool lockActive =
                CircadianRules.isIntestinalLockActive(_now);

            final String lockLabel = lockActive
                ? 'Bloqueo intestinal activo'
                : _formatDuration(timeUntilLock);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Header ───────────────────────────────────────────
                  _buildHeader(context),
                  const SizedBox(height: 20),

                  // ── IMR Score Card ───────────────────────────────────
                  _buildIMRScoreCard(result),
                  const SizedBox(height: 16),

                  // ── Desglose de bloques ──────────────────────────────
                  IMRBreakdownCard(
                    result: result,
                    isHardcoded: user.isMeasurementEstimated,
                  ),
                  const SizedBox(height: 24),

                  // ── Sección pilares ──────────────────────────────────
                  _buildSectionLabel('ESTADO DE PILARES HOY'),
                  const SizedBox(height: 12),

                  // Pilar Ayuno
                  PillarSummaryRow(
                    icon: Icons.timelapse_rounded,
                    pillarName: 'Ayuno',
                    value: fastingState.isActive
                        ? '${fastingHours.toStringAsFixed(1)}h'
                        : 'Inactivo',
                    imrContribution: fastingState.isActive
                        ? '${(result.metabolicScore * 25).toStringAsFixed(0)} pts'
                        : '0 pts',
                    progress: fastingState.progressPercentage,
                    color: const Color(0xFF10B981),
                  ),
                  const SizedBox(height: 10),

                  // Pilar Sueño
                  PillarSummaryRow(
                    icon: Icons.nightlight_round,
                    pillarName: 'Sueño',
                    value: sleepHours > 0
                        ? '${sleepState.lastLog!.duration.inHours}h '
                          '${sleepState.lastLog!.duration.inMinutes.remainder(60)}m'
                        : 'Sin registro',
                    imrContribution: sleepHours >= 7
                        ? '+8 pts'
                        : (sleepHours > 0 ? '+4 pts' : '0 pts'),
                    progress: (sleepHours / 9.0).clamp(0.0, 1.0),
                    color: const Color(0xFF818CF8),
                  ),
                  const SizedBox(height: 10),

                  // Pilar Hidratación
                  PillarSummaryRow(
                    icon: Icons.water_drop_rounded,
                    pillarName: 'Hidratación',
                    value: '${hydrationState.currentFormatted}L',
                    imrContribution:
                        hydrationState.isGoalReached ? '+5 pts' : 'En progreso',
                    progress: hydrationState.progressPercentage,
                    color: const Color(0xFF38BDF8),
                  ),
                  const SizedBox(height: 10),

                  // Pilar Ejercicio — datos reales de ExerciseNotifier (SPEC-03)
                  PillarSummaryRow(
                    icon: Icons.fitness_center_rounded,
                    pillarName: 'Ejercicio',
                    value: exerciseMin > 0
                        ? '${exerciseMin.toInt()} min'
                        : 'Sin registro',
                    imrContribution: exerciseMin >= 30
                        ? '+${(exerciseMin / 60 * 6.25).toStringAsFixed(0)} pts'
                        : '0 pts',
                    progress: (exerciseMin / 60.0).clamp(0.0, 1.0),
                    color: const Color(0xFF2DD4BF),
                  ),
                  const SizedBox(height: 10),

                  // Pilar Nutrición — datos reales de NutritionNotifier (SPEC-04)
                  PillarSummaryRow(
                    icon: Icons.restaurant_menu_rounded,
                    pillarName: 'Nutrición',
                    value: nutritionState.mealsLoggedToday > 0
                        ? '${nutritionState.mealsLoggedToday}/${nutritionState.targetMeals} comidas'
                        : 'Sin registro',
                    imrContribution: nutritionState.nutritionScore > 0
                        ? '+${(nutritionState.nutritionScore * 3.75).toStringAsFixed(1)} pts'
                        : '0 pts',
                    progress: nutritionState.progressPercentage,
                    color: const Color(0xFFFB923C),
                  ),
                  const SizedBox(height: 24),

                  // ── Racha Metabólica ─────────────────────────────────
                  _buildSectionLabel('RACHA METABÓLICA'),
                  const SizedBox(height: 12),
                  _buildStreakCard(streakState),
                  const SizedBox(height: 24),

                  // ── Ritmo Circadiano ─────────────────────────────────
                  _buildSectionLabel('RITMO CIRCADIANO'),
                  const SizedBox(height: 12),
                  _buildCircadianCard(
                    circadianPhase: circadianPhase,
                    lockLabel: lockLabel,
                    lockActive: lockActive,
                    circadianAlignment: result.circadianAlignment,
                  ),
                  const SizedBox(height: 30),

                  // ── Deep Analysis (SPEC-09) ──────────────────────────
                  _buildSectionLabel('ANÁLISIS PROFUNDO'),
                  const SizedBox(height: 12),
                  _buildDeepAnalysisSection(ref, streakState),
                  const SizedBox(height: 40),
                ],
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  // ── Widgets Privados ────────────────────────────────────────────────────

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ANÁLISIS',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
              ),
            ),
            Text(
              'Resumen del día de hoy',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.4),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.surfaceDark,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDate(_now),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.55),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIMRScoreCard(IMRv2Result result) {
    final zoneColor = _zoneColor(result.zone);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: zoneColor.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        children: [
          // Score circular
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: zoneColor, width: 3),
            ),
            child: Center(
              child: Text(
                '${result.totalScore}',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: zoneColor,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.zone,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: zoneColor,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  result.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.55),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircadianCard({
    required String circadianPhase,
    required String lockLabel,
    required bool lockActive,
    required double circadianAlignment,
  }) {
    final alignPct = (circadianAlignment * 100).toStringAsFixed(0);
    final lockColor =
        lockActive ? Colors.redAccent : const Color(0xFF10B981);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _circadianStat(
                icon: Icons.wb_twilight_rounded,
                label: 'FASE ACTUAL',
                value: circadianPhase,
                color: const Color(0xFFEAB308),
              ),
              _circadianStat(
                icon: Icons.lock_clock_rounded,
                label: 'BLOQUEO INTESTINAL',
                value: lockLabel,
                color: lockColor,
              ),
              _circadianStat(
                icon: Icons.align_vertical_center_rounded,
                label: 'ALINEACIÓN',
                value: '$alignPct%',
                color: const Color(0xFF818CF8),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circadianStat({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w900,
            color: Colors.white.withOpacity(0.35),
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white.withOpacity(0.3),
          fontSize: 10,
          letterSpacing: 1.5,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStreakCard(StreakState streak) {
    final bool todayDone = streak.todayCompleted;
    final Color flameColor = todayDone
        ? const Color(0xFFFB923C)
        : Colors.white.withOpacity(0.2);

    final entry = streak.todayEntry;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: todayDone
              ? const Color(0xFFFB923C).withOpacity(0.35)
              : Colors.white.withOpacity(0.06),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Encabezado: racha actual y récord ──────────────────────────
          Row(
            children: [
              Icon(Icons.local_fire_department_rounded,
                  color: flameColor, size: 28),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${streak.currentStreak} ${streak.currentStreak == 1 ? 'día' : 'días'} consecutivos',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: flameColor,
                    ),
                  ),
                  Text(
                    'Récord: ${streak.longestStreak} días',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              // Adherencia semanal
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${(streak.weeklyAdherence * 100).round()}%',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF10B981),
                    ),
                  ),
                  Text(
                    '7 días',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Consumer(
                    builder: (context, ref, child) {
                      final engagement = ref.watch(engagementProvider);
                      return Text(
                        engagement.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.w900,
                          color: _engagementColor(engagement.level),
                          letterSpacing: 0.5,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Progreso de pilares de hoy ──────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _pillarIcon(Icons.nightlight_round, 'Ayuno', entry?.fastingCompleted ?? false),
              _pillarIcon(Icons.bedtime_rounded, 'Sueño', entry?.sleepCompleted ?? false),
              _pillarIcon(Icons.water_drop_rounded, 'Hidrat.', entry?.hydrationCompleted ?? false),
              _pillarIcon(Icons.fitness_center_rounded, 'Ejerc.', entry?.exerciseLogged ?? false),
              _pillarIcon(Icons.restaurant_rounded, 'Nutrición', entry?.nutritionLogged ?? false),
            ],
          ),
          const SizedBox(height: 12),

          // ── Texto de estado ─────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(
                  todayDone
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 14,
                  color: todayDone
                      ? const Color(0xFF10B981)
                      : Colors.white.withOpacity(0.3),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    todayDone
                        ? '✓ Hoy cuenta para tu racha (${streak.pillarsToday}/5 pilares)'
                        : 'Necesitas ${3 - streak.pillarsToday} pilar${3 - streak.pillarsToday == 1 ? "" : "es"} más para mantener la racha',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: todayDone
                          ? const Color(0xFF10B981)
                          : Colors.white.withOpacity(0.45),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillarIcon(IconData icon, String label, bool completed) {
    return Column(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: completed
                ? const Color(0xFF10B981).withOpacity(0.15)
                : const Color(0xFF0F172A),
            border: Border.all(
              color: completed
                  ? const Color(0xFF10B981)
                  : Colors.white.withOpacity(0.1),
              width: 1.5,
            ),
          ),
          child: Center(
            child: Icon(
              icon, 
              size: 18, 
              color: completed ? const Color(0xFF10B981) : Colors.white.withOpacity(0.2)
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w700,
            color: completed
                ? const Color(0xFF10B981)
                : Colors.white.withOpacity(0.25),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: const Color(0xFF0F172A),
      selectedItemColor: AppColors.metabolicGreen,
      unselectedItemColor: Colors.grey.withOpacity(0.5),
      currentIndex: 1, // Analysis es índice 1
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 0) context.go('/dashboard');
        if (index == 1) context.go('/analysis');
        if (index == 2) context.go('/profile');
      },
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.grid_view_rounded),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.insights_rounded),
          label: 'Análisis',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Perfil',
        ),
      ],
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────

  Widget _buildEducationalPlaceholder(int historyCount) {
    final int daysRemaining = (7 - historyCount).clamp(1, 7);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.biotech_rounded,
              color: Color(0xFF10B981),
              size: 32,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'INTELIGENCIA METABÓLICA',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: Color(0xFF10B981),
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Estamos analizando tu sensibilidad a la insulina y flexibilidad metabólica.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.9),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Completa $daysRemaining ${daysRemaining == 1 ? 'día más' : 'días más'} para desbloquear tu perfil de oxidación de grasas y el análisis de correlaciones.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.5),
              height: 1.5,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 24),
          // Indicador de progreso sutil
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progreso del Análisis',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$historyCount de 7 días',
                    style: TextStyle(
                      fontSize: 10,
                      color: Colors.white.withOpacity(0.3),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (historyCount / 7).clamp(0.0, 1.0),
                  backgroundColor: Colors.white.withOpacity(0.05),
                  valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                  minHeight: 6,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDeepAnalysisSection(WidgetRef ref, StreakState streak) {
    final analysisAsync = ref.watch(analysisResultProvider);

    return analysisAsync.when(
      loading: () => const Center(child: Padding(
        padding: EdgeInsets.all(20.0),
        child: CircularProgressIndicator(),
      )),
      error: (err, _) => Center(child: Text('Error en análisis: $err')),
      data: (cache) {
        if (cache == null) {
          final historyCount = streak.history.length;
          return _buildEducationalPlaceholder(historyCount);
        }

        final imrHistory = streak.history.take(7).map((e) => e.imrScore.toDouble()).toList().reversed.toList();

        return Column(
          children: [
            // Gráfica de tendencia (RF-09-01)
            TrendChart(
              data: imrHistory,
              label: 'Tendencia IMR (Últimos 7 días)',
              color: const Color(0xFF10B981),
            ),
            const SizedBox(height: 24),

            // Reporte Semanal (RF-09-05)
            _buildSectionLabel('REPORTE SEMANAL DE METAMORFOSIS'),
            const SizedBox(height: 12),
            WeeklyReportCard(
              current: cache.currentWeek,
              previous: cache.previousWeek,
            ),
            const SizedBox(height: 24),

            // Insights de Correlación (RF-09-02)
            _buildSectionLabel('DESCUBRIMIENTOS Y CORRELACIONES'),
            const SizedBox(height: 12),
            ...cache.correlations.map((c) => InsightCard(correlation: c)),
          ],
        );
      },
    );
  }

  Color _zoneColor(String zone) {
    switch (zone) {
      case 'OPTIMIZADO':
        return const Color(0xFF10B981);
      case 'EFICIENTE':
        return const Color(0xFF22BB33);
      case 'FUNCIONAL':
        return const Color(0xFFFFD700);
      case 'INESTABLE':
        return const Color(0xFFFF8C00);
      default:
        return const Color(0xFFFF4444);
    }
  }

  String _formatDuration(Duration d) {
    if (d.isNegative) return 'Pasado';
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  String _formatDate(DateTime dt) {
    const months = [
      'ENE', 'FEB', 'MAR', 'ABR', 'MAY', 'JUN',
      'JUL', 'AGO', 'SEP', 'OCT', 'NOV', 'DIC'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Color _engagementColor(EngagementLevel level) {
    switch (level) {
      case EngagementLevel.excelente:
        return const Color(0xFF10B981);
      case EngagementLevel.bueno:
        return const Color(0xFF34D399);
      case EngagementLevel.regular:
        return const Color(0xFFFBBF24);
      case EngagementLevel.critico:
        return const Color(0xFFF87171);
      case EngagementLevel.neutro:
        return Colors.grey;
    }
  }
}
