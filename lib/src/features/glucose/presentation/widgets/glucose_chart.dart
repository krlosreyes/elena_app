// Módulo "Tu Glucosa" — gráfico histórico simple (propuesta §7.3).
//
// CustomPainter propio en vez de agregar una dependencia nueva de
// charting (fl_chart/charts_flutter/syncfusion no están en pubspec.yaml
// hoy y este sandbox no puede correr `flutter pub get` para validar una
// dependencia nueva) — decisión documentada en el informe de
// implementación. Es un line chart minimalista: puntos + línea +
// bandas de referencia de rango, coherente con el resto de la UI
// (fondo oscuro, acentos de color puntuales, sin ejes recargados).

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';

class GlucoseChart extends StatelessWidget {
  const GlucoseChart({super.key, required this.readings, this.height = 160});

  /// Ordenadas por measuredAt ASCENDENTE (más antigua primero) — el
  /// caller es responsable de invertir si viene descendente de
  /// Firestore.
  final List<GlucoseReading> readings;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (readings.isEmpty) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            'Todavía no hay lecturas para graficar.',
            style: TextStyle(color: Colors.white.withValues(alpha: 0.4)),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      width: double.infinity,
      child: CustomPaint(
        painter: _GlucoseChartPainter(readings: readings),
      ),
    );
  }
}

class _GlucoseChartPainter extends CustomPainter {
  _GlucoseChartPainter({required this.readings});

  final List<GlucoseReading> readings;

  static const _lineColor = Color(0xFFE879F9);
  static const _normalBandColor = Color(0x1A22C55E); // verde muy tenue

  @override
  void paint(Canvas canvas, Size size) {
    final values = readings.map((r) => r.valueMgDl).toList();
    final minV = (values.reduce((a, b) => a < b ? a : b) - 15)
        .clamp(0, 400)
        .toDouble();
    final maxV = (values.reduce((a, b) => a > b ? a : b) + 15)
        .clamp(0, 400)
        .toDouble();
    final range = (maxV - minV).clamp(1, 400).toDouble();

    double yFor(int v) => size.height - ((v - minV) / range) * size.height;
    double xFor(int i) => readings.length <= 1
        ? size.width / 2
        : (i / (readings.length - 1)) * size.width;

    // Banda de referencia "en rango" (ayunas <100 mg/dL) — solo visual,
    // no es una afirmación diagnóstica per se.
    if (100 >= minV && 100 <= maxV) {
      final bandTop = yFor(100);
      canvas.drawRect(
        Rect.fromLTRB(0, bandTop, size.width, size.height),
        Paint()..color = _normalBandColor,
      );
    }

    final linePaint = Paint()
      ..color = _lineColor
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();
    for (var i = 0; i < readings.length; i++) {
      final x = xFor(i);
      final y = yFor(readings[i].valueMgDl);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = _lineColor;
    for (var i = 0; i < readings.length; i++) {
      canvas.drawCircle(
        Offset(xFor(i), yFor(readings[i].valueMgDl)),
        2.6,
        dotPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _GlucoseChartPainter oldDelegate) =>
      oldDelegate.readings != readings;
}
