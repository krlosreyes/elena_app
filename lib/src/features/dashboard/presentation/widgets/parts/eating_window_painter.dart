import 'package:flutter/material.dart';
import 'dart:math' as math;

class EatingWindowPainter extends CustomPainter {
  final double windowProgress; // Progreso de la ventana (ej: 0.0 a 1.0)
  final Color indicatorColor;

  EatingWindowPainter({
    required this.windowProgress,
    required this.indicatorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Mantenemos la misma matemática de radios para que el cambio de widget sea fluido
    final double radiusPhases = size.width / 2 - 55;
    const double strokeWidthPhases = 22.0;
    const double strokeWidthWindow = 10.0;
    const double indicatorPointRadius = 6.0;
    const double netGap = 12.0; 

    final double radiusWindow = radiusPhases - (strokeWidthPhases / 2) - netGap - (strokeWidthWindow / 2);
    final double orbitRadius = (radiusPhases - (strokeWidthPhases / 2)) - (netGap / 2);

    // 1. Anillo de fondo (Naranja muy tenue: Estado Anabólico)
    canvas.drawCircle(center, radiusWindow, Paint()
      ..color = Colors.orange.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidthWindow);

    // 2. Hitos de Alimentación (Resaltados en Blanco para coherencia)
    _drawEatingMilestones(canvas, center, radiusWindow);

    // 3. Progreso de la Ventana
    if (windowProgress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radiusWindow),
        -math.pi / 2,
        math.pi * 2 * windowProgress,
        false,
        Paint()
          ..color = Colors.orangeAccent
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidthWindow,
      );
    }

    // 4. Punto Indicador de Tiempo Real (Sincronizado con el ciclo circadiano)
    _drawLiveIndicator(canvas, center, orbitRadius, indicatorPointRadius);
  }

  void _drawEatingMilestones(Canvas canvas, Offset center, double radius) {
    final milestones = {
      0: Icons.restaurant_rounded,    // Inicio: Carga nutricional
      12: Icons.timer_off_rounded,    // Fin: Preparación para restauración
    };

    for (var hour in milestones.keys) {
      double angle = (hour * (2 * math.pi / 24)) - (math.pi / 2);
      
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(milestones[hour]!.codePoint),
          style: TextStyle(
            fontSize: 22.0,
            fontFamily: milestones[hour]!.fontFamily,
            package: milestones[hour]!.fontPackage,
            color: Colors.white.withOpacity(0.8), // Blanco para máximo contraste
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      final iconPos = Offset(
        center.dx + (radius - 24) * math.cos(angle) - tp.width / 2,
        center.dy + (radius - 24) * math.sin(angle) - tp.height / 2,
      );
      tp.paint(canvas, iconPos);
    }
  }

  void _drawLiveIndicator(Canvas canvas, Offset center, double orbitRadius, double pointRadius) {
    final now = DateTime.now();
    double currentHour = now.hour + (now.minute / 60.0);
    double angle = (currentHour * (2 * math.pi / 24)) - (math.pi / 2);
    final pos = Offset(center.dx + orbitRadius * math.cos(angle), center.dy + orbitRadius * math.sin(angle));

    // Glow azul (Indicador de "Estás aquí")
    canvas.drawCircle(pos, pointRadius + 2, Paint()
      ..color = Colors.blueAccent.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    canvas.drawCircle(pos, pointRadius, Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    canvas.drawCircle(pos, pointRadius - 2, Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(covariant EatingWindowPainter oldDelegate) => 
    oldDelegate.windowProgress != windowProgress;
}