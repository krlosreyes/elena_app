// SPEC-113 + SPEC-118: tendencia del IMR día a día. CustomPaint puro
// para máximo control estético.
//
// Diseño premium (post-SPEC-118):
//   - 4 bandas de zona horizontales (deteriorado/inestable/funcional/
//     óptimo) en el fondo, alpha bajísimo → contexto sin ruido.
//   - Línea promedio horizontal punteada → ancla mental.
//   - Path con curva Bezier suave entre puntos (no líneas rectas
//     dentadas).
//   - Área gradiente bajo la línea → masa visual.
//   - Dots regulares + dot grande con halo para mejor/peor del
//     período. Hoy se distingue con ring outline.
//   - Eje Y con labels 0/25/50/75/100 a la izquierda.
//   - Eje X con 3-5 fechas distribuidas.
//   - Footer compacto: chips Mejor/Peor con fecha.

import 'dart:math' as math;

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
    final stats = _ChartStats.compute(docs);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: título + chip de promedio.
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
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
              const Spacer(),
              if (stats.hasData)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Promedio · ${stats.average}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.65),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          // Plot.
          SizedBox(
            height: 170,
            width: double.infinity,
            child: CustomPaint(
              painter: _ImrTrendPainter(
                docs: docs,
                daysInPeriod: daysInPeriod,
                stats: stats,
                now: DateTime.now(),
              ),
            ),
          ),
          // Footer: chips de mejor / peor día (solo si hay >1 día).
          if (stats.hasData && stats.best != null && stats.worst != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _LegendChip(
                  label: 'Mejor',
                  value: stats.best!.imrScore,
                  date: _humanDate(_parseDate(stats.best!.date)),
                  color: AppColors.metabolicGreen,
                ),
                const SizedBox(width: 10),
                _LegendChip(
                  label: 'Peor',
                  value: stats.worst!.imrScore,
                  date: _humanDate(_parseDate(stats.worst!.date)),
                  color: const Color(0xFFFB923C),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  static DateTime _parseDate(String s) {
    final parts = s.split('-');
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }

  static String _humanDate(DateTime d) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stats precomputadas (avg, best, worst)
// ─────────────────────────────────────────────────────────────────────────────

class _ChartStats {
  final int average;
  final DailySummaryDoc? best;
  final DailySummaryDoc? worst;
  final bool hasData;

  const _ChartStats._({
    required this.average,
    required this.best,
    required this.worst,
    required this.hasData,
  });

  static _ChartStats compute(List<DailySummaryDoc> docs) {
    if (docs.isEmpty) {
      return const _ChartStats._(
        average: 0,
        best: null,
        worst: null,
        hasData: false,
      );
    }
    int sum = 0;
    DailySummaryDoc best = docs.first;
    DailySummaryDoc worst = docs.first;
    for (final d in docs) {
      sum += d.imrScore;
      if (d.imrScore > best.imrScore) best = d;
      if (d.imrScore < worst.imrScore) worst = d;
    }
    final avg = (sum / docs.length).round();
    // Si solo hay 1 día con data, no tiene sentido mostrar "mejor/peor"
    // (sería el mismo doc). Reportamos null para que el footer se oculte.
    final isSingleton = docs.length == 1 || best.date == worst.date;
    return _ChartStats._(
      average: avg,
      best: isSingleton ? null : best,
      worst: isSingleton ? null : worst,
      hasData: true,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip de leyenda (Mejor / Peor)
// ─────────────────────────────────────────────────────────────────────────────

class _LegendChip extends StatelessWidget {
  final String label;
  final int value;
  final String date;
  final Color color;

  const _LegendChip({
    required this.label,
    required this.value,
    required this.date,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '$value · $date',
                    style: TextStyle(
                      color: color,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Painter
// ─────────────────────────────────────────────────────────────────────────────

class _ImrTrendPainter extends CustomPainter {
  final List<DailySummaryDoc> docs;
  final int daysInPeriod;
  final _ChartStats stats;
  final DateTime now;

  _ImrTrendPainter({
    required this.docs,
    required this.daysInPeriod,
    required this.stats,
    required this.now,
  });

  // Zonas de IMR (umbrales 0-100): rojo / naranja / ámbar / verde.
  static const _zoneRed = Color(0xFFFF4444);
  static const _zoneOrange = Color(0xFFFF8C00);
  static const _zoneYellow = Color(0xFFFFD700);
  static const _zoneGreen = Color(0xFF22BB33);

  @override
  void paint(Canvas canvas, Size size) {
    const padLeft = 26.0;
    const padRight = 8.0;
    const padTop = 8.0;
    const padBottom = 22.0;
    final plotW = size.width - padLeft - padRight;
    final plotH = size.height - padTop - padBottom;
    final plotRect = Rect.fromLTWH(padLeft, padTop, plotW, plotH);

    // ── Capa 1: bandas de zona ──────────────────────────────────────────
    _drawZoneBands(canvas, plotRect);

    // ── Capa 2: grid horizontal y eje Y ────────────────────────────────
    _drawYAxis(canvas, plotRect);

    if (!stats.hasData) {
      _drawText(
        canvas,
        'Sin datos del período aún',
        Offset(padLeft + plotW / 2 - 56, padTop + plotH / 2 - 7),
        TextStyle(
          color: Colors.white.withValues(alpha: 0.45),
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      );
      return;
    }

    final today = DateTime(now.year, now.month, now.day);
    final rangeStart = today.subtract(Duration(days: daysInPeriod - 1));

    // Map de doc → punto en pantalla.
    final points = <_PlotPoint>[];
    for (final d in docs) {
      final date = _parseDate(d.date);
      final daysFromStart = date.difference(rangeStart).inDays;
      if (daysFromStart < 0 || daysFromStart >= daysInPeriod) continue;
      final denom = (daysInPeriod - 1).clamp(1, 1000);
      final x = padLeft + plotW * (daysFromStart / denom);
      final y =
          padTop + plotH - plotH * (d.imrScore.clamp(0, 100) / 100);
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;
      points.add(_PlotPoint(
        doc: d,
        offset: Offset(x, y),
        isToday: isToday,
      ));
    }

    // ── Capa 3: línea promedio horizontal punteada ─────────────────────
    final avgY = padTop + plotH - plotH * (stats.average.clamp(0, 100) / 100);
    _drawDashedHorizontal(
      canvas,
      Offset(padLeft, avgY),
      Offset(padLeft + plotW, avgY),
      Colors.white.withValues(alpha: 0.22),
    );

    // ── Capa 4: área gradiente bajo la línea ───────────────────────────
    if (points.length >= 2) {
      _drawAreaGradient(canvas, plotRect, points);
    }

    // ── Capa 5: línea con curva suave ──────────────────────────────────
    if (points.length >= 2) {
      _drawSmoothLine(canvas, points);
    }

    // ── Capa 6: dots ──────────────────────────────────────────────────
    _drawDots(canvas, points);

    // ── Capa 7: eje X con fechas distribuidas ──────────────────────────
    _drawXAxis(canvas, plotRect, rangeStart, today);
  }

  // ── Helpers de dibujo ─────────────────────────────────────────────────

  void _drawZoneBands(Canvas canvas, Rect plot) {
    // Mapear umbrales (40, 60, 75) a Y. Y=0 está arriba.
    double yAt(int pct) =>
        plot.top + plot.height - plot.height * (pct / 100);

    // Banda óptima 75-100 (verde) en el TOP.
    canvas.drawRect(
      Rect.fromLTRB(plot.left, yAt(100), plot.right, yAt(75)),
      Paint()..color = _zoneGreen.withValues(alpha: 0.06),
    );
    // Banda funcional 60-75 (ámbar).
    canvas.drawRect(
      Rect.fromLTRB(plot.left, yAt(75), plot.right, yAt(60)),
      Paint()..color = _zoneYellow.withValues(alpha: 0.04),
    );
    // Banda inestable 40-60 (naranja).
    canvas.drawRect(
      Rect.fromLTRB(plot.left, yAt(60), plot.right, yAt(40)),
      Paint()..color = _zoneOrange.withValues(alpha: 0.04),
    );
    // Banda deteriorado 0-40 (rojo) en el BOTTOM.
    canvas.drawRect(
      Rect.fromLTRB(plot.left, yAt(40), plot.right, yAt(0)),
      Paint()..color = _zoneRed.withValues(alpha: 0.05),
    );
  }

  void _drawYAxis(Canvas canvas, Rect plot) {
    final labelStyle = TextStyle(
      color: Colors.white.withValues(alpha: 0.40),
      fontSize: 9,
      fontWeight: FontWeight.w700,
    );
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..strokeWidth = 1;

    const ticks = [0, 25, 50, 75, 100];
    for (final t in ticks) {
      final y = plot.top + plot.height - plot.height * (t / 100);
      // Línea de grid horizontal.
      canvas.drawLine(
          Offset(plot.left, y), Offset(plot.right, y), gridPaint);
      // Label numérico a la izquierda del plot.
      _drawText(
        canvas,
        '$t',
        Offset(plot.left - 22, y - 5),
        labelStyle,
      );
    }
  }

  void _drawDashedHorizontal(
      Canvas canvas, Offset a, Offset b, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..strokeCap = StrokeCap.round;
    const dash = 4.0;
    const gap = 4.0;
    final total = (b.dx - a.dx).abs();
    double drawn = 0;
    while (drawn < total) {
      final x1 = a.dx + drawn;
      final x2 = a.dx + math.min(drawn + dash, total);
      canvas.drawLine(Offset(x1, a.dy), Offset(x2, a.dy), paint);
      drawn += dash + gap;
    }
  }

  void _drawAreaGradient(
      Canvas canvas, Rect plot, List<_PlotPoint> points) {
    final path = Path();
    path.moveTo(points.first.offset.dx, plot.bottom);
    for (int i = 0; i < points.length; i++) {
      final p = points[i].offset;
      if (i == 0) {
        path.lineTo(p.dx, p.dy);
      } else {
        // Curva suave estilo Bezier (control points en el midpoint).
        final prev = points[i - 1].offset;
        final midX = (prev.dx + p.dx) / 2;
        path.cubicTo(midX, prev.dy, midX, p.dy, p.dx, p.dy);
      }
    }
    path.lineTo(points.last.offset.dx, plot.bottom);
    path.close();

    final gradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        AppColors.metabolicGreen.withValues(alpha: 0.28),
        AppColors.metabolicGreen.withValues(alpha: 0.02),
      ],
    );
    canvas.drawPath(
      path,
      Paint()..shader = gradient.createShader(plot),
    );
  }

  void _drawSmoothLine(Canvas canvas, List<_PlotPoint> points) {
    final paint = Paint()
      ..color = AppColors.metabolicGreen
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(points.first.offset.dx, points.first.offset.dy);
    for (int i = 1; i < points.length; i++) {
      final prev = points[i - 1].offset;
      final p = points[i].offset;
      final midX = (prev.dx + p.dx) / 2;
      // Bezier cúbico con control en midpoints — curva suave.
      path.cubicTo(midX, prev.dy, midX, p.dy, p.dx, p.dy);
    }
    canvas.drawPath(path, paint);
  }

  void _drawDots(Canvas canvas, List<_PlotPoint> points) {
    final regularFill = Paint()..color = AppColors.metabolicGreen;
    final bestDate = stats.best?.date;
    final worstDate = stats.worst?.date;

    for (final p in points) {
      final date = p.doc.date;
      final isBest = bestDate != null && date == bestDate;
      final isWorst = worstDate != null && date == worstDate;
      final isToday = p.isToday;

      if (isBest) {
        // Halo verde grande.
        canvas.drawCircle(
          p.offset,
          7,
          Paint()
            ..color = AppColors.metabolicGreen.withValues(alpha: 0.25),
        );
        canvas.drawCircle(p.offset, 4.5, regularFill);
      } else if (isWorst) {
        // Halo naranja grande.
        canvas.drawCircle(
          p.offset,
          7,
          Paint()
            ..color = const Color(0xFFFB923C).withValues(alpha: 0.30),
        );
        canvas.drawCircle(
          p.offset,
          4.5,
          Paint()..color = const Color(0xFFFB923C),
        );
      } else if (isToday) {
        // Ring outline para hoy.
        canvas.drawCircle(p.offset, 5, Paint()..color = const Color(0xFF1E293B));
        canvas.drawCircle(
          p.offset,
          5,
          Paint()
            ..color = AppColors.metabolicGreen
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
      } else {
        canvas.drawCircle(p.offset, 3, regularFill);
      }
    }
  }

  void _drawXAxis(
      Canvas canvas, Rect plot, DateTime rangeStart, DateTime today) {
    final style = TextStyle(
      color: Colors.white.withValues(alpha: 0.45),
      fontSize: 9,
      fontWeight: FontWeight.w700,
    );

    // Cantidad de ticks según largo del período.
    final int ticksCount = daysInPeriod <= 7 ? 4 : (daysInPeriod <= 30 ? 5 : 5);
    for (int i = 0; i < ticksCount; i++) {
      final ratio = i / (ticksCount - 1);
      final daysOffset =
          (ratio * (daysInPeriod - 1)).round().clamp(0, daysInPeriod - 1);
      final date = rangeStart.add(Duration(days: daysOffset));
      final x = plot.left + plot.width * (daysOffset / (daysInPeriod - 1).clamp(1, 1000));
      _drawText(
        canvas,
        _shortDate(date),
        Offset(x - 16, plot.bottom + 6),
        style,
      );
    }
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
      old.docs != docs ||
      old.daysInPeriod != daysInPeriod ||
      old.stats.average != stats.average;
}

// Punto en el plot (doc + posición en pantalla + flag de hoy).
class _PlotPoint {
  final DailySummaryDoc doc;
  final Offset offset;
  final bool isToday;
  _PlotPoint({
    required this.doc,
    required this.offset,
    required this.isToday,
  });
}
