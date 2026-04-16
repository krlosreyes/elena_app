import 'package:flutter/material.dart';
import 'dart:math' as math;

class EatingWindowPainter extends CustomPainter {
  final DateTime startTime; 
  final Duration duration;  
  final Color indicatorColor;
  final int mealsCount;     
  final int targetWindowHours; 

  EatingWindowPainter({
    required this.startTime,
    required this.duration,
    required this.indicatorColor,
    this.mealsCount = 3, 
    this.targetWindowHours = 8,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // --- CALIBRACIÓN DE HARDWARE VISUAL (PROPORCIÓN EQUILIBRADA) ---
    final double radiusPhases = size.width * 0.38; 
    final double strokeWidthPhases = size.width * 0.05; 
    final double strokeWidthWindow = size.width * 0.03; 
    final double indicatorPointRadius = size.width * 0.015;
    final double netGap = size.width * 0.03; 

    final double radiusWindow = radiusPhases - (strokeWidthPhases / 2) - netGap - (strokeWidthWindow / 2);
    final double orbitRadius = (radiusPhases - (strokeWidthPhases / 2)) - (netGap / 2);

    // 1. Fondo del anillo
    canvas.drawCircle(center, radiusWindow, Paint()
      ..color = Colors.orange.withOpacity(0.06)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidthWindow);

    // --- GEOMETRÍA CIRCADIANA ---
    double startHour = startTime.hour + (startTime.minute / 60.0) + (startTime.second / 3600.0);
    double startAngle = (startHour * (math.pi / 12)) - (math.pi / 2);

    // 2. HITOS NUTRICIONALES (TAMAÑO REFINADO)
    _drawNutritionalMilestones(canvas, center, radiusWindow, size.width, startAngle);

    // 3. PROGRESO DE LA VENTANA
    final double windowHours = duration.inSeconds / 3600.0;
    double sweepAngle = (windowHours * (math.pi / 12));

    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radiusWindow),
        startAngle,
        sweepAngle.clamp(0.0, math.pi * 2),
        false,
        Paint()
          ..color = Colors.orangeAccent
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidthWindow,
      );
    }

    // 4. Indicador de tiempo real
    _drawLiveIndicator(canvas, center, orbitRadius, indicatorPointRadius);
  }

  void _drawNutritionalMilestones(Canvas canvas, Offset center, double radius, double fullWidth, double startAngle) {
    final double intervalHours = targetWindowHours / (mealsCount - 1);
    
    // TAMAÑO REFINADO: 5.5% para bordes, 4.5% para intermedios
    final double mainIconSize = fullWidth * 0.055; 
    final double secondaryIconSize = fullWidth * 0.045;
    
    // Posicionamiento interno
    final double internalDistance = radius - (fullWidth * 0.075);

    for (int i = 0; i < mealsCount; i++) {
      double milestoneHourOffset = i * intervalHours;
      double milestoneAngle = startAngle + (milestoneHourOffset * (math.pi / 12));

      final dotPos = Offset(
        center.dx + radius * math.cos(milestoneAngle),
        center.dy + radius * math.sin(milestoneAngle)
      );

      bool isEdge = (i == 0 || i == mealsCount - 1);
      
      // Halo sutil
      canvas.drawCircle(dotPos, fullWidth * 0.015, Paint()
        ..color = Colors.orange.withOpacity(0.15)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

      // Punto del hito
      canvas.drawCircle(dotPos, isEdge ? 4.0 : 2.5, Paint()
        ..color = isEdge ? Colors.orange : Colors.orange.withOpacity(0.5));

      // Selección de iconos
      IconData iconData;
      if (i == 0) {
        iconData = Icons.restaurant_rounded;
      } else if (i == mealsCount - 1) {
        iconData = Icons.bedtime_rounded;
      } else {
        iconData = Icons.lunch_dining_rounded;
      }

      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(iconData.codePoint),
          style: TextStyle(
            fontSize: isEdge ? mainIconSize : secondaryIconSize,
            fontFamily: iconData.fontFamily,
            package: iconData.fontPackage,
            color: isEdge ? Colors.orangeAccent.withOpacity(0.8) : Colors.orangeAccent.withOpacity(0.3),
            shadows: isEdge ? [
              Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 2, offset: const Offset(0.5, 0.5))
            ] : null,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final iconPos = Offset(
        center.dx + internalDistance * math.cos(milestoneAngle) - tp.width / 2,
        center.dy + internalDistance * math.sin(milestoneAngle) - tp.height / 2,
      );
      
      tp.paint(canvas, iconPos);
    }
  }

  void _drawLiveIndicator(Canvas canvas, Offset center, double orbitRadius, double pointRadius) {
    final now = DateTime.now();
    double currentHour = now.hour + (now.minute / 60.0);
    double angle = (currentHour * (math.pi / 12)) - (math.pi / 2);
    final pos = Offset(center.dx + orbitRadius * math.cos(angle), center.dy + orbitRadius * math.sin(angle));

    canvas.drawCircle(pos, pointRadius + 2, Paint()
      ..color = const Color(0xFF60A5FA).withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    canvas.drawCircle(pos, pointRadius, Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    canvas.drawCircle(pos, pointRadius - 1.2, Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant EatingWindowPainter oldDelegate) => true;
}