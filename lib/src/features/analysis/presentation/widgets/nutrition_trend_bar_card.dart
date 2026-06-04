// SPEC-168.5.4 (2026-06-03): card de evolución diaria de Nutrición en
// la pantalla de Tendencias. Cada barra representa el % A-dominante
// del bucket; el COLOR de la barra cambia según si dominó A (verde) o
// E (amarillo) ese día.
//
// Separada de BarChartCard general porque la lógica de bicolor por
// barra es específica de este pilar. Reusa el patrón visual del
// hero block y los axis pero pinta su propio painter.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/analysis/application/chart_hero_computer.dart';
import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/domain/hero_aggregation.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/chart_hero_block.dart';

class NutritionTrendBarCard extends StatelessWidget {
  const NutritionTrendBarCard({
    super.key,
    required this.series,
    required this.aggregationMode,
    required this.headline,
  });

  final MetricSeries series;
  final AggregationMode aggregationMode;
  final String headline;

  static const _colorA = Color(0xFF10B981); // verde A-dominante
  static const _colorE = Color(0xFFFBBF24); // amarillo E-dominante

  @override
  Widget build(BuildContext context) {
    final heroValue =
        ChartHeroComputer.aggregateValue(series, HeroAggregation.avg);
    final dateRange =
        ChartHeroComputer.formatDateRange(series, aggregationMode);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: const Color(0xFF0C0C0E),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            headline,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.92),
              fontSize: 17,
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (heroValue != null) ...[
            const SizedBox(height: 18),
            ChartHeroBlock(
              label: 'PROMEDIO',
              value: ChartHeroComputer.formatValue(heroValue),
              unit: '%',
              dateRange: dateRange,
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: _renderChart(),
          ),
          const SizedBox(height: 12),
          _buildLegend(),
        ],
      ),
    );
  }

  Widget _renderChart() {
    if (series.points.isEmpty) {
      return _emptyMessage('Sin datos en este rango.');
    }
    if (series.points.length < 2) {
      return _emptyMessage('Necesitás 2+ semanas para ver tendencia.');
    }
    return CustomPaint(
      size: Size.infinite,
      painter: _BicolorBarsPainter(
        series: series,
        colorA: _colorA,
        colorE: _colorE,
      ),
    );
  }

  Widget _emptyMessage(String msg) {
    return Center(
      child: Text(
        msg,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _swatch(_colorA, 'A-dominante'),
        const SizedBox(width: 18),
        _swatch(_colorE, 'E-dominante'),
      ],
    );
  }

  Widget _swatch(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.65),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _BicolorBarsPainter extends CustomPainter {
  _BicolorBarsPainter({
    required this.series,
    required this.colorA,
    required this.colorE,
  });

  final MetricSeries series;
  final Color colorA;
  final Color colorE;

  /// Umbral de dominancia. ≥ 50 % A → verde; < 50 % → amarillo.
  static const double _dominantThreshold = 50.0;

  static const double _yAxisRightWidth = 36;
  static const double _xAxisHeight = 22;
  static const double _gridPaddingTop = 8;
  static const double _barGap = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final values = series.points.map((p) => p.value).toList();
    const yMin = 0.0;
    const yMax = 100.0; // siempre 0–100% para que el threshold quede claro

    final plotLeft = 0.0;
    final plotTop = _gridPaddingTop;
    final plotRight = size.width - _yAxisRightWidth;
    final plotBottom = size.height - _xAxisHeight;
    final plotHeight = plotBottom - plotTop;
    final plotWidth = plotRight - plotLeft;

    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final ticks = [0.0, 25.0, 50.0, 75.0, 100.0];
    for (final t in ticks) {
      final y = plotBottom - (t - yMin) / (yMax - yMin) * plotHeight;
      canvas.drawLine(
        Offset(plotLeft, y),
        Offset(plotRight, y),
        gridPaint,
      );
      _drawYLabel(canvas, plotRight + 6, y, '${t.toInt()}');
    }

    // Línea de threshold 50 % (separa A de E) — sutil pero visible.
    final thresholdY = plotBottom - (50 - yMin) / (yMax - yMin) * plotHeight;
    final thresholdPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 4.0, gap = 3.0;
    double x = plotLeft;
    while (x < plotRight) {
      final end = math.min(x + dash, plotRight);
      canvas.drawLine(
        Offset(x, thresholdY),
        Offset(end, thresholdY),
        thresholdPaint,
      );
      x += dash + gap;
    }

    final n = values.length;
    final totalGap = _barGap * (n - 1);
    final barWidth = (plotWidth - totalGap) / n;
    final paintA = Paint()..color = colorA;
    final paintE = Paint()..color = colorE;
    for (int i = 0; i < n; i++) {
      final v = values[i].clamp(0.0, yMax);
      final barHeight = (v - yMin) / (yMax - yMin) * plotHeight;
      if (barHeight <= 0) continue;
      final xPos = plotLeft + i * (barWidth + _barGap);
      final y = plotBottom - barHeight;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(xPos, y, barWidth, barHeight),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      final isADominant = values[i] >= _dominantThreshold;
      canvas.drawRRect(rect, isADominant ? paintA : paintE);
    }

    _drawXLabels(canvas, plotLeft, plotBottom, plotWidth, n);
  }

  void _drawYLabel(Canvas canvas, double x, double y, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.40),
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(minWidth: 0, maxWidth: 32);
    tp.paint(canvas, Offset(x, y - tp.height / 2));
  }

  void _drawXLabels(
    Canvas canvas,
    double plotLeft,
    double plotBottom,
    double plotWidth,
    int n,
  ) {
    if (n < 2) return;
    final maxLabels = n >= 6 ? 4 : (n >= 3 ? 3 : 2);
    for (int k = 0; k < maxLabels; k++) {
      final i = ((n - 1) * k / (maxLabels - 1)).round();
      final dt = series.points[i].weekStart;
      final barWidth = (plotWidth - _barGap * (n - 1)) / n;
      final x = plotLeft + i * (barWidth + _barGap) + barWidth / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: _fmtDate(dt),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(x - tp.width / 2, plotBottom + 6));
    }
  }

  static const _monthsShort = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String _fmtDate(DateTime dt) {
    if (series.points.isEmpty) return '';
    final span = series.points.last.weekStart
        .difference(series.points.first.weekStart);
    if (span.inDays > 60) return _monthsShort[dt.month - 1];
    return '${dt.day} ${_monthsShort[dt.month - 1]}';
  }

  @override
  bool shouldRepaint(covariant _BicolorBarsPainter old) =>
      old.series != series ||
      old.colorA != colorA ||
      old.colorE != colorE;
}
