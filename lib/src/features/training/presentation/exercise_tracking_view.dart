import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/widgets/blueprint_grid.dart';
import 'package:elena_app/src/features/profile/application/user_controller.dart';
import 'package:elena_app/src/features/training/application/training_controller.dart';
import 'package:elena_app/src/features/training/application/training_provider.dart';
import 'package:elena_app/src/features/training/domain/entities/workout_log.dart';
import 'package:elena_app/src/features/training/domain/training_enums.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';

final exerciseJustCompletedProvider = StateProvider<bool>((ref) => false);

class ExerciseTrackingView extends ConsumerStatefulWidget {
  const ExerciseTrackingView({super.key});

  @override
  ConsumerState<ExerciseTrackingView> createState() =>
      _ExerciseTrackingViewState();
}

class _ExerciseTrackingViewState extends ConsumerState<ExerciseTrackingView> {
  Future<void> _submitWorkout(
      TrainingStatusState state, TrainingController controller) async {
    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null) return;

    final durationMinutes = (state.elapsedSeconds / 60).ceil().clamp(1, 180);

    final log = WorkoutLog(
      id: const Uuid().v4(),
      templateId: 'manual_${state.category.name}',
      date: DateTime.now(),
      sessionRirScore: (10 - state.rpe).clamp(0, 10),
      durationMinutes: durationMinutes,
      type: state.category.title,
      completedExercises: [
        {
          'exerciseId': 'manual_mission',
          'name': 'Misión Elena: ${state.category.title}',
          'sets': [
            {'reps': 1, 'intensity': state.rpe}
          ]
        }
      ],
    );

    final isHighIntensity = state.category == ExerciseCategory.strength ||
        state.category == ExerciseCategory.hiit;

    try {
      await ref.read(trainingRepositoryProvider).completeWorkoutSession(
            userId: user.uid,
            log: log,
            isHighIntensity: isHighIntensity,
          );

      ref.read(exerciseJustCompletedProvider.notifier).state = true;

      if (mounted) {
        controller.resetSession();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: AppTheme.primary),
                const SizedBox(width: 12),
                Text('MISIÓN REGISTRADA',
                    style:
                        GoogleFonts.jetBrainsMono(fontWeight: FontWeight.bold)),
              ],
            ),
            backgroundColor: const Color(0xFF0A0A0A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al registrar: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trainingState = ref.watch(trainingControllerProvider);
    final trainingNotifier = ref.read(trainingControllerProvider.notifier);

    return Scaffold(
      backgroundColor: Colors.black,
      body: BlueprintGrid(
        child: SafeArea(
          child: Column(
            children: [
              _buildTopNav(trainingState, trainingNotifier),
              _buildMissionBriefing(trainingState),
              Expanded(
                child: _buildPhaseContent(trainingState, trainingNotifier),
              ),
              if (trainingState.phase == TrainingSessionStep.selection)
                _buildStartAction(trainingNotifier),
              if (trainingState.phase == TrainingSessionStep.active)
                _buildActiveAction(trainingNotifier),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopNav(
      TrainingStatusState state, TrainingController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _HUDIconButton(
            icon: Icons.chevron_left_rounded,
            onPressed: () {
              HapticFeedback.lightImpact();
              if (state.phase == TrainingSessionStep.selection) {
                context.pop();
              } else {
                controller.resetSession();
              }
            },
          ),
          Column(
            children: [
              Text(
                'MISSION COMMAND',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                  color: AppTheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'ENCRYPTED BIOMETRIC LINK [ONLINE]',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 8,
                  color: AppTheme.primary.withValues(alpha: 0.4),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          _HUDIconButton(
            icon: Icons.info_outline_rounded,
            onPressed: () {
              _showMissionProtocol(context);
            },
          ),
        ],
      ),
    );
  }

  void _showMissionProtocol(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0A0A0A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: AppTheme.primary.withValues(alpha: 0.3), width: 1),
        ),
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: AppTheme.primary),
            const SizedBox(width: 12),
            Text(
              'PROTOCOLO DE MISIÓN',
              style: GoogleFonts.outfit(
                color: AppTheme.primary,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProtocolItem(
              title: 'OBJETIVO',
              description:
                  'Máxima activación metabólica mediante estímulo mecánico o de alta intensidad.',
            ),
            const SizedBox(height: 16),
            _ProtocolItem(
              title: 'OPTIMIZACIÓN',
              description:
                  'Si estás en ayuno (>16h), la movilización de ácidos grasos será prioritaria.',
            ),
            const SizedBox(height: 16),
            _ProtocolItem(
              title: 'POST-MISIÓN',
              description:
                  'Registra tu nivel de esfuerzo (RPE) para ajustar la prescripción alimentaria.',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ENTENDIDO',
              style: GoogleFonts.outfit(
                color: AppTheme.primary,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissionBriefing(TrainingStatusState state) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            'OBJETIVO: AGOTAMIENTO DE ${state.category.objective}',
            style: GoogleFonts.robotoMono(
              fontSize: 14,
              color: state.category.color,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            height: 1,
            width: 150,
            color: state.category.color.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildPhaseContent(
      TrainingStatusState state, TrainingController controller) {
    switch (state.phase) {
      case TrainingSessionStep.selection:
        return _buildSelectionHUD(state, controller);
      case TrainingSessionStep.active:
        return _buildActiveHUD(state);
      case TrainingSessionStep.summary:
        return _buildSummaryHUD(state, controller);
    }
  }

  Widget _buildSelectionHUD(
      TrainingStatusState state, TrainingController controller) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ExerciseCategory.values.map((cat) {
            final isSelected = state.category == cat;
            return GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                controller.selectCategory(cat);
              },
              child: _NeonCircleButton(
                category: cat,
                isSelected: isSelected,
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 48),
        Text(
          'SELECCIONA PROTOCOLO DE CARGA',
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            color: Colors.white30,
            letterSpacing: 2,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveHUD(TrainingStatusState state) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'MISIÓN EN CURSO',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: AppTheme.primary.withValues(alpha: 0.5),
              letterSpacing: 4,
            ),
          ),
          const SizedBox(height: 32),
          Text(
            _formatDuration(Duration(seconds: state.elapsedSeconds)),
            style: GoogleFonts.outfit(
              fontSize: 72,
              fontWeight: FontWeight.w200,
              color: AppTheme.primary,
              letterSpacing: -2,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildPulseDot(),
              const SizedBox(width: 8),
              Text(
                'TRACKING BIOMÉTRICO ACTIVO',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: Colors.white24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryHUD(
      TrainingStatusState state, TrainingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'PERCEPCIÓN DE IMPACTO',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: Colors.white54,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 48),
          Text(
            '${state.rpe}',
            style: GoogleFonts.outfit(
              fontSize: 84,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'RPE (ESFUERZO)',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 12,
              color: Colors.white30,
            ),
          ),
          const SizedBox(height: 40),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppTheme.primary,
              inactiveTrackColor: Colors.white10,
              thumbColor: Colors.white,
              overlayColor: AppTheme.primary.withValues(alpha: 0.2),
              trackHeight: 8,
            ),
            child: Slider(
              value: state.rpe.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (val) {
                HapticFeedback.selectionClick();
                controller.updateRpe(val.toInt());
              },
            ),
          ),
          const SizedBox(height: 64),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _submitWorkout(state, controller),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                'REGISTRAR Y FINALIZAR',
                style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold, letterSpacing: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStartAction(TrainingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: SizedBox(
        width: double.infinity,
        height: 64,
        child: ElevatedButton(
          onPressed: () {
            HapticFeedback.mediumImpact();
            controller.startMission();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.black,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(32)),
            elevation: 12,
            shadowColor: AppTheme.primary.withValues(alpha: 0.4),
          ),
          child: Text(
            'INICIAR MISIÓN',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActiveAction(TrainingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0),
      child: Center(
        child: GestureDetector(
          onLongPress: () {
            HapticFeedback.heavyImpact();
            controller.finishMission();
          },
          child: Column(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  border: Border.all(color: Colors.redAccent, width: 2),
                ),
                child:
                    const Icon(Icons.stop, color: Colors.redAccent, size: 32),
              ),
              const SizedBox(height: 12),
              Text(
                'MANTÉN PARA FINALIZAR',
                style: GoogleFonts.jetBrainsMono(
                  fontSize: 10,
                  color: Colors.redAccent.withValues(alpha: 0.6),
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulseDot() {
    return _PulseDot();
  }
}

class _PulseDot extends StatefulWidget {
  @override
  State<_PulseDot> createState() => _PulseDotState();
}

class _PulseDotState extends State<_PulseDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: 8,
        height: 8,
        decoration: const BoxDecoration(
          color: AppTheme.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary,
              blurRadius: 4,
              spreadRadius: 1,
            )
          ],
        ),
      ),
    );
  }
}

class _HUDIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onPressed;

  const _HUDIconButton({required this.icon, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
            width: 1,
          ),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: Icon(icon, color: Colors.white70, size: 20),
      ),
    );
  }
}

class _NeonCircleButton extends StatefulWidget {
  final ExerciseCategory category;
  final bool isSelected;

  const _NeonCircleButton({
    required this.category,
    required this.isSelected,
  });

  @override
  State<_NeonCircleButton> createState() => _NeonCircleButtonState();
}

class _NeonCircleButtonState extends State<_NeonCircleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.category.color;
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            // Outer Radar Background
            if (widget.isSelected)
              RotationTransition(
                turns: _radarController,
                child: Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      center: FractionalOffset.center,
                      colors: [
                        color.withValues(alpha: 0.5),
                        Colors.transparent,
                      ],
                      stops: const [0.0, 0.25],
                    ),
                  ),
                ),
              ),
            // Inner HUD Circle
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: widget.isSelected
                    ? color.withValues(alpha: 0.2)
                    : Colors.white.withValues(alpha: 0.03),
                border: Border.all(
                  color: widget.isSelected ? color : Colors.white10,
                  width: widget.isSelected ? 2 : 1,
                ),
                boxShadow: widget.isSelected
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.4),
                          blurRadius: 25,
                          spreadRadius: 2,
                        )
                      ]
                    : [],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Grid-like background
                  Opacity(
                    opacity: 0.1,
                    child: CustomPaint(
                      painter: _CircleGridPainter(color),
                      size: const Size(80, 80),
                    ),
                  ),
                  Icon(
                    widget.category.icon,
                    color: widget.isSelected ? color : Colors.white24,
                    size: 32,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          widget.category.title,
          style: GoogleFonts.jetBrainsMono(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            letterSpacing: 2,
            color: widget.isSelected ? Colors.white : Colors.white24,
          ),
        ),
      ],
    );
  }
}

class _CircleGridPainter extends CustomPainter {
  final Color color;
  _CircleGridPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    canvas.drawCircle(center, size.width * 0.3, paint);
    canvas.drawCircle(center, size.width * 0.15, paint);
    canvas.drawLine(
        Offset(0, size.height / 2), Offset(size.width, size.height / 2), paint);
    canvas.drawLine(
        Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

String _formatDuration(Duration d) {
  String twoDigits(int n) => n.toString().padLeft(2, "0");
  String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
  String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
  return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
}

class _ProtocolItem extends StatelessWidget {
  final String title;
  final String description;

  const _ProtocolItem({required this.title, required this.description});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            color: AppTheme.primary,
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          description,
          style: GoogleFonts.jetBrainsMono(
            color: Colors.white70,
            fontSize: 11,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}
