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

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;

        return Stack(
          alignment: Alignment.center,
          children: [
            // CAPA 1: Ciclos Biológicos (Fondo estático de 24h)
            SizedBox(
              height: size, width: size,
              child: CustomPaint(
                painter: BiologicalCyclesPainter(
                  indicatorColor: colorDeTexto, 
                  currentTime: now
                ),
              ),
            ),

            // CAPA 2: Radar Metabólico Activo (COORDENADAS REALES)
            SizedBox(
              height: size, width: size,
              child: CustomPaint(
                painter: fastingState.isActive 
                  ? FastingRingPainter(
                      // IMPORTANTE: Pasamos el startTime para que el Painter 
                      // sepa el ángulo de inicio real en el círculo de 24h
                      startTime: fastingState.startTime ?? now,
                      duration: fastingState.duration,
                      phaseColor: _getPhaseColor(fastingState.phase),
                      indicatorColor: colorDeTexto,
                    )
                  : EatingWindowPainter(
                      // Lo mismo para la ventana de comida
                      startTime: fastingState.startTime ?? now,
                      duration: fastingState.duration,
                      indicatorColor: colorDeTexto,
                    ),
              ),
            ),

            // CAPA 3: IMR SCORE Central
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "IMR SCORE", 
                  style: TextStyle(
                    color: colorDeTexto.withOpacity(0.5), 
                    letterSpacing: 2.0,
                    fontSize: size * 0.035,
                    fontWeight: FontWeight.w600,
                  )
                ),
                Text(
                  "${score.toInt()}", 
                  style: TextStyle(
                    fontSize: size * 0.25, 
                    height: 1.0, 
                    color: colorDeTexto,
                    fontWeight: FontWeight.w900,
                    fontFamily: 'monospace',
                  )
                ),
                const SizedBox(height: 6),
                
                _buildZoneBadge(size),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildZoneBadge(double size) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.metabolicGreen.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.metabolicGreen.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, color: AppColors.metabolicGreen, size: size * 0.04),
          const SizedBox(width: 4),
          Text(
            zone.toUpperCase(), 
            style: TextStyle(
              color: AppColors.metabolicGreen, 
              fontWeight: FontWeight.w900,
              fontSize: size * 0.035,
              letterSpacing: 1.0,
            )
          ),
        ],
      ),
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