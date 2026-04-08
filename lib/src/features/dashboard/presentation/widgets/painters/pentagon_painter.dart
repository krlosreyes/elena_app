import 'dart:math';
import 'package:flutter/material.dart';

class PentagonItem {
  final String label;
  final double value;
  final IconData icon;
  final Color color;
  PentagonItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });
}

class PentagonDataPainter extends CustomPainter {
  final List<PentagonItem> items;
  PentagonDataPainter({required this.items});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.width / 4.0;
    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.05)
      ..style = PaintingStyle.stroke;
    final paintData = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.12)
      ..style = PaintingStyle.fill;
    final paintOutline = Paint()
      ..color = const Color(0xFF00E676).withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, radius * (i / 4), paintGrid);
    }

    final dataPoints = <Offset>[];
    for (int i = 0; i < 5; i++) {
      final angle = (i * 72 - 90) * pi / 180;
      final valPercent = items[i].value / 100;
      final dx = center.dx + radius * valPercent * cos(angle);
      final dy = center.dy + radius * valPercent * sin(angle);
      
      canvas.drawLine(
        center, 
        Offset(center.dx + radius * cos(angle), center.dy + radius * sin(angle)), 
        paintGrid
      );
      
      dataPoints.add(Offset(dx, dy));
      _drawDataItem(canvas, center, radius + 58, angle, items[i]);
    }

    if (dataPoints.length == 5) {
      canvas.drawPath(Path()..addPolygon(dataPoints, true), paintData);
      canvas.drawPath(Path()..addPolygon(dataPoints, true), paintOutline);
    }
  }

  void _drawDataItem(Canvas canvas, Offset center, double dist, double angle, PentagonItem item) {
    final x = center.dx + dist * cos(angle);
    final y = center.dy + dist * sin(angle);

    final tpIcon = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(item.icon.codePoint),
        style: TextStyle(
          color: Colors.white24,
          fontSize: 24,
          fontFamily: item.icon.fontFamily,
          package: item.icon.fontPackage,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpIcon.paint(canvas, Offset(x - tpIcon.width / 2, y - 32));

    final tpVal = TextPainter(
      text: TextSpan(
        text: item.value.toInt().toString(),
        style: TextStyle(
          color: item.color,
          fontSize: 22,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpVal.paint(canvas, Offset(x - tpVal.width / 2, y - 4));

    final tpLab = TextPainter(
      text: TextSpan(
        text: item.label,
        style: const TextStyle(
          color: Colors.white24,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tpLab.paint(canvas, Offset(x - tpLab.width / 2, y + 24));
  }

  @override
  bool shouldRepaint(covariant PentagonDataPainter oldDelegate) {
    if (items.length != oldDelegate.items.length) return true;
    for (int i = 0; i < items.length; i++) {
      if (items[i].value != oldDelegate.items[i].value || 
          items[i].color != oldDelegate.items[i].color) {
        return true;
      }
    }
    return false;
  }
}