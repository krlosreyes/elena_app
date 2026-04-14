import 'package:flutter/material.dart';
import 'dart:math' as math;

class FastingRingPainter extends CustomPainter {
  final DateTime startTime; // Coordenada de inicio real (0h)
  final Duration duration;  // Longitud del arco de progreso
  final Color phaseColor;   // Color de la fase biológica actual
  final Color indicatorColor; // Color de contraste (azul Elena)

  FastingRingPainter({
    required this.startTime,
    required this.duration,
    required this.phaseColor,
    required this.indicatorColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // --- MEDIDAS PROPORCIONALES SISTEMA ELENA (Calibración de Hardware) ---
    final double radiusPhases = size.width * 0.38; 
    final double strokeWidthPhases = size.width * 0.05; 
    final double strokeWidthFasting = size.width * 0.035; // Aro de ayuno un poco más robusto
    final double indicatorPointRadius = size.width * 0.015;
    final double netGap = size.width * 0.03; 

    final double radiusFasting = radiusPhases - (strokeWidthPhases / 2) - netGap - (strokeWidthFasting / 2);
    final double orbitRadius = (radiusPhases - (strokeWidthPhases / 2)) - (netGap / 2);

    // 1. Anillo de fondo (Soporte visual técnico)
    canvas.drawCircle(center, radiusFasting, Paint()
      ..color = indicatorColor.withOpacity(0.05)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidthFasting);

    // --- CÁLCULO DE COORDENADAS BASE ---
    // Convertimos el startTime a ángulo en el reloj de 24h
    double startHour = startTime.hour + (startTime.minute / 60.0);
    double startAngle = (startHour * (2 * math.pi / 24)) - (math.pi / 2);

    // 2. HITOS DINÁMICOS (Adaptados al inicio, ubicados EN EL INTERIOR)
    _drawFastingMilestones(canvas, center, radiusFasting, size.width, startAngle, strokeWidthFasting);

    // 3. PROGRESO DE AYUNO (Arco reactivo)
    final double fastingHours = duration.inSeconds / 3600;
    double sweepAngle = (fastingHours * (2 * math.pi / 24));

    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radiusFasting),
        startAngle,
        sweepAngle.clamp(0.0, math.pi * 2), // Límite de 24h para el arco
        false,
        Paint()
          ..color = phaseColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidthFasting,
      );
    }

    // 4. Punto Indicador de Tiempo Real (Manecilla azul)
    _drawLiveIndicator(canvas, center, orbitRadius, indicatorPointRadius);
  }

  void _drawFastingMilestones(Canvas canvas, Offset center, double radius, double fullWidth, double startAngle, double fastingStrokeWidth) {
    // Definimos los Checkpoints metabólicos del sistema ElenaApp
    final milestones = {
      12: Icons.water_drop_outlined,              // Descenso de Insulina (12h)
      18: Icons.local_fire_department_rounded,    // Quema de Grasa (18h)
      24: Icons.published_with_changes_rounded,    // Autofagia (24h)
    };

    // CALIBRACIÓN DE TAMAÑO COHERENTE
    // Iconos más grandes y robustos para que sean el "Target" visual
    final double iconSize = fullWidth * 0.06; // Tamaño robusto (6% del ancho total)
    
    // DISTANCIA INTERNA: Los movemos hacia ADENTRO del aro
    // Calculamos la distancia restando el ancho del trazo y un gap de seguridad
    final double internalDistance = radius - (fastingStrokeWidth / 2) - (fullWidth * 0.045);

    for (var milestoneHour in milestones.keys) {
      // CALIBRACIÓN DINÁMICA:
      // Calculamos el ángulo sumando las horas del hito al ángulo de inicio
      double milestoneAngle = startAngle + (milestoneHour * (2 * math.pi / 24));
      
      // Posición del punto de control SOBRE el aro (como referencia)
      final dotPos = Offset(
        center.dx + radius * math.cos(milestoneAngle), 
        center.dy + radius * math.sin(milestoneAngle)
      );
      
      // Dibujamos el "Checkpoint" sobre el aro
      canvas.drawCircle(dotPos, 2.5, Paint()
        ..color = indicatorColor.withOpacity(0.6)
        ..style = PaintingStyle.fill);

      // Dibujamos el icono descriptivo del hito (INTERNO y ROBUSTO)
      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(milestones[milestoneHour]!.codePoint),
          style: TextStyle(
            fontSize: iconSize, 
            fontFamily: milestones[milestoneHour]!.fontFamily,
            package: milestones[milestoneHour]!.fontPackage,
            color: indicatorColor.withOpacity(0.4), // Sutil pero visible
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      // Posicionamos el icono en la coordenada interna calculada
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
  bool shouldRepaint(FastingRingPainter oldDelegate) =>
      oldDelegate.duration != duration ||
      oldDelegate.startTime != startTime ||
      oldDelegate.phaseColor != phaseColor;
}