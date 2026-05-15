// SPEC-113: línea de tendencia del IMR día a día. CustomPaint puro
// — sin librerías externas para mantener control de estética.
//
// Inputs:
//   - docs: lista ordenada ascendente por fecha (puede tener gaps).
//   - daysInPeriod: cuántos días cubre el eje X.
//
// Renderea N puntos (uno por día con data) unidos por línea. Días
// sin data generan gap (no se dibuja línea entre los puntos
// adyacentes). El mejor día se destaca con dot grande + label.
//
// NOTA: este widget reemplaza el uso del antiguo TrendChart en la
// pantalla Análisis. El TrendChart genérico (data/label/color) sigue
// vivo en `trend_chart.dart` para uso de `progress_screen.dart`.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/data/daily_summary_doc.dart';

class ImrTrendChart extends StatelessWidget {
  final List<DailySummaryDoc> docs;
  final int daysInPeriod;

  const ImrTrendChart({
    super.key,
    required this.docs,
    required this.daysInPeriod,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IMR DÍA A DÍA',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 140,
            width: double.infinity,
            child: CustomPaint(
              painter: _ImrTrendPainter(
                docs: docs,
                daysInPeriod: daysInPeriod,
                now: DateTime.now(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ImrTrendPainter extends CustomPainter {
  final List<DailySummaryDoc> docs;
  final int daysInPeriod;
  final DateTime now;

  _ImrTrendPainter({
    required this.docs,
    required this.daysInPeriod,
    required this.now,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const padLeft = 18.0;
    const padRight = 6.0;
    const padTop = 6.0;
    const padBottom = 18.0;
    final plotW = size.width - padLeft - padRight;
    final plotH = size.height - padTop - padBottom;

    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.35),
      fontSize: 9,
      fontWeight: FontWeight.w600,
    );

    // Grid horizontal.
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    for (int i = 0; i <= 4; i++) {
      final y = padTop + plotH * (i / 4);
      canvas.drawLine(
          Offset(padLeft, y), Offset(padLeft + plotW, y), gridPaint);
    }

    // Etiquetas Y (100 / 50 / 0).
    _drawText(canvas, '100', const Offset(0, padTop - 4), labelStyle);
    _drawText(canvas, '50', Offset(2, padTop + plotH / 2 - 4), labelStyle);
    _drawText(canvas, '0', Offset(4, padTop + plotH - 4), labelStyle);

    if (docs.isEmpty) {
      _drawText(
        canvas,
        'Sin datos aún',
        Offset(size.width / 2 - 36, size.height / 2 - 6),
        labelStyle.copyWith(fontSize: 11),
      );
      return;
    }

    final today = DateTime(now.year, now.month, now.day);
    final rangeStart = today.subtract(Duration(days: daysInPeriod - 1));

    final points = <Offset>[];
    int? bestImr;
    Offset? bestPt;
    for (final d in docs) {
      final date = _parseDate(d.date);
      final daysFromStart = date.difference(rangeStart).inDays;
      if (daysFromStart < 0 || daysFromStart >= daysInPeriod) continue;
      final denom = (daysInPeriod - 1).clamp(1, 1000);
      final x = padLeft + plotW * (daysFromStart / denom);
      final y = padTop + plotH - plotH * (d.imrScore.clamp(0, 100) / 100);
      points.add(Offset(x, y));
      if (bestImr == null || d.imrScore > bestImr) {
        bestImr = d.imrScore;
        bestPt = Offset(x, y);
      }
    }

    // Línea.
    if (points.length >= 2) {
      final linePaint = Paint()
        ..color = AppColors.metabolicGreen
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (int i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      canvas.drawPath(path, linePaint);
    }

    // Dots regulares.
    final dotPaint = Paint()
      ..color = AppColors.metabolicGreen
      ..style = PaintingStyle.fill;
    for (final p in points) {
      canvas.drawCircle(p, 2.8, dotPaint);
    }

    // Dot grande para el mejor día.
    if (bestPt != null) {
      canvas.drawCircle(
        bestPt,
        6,
        Paint()..color = AppColors.metabolicGreen.withValues(alpha: 0.25),
      );
      canvas.drawCircle(bestPt, 4, dotPaint);
      _drawText(
        canvas,
        'Mejor: $bestImr',
        Offset(bestPt.dx - 22, (bestPt.dy - 18).clamp(0, size.height)),
        TextStyle(
          color: AppColors.metabolicGreen,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      );
    }

    // Etiquetas X: primer día y hoy.
    final tickStyle = labelStyle.copyWith(fontSize: 9);
    _drawText(canvas, _shortDate(rangeStart),
        Offset(padLeft, padTop + plotH + 4), tickStyle);
    _drawText(canvas, _shortDate(today),
        Offset(padLeft + plotW - 32, padTop + plotH + 4), tickStyle);
  }

  static DateTime _parseDate(String s) {
    try {
      final parts = s.split('-');
      return DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
    } catch (_) {
      return DateTime.fromMillisecondsSinceEpoch(0);
    }
  }

  static String _shortDate(DateTime d) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }

  static void _drawText(
      Canvas canvas, String text, Offset offset, TextStyle style) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, offset);
  }

  @override
  bool shouldRepaint(covariant _ImrTrendPainter old) =>
      old.docs != docs || old.daysInPeriod != daysInPeriod;
}
