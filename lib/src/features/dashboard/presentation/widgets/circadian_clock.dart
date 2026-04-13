import 'package:flutter/material.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import '../../domain/fasting_status.dart';
import 'parts/biological_cycles_painter.dart';
import 'parts/fasting_ring_painter.dart';
import 'parts/eating_window_painter.dart';

class CircadianClock extends StatelessWidget {
  final UserModel user;
  final FastingState fastingState;
  final double score;
  final String zone;

  const CircadianClock({
    super.key,
    required this.user,
    required this.fastingState,
    required this.score,
    required this.zone,
  });

  @override
  Widget build(BuildContext context) {
    final colorDeTexto = Theme.of(context).colorScheme.onBackground;
    final now = DateTime.now();

    return Stack(
      alignment: Alignment.center,
      children: [
        // CAPA 1: Ciclos Biológicos (Fondo)
        SizedBox(
          height: 440, width: 440,
          child: CustomPaint(
            painter: BiologicalCyclesPainter(indicatorColor: colorDeTexto, currentTime: now),
          ),
        ),

        // CAPA 2: INTERRUPTOR DINÁMICO (Ayuno vs Ventana)
        SizedBox(
          height: 440, width: 440,
          child: CustomPaint(
            painter: fastingState.isActive 
              ? FastingRingPainter(
                  fastingProgress: (fastingState.duration.inSeconds / (24 * 3600)).clamp(0.0, 1.0),
                  phaseColor: _getPhaseColor(fastingState.phase),
                  indicatorColor: colorDeTexto,
                )
              : EatingWindowPainter(
                  // Asumimos una ventana estándar de 8 horas para el progreso visual
                  windowProgress: (fastingState.duration.inSeconds / (8 * 3600)).clamp(0.0, 1.0),
                  indicatorColor: colorDeTexto,
                ),
          ),
        ),

        // CAPA 3: IMR SCORE
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("IMR SCORE", style: Theme.of(context).textTheme.labelSmall?.copyWith(color: colorDeTexto.withOpacity(0.6), letterSpacing: 1.2)),
            Text("${score.toInt()}", style: Theme.of(context).textTheme.displayLarge?.copyWith(fontSize: 85, height: 1.1, color: colorDeTexto)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt, color: AppColors.metabolicGreen, size: 18),
                Text(zone.toUpperCase(), style: const TextStyle(color: AppColors.metabolicGreen, fontWeight: FontWeight.w900)),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Color _getPhaseColor(FastingPhase phase) {
    switch (phase) {
      case FastingPhase.postAbsorption: return Colors.lightBlueAccent;
      case FastingPhase.transition: return Colors.orangeAccent;
      case FastingPhase.fatBurning: return AppColors.metabolicGreen;
      case FastingPhase.autophagy: return const Color(0xFF6366F1);
      default: return AppColors.metabolicGreen;
    }
  }
}