import 'package:flutter/material.dart';
import 'dart:math' as math;

class EatingWindowPainter extends CustomPainter {
  final DateTime startTime; // Coordenada real de inicio
  final Duration duration;  // Tiempo transcurrido
  final Color indicatorColor;

  EatingWindowPainter({
    required this.startTime,
    required this.duration,
    required this.indicatorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // --- CÁLCULOS PROPORCIONALES SISTEMA ELENA ---
    final double radiusPhases = size.width * 0.38; 
    final double strokeWidthPhases = size.width * 0.05; 
    final double strokeWidthWindow = size.width * 0.025;
    final double indicatorPointRadius = size.width * 0.015;
    final double netGap = size.width * 0.03; 

    final double radiusWindow = radiusPhases - (strokeWidthPhases / 2) - netGap - (strokeWidthWindow / 2);
    final double orbitRadius = (radiusPhases - (strokeWidthPhases / 2)) - (netGap / 2);

    // 1. Anillo de fondo (Estado Anabólico tenue)
    canvas.drawCircle(center, radiusWindow, Paint()
      ..color = Colors.orange.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidthWindow);

    // 2. Hitos de Alimentación (Adaptables)
    _drawEatingMilestones(canvas, center, radiusWindow, size.width);

    // 3. PROGRESO DE LA VENTANA (COORDENADA DINÁMICA)
    final double windowHours = duration.inSeconds / 3600;
    
    // Calculamos el ángulo de inicio basado en la hora del startTime (Radar 24h)
    double startHour = startTime.hour + (startTime.minute / 60.0);
    double startAngle = (startHour * (2 * math.pi / 24)) - (math.pi / 2);
    
    // El barrido (sweep) representa el tiempo que llevas en ventana de comida
    double sweepAngle = (windowHours * (2 * math.pi / 24));

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

    // 4. Punto Indicador de Tiempo Real (Ubicación actual en el ciclo)
    _drawLiveIndicator(canvas, center, orbitRadius, indicatorPointRadius);
  }

  void _drawEatingMilestones(Canvas canvas, Offset center, double radius, double fullWidth) {
    final milestones = {
      0: Icons.restaurant_rounded,    
      12: Icons.timer_off_rounded,    
    };

    final double iconSize = fullWidth * 0.05;
    final double inset = fullWidth * 0.065;

    for (var hour in milestones.keys) {
      double angle = (hour * (2 * math.pi / 24)) - (math.pi / 2);
      
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(milestones[hour]!.codePoint),
          style: TextStyle(
            fontSize: iconSize,
            fontFamily: milestones[hour]!.fontFamily,
            package: milestones[hour]!.fontPackage,
            color: indicatorColor.withOpacity(0.3),
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final iconPos = Offset(
        center.dx + (radius - inset) * math.cos(angle) - tp.width / 2,
        center.dy + (radius - inset) * math.sin(angle) - tp.height / 2,
      );
      tp.paint(canvas, iconPos);
    }
  }

  void _drawLiveIndicator(Canvas canvas, Offset center, double orbitRadius, double pointRadius) {
    final now = DateTime.now();
    double currentHour = now.hour + (now.minute / 60.0);
    double angle = (currentHour * (2 * math.pi / 24)) - (math.pi / 2);
    final pos = Offset(center.dx + orbitRadius * math.cos(angle), center.dy + orbitRadius * math.sin(angle));

    canvas.drawCircle(pos, pointRadius + 3, Paint()
      ..color = const Color(0xFF60A5FA).withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4));

    canvas.drawCircle(pos, pointRadius, Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);

    canvas.drawCircle(pos, pointRadius - 1.5, Paint()
      ..color = const Color(0xFF60A5FA)
      ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant EatingWindowPainter oldDelegate) => 
    oldDelegate.duration != duration || oldDelegate.startTime != startTime;
}