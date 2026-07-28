import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/fasting/domain/eating_window_state.dart';
import 'package:elena_app/src/features/fasting/domain/fasting_status.dart';
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
    with TickerProviderStateMixin {
  // UI #3 (motion A): late "respira" la punta viva del arco mientras hay
  // ayuno activo. Gateado a reduce-motion (accesibilidad).
  late final AnimationController _pulse;

  // UI #3 (motion B): burst one-shot al cruzar un hito (12/18/24h o target).
  late final AnimationController _celebrate;

  /// Hito que se está celebrando ahora (12/18/24 o target). `null` = ninguno.
  int? _celebratingHour;

  /// Hitos ya celebrados en el ayuno ACTUAL — evita repetir el destello en
  /// cada tick. Se limpia al iniciar un ayuno nuevo o al cerrarlo.
  final Set<int> _celebratedHours = {};

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
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

    final old = oldWidget.fastingState;
    final now = widget.fastingState;

    // Reset del registro de hitos al iniciar un ayuno nuevo o al cerrarlo,
    // para que la próxima sesión vuelva a poder celebrar.
    if (!now.isActive || now.startTime != old.startTime) {
      _celebratedHours.clear();
    }

    if (old.isActive != now.isActive) {
      _syncPulse();
    }

    if (now.isActive) {
      _maybeCelebrate(old.duration, now.duration);
    }
  }

  void _syncPulse() {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final shouldAnimate = widget.fastingState.isActive && !reduceMotion;
    if (shouldAnimate) {
      if (!_pulse.isAnimating) _pulse.repeat(reverse: true);
    } else {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  /// Detecta el cruce de un hito entre la duración previa y la actual.
  /// Sólo dispara hacia adelante (oldDur < hito ≤ newDur) y una vez por hito.
  /// No dispara en el mount inicial (no hay `oldWidget`), por lo que reabrir
  /// la app a mitad de ayuno NO repite celebraciones ya pasadas.
  void _maybeCelebrate(Duration oldDur, Duration newDur) {
    if (newDur <= oldDur) return;
    final oldSecs = oldDur.inSeconds;
    final newSecs = newDur.inSeconds;
    final target = widget.fastingState.targetHours;
    final milestones = <int>{12, 18, 24, if (target > 0) target};

    for (final h in milestones) {
      final threshold = h * 3600;
      final crossed = oldSecs < threshold && newSecs >= threshold;
      if (crossed && !_celebratedHours.contains(h)) {
        _celebratedHours.add(h);
        HapticFeedback.mediumImpact();
        final reduceMotion =
            MediaQuery.maybeOf(context)?.disableAnimations ?? false;
        if (!reduceMotion) {
          setState(() => _celebratingHour = h);
          _celebrate.forward(from: 0).whenComplete(() {
            if (mounted) setState(() => _celebratingHour = null);
          });
        }
        break; // una celebración a la vez
      }
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _celebrate.dispose();
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
                      animation: Listenable.merge([_pulse, _celebrate]),
                      builder: (context, _) => CustomPaint(
                        painter: FastingRingPainter(
                          startTime: fastingState.startTime ?? now,
                          duration: fastingState.duration,
                          // SPEC-103: color fijo verde durante ayuno.
                          phaseColor: AppColors.metabolicGreen,
                          indicatorColor: colorDeTexto,
                          pulse: Curves.easeInOut.transform(_pulse.value),
                          celebrateHour: _celebratingHour,
                          celebrateT:
                              Curves.easeOut.transform(_celebrate.value),
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
