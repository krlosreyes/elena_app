import 'package:flutter/material.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import '../../domain/eating_window_state.dart';
import '../../domain/fasting_status.dart';
import 'parts/biological_cycles_painter.dart';
import 'parts/fasting_ring_painter.dart';
import 'parts/eating_window_painter.dart';

class CircadianClock extends StatelessWidget {
  final UserModel user;
  final FastingState fastingState;
  final double score;

  /// SPEC-95: estado de la ventana de comida. Se calcula en
  /// `eatingWindowProvider` y se pasa explícito al widget. Puede ser
  /// `null` mientras los providers están cargando.
  final EatingWindowState? eatingWindow;

  // SPEC-91: el badge `zone` (INESTABLE/ESTABLE/etc.) ya no se pinta
  // dentro del reloj. Si en el futuro se reincorpora a otra pantalla,
  // se vuelve a agregar como parámetro.

  const CircadianClock({
    super.key,
    required this.user,
    required this.fastingState,
    required this.score,
    this.eatingWindow,
  });

  @override
  Widget build(BuildContext context) {
    // SPEC-72.10: `onBackground` deprecated en Material 3 → migrado a `onSurface`.
    final colorDeTexto = Theme.of(context).colorScheme.onSurface;
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
            //
            // SPEC-95: cuando NO hay ayuno activo, el painter consume
            // `eatingWindow` (computado en `eatingWindowProvider`) con
            // sus DateTimes explícitos. Antes consumía el FastingState
            // y mezclaba conceptos — la ventana no se pintaba.
            //
            // Si `eatingWindow == null` (providers cargando) se omite
            // la capa para no dibujar datos inventados.
            SizedBox(
              height: size, width: size,
              child: CustomPaint(
                painter: fastingState.isActive
                    ? FastingRingPainter(
                        startTime: fastingState.startTime ?? now,
                        duration: fastingState.duration,
                        phaseColor: _getPhaseColor(fastingState.phase),
                        indicatorColor: colorDeTexto,
                      )
                    : (eatingWindow != null
                        ? EatingWindowPainter(
                            windowStart: eatingWindow!.windowStart,
                            windowEnd: eatingWindow!.windowEnd,
                            now: now,
                            indicatorColor: colorDeTexto,
                            mealsCount: user.mealsPerDay,
                          )
                        : null),
              ),
            ),

            // CAPA 3: IMR SCORE Central
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "IMR SCORE", 
                  style: TextStyle(
                    color: colorDeTexto.withValues(alpha: 0.5), 
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
                // SPEC-91: badge de zona (INESTABLE/ESTABLE/etc.) removido
                // del círculo del IMR; se veía visualmente ruidoso encima
                // de las capas del reloj. El estado sigue disponible en la
                // pantalla Análisis y vía `zone` para futuros usos.
              ],
            ),
          ],
        );
      },
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