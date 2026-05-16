// SPEC-112: celda individual del grid del calendario mensual.
// Renderea el número del día encima de un mini-anillo de IMR.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

class CalendarDayCell extends StatelessWidget {
  /// Número del día (1..31). null si la celda es un padding antes
  /// del primer día del mes.
  final int? dayNumber;

  /// IMR del día (0..100). null si no hay data persistida.
  final int? imrScore;

  /// True si es el día actual.
  final bool isToday;

  /// True si la fecha cae en el futuro (sin datos posibles aún).
  final bool isFuture;

  const CalendarDayCell({
    super.key,
    this.dayNumber,
    this.imrScore,
    this.isToday = false,
    this.isFuture = false,
  });

  @override
  Widget build(BuildContext context) {
    if (dayNumber == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
      child: AspectRatio(
        aspectRatio: 1,
        child: CustomPaint(
          painter: _CalendarRingPainter(
            progress: imrScore != null ? (imrScore!.clamp(0, 100) / 100.0) : 0,
            isToday: isToday,
            isFuture: isFuture,
            hasData: imrScore != null,
          ),
          child: Center(
            child: Text(
              '$dayNumber',
              style: TextStyle(
                color: isToday
                    ? Colors.white
                    : Colors.white.withValues(
                        alpha: isFuture ? 0.25 : 0.75,
                      ),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CalendarRingPainter extends CustomPainter {
  final double progress;
  final bool isToday;
  final bool isFuture;
  final bool hasData;

  _CalendarRingPainter({
    required this.progress,
    required this.isToday,
    required this.isFuture,
    required this.hasData,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final stroke = size.width * 0.10;
    final radius = (size.width / 2) - (stroke / 2) - 1;

    // Halo si es el día actual.
    if (isToday) {
      canvas.drawCircle(
        center,
        radius + 1,
        Paint()
          ..color = AppColors.metabolicGreen.withValues(alpha: 0.18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    // Track.
    final trackPaint = Paint()
      ..color = Colors.white.withValues(
        alpha: isFuture ? 0.05 : (hasData ? 0.12 : 0.08),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, trackPaint);

    // Arco de progreso solo si hay data.
    if (hasData && progress > 0) {
      final color = isToday
          ? AppColors.metabolicGreen
          : AppColors.metabolicGreen.withValues(alpha: 0.85);
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * progress,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CalendarRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isToday != isToday ||
      oldDelegate.isFuture != isFuture ||
      oldDelegate.hasData != hasData;
}
