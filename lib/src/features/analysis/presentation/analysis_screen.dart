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
import 'widgets/imr_breakdown_card.dart';
import 'widgets/pillar_summary_row.dart';

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

            // Ejercicio y Nutrición: hardcoded hasta SPEC-03/04
            const double exerciseMin = 45.0;

            final DateTime lastMealTime =
                fastingState.startTime ??
                user.profile.lastMealGoal ??
                _now;

            // ── Cálculo IMR con datos reales del día ────────────────────
            final IMRv2Result result = engine.calculateIMR(
              user,
              fastingHours: fastingHours,
              weeklyAdherence: 0.85, // hardcoded hasta SPEC-07
              exerciseMin: exerciseMin,
              sleepHours: sleepHours > 0 ? sleepHours : 7.0,
              lastMealTime: lastMealTime,
            );

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
                  IMRBreakdownCard(result: result),
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

                  // Pilar Ejercicio (SPEC-03 pendiente)
                  PillarSummaryRow(
                    icon: Icons.fitness_center_rounded,
                    pillarName: 'Ejercicio',
                    value: '${exerciseMin.toInt()} min',
                    imrContribution: '+6 pts',
                    progress: (exerciseMin / 60.0).clamp(0.0, 1.0),
                    color: const Color(0xFF2DD4BF),
                    isHardcoded: true,
                  ),
                  const SizedBox(height: 10),

                  // Pilar Nutrición (SPEC-04 pendiente)
                  PillarSummaryRow(
                    icon: Icons.restaurant_menu_rounded,
                    pillarName: 'Nutrición',
                    value: lastMealTime.hour < 18 ? 'eTRF ✓' : 'Sin bono',
                    imrContribution: lastMealTime.hour < 18 ? '+bono eTRF' : '–',
                    progress: lastMealTime.hour < 18 ? 1.0 : 0.5,
                    color: const Color(0xFFFB923C),
                    isHardcoded: true,
                  ),
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
            color: const Color(0xFF1E293B),
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
}
