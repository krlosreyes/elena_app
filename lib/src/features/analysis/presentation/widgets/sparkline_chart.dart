// SPEC-162: sparkline minimal compartido por Resultados y Hábitos.
//
// Renderiza una línea simple con punto destacado al final + gradiente
// sutil debajo. Sin ejes, sin labels. La info numérica vive afuera.

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/analysis/domain/metric_series.dart';

class SparklineChart extends StatelessWidget {
  const SparklineChart({
    super.key,
    required this.series,
    required this.color,
    this.height = 44,
  });

  final MetricSeries series;
  final Color color;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (series.points.length < 2) {
      return SizedBox(
        height: height,
        child: Center(
          child: Text(
            series.points.isEmpty
                ? 'Sin datos en este rango'
                : 'Solo 1 semana — necesitás 2+ para tendencia',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.30),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: height,
      child: CustomPaint(
        size: Size.infinite,
        painter: _SparklinePainter(series: series, color: color),
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.series, required this.color});

  final MetricSeries series;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final values = series.points.map((p) => p.value).toList();
    final minV = series.minValue;
    final maxV = series.maxValue;
    final range = (maxV - minV).abs();
    final padding = range > 0 ? range * 0.10 : 1.0;
    final yMin = minV - padding;
    final yMax = maxV + padding;
    final yRange = (yMax - yMin) == 0 ? 1.0 : (yMax - yMin);

    double yOf(double v) {
      final n = (v - yMin) / yRange;
      return size.height - (n * size.height);
    }

    double xOf(int i) {
      if (values.length == 1) return size.width / 2;
      return (i / (values.length - 1)) * size.width;
    }

    final linePath = Path();
    final fillPath = Path();
    for (int i = 0; i < values.length; i++) {
      final x = xOf(i);
      final y = yOf(values[i]);
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.22),
          color.withValues(alpha: 0.02),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final lastX = xOf(values.length - 1);
    final lastY = yOf(values.last);
    canvas.drawCircle(Offset(lastX, lastY), 3.0, Paint()..color = color);
    canvas.drawCircle(
      Offset(lastX, lastY),
      5.0,
      Paint()..color = color.withValues(alpha: 0.30),
    );
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.series != series || old.color != color;
}
