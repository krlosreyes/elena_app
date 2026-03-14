import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../authentication/application/auth_controller.dart';
import '../../profile/application/user_controller.dart';
import '../../profile/domain/user_model.dart';
import '../../onboarding/logic/elena_brain.dart';
import 'widgets/fasting_card.dart';
import 'widgets/dashboard_header.dart';
import 'widgets/dashboard_action_card.dart';
import '../../../shared/presentation/widgets/responsive_centered_view.dart';
import '../../progress/presentation/widgets/week_calendar.dart';
import '../../imx/presentation/widgets/imx_telemetry_board.dart';
import '../../imx/application/imx_providers.dart';
import '../../imx/domain/imx_engine.dart';
import '../../fasting/presentation/fasting_controller.dart';
import 'widgets/mission_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Obtener Usuario
    final userAsync = ref.watch(currentUserStreamProvider);
    final imxAsync = ref.watch(currentImxResultProvider);
    
    return userAsync.when(
      data: (user) {
        if (user == null) {
          return const Center(child: Text('Perfil no encontrado.'));
        }
        
        return Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: ResponsiveCenteredView(
              maxWidth: 600,
              child: SingleChildScrollView(
                key: ValueKey('dashboard-${user.uid}'),
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DashboardHeader(),
                    const SizedBox(height: 16),
                    WeekCalendar(
                      checkInDay: user.checkInDay ?? 1,
                      onCheckInTap: () {},
                    ),
                    const SizedBox(height: 16),
                    const ImxTelemetryBoard(),
                    const SizedBox(height: 24),
                    imxAsync.when(
                      data: (imx) => _MissionView(imx: imx, user: user),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, st) => const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, st) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            'Error al sincronizar perfil: $e',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.redAccent),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MISSION VIEW (ISOLATED FOR STABILITY)
// ─────────────────────────────────────────────────────────────────────────────

class _MissionView extends ConsumerWidget {
  final ImxResult imx;
  final UserModel user;

  const _MissionView({required this.imx, required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Isolate 1Hz State: Only rebuilds when isFasting changes
    final isFasting = ref.watch(fastingControllerProvider.select((s) => s.value?.isFasting ?? false));

    // 2. Misión Estructura logic
    final waist = user.waistCircumferenceCm;
    final height = user.heightCm;
    final targetWaist = (height * 0.5).round();
    final waistProgress = waist > 0 ? (targetWaist / waist).clamp(0.0, 1.0) : 0.0;
    
    final bodyFat = imx.bodyFat;
    const targetFat = 15.0;
    final fatProgress = bodyFat > 0 ? (targetFat / bodyFat).clamp(0.0, 1.0) : 0.0;

    final isStructureUrgent = imx.scoreStructure < 50;

    final structureContent = Column(
      children: [
        _buildProgressRow(
          label: 'Cintura',
          current: '${waist.toInt()}cm',
          target: '${targetWaist}cm',
          progress: waistProgress,
          color: const Color(0xFF00BCD4),
        ),
        const SizedBox(height: 12),
        _buildProgressRow(
          label: 'Grasa Corporal',
          current: '${bodyFat.toStringAsFixed(1)}%',
          target: '15%',
          progress: fatProgress,
          color: const Color(0xFF00BCD4),
        ),
      ],
    );

    // 3. Misión Hábitos logic
    final isHabitsDone = (user.averageSleepHours ?? 0) > 0;
    final habitScore = imx.scoreBehavior.toInt();
    String habitSubtitle = isHabitsDone ? 'DESCANSO REGISTRADO' : 'CONSISTENCIA Y DESCANSO';
    if (habitScore == 100) {
      habitSubtitle = 'ESTATUS: SISTEMA EN RECUPERACIÓN';
    }

    final missions = [
      _MissionData(
        id: 'metabolic',
        score: imx.scoreMetabolic,
        title: 'Misión Metabólica',
        subtitle: isFasting ? 'QUEMA DE GRASA ACTIVA' : 'FLEXIBILIDAD Y AUTOFAGIA',
        icon: Icons.bolt,
        accentColor: const Color(0xFF4CAF50),
        state: isFasting ? MissionState.active : MissionState.pending,
        action: const _FastingActionButton(),
      ),
      _MissionData(
        id: 'structure',
        score: imx.scoreStructure,
        title: 'Misión Estructura',
        subtitle: 'COMPOSICIÓN Y SALUD VISCERAL',
        icon: Icons.fitness_center,
        accentColor: const Color(0xFF00BCD4),
        content: structureContent,
        action: _buildStructureAction(context, isStructureUrgent),
      ),
      _MissionData(
        id: 'habits',
        score: imx.scoreBehavior,
        title: 'Misión Hábitos',
        subtitle: habitSubtitle,
        icon: Icons.nights_stay_outlined,
        accentColor: const Color(0xFFCE93D8),
        state: isHabitsDone ? MissionState.success : MissionState.pending,
        action: _buildHabitsAction(context, habitScore == 100),
      ),
    ];

    missions.sort((a, b) {
      int cmp = a.score.compareTo(b.score);
      if (cmp != 0) return cmp;
      return a.id.compareTo(b.id);
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TU PRÓXIMO PASO CRÍTICO',
          style: GoogleFonts.firaCode(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 16),
        ...missions.map((m) => MissionCard(
              key: ValueKey('mission-${m.id}'),
              title: m.title,
              subtitle: m.subtitle,
              icon: m.icon,
              accentColor: m.accentColor,
              score: m.score.toInt().toString(),
              state: m.state,
              content: m.content,
              bottomAction: m.action,
              onTap: m.id == 'metabolic' ? () => context.push('/fasting') : null,
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ATOMIC COMPONENTS (NO-REBUILD LEAVES)
// ─────────────────────────────────────────────────────────────────────────────

class _FastingActionButton extends ConsumerWidget {
  const _FastingActionButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Only this small button rebuilds at 1Hz
    final fastStateAsync = ref.watch(fastingControllerProvider);
    
    return fastStateAsync.maybeWhen(
      data: (fastState) {
        final isActive = fastState.isFasting;
        String text = '🚀 INICIAR AYUNO';
        if (isActive) {
          final elapsed = fastState.elapsed;
          text = '🔥 AYUNANDO: ${elapsed.inHours}h ${elapsed.inMinutes.remainder(60)}m (Ver Etapas)';
        }

        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => context.push('/fasting'),
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? Colors.transparent : const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: isActive ? const BorderSide(color: Color(0xFF4CAF50), width: 1.5) : BorderSide.none,
              ),
              elevation: isActive ? 0 : 4,
            ),
            child: Text(
              text,
              style: GoogleFonts.robotoMono(
                fontWeight: FontWeight.w900, 
                letterSpacing: 0.5,
                fontSize: 14,
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );
  }
}

class _MissionData {
  final String id;
  final double score;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final Widget? action;
  final Widget? content;
  final MissionState state;

  _MissionData({
    required this.id,
    required this.score,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.action,
    this.content,
    this.state = MissionState.pending,
  });
}

Widget _buildStructureAction(BuildContext context, bool isUrgent) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton.icon(
      onPressed: () => context.push('/daily-workout'),
      icon: const Icon(Icons.warning_amber_rounded, size: 18),
      label: const Text('REGISTRAR ACTIVIDAD FÍSICA'),
      style: ElevatedButton.styleFrom(
        backgroundColor: isUrgent ? const Color(0xFF00BCD4) : Colors.transparent,
        foregroundColor: isUrgent ? Colors.black : const Color(0xFF00BCD4),
        side: const BorderSide(color: Color(0xFF00BCD4), width: 1.5),
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: isUrgent ? 8 : 0,
        shadowColor: isUrgent ? const Color(0xFF00BCD4).withOpacity(0.4) : null,
      ),
    ),
  );
}

Widget _buildHabitsAction(BuildContext context, bool isPerfect) {
  if (isPerfect) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.visibility_outlined, size: 18),
        label: const Text('REVISAR HÁBITOS'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFCE93D8).withOpacity(0.7),
          side: BorderSide(color: const Color(0xFFCE93D8).withOpacity(0.4)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
  return SizedBox(
    width: double.infinity,
    child: TextButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.check_circle_outline, size: 18),
      label: const Text('REGISTRAR HÁBITOS'),
      style: TextButton.styleFrom(
        foregroundColor: const Color(0xFFCE93D8),
        padding: const EdgeInsets.symmetric(vertical: 14),
      ),
    ),
  );
}

Widget _buildProgressRow({
  required String label,
  required String current,
  required String target,
  required double progress,
  required Color color,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label.toUpperCase(), 
            style: GoogleFonts.firaCode(fontSize: 10, color: Colors.white54, fontWeight: FontWeight.bold)
          ),
          Text(
            '$current / Meta $target', 
            style: GoogleFonts.firaCode(fontSize: 10, color: color, fontWeight: FontWeight.bold)
          ),
        ],
      ),
      const SizedBox(height: 6),
      ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: LinearProgressIndicator(
          value: progress,
          backgroundColor: Colors.black,
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 6,
        ),
      ),
    ],
  );
}
