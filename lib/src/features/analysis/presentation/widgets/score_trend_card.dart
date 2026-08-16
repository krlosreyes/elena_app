// SPEC-300 — Progreso = tendencia (no el estado en vivo de Hoy).
//
// Card "hero" del tab Progreso: la LÍNEA del Score del Día en el rango, con el
// valor actual, el promedio y la tendencia. Es lo que el Dashboard (Hoy) no
// tiene — la historia. Fuente canónica: resolvedDailyScoreSeriesProvider
// (SPEC-219). Toca → detalle de Resultados.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/analysis_series_providers.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';

class ScoreTrendCard extends ConsumerWidget {
  const ScoreTrendCard({super.key});

  static const _accent = AppColors.metabolicGreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final series = ref.watch(resolvedDailyScoreSeriesProvider);

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/analysis/resultados'),
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: series.isEmpty ? _empty() : _content(series),
      ),
    );
  }

  Widget _content(MetricSeries series) {
    final current = series.currentValue!.round();
    final values = series.points.map((p) => p.value).toList();
    final avg = (values.reduce((a, b) => a + b) / values.length).round();
    final delta = series.delta; // last - first
    final hasTrend = delta != null && delta.abs() >= 1;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'SCORE · TU TENDENCIA',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w900,
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.3), size: 20),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$current',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(width: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Text(
                'hoy',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Spacer(),
            if (hasTrend) _trendChip(delta),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Promedio del periodo: $avg',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 78,
          width: double.infinity,
          child: CustomPaint(
            painter: _ScoreLinePainter(
              values: values,
              color: _accent,
            ),
          ),
        ),
      ],
    );
  }

  Widget _trendChip(double delta) {
    final up = delta >= 0;
    final color = up ? _accent : const Color(0xFFEF4444);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(up ? Icons.trending_up_rounded : Icons.trending_down_rounded,
              size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            '${up ? '+' : ''}${delta.round()} en el periodo',
            style: TextStyle(
                color: color, fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }

  Widget _empty() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'SCORE · TU TENDENCIA',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 10,
            letterSpacing: 1.4,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Icon(Icons.show_chart_rounded,
                color: Colors.white.withValues(alpha: 0.35), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Cierra tu día unos días más y aquí verás cómo evoluciona tu '
                'Score en el tiempo.',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.6),
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Línea del Score sobre un dominio fijo 0–100 (el Score ya es 0–100), con
/// relleno tenue debajo y un punto en el último valor. Si solo hay un punto,
/// dibuja el punto centrado.
class _ScoreLinePainter extends CustomPainter {
  final List<double> values;
  final Color color;

  _ScoreLinePainter({required this.values, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    const pad = 4.0;

    double yOf(double v) {
      final t = (v.clamp(0, 100)) / 100.0;
      return h - pad - t * (h - 2 * pad);
    }

    // Línea base tenue (0 del dominio visible).
    final baseline = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, h - pad), Offset(w, h - pad), baseline);

    if (values.isEmpty) return;

    if (values.length == 1) {
      final dot = Paint()..color = color;
      canvas.drawCircle(Offset(w / 2, yOf(values.first)), 4, dot);
      return;
    }

    final n = values.length;
    final dx = w / (n - 1);
    final pts = <Offset>[
      for (var i = 0; i < n; i++) Offset(i * dx, yOf(values[i])),
    ];

    // Relleno bajo la curva.
    final fillPath = Path()..moveTo(pts.first.dx, h - pad);
    for (final p in pts) {
      fillPath.lineTo(p.dx, p.dy);
    }
    fillPath.lineTo(pts.last.dx, h - pad);
    fillPath.close();
    canvas.drawPath(
      fillPath,
      Paint()..color = color.withValues(alpha: 0.10),
    );

    // Línea.
    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final line = Path()..moveTo(pts.first.dx, pts.first.dy);
    for (var i = 1; i < pts.length; i++) {
      line.lineTo(pts[i].dx, pts[i].dy);
    }
    canvas.drawPath(line, linePaint);

    // Punto final.
    canvas.drawCircle(pts.last, 4, Paint()..color = color);
    canvas.drawCircle(
      pts.last,
      4,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  @override
  bool shouldRepaint(covariant _ScoreLinePainter old) =>
      old.values != values || old.color != color;
}
