import 'package:flutter/material.dart';
import 'dart:math' as math;

class FastingRingPainter extends CustomPainter {
  final DateTime startTime; // Coordenada de inicio real (Hito en el tiempo)
  final Duration duration; // Diferencia real: DateTime.now() - startTime
  final Color phaseColor; // Color de la fase biológica actual
  final Color indicatorColor; // Color de contraste (azul Elena)

  /// UI #3 (motion A): 0..1 que hace "respirar" el glow de la punta viva.
  /// 0 = glow base estático (reduce-motion); oscila 0..1 cuando hay motion.
  final double pulse;

  FastingRingPainter({
    required this.startTime,
    required this.duration,
    required this.phaseColor,
    required this.indicatorColor,
    this.pulse = 0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // --- MEDIDAS PROPORCIONALES SISTEMA ELENA ---
    final double radiusPhases = size.width * 0.38;
    final double strokeWidthPhases = size.width * 0.05;
    final double strokeWidthFasting = size.width * 0.035;
    final double indicatorPointRadius = size.width * 0.015;
    final double netGap = size.width * 0.03;

    final double radiusFasting = radiusPhases -
        (strokeWidthPhases / 2) -
        netGap -
        (strokeWidthFasting / 2);
    final double orbitRadius =
        (radiusPhases - (strokeWidthPhases / 2)) - (netGap / 2);

    // 1. Anillo de fondo (Soporte visual técnico)
    canvas.drawCircle(
        center,
        radiusFasting,
        Paint()
          ..color = indicatorColor.withValues(alpha: 0.05)
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidthFasting);

    // --- CÁLCULO DE COORDENADAS CIRCADIANAS (VIAJE EN EL TIEMPO) ---
    // En Flutter, -pi/2 es el "Norte" (12:00 AM en nuestro reloj de 24h)
    // 24 horas = 2*pi radianes. 1 hora = pi/12 radianes.

    double startHour = startTime.hour +
        (startTime.minute / 60.0) +
        (startTime.second / 3600.0);
    double startAngle = (startHour * (math.pi / 12)) - (math.pi / 2);

    // 2. HITOS DINÁMICOS (Checkpoint Metabólicos)
    _drawFastingMilestones(canvas, center, radiusFasting, size.width,
        startAngle, strokeWidthFasting);

    // 3. PROGRESO DE AYUNO (Arco reactivo)
    // Calculamos las horas totales transcurridas desde el startTime hasta el presente
    final double fastingHours = duration.inSeconds / 3600.0;

    // El sweepAngle debe representar cuánto espacio del círculo de 24h ocupa la duración
    double sweepAngle = (fastingHours * (math.pi / 12));

    if (sweepAngle > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radiusFasting),
        startAngle,
        sweepAngle.clamp(
            0.0, math.pi * 2), // Límite de un ciclo completo de 24h
        false,
        Paint()
          ..color = phaseColor
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..strokeWidth = strokeWidthFasting,
      );
    }

    // 4. Punto Indicador de Tiempo Real (Ubicación actual en el reloj de 24h)
    _drawLiveIndicator(canvas, center, orbitRadius, indicatorPointRadius);
  }

  void _drawFastingMilestones(Canvas canvas, Offset center, double radius,
      double fullWidth, double startAngle, double fastingStrokeWidth) {
    final milestones = {
      12: Icons.water_drop_outlined, // Descenso de Insulina (12h)
      18: Icons.local_fire_department_rounded, // Quema de Grasa (18h)
      24: Icons.published_with_changes_rounded, // Autofagia (24h)
    };

    final double iconSize = fullWidth * 0.05;
    final double internalDistance =
        radius - (fastingStrokeWidth / 2) - (fullWidth * 0.045);

    for (var milestoneHour in milestones.keys) {
      // El hito se posiciona sumando sus horas al ángulo de inicio del ayuno
      double milestoneAngle = startAngle + (milestoneHour * (math.pi / 12));

      final dotPos = Offset(center.dx + radius * math.cos(milestoneAngle),
          center.dy + radius * math.sin(milestoneAngle));

      canvas.drawCircle(
          dotPos,
          2.0,
          Paint()
            ..color = indicatorColor.withValues(alpha: 0.3)
            ..style = PaintingStyle.fill);

      final tp = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(milestones[milestoneHour]!.codePoint),
          style: TextStyle(
            fontSize: iconSize,
            fontFamily: milestones[milestoneHour]!.fontFamily,
            package: milestones[milestoneHour]!.fontPackage,
            color: indicatorColor.withValues(alpha: 0.3),
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

  void _drawLiveIndicator(
      Canvas canvas, Offset center, double orbitRadius, double pointRadius) {
    final now = DateTime.now();
    double currentHour = now.hour + (now.minute / 60.0);
    double angle = (currentHour * (math.pi / 12)) - (math.pi / 2);
    final pos = Offset(center.dx + orbitRadius * math.cos(angle),
        center.dy + orbitRadius * math.sin(angle));

    // UI #3 (motion A): el halo "respira" con `pulse` — radio y opacidad
    // oscilan suavemente para dar sensación de vivo en tiempo real.
    canvas.drawCircle(
        pos,
        pointRadius + 3 + pulse * 4,
        Paint()
          ..color =
              const Color(0xFF60A5FA).withValues(alpha: 0.16 + pulse * 0.18)
          ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 + pulse * 3));

    canvas.drawCircle(
        pos,
        pointRadius,
        Paint()
          ..color = indicatorColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2);

    canvas.drawCircle(
        pos,
        pointRadius - 1.5,
        Paint()
          ..color = const Color(0xFF60A5FA)
          ..style = PaintingStyle.fill);
  }

  // Siempre repinta: el indicador "vivo" depende de DateTime.now() y del
  // `pulse`. El costo es bajo (un solo painter pequeño) y el AnimatedBuilder
  // controla la frecuencia de repaint.
  @override
  bool shouldRepaint(FastingRingPainter oldDelegate) => true;
}
