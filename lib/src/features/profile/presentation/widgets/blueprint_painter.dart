import 'package:flutter/material.dart';

class BlueprintPainter extends CustomPainter {
  final Color color;
  final double screenWidth;
  final double screenHeight;

  BlueprintPainter({
    required this.color,
    required this.screenWidth,
    required this.screenHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.4)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    // --- COORDINATES PERFECTLY MAPPED TO SCREEN RATIOS ---

    // 1. CUELLO (Right Side)
    // El label "CUELLO" estará un poco arriba del marker (Offset vertical -0.05)
    _drawTechnicalLine(
      canvas, paint, dotPaint,
      Offset(screenWidth * 0.72, screenHeight * 0.28), // Box Origin
      Offset(screenWidth * 0.50, screenHeight * 0.33), // Target (Nuez/Cuello)
      isLeft: false,
    );

    // 2. CINTURA (Left Side)
    // El label "CINTURA" a la izquierda, línea sale hacia el centro (Offset vertical -0.04)
    _drawTechnicalLine(
      canvas, paint, dotPaint,
      Offset(screenWidth * 0.28, screenHeight * 0.45), // Box Origin
      Offset(screenWidth * 0.45, screenHeight * 0.50), // Target (Cintura)
      isLeft: true,
    );

    // 3. CADERA (Right Side)
    // El label "CADERA" abajo a la derecha, la línea sube (Offset vertical +0.06)
    _drawTechnicalLine(
      canvas, paint, dotPaint,
      Offset(screenWidth * 0.72, screenHeight * 0.63), // Box Origin
      Offset(screenWidth * 0.55, screenHeight * 0.57), // Target (Cadera)
      isLeft: false,
    );
  }

  void _drawTechnicalLine(
    Canvas canvas,
    Paint linePaint,
    Paint dotPaint,
    Offset boxOrigin,
    Offset target, {
    required bool isLeft,
  }) {
    final path = Path();
    path.moveTo(boxOrigin.dx, boxOrigin.dy);

    // Tramo horizontal (Salida técnica de 40px)
    double intermediateX = isLeft ? boxOrigin.dx + 40 : boxOrigin.dx - 40;
    path.lineTo(intermediateX, boxOrigin.dy);

    // Tramo diagonal directo al target
    path.lineTo(target.dx, target.dy);

    canvas.drawPath(path, linePaint);

    // Hotspot (Círculo hueco quirúrgico)
    canvas.drawCircle(target, 5, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
