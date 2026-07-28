// SPEC-202: bottom sheet educativo del reloj circadiano.
//
// El reloj codifica mucho (fase biológica por color, arco del ayuno, punto
// "ahora", hitos, horas). Para que un usuario nuevo lo entienda sin ensuciar
// la estética densa del Dashboard, se explica ON-DEMAND al tocar el reloj.
//
// Layout de la leyenda: cada fila tiene su marcador en una caja de ancho fijo
// + texto en una columna aparte (Row, sin Stack) — los íconos NUNCA se cruzan
// ni se anteponen a otros elementos.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

void showClockExplainerSheet(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _ClockExplainerSheet(),
  );
}

class _ClockExplainerSheet extends StatelessWidget {
  const _ClockExplainerSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Tu reloj metabólico',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Es tu día de 24 horas visto desde tu biología. Esto es lo que '
              'muestra cada parte:',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 14,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            _LegendRow(
              marker: _Dot(color: const Color(0xFF60A5FA)),
              title: 'El punto azul: ahora',
              body: 'Es tu posición en el día. Se mueve con la hora real.',
            ),
            _LegendRow(
              marker: const Icon(Icons.timer_rounded,
                  color: AppColors.metabolicGreen, size: 22),
              title: 'El arco verde: tu ayuno',
              body: 'Crece a medida que avanza tu ayuno en curso. El número '
                  'del centro es el tiempo que llevas.',
            ),
            _LegendRow(
              marker: const Icon(Icons.donut_large_rounded,
                  color: AppColors.accent, size: 22),
              title: 'El anillo de color: tu fase biológica',
              body: 'Cada tramo es un momento de tu día (fuerza, cognición, '
                  'sueño…). El tramo encendido es en el que estás ahora — por '
                  'eso a veces es buena hora para entrenar o pensar.',
            ),
            _LegendRow(
              marker: const Icon(Icons.local_fire_department_rounded,
                  color: Color(0xFFFB923C), size: 22),
              title: 'Los íconos del aro: hitos del ayuno',
              body: '12 h descenso de insulina, 18 h quema de grasa, 24 h '
                  'autofagia. Marcan cuándo tu cuerpo cambia de marcha.',
            ),
            _LegendRow(
              marker: const Icon(Icons.schedule_rounded,
                  color: Color(0xFF94A3B8), size: 22),
              title: 'Los números 00 · 06 · 12 · 18',
              body: 'Las horas del día, con luna y sol según sea noche o día.',
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.metabolicGreen.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.metabolicGreen.withValues(alpha: 0.20),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lightbulb_outline,
                      color: AppColors.metabolicGreen, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'No tienes que mirarlo todo el tiempo: el reloj te avisa '
                      'cuándo aprovechar cada fase. Tú solo segui tu día.',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 13,
                        height: 1.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fila de leyenda: marcador (caja de ancho fijo) + texto. Sin solapes.
class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.marker,
    required this.title,
    required this.body,
  });

  final Widget marker;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 40, child: Center(child: marker)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.70),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border:
            Border.all(color: Colors.white.withValues(alpha: 0.9), width: 2),
      ),
    );
  }
}
