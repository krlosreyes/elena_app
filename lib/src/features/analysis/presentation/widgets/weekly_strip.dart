// SPEC-110: strip semanal de 7 días con un micro-anillo IMR por día.
//
// MVP: solo el día actual usa data real (`summary`). Los otros 6
// aparecen como placeholders en gris hasta que SPEC-111 introduzca
// persistencia diaria de DailySummary.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/domain/daily_summary.dart';

class WeeklyStrip extends StatelessWidget {
  final DailySummary todaySummary;

  /// `DateTime.now()` por defecto; testeable inyectando otro.
  final DateTime now;

  WeeklyStrip({
    super.key,
    required this.todaySummary,
    DateTime? now,
  }) : now = now ?? DateTime.now();

  static const _labels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  @override
  Widget build(BuildContext context) {
    // Calculamos el lunes de esta semana.
    final today = DateTime(now.year, now.month, now.day);
    final monday = today.subtract(Duration(days: today.weekday - 1));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(7, (i) {
          final date = monday.add(Duration(days: i));
          final isToday = date.year == today.year &&
              date.month == today.month &&
              date.day == today.day;
          final isFuture = date.isAfter(today);
          return _DayCell(
            label: _labels[i],
            dayNumber: date.day,
            isToday: isToday,
            isFuture: isFuture,
            imrScore: isToday ? todaySummary.imrScore : 0,
          );
        }),
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  final String label;
  final int dayNumber;
  final bool isToday;
  final bool isFuture;
  final int imrScore;

  const _DayCell({
    required this.label,
    required this.dayNumber,
    required this.isToday,
    required this.isFuture,
    required this.imrScore,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = isToday
        ? AppColors.metabolicGreen
        : Colors.white.withValues(alpha: 0.18);
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: isToday ? 0.85 : 0.40),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: 36,
          height: 36,
          child: CustomPaint(
            painter: _MicroRingPainter(
              progress: isToday ? imrScore / 100 : 0,
              color: activeColor,
              isFuture: isFuture,
            ),
            child: Center(
              child: Text(
                '$dayNumber',
                style: TextStyle(
                  color: Colors.white.withValues(
                    alpha: isToday ? 1.0 : (isFuture ? 0.25 : 0.5),
                  ),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MicroRingPainter extends CustomPainter {
  final double progress;
  final Color color;
  final bool isFuture;

  _MicroRingPainter({
    required this.progress,
    required this.color,
    required this.isFuture,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 2.5;
    final stroke = 2.5;

    final trackPaint = Paint()
      ..color = Colors.white.withValues(alpha: isFuture ? 0.06 : 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0) return;
    final p = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      p,
    );
  }

  @override
  bool shouldRepaint(covariant _MicroRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.isFuture != isFuture;
}
