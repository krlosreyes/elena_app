import 'package:flutter/material.dart';

class BlueprintGrid extends StatelessWidget {
  final Widget child;
  const BlueprintGrid({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _GridPainter(),
      child: child,
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // FONDOS OSCURO ABSOLUTO (Garantiza modo oscuro siempre)
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFF0B0B0B));

    final dotPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;

    const spacing = 20.0;
    for (double x = 0; x < size.width; x += spacing) {
      for (double y = 0; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 1.0, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
