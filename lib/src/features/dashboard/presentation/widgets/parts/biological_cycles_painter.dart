import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:elena_app/src/core/rules/circadian_rules.dart';

class BiologicalCyclesPainter extends CustomPainter {
  final Color indicatorColor;
  final DateTime currentTime; // Necesario para determinar la fase activa

  BiologicalCyclesPainter({
    required this.indicatorColor,
    required this.currentTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final double radiusPhases = size.width / 2 - 55;
    final rectPhases = Rect.fromCircle(center: center, radius: radiusPhases);
    const double strokeWidthPhases = 22.0;

    // 1. Marcas horarias
    _drawHourMarkers(canvas, center, radiusPhases);

    // 2. Fases Biológicas Dinámicas
    // Iteramos sobre la lista maestra de CircadianRules
    for (var phase in CircadianRules.allPhases) {
      final bool isActive = CircadianRules.isPhaseActive(phase, currentTime);
      
      // Si está activa, usamos su color original. 
      // Si no, usamos un gris con opacidad baja para el efecto "apagado".
      final Color displayColor = isActive 
          ? phase.activeColor 
          : Colors.grey.withOpacity(0.2);

      _drawPhase(
        canvas, 
        rectPhases, 
        phase.startHour, 
        phase.endHour, 
        displayColor, 
        phase.label, 
        strokeWidthPhases,
        isActive, // Pasamos el estado para ajustar el texto
      );
    }
  }

  void _drawHourMarkers(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = indicatorColor.withOpacity(0.4)
      ..strokeWidth = 1.5;

    for (int i = 0; i < 24; i++) {
      double angle = (i * (2 * math.pi / 24)) - (math.pi / 2);
      bool isMajor = i % 6 == 0;
      double start = radius + 30;
      double end = radius + (isMajor ? 45 : 35);
      canvas.drawLine(
        Offset(center.dx + start * math.cos(angle), center.dy + start * math.sin(angle)),
        Offset(center.dx + end * math.cos(angle), center.dy + end * math.sin(angle)),
        paint,
      );
      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(
            text: i.toString().padLeft(2, '0'),
            style: TextStyle(
              color: indicatorColor.withOpacity(0.8),
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(canvas, Offset(
          center.dx + (end + 15) * math.cos(angle) - tp.width / 2,
          center.dy + (end + 15) * math.sin(angle) - tp.height / 2,
        ));
      }
    }
  }

  // Refactorizado para aceptar double (horas decimales) y el flag isActive
  void _drawPhase(Canvas canvas, Rect rect, double startH, double endH, Color color, String label, double strokeWidth, bool isActive) {
    double startHour = startH;
    double endHour = endH;
    if (endHour <= startHour) endHour += 24;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    double startAngle = (startHour * (2 * math.pi / 24)) - (math.pi / 2);
    double sweepAngle = (endHour - startHour) * (2 * math.pi / 24);

    canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

    // El texto también se atenúa si la fase no está activa
    final tp = TextPainter(
      text: TextSpan(
        text: label, 
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey.withOpacity(0.5), 
          fontSize: 8, 
          fontWeight: isActive ? FontWeight.w900 : FontWeight.w400,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    double midAngle = startAngle + (sweepAngle / 2);
    canvas.rotate(midAngle + math.pi / 2);
    double checkAngle = (midAngle + math.pi / 2) % (2 * math.pi);
    if (checkAngle > math.pi / 2 && checkAngle < 3 * math.pi / 2) {
      canvas.rotate(math.pi);
      tp.paint(canvas, Offset(-tp.width / 2, (rect.width / 2) - (tp.height / 2)));
    } else {
      tp.paint(canvas, Offset(-tp.width / 2, -(rect.width / 2) - (tp.height / 2)));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BiologicalCyclesPainter oldDelegate) {
    // Solo repintamos si cambió la hora (minuto a minuto es suficiente)
    return oldDelegate.currentTime.minute != currentTime.minute || 
           oldDelegate.currentTime.hour != currentTime.hour;
  }
}