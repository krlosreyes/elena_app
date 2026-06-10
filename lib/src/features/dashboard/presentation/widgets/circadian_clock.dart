import 'package:flutter/material.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import '../../domain/eating_window_state.dart';
import '../../domain/fasting_status.dart';
import 'fasting_hero_display.dart';
import 'parts/biological_cycles_painter.dart';
import 'parts/fasting_ring_painter.dart';
import 'parts/eating_window_painter.dart';

class CircadianClock extends StatefulWidget {
  final UserModel user;
  final FastingState fastingState;

  /// SPEC-95: estado de la ventana de comida. Se calcula en
  /// `eatingWindowProvider` y se pasa explícito al widget. Puede ser
  /// `null` mientras los providers están cargando.
  final EatingWindowState? eatingWindow;

  // SPEC-91: el badge `zone` (INESTABLE/ESTABLE/etc.) ya no se pinta
  // dentro del reloj. Si en el futuro se reincorpora a otra pantalla,
  // se vuelve a agregar como parámetro.
  //
  // SPEC-115: el parámetro `score` (IMR central) fue eliminado. El
  // centro ahora muestra el estado del ayuno + próximo hito vía
  // FastingHeroDisplay. El IMR sigue siendo la métrica central de
  // Análisis, no de "Hoy".

  const CircadianClock({
    super.key,
    required this.user,
    required this.fastingState,
    this.eatingWindow,
  });

  @override
  State<CircadianClock> createState() => _CircadianClockState();
}

class _CircadianClockState extends State<CircadianClock>
    with SingleTickerProviderStateMixin {
  // UI #3 (motion A): late "respira" la punta viva del arco mientras hay
  // ayuno activo. Gateado a reduce-motion (accesibilidad).
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncPulse();
  }

  @override
  void didUpdateWidget(covariant CircadianClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fastingState.isActive != widget.fastingState.isActive) {
      _syncPulse();
    }
  }

  void _syncPulse() {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldAnimate = widget.fastingState.isActive && !reduceMotion;
    if (shouldAnimate) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // SPEC-72.10: `onBackground` deprecated en Material 3 → migrado a `onSurface`.
    final colorDeTexto = Theme.of(context).colorScheme.onSurface;
    final now = DateTime.now();
    final fastingState = widget.fastingState;
    final user = widget.user;
    final eatingWindow = widget.eatingWindow;
    // `colorDeTexto` se conserva para los painters que sí lo consumen;
    // el centro vive ahora dentro de FastingHeroDisplay.

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;

        return Stack(
          alignment: Alignment.center,
          children: [
            // CAPA 1: Ciclos Biológicos (Fondo estático de 24h)
            SizedBox(
              height: size,
              width: size,
              child: CustomPaint(
                painter: BiologicalCyclesPainter(
                    indicatorColor: colorDeTexto, currentTime: now),
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
              height: size,
              width: size,
              child: fastingState.isActive
                  // UI #3 (motion A): el arco repinta con el pulso para que la
                  // punta viva "respire". AnimatedBuilder solo se monta con
                  // ayuno activo; el controller no late en reduce-motion.
                  ? AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, _) => CustomPaint(
                        painter: FastingRingPainter(
                          startTime: fastingState.startTime ?? now,
                          duration: fastingState.duration,
                          // SPEC-103: color fijo verde durante ayuno.
                          phaseColor: AppColors.metabolicGreen,
                          indicatorColor: colorDeTexto,
                          pulse: Curves.easeInOut.transform(_pulse.value),
                        ),
                      ),
                    )
                  : (eatingWindow != null
                      ? CustomPaint(
                          painter: EatingWindowPainter(
                            windowStart: eatingWindow.windowStart,
                            windowEnd: eatingWindow.windowEnd,
                            now: now,
                            indicatorColor: colorDeTexto,
                            mealsCount: user.mealsPerDay,
                          ),
                        )
                      : const SizedBox.shrink()),
            ),

            // CAPA 3: SPEC-115 — Hero del ayuno (cronómetro, countdown
            // o completado) + próximo hito metabólico. Reemplaza al
            // antiguo "IMR SCORE / 75". El IMR sigue en Análisis.
            FastingHeroDisplay(
              fastingState: fastingState,
              eatingWindow: eatingWindow,
              size: size,
            ),
          ],
        );
      },
    );
  }

  // SPEC-103: `_getPhaseColor` eliminado. La fase del ayuno se
  // comunica por hitos visuales (water_drop, fire, recycle) en el
  // anillo y por la etiqueta "Estado actual: <fase>" en el card de
  // Ayuno (SPEC-101). El color del arco es siempre verde durante
  // ayuno para diferenciarlo de la ventana de comida (naranja).
}
