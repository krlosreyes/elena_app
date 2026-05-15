// SPEC-110: composición visual central de la pantalla Análisis.
//
// Layout: un anillo grande al centro con el IMR del día, y 5
// satélites pequeños distribuidos en pentágono alrededor — uno por
// pilar. Cada satélite es un mini-anillo de progreso con icono.
//
// Decisión: pentágono (72° entre satélites) en lugar de hexágono
// porque tenemos exactamente 5 pilares y queremos simetría perfecta.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/domain/daily_summary.dart';

class ImrRingWithSatellites extends StatelessWidget {
  final DailySummary summary;

  const ImrRingWithSatellites({super.key, required this.summary});

  /// Configuración de cada pilar (orden = posición en el pentágono).
  static const List<_PillarSpec> _pillars = [
    _PillarSpec(
      label: 'Sueño',
      icon: Icons.nightlight_round,
      color: Color(0xFF818CF8),
    ),
    _PillarSpec(
      label: 'Hidratación',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF38BDF8),
    ),
    _PillarSpec(
      label: 'Ejercicio',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFF14B8A6),
    ),
    _PillarSpec(
      label: 'Comidas',
      icon: Icons.restaurant_rounded,
      color: Color(0xFFFB923C),
    ),
    _PillarSpec(
      label: 'Ayuno',
      icon: Icons.timer_rounded,
      color: AppColors.metabolicGreen,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.maxWidth;
        return SizedBox(
          height: size,
          width: size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // 1. Anillo central con IMR del día.
              // SPEC-110.4: bajado a 0.48 para que el satélite Sueño
              // (en el norte del pentágono) no toque el borde superior
              // del contenedor. La geometría es:
              //   topSatelliteY = centerY - orbit - totalHeight/2
              // Con orbit 0.36 y satellite 0.15, esto da 0.065N de
              // margen superior real (antes era negativo → overflow).
              SizedBox(
                height: size * 0.48,
                width: size * 0.48,
                child: CustomPaint(
                  painter: _CentralRingPainter(
                    score: summary.imrScore,
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'IMR HOY',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.50),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${summary.imrScore}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 56,
                            fontWeight: FontWeight.w900,
                            fontFamily: 'monospace',
                            height: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 2. Satélites en pentágono (5 puntos a 72° cada uno).
              ..._buildSatellites(size),
            ],
          ),
        );
      },
    );
  }

  List<Widget> _buildSatellites(double containerSize) {
    final progresses = <double>[
      summary.sleepProgress,
      summary.hydrationProgress,
      summary.exerciseProgress,
      summary.mealsProgress,
      summary.fastingProgress,
    ];

    // SPEC-110.4: geometría que cabe matemáticamente sin overflow.
    //   - satelliteSize 0.17 → 0.15
    //   - orbitRadius 0.42 → 0.36
    // Esto garantiza que el satélite Sueño (norte) tenga margen
    // positivo desde el borde superior del contenedor:
    //   topY = 0.5N - 0.36N - 0.075N - ~7 ≈ 0.065N
    final double satelliteSize = containerSize * 0.15;
    final double orbitRadius = containerSize * 0.36;
    final double centerX = containerSize / 2;
    final double centerY = containerSize / 2;

    // SPEC-110.1: ahora cada satélite incluye un label debajo del
    // anillo. Calculamos un ancho holgado para el label (más amplio
    // que el anillo) y centramos la composición vertical (anillo +
    // spacing + label) en el orbit.
    //
    // SPEC-110.2 fix: labelHeight subido de 14 → 18 — el Text con
    // fontSize 10 + default line-height ocupa ~15px, así que 14
    // generaba overflow de 1px. 18 da margen seguro.
    const double spacingBelow = 4;
    const double labelHeight = 18;
    final double totalHeight = satelliteSize + spacingBelow + labelHeight;
    final double satelliteWidth = satelliteSize * 1.7; // ancho extra para label

    // 5 ángulos: -π/2 (norte) + i * 2π/5
    final result = <Widget>[];
    for (int i = 0; i < _pillars.length; i++) {
      final angle = -math.pi / 2 + i * (2 * math.pi / 5);
      final cx = centerX + orbitRadius * math.cos(angle);
      final cy = centerY + orbitRadius * math.sin(angle);
      result.add(Positioned(
        left: cx - satelliteWidth / 2,
        top: cy - totalHeight / 2,
        child: SizedBox(
          width: satelliteWidth,
          height: totalHeight,
          child: _PillarSatellite(
            spec: _pillars[i],
            progress: progresses[i],
            ringSize: satelliteSize,
          ),
        ),
      ));
    }
    return result;
  }
}

class _PillarSpec {
  final String label;
  final IconData icon;
  final Color color;

  const _PillarSpec({
    required this.label,
    required this.icon,
    required this.color,
  });
}

/// Mini-anillo de progreso de un pilar con icono al centro + label
/// compacta debajo. SPEC-110.1: label agregada para que el usuario
/// identifique cada pilar sin depender solo del icono.
class _PillarSatellite extends StatelessWidget {
  final _PillarSpec spec;
  final double progress; // 0..1
  final double ringSize;

  const _PillarSatellite({
    required this.spec,
    required this.progress,
    required this.ringSize,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Anillo con icono al centro.
        SizedBox(
          width: ringSize,
          height: ringSize,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(ringSize, ringSize),
                painter: _SatelliteArcPainter(
                  progress: progress.clamp(0.0, 1.0),
                  color: spec.color,
                ),
              ),
              Icon(spec.icon, color: spec.color, size: ringSize * 0.40),
            ],
          ),
        ),
        const SizedBox(height: 4),
        // Label compacta — identifica el pilar sin depender solo
        // del icono.
        //
        // SPEC-110.2 fix: `height: 1.0` fuerza line-height igual al
        // fontSize, eliminando el descender extra del default 1.461.
        // Esto resuelve el overflow de ~1px que aparecía aún con
        // labelHeight=18.
        Text(
          spec.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
            height: 1.0,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}

// ─── Painters ─────────────────────────────────────────────────────────────

class _CentralRingPainter extends CustomPainter {
  final int score;

  _CentralRingPainter({required this.score});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // SPEC-110.4: stroke 10% → 7%. 10% se veía burdo en pantalla.
    // 7% mantiene presencia visual del anillo central como
    // protagonista pero con elegancia de diseño profesional.
    final stroke = size.width * 0.07;
    final radius = (size.width / 2) - (stroke / 2) - 2;
    final progress = (score / 100).clamp(0.0, 1.0);

    // Track de fondo
    final trackPaint = Paint()
      ..color = AppColors.metabolicGreen.withValues(alpha: 0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    // Arco activo
    final progressPaint = Paint()
      ..color = AppColors.metabolicGreen
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _CentralRingPainter oldDelegate) =>
      oldDelegate.score != score;
}

class _SatelliteArcPainter extends CustomPainter {
  final double progress; // 0..1
  final Color color;

  _SatelliteArcPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    // SPEC-110.3: stroke 11.5% → 8.5% para anillo más refinado y
    // menos macizo. Radio recalculado en función del nuevo stroke.
    final stroke = size.width * 0.085;
    final radius = (size.width / 2) - (stroke / 2) - 1;

    // SPEC-110.3: alpha del track 0.28 → 0.12. Con colores saturados
    // (cyan, naranja, teal) 0.28 se ve como anillo completo y
    // confunde con "100% completado". 0.12 da el placeholder discreto
    // adecuado.
    final trackPaint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;

    final progressPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      progressPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SatelliteArcPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
