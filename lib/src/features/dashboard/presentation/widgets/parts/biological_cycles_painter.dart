import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:elena_app/src/core/rules/circadian_rules.dart';
import 'package:elena_app/src/core/theme/circadian_theme.dart';

class BiologicalCyclesPainter extends CustomPainter {
  final Color indicatorColor;
  final DateTime currentTime; 

  BiologicalCyclesPainter({
    required this.indicatorColor,
    required this.currentTime,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // --- MEDIDAS PROPORCIONALES ---
    final double radiusPhases = size.width * 0.38; // Coincide con Fasting/Eating Painters
    final double strokeWidthPhases = size.width * 0.05;
    final rectPhases = Rect.fromCircle(center: center, radius: radiusPhases);

    // 1. Marcas horarias
    _drawHourMarkers(canvas, center, radiusPhases, size.width);

    // 2. Fases Biológicas Dinámicas
    for (var phase in CircadianRules.allPhases) {
      final bool isActive = CircadianRules.isPhaseActive(phase, currentTime);
      
      final Color displayColor = isActive 
          ? CircadianTheme.getColorForPhase(phase.label) 
          : Colors.grey.withOpacity(0.15); // Un poco más tenue para Android

      _drawPhase(
        canvas, 
        rectPhases, 
        phase.startHour, 
        phase.endHour, 
        displayColor, 
        phase.label, 
        strokeWidthPhases,
        isActive,
        size.width,
      );
    }
  }

  void _drawHourMarkers(Canvas canvas, Offset center, double radius, double fullWidth) {
    final paint = Paint()
      ..color = indicatorColor.withOpacity(0.3)
      ..strokeWidth = 1.2;

    // Distancias proporcionales
    final double markerStart = radius + (fullWidth * 0.05);
    final double markerEndBase = radius + (fullWidth * 0.08);
    final double textDistance = radius + (fullWidth * 0.13);

    for (int i = 0; i < 24; i++) {
      double angle = (i * (2 * math.pi / 24)) - (math.pi / 2);
      bool isMajor = i % 6 == 0;
      
      double end = isMajor ? markerEndBase + 5 : markerEndBase;
      
      canvas.drawLine(
        Offset(center.dx + markerStart * math.cos(angle), center.dy + markerStart * math.sin(angle)),
        Offset(center.dx + end * math.cos(angle), center.dy + end * math.sin(angle)),
        paint,
      );

      if (isMajor) {
        final tp = TextPainter(
          text: TextSpan(
            text: i.toString().padLeft(2, '0'),
            style: TextStyle(
              color: indicatorColor.withOpacity(0.6),
              fontSize: fullWidth * 0.028, // Fuente proporcional
              fontWeight: FontWeight.bold,
              fontFamily: 'monospace',
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        
        tp.paint(canvas, Offset(
          center.dx + textDistance * math.cos(angle) - tp.width / 2,
          center.dy + textDistance * math.sin(angle) - tp.height / 2,
        ));
      }
    }
  }

  void _drawPhase(Canvas canvas, Rect rect, double startH, double endH, Color color, String label, double strokeWidth, bool isActive, double fullWidth) {
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

    // Texto de la fase adaptable
    final tp = TextPainter(
      text: TextSpan(
        text: label.toUpperCase(), 
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey.withOpacity(0.4), 
          fontSize: fullWidth * 0.018, // Fuente proporcional
          fontWeight: isActive ? FontWeight.w900 : FontWeight.w400,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    canvas.save();
    canvas.translate(rect.center.dx, rect.center.dy);
    double midAngle = startAngle + (sweepAngle / 2);
    canvas.rotate(midAngle + math.pi / 2);
    double checkAngle = (midAngle + math.pi / 2) % (2 * math.pi);
    
    // El offset de los textos ahora depende del radio dinámico del rect
    double textRadiusOffset = rect.width / 2;

    if (checkAngle > math.pi / 2 && checkAngle < 3 * math.pi / 2) {
      canvas.rotate(math.pi);
      tp.paint(canvas, Offset(-tp.width / 2, textRadiusOffset - (tp.height / 2)));
    } else {
      tp.paint(canvas, Offset(-tp.width / 2, -textRadiusOffset - (tp.height / 2)));
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant BiologicalCyclesPainter oldDelegate) {
    return oldDelegate.currentTime.minute != currentTime.minute || 
           oldDelegate.currentTime.hour != currentTime.hour;
  }
}