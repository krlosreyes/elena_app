import 'package:flutter/material.dart';
import 'dart:math' as math;

class FastingRingPainter extends CustomPainter {
  final double fastingProgress;
  final Color phaseColor;
  final Color indicatorColor;

  FastingRingPainter({
    required this.fastingProgress,
    required this.phaseColor,
    required this.indicatorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final double radiusPhases = size.width / 2 - 55;
    const double strokeWidthPhases = 22.0;
    const double strokeWidthFasting = 10.0;
    const double indicatorPointRadius = 6.0;
    const double netGap = 12.0; 

    final double radiusFasting = radiusPhases - (strokeWidthPhases / 2) - netGap - (strokeWidthFasting / 2);
    final double orbitRadius = (radiusPhases - (strokeWidthPhases / 2)) - (netGap / 2);

    // 1. Anillo de fondo (estático)
    canvas.drawCircle(center, radiusFasting, Paint()
      ..color = indicatorColor.withOpacity(0.05) // Opacidad baja para no ensuciar
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidthFasting);

    // 2. Hitos del Ayuno (Iconografía técnica RESALTADA)
    _drawFastingMilestones(canvas, center, radiusFasting);

    // 3. Progreso de ayuno (Dinámico)
    if (fastingProgress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radiusFasting),
        -math.pi / 2,
        math.pi * 2 * fastingProgress,
        false,
        Paint()
          ..color = phaseColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidthFasting,
      );
    }

    // 4. Punto Indicador de Tiempo Real
    _drawLiveIndicator(canvas, center, orbitRadius, indicatorPointRadius);
  }

  void _drawFastingMilestones(Canvas canvas, Offset center, double radius) {
    // Definimos los hitos metabólicos reales de Metamorfosis Real
    final milestones = {
      12: Icons.water_drop_outlined, // Descenso de Insulina (Gota)
      18: Icons.whatshot_rounded,    // Quema de Grasa (Fuego)
      24: Icons.published_with_changes_rounded, // Autofagia (Reciclaje)
    };

    for (var hour in milestones.keys) {
      // El anillo representa un ciclo completo para el progreso
      double angle = (hour * (2 * math.pi / 24)) - (math.pi / 2);
      
      // Marca visual técnica sobre el anillo
      final pos = Offset(center.dx + radius * math.cos(angle), center.dy + radius * math.sin(angle));
      
      canvas.drawCircle(pos, 2, Paint()
        ..color = indicatorColor.withOpacity(0.5)
        ..style = PaintingStyle.fill);

      // Renderizado del icono con NUEVAS MEDIDAS
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(milestones[hour]!.codePoint),
          style: TextStyle(
            fontSize: 20.0, // AUMENTO COHERENTE DE TAMAÑO
            fontFamily: milestones[hour]!.fontFamily,
            package: milestones[hour]!.fontPackage,
            color: Colors.white, // CAMBIO DE COLOR A BLANCO (MÁXIMO CONTRASTE)
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Desplazamiento hacia el interior ajustado para iconos más grandes
      final iconPos = Offset(
        center.dx + (radius - 22) * math.cos(angle) - tp.width / 2,
        center.dy + (radius - 22) * math.sin(angle) - tp.height / 2,
      );
      
      tp.paint(canvas, iconPos);
    }
  }

  void _drawLiveIndicator(Canvas canvas, Offset center, double orbitRadius, double pointRadius) {
    final now = DateTime.now();
    double currentHour = now.hour + (now.minute / 60.0);
    double angle = (currentHour * (2 * math.pi / 24)) - (math.pi / 2);
    final pos = Offset(center.dx + orbitRadius * math.cos(angle), center.dy + orbitRadius * math.sin(angle));

    // Glow suave
    canvas.drawCircle(pos, pointRadius + 2, Paint()
      ..color = Colors.blueAccent.withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3));

    // Borde (Contacto visual)
    canvas.drawCircle(pos, pointRadius, Paint()
      ..color = indicatorColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);

    // Centro (Giro dinámico)
    canvas.drawCircle(pos, pointRadius - 2, Paint()
      ..color = Colors.blueAccent
      ..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(FastingRingPainter oldDelegate) =>
      oldDelegate.fastingProgress != fastingProgress ||
      oldDelegate.phaseColor != phaseColor;
}