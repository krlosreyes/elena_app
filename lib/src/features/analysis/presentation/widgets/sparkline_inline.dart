// SPEC-168.4 (2026-06-03): mini-sparkline reutilizable, sin axis ni
// labels. Pensada para tiles de overview tipo Apple Health "Anteriores".
//
// Recibe una lista de doubles y dibuja una línea simple normalizada
// al espacio disponible. Si solo hay 1 punto, dibuja un dot centrado.

import 'package:flutter/material.dart';

class SparklineInline extends StatelessWidget {
  const SparklineInline({
    super.key,
    required this.values,
    required this.color,
  });

  final List<double> values;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (values.isEmpty) return const SizedBox.shrink();
    return CustomPaint(
      size: Size.infinite,
      painter: _SparklinePainter(values: values, color: color),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  _SparklinePainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;

    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);
    final range = (maxV - minV).abs();
    final pad = size.height * 0.15;
    final plotH = size.height - pad * 2;

    double yOf(double v) {
      if (range == 0) return size.height / 2;
      return size.height - pad - ((v - minV) / range) * plotH;
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    if (values.length == 1) {
      // Un solo punto → dot centrado.
      canvas.drawCircle(
        Offset(size.width / 2, yOf(values.first)),
        2.5,
        Paint()..color = color,
      );
      return;
    }

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = yOf(values[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter old) =>
      old.values != values || old.color != color;
}
