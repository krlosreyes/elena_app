// SPEC-95: pinta la ventana de alimentación a partir de DateTimes
// explícitos (`windowStart`, `windowEnd`, `now`), no de datos del
// FastingState que mezcla ayuno y ventana.
//
// Capas dibujadas:
// 1. Anillo de fondo (track tenue).
// 2. Arco completo de la ventana planeada (alpha 0.20).
// 3. Arco de progreso real si `now ∈ [windowStart, windowEnd]`.
// 4. Hitos nutricionales distribuidos entre windowStart y windowEnd.
// 5. Indicador "now" en el orbit exterior.

import 'package:flutter/material.dart';
import 'dart:math' as math;

class EatingWindowPainter extends CustomPainter {
  /// Hora a la que abrió (o abrirá) la ventana de comida.
  final DateTime windowStart;

  /// Hora a la que cierra (o cerró) la ventana.
  final DateTime windowEnd;

  /// Instante actual (inyectado para que el painter sea determinista
  /// en tests / hot-reload).
  final DateTime now;

  /// Color de contraste para el indicador "now".
  final Color indicatorColor;

  /// Número de hitos nutricionales (comidas) a distribuir entre
  /// windowStart y windowEnd.
  final int mealsCount;

  EatingWindowPainter({
    required this.windowStart,
    required this.windowEnd,
    required this.now,
    required this.indicatorColor,
    this.mealsCount = 3,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // --- Geometría base ---
    final double radiusPhases = size.width * 0.38;
    final double strokeWidthPhases = size.width * 0.05;
    final double strokeWidthWindow = size.width * 0.03;
    final double indicatorPointRadius = size.width * 0.015;
    final double netGap = size.width * 0.03;

    final double radiusWindow =
        radiusPhases - (strokeWidthPhases / 2) - netGap - (strokeWidthWindow / 2);
    final double orbitRadius =
        (radiusPhases - (strokeWidthPhases / 2)) - (netGap / 2);

    // --- 1. Track de fondo (anillo completo, muy tenue) ---
    canvas.drawCircle(
      center,
      radiusWindow,
      Paint()
        ..color = Colors.orange.withValues(alpha: 0.06)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidthWindow,
    );

    // --- Ángulos en el reloj de 24h ---
    // Norte (-pi/2) = 00:00. Cada hora = pi/12.
    final double startAngle = _hourToAngle(windowStart);
    final double endAngle = _hourToAngle(windowEnd);
    double windowSweep = endAngle - startAngle;
    if (windowSweep <= 0) windowSweep += 2 * math.pi;

    // --- 2. Arco completo de la ventana PLANEADA (tenue) ---
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radiusWindow),
      startAngle,
      windowSweep.clamp(0.0, math.pi * 2),
      false,
      Paint()
        ..color = Colors.orangeAccent.withValues(alpha: 0.20)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeWidth = strokeWidthWindow,
    );

    // --- 3. Arco de PROGRESO real (saturado) ---
    final bool nowAfterStart = !now.isBefore(windowStart);
    final bool nowBeforeEnd = now.isBefore(windowEnd);

    if (nowAfterStart) {
      // Cuánto va de la ventana: desde windowStart hasta min(now, windowEnd).
      final DateTime progressEnd = nowBeforeEnd ? now : windowEnd;
      final double progressSweep =
          _hoursBetween(windowStart, progressEnd) * (math.pi / 12);

      if (progressSweep > 0) {
        // Color: naranja saturado si dentro de ventana, rojizo si ya
        // cerró (señala que debería iniciar ayuno).
        final Color arcColor = nowBeforeEnd
            ? Colors.orangeAccent
            : const Color(0xFFEF4444); // rojo suave indicando "ventana cerrada"

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radiusWindow),
          startAngle,
          progressSweep.clamp(0.0, math.pi * 2),
          false,
          Paint()
            ..color = arcColor
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = strokeWidthWindow,
        );
      }
    }

    // --- 4. Hitos nutricionales distribuidos en la ventana real ---
    _drawNutritionalMilestones(
      canvas,
      center,
      radiusWindow,
      size.width,
      startAngle,
      windowSweep,
    );

    // --- 5. Indicador de tiempo real ---
    _drawLiveIndicator(canvas, center, orbitRadius, indicatorPointRadius);
  }

  /// Convierte un DateTime en un ángulo del reloj de 24h (norte = 00:00).
  static double _hourToAngle(DateTime t) {
    final double hour = t.hour + (t.minute / 60.0) + (t.second / 3600.0);
    return (hour * (math.pi / 12)) - (math.pi / 2);
  }

  /// Horas (con decimales) entre dos DateTimes.
  static double _hoursBetween(DateTime a, DateTime b) {
    return b.difference(a).inSeconds / 3600.0;
  }

  void _drawNutritionalMilestones(
    Canvas canvas,
    Offset center,
    double radius,
    double fullWidth,
    double startAngle,
    double windowSweep,
  ) {
    if (mealsCount < 1) return;

    // Si hay solo 1 comida, se centra en windowStart. Si hay >=2, se
    // distribuyen en partes iguales entre windowStart y windowEnd.
    final int slots = mealsCount > 1 ? (mealsCount - 1) : 1;
    final double intervalAngle = windowSweep / slots;

    final double mainIconSize = fullWidth * 0.055;
    final double secondaryIconSize = fullWidth * 0.045;
    final double internalDistance = radius - (fullWidth * 0.075);

    for (int i = 0; i < mealsCount; i++) {
      final double milestoneAngle = startAngle + (intervalAngle * i);

      final dotPos = Offset(
        center.dx + radius * math.cos(milestoneAngle),
        center.dy + radius * math.sin(milestoneAngle),
      );

      final bool isEdge = (i == 0 || i == mealsCount - 1);

      // Halo
      canvas.drawCircle(
        dotPos,
        fullWidth * 0.015,
        Paint()
          ..color = Colors.orange.withValues(alpha: 0.15)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Punto
      canvas.drawCircle(
        dotPos,
        isEdge ? 4.0 : 2.5,
        Paint()
          ..color = isEdge
              ? Colors.orange
              : Colors.orange.withValues(alpha: 0.5),
      );

      // Ícono según posición
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
            color: isEdge
                ? Colors.orangeAccent.withValues(alpha: 0.8)
                : Colors.orangeAccent.withValues(alpha: 0.3),
            shadows: isEdge
                ? [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 2,
                      offset: const Offset(0.5, 0.5),
                    )
                  ]
                : null,
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
    Canvas canvas,
    Offset center,
    double orbitRadius,
    double pointRadius,
  ) {
    final double currentHour = now.hour + (now.minute / 60.0);
    final double angle = (currentHour * (math.pi / 12)) - (math.pi / 2);
    final pos = Offset(
      center.dx + orbitRadius * math.cos(angle),
      center.dy + orbitRadius * math.sin(angle),
    );

    canvas.drawCircle(
      pos,
      pointRadius + 2,
      Paint()
        ..color = const Color(0xFF60A5FA).withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    canvas.drawCircle(
      pos,
      pointRadius,
      Paint()
        ..color = indicatorColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    canvas.drawCircle(
      pos,
      pointRadius - 1.2,
      Paint()
        ..color = const Color(0xFF60A5FA)
        ..style = PaintingStyle.fill,
    );
  }

  @override
  bool shouldRepaint(covariant EatingWindowPainter oldDelegate) {
    return oldDelegate.windowStart != windowStart ||
        oldDelegate.windowEnd != windowEnd ||
        oldDelegate.now != now ||
        oldDelegate.mealsCount != mealsCount;
  }
}
