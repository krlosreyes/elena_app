// SPEC-168.4.4 v3 (2026-06-03): gauge horizontal de 5 zonas ACSM.
//
// v1 (CustomPainter abstracto) se veía rígido. v2 (SVG assets) tenía
// problemas de carga de assets en web. v3 vuelve a CustomPainter puro
// — barra horizontal de 5 segmentos (Esencial, Atlético, Fitness,
// Promedio, Alto) con un indicador triangular apuntando a la zona
// actual del usuario. Más informativo que una silueta: comunica de un
// golpe "estás en X y la siguiente meta es Y".
//
// El nombre del archivo queda `body_silhouette.dart` por compatibilidad
// con los imports existentes (es la misma feature).

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/analysis/domain/body_zone.dart';

class BodySilhouette extends StatelessWidget {
  const BodySilhouette({
    super.key,
    required this.bodyFatPct,
    required this.isMale,
  });

  final double? bodyFatPct;
  final bool isMale;

  @override
  Widget build(BuildContext context) {
    final zone = bodyZoneFor(bodyFatPct, isMale);
    final hasData = zone != null && bodyFatPct != null;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TU ZONA',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.50),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 6),
        if (hasData) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                zone.label,
                style: TextStyle(
                  color: zone.color,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  height: 1.0,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '${bodyFatPct!.toStringAsFixed(1)} % grasa',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ] else
          Text(
            'Registrá tu % de grasa',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        const SizedBox(height: 14),
        SizedBox(
          height: 64,
          child: CustomPaint(
            size: Size.infinite,
            painter: _ZoneGaugePainter(
              currentBf: bodyFatPct,
              isMale: isMale,
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Rangos ACSM ${isMale ? '♂' : '♀'} — '
          '${isMale ? 'Atlético <14, Fitness 14–17, Promedio 18–24, Alto ≥25' : 'Atlético <21, Fitness 21–24, Promedio 25–31, Alto ≥32'}',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.40),
            fontSize: 10.5,
            height: 1.4,
          ),
        ),
      ],
    );
  }
}

class _ZoneGaugePainter extends CustomPainter {
  _ZoneGaugePainter({required this.currentBf, required this.isMale});

  final double? currentBf;
  final bool isMale;

  // Bordes de zona en % grasa.
  // Hombre: 6 (esencial→atlético), 14 (atlético→fitness),
  //         18 (fitness→promedio), 25 (promedio→alto), 40 (techo gauge)
  // Mujer:  14, 21, 25, 32, 50
  List<double> get _bounds => isMale
      ? const [6, 14, 18, 25, 40]
      : const [14, 21, 25, 32, 50];

  // 5 segmentos en orden: esencial, atlético, fitness, promedio, alto.
  static const _zoneOrder = [
    BodyZone.esencial,
    BodyZone.atletico,
    BodyZone.fitness,
    BodyZone.promedio,
    BodyZone.alto,
  ];

  static const double _barHeight = 18.0;
  static const double _barRadius = 9.0;
  static const double _indicatorSize = 12.0;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Barra vertical: centrada verticalmente con espacio para indicador.
    final barTop = h * 0.45;
    final barBottom = barTop + _barHeight;

    // Cada segmento tiene ancho proporcional a su rango en %grasa.
    final minBf = _bounds.first;
    final maxBf = _bounds.last;
    final totalSpan = maxBf - minBf;

    // Dibujar segmentos.
    double xCursor = 0;
    for (int i = 0; i < _zoneOrder.length; i++) {
      final zone = _zoneOrder[i];
      final segmentSpan = _bounds[i + 1] - _bounds[i];
      final segmentWidth = (segmentSpan / totalSpan) * w;
      final isFirst = i == 0;
      final isLast = i == _zoneOrder.length - 1;

      final rect = Rect.fromLTRB(
        xCursor,
        barTop,
        xCursor + segmentWidth,
        barBottom,
      );
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: isFirst ? const Radius.circular(_barRadius) : Radius.zero,
        bottomLeft:
            isFirst ? const Radius.circular(_barRadius) : Radius.zero,
        topRight: isLast ? const Radius.circular(_barRadius) : Radius.zero,
        bottomRight:
            isLast ? const Radius.circular(_barRadius) : Radius.zero,
      );

      final paint = Paint()..color = zone.color.withValues(alpha: 0.65);
      canvas.drawRRect(rrect, paint);

      xCursor += segmentWidth;
    }

    // Indicador (triángulo apuntando hacia abajo) en la posición actual.
    if (currentBf != null) {
      final clamped = currentBf!.clamp(minBf, maxBf);
      final indicatorX = ((clamped - minBf) / totalSpan) * w;
      _drawIndicator(canvas, indicatorX, barTop);
    }

    // Etiquetas debajo: límites de zona (solo las divisiones internas).
    final labelPaint = TextStyle(
      color: Colors.white.withValues(alpha: 0.45),
      fontSize: 9,
      fontWeight: FontWeight.w600,
    );
    for (int i = 1; i < _bounds.length - 1; i++) {
      final x = ((_bounds[i] - minBf) / totalSpan) * w;
      final tp = TextPainter(
        text: TextSpan(
          text: _bounds[i].toStringAsFixed(0),
          style: labelPaint,
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, barBottom + 4));
    }
  }

  void _drawIndicator(Canvas canvas, double x, double barTop) {
    // Triángulo apuntando hacia abajo justo encima de la barra.
    final triHeight = _indicatorSize;
    final triHalf = _indicatorSize * 0.7;
    final tipY = barTop - 2;
    final baseY = barTop - triHeight - 2;

    final path = Path()
      ..moveTo(x, tipY)
      ..lineTo(x - triHalf, baseY)
      ..lineTo(x + triHalf, baseY)
      ..close();

    canvas.drawPath(path, Paint()..color = Colors.white);

    // Pequeño círculo blanco en la barra como reforzamiento visual.
    final dotY = barTop + _barHeight / 2;
    canvas.drawCircle(
      Offset(x, dotY),
      4.0,
      Paint()..color = Colors.white,
    );
    canvas.drawCircle(
      Offset(x, dotY),
      2.0,
      Paint()..color = Colors.black,
    );
  }

  @override
  bool shouldRepaint(covariant _ZoneGaugePainter old) =>
      old.currentBf != currentBf || old.isMale != isMale;
}

// Mantener `math` imported para futuras extensiones (no usado por ahora).
// ignore: unused_element
double _kUnused(double v) => math.max(v, 0);
