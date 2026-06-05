// SPEC-168.5.4 (2026-06-03): card de evolución diaria de Nutrición en
// la pantalla de Tendencias. Cada barra representa el % A-dominante
// del bucket; el COLOR de la barra cambia según si dominó A (verde) o
// E (amarillo) ese día.
//
// Separada de BarChartCard general porque la lógica de bicolor por
// barra es específica de este pilar. Reusa el patrón visual del
// hero block y los axis pero pinta su propio painter.

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/analysis/application/chart_hero_computer.dart';
import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/domain/hero_aggregation.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/chart_hero_block.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/chart_tooltip.dart';

class NutritionTrendBarCard extends StatefulWidget {
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
  State<NutritionTrendBarCard> createState() => _NutritionTrendBarCardState();
}

class _NutritionTrendBarCardState extends State<NutritionTrendBarCard> {
  // SPEC-168.7 (2026-06-04): índice de la barra seleccionada por tap.
  int? _selectedIndex;
  Timer? _dismissTimer;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  MetricSeries get series => widget.series;
  AggregationMode get aggregationMode => widget.aggregationMode;
  String get headline => widget.headline;

  static const double _yAxisRightWidth = 36;
  static const double _xAxisHeight = 22;

  void _handleTap(Offset localPos, Size chartSize) {
    final n = series.points.length;
    if (n < 2) return;
    final plotLeft = 0.0;
    final plotRight = chartSize.width - _yAxisRightWidth;
    final plotBottom = chartSize.height - _xAxisHeight;
    if (localPos.dx < plotLeft ||
        localPos.dx > plotRight ||
        localPos.dy < 0 ||
        localPos.dy > plotBottom) {
      setState(() => _selectedIndex = null);
      _dismissTimer?.cancel();
      return;
    }
    final plotWidth = plotRight - plotLeft;
    final slotWidth = plotWidth / n;
    final idx = ((localPos.dx - plotLeft) / slotWidth).floor().clamp(0, n - 1);
    setState(() => _selectedIndex = idx);
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _selectedIndex = null);
    });
  }

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
    return LayoutBuilder(
      builder: (context, c) {
        final size = Size(c.maxWidth, c.maxHeight);
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapUp: (details) => _handleTap(details.localPosition, size),
          child: Stack(
            children: [
              CustomPaint(
                size: Size.infinite,
                painter: _BicolorBarsPainter(
                  series: series,
                  colorA: NutritionTrendBarCard._colorA,
                  colorE: NutritionTrendBarCard._colorE,
                  selectedIndex: _selectedIndex,
                ),
              ),
              if (_selectedIndex != null) _buildTooltipLayer(size),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTooltipLayer(Size chartSize) {
    final idx = _selectedIndex!;
    final point = series.points[idx];
    final plotLeft = 0.0;
    final plotRight = chartSize.width - _yAxisRightWidth;
    final plotBottom = chartSize.height - _xAxisHeight;
    final plotWidth = plotRight - plotLeft;
    final slotWidth = plotWidth / series.points.length;
    final barCenterX = plotLeft + (idx + 0.5) * slotWidth;
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: chartSize.height - plotBottom,
      child: IgnorePointer(
        child: ChartTooltip(
          anchorX: barCenterX,
          plotRight: plotRight,
          unit: '%',
          value: _formatPointValue(point.value),
          dateText: ChartHeroComputer.formatTooltipDate(
              point.weekStart, aggregationMode),
        ),
      ),
    );
  }

  String _formatPointValue(double v) {
    if (v.abs() >= 100) return v.toStringAsFixed(0);
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
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
        _swatch(NutritionTrendBarCard._colorA, 'A-dominante'),
        const SizedBox(width: 18),
        _swatch(NutritionTrendBarCard._colorE, 'E-dominante'),
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
    this.selectedIndex,
  });

  final MetricSeries series;
  final Color colorA;
  final Color colorE;

  /// SPEC-168.7: índice de la barra seleccionada por tap (outline blanco).
  final int? selectedIndex;

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

      // SPEC-168.7: outline blanco sobre la barra seleccionada.
      if (selectedIndex != null && selectedIndex == i) {
        final outlinePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.95);
        canvas.drawRRect(rect.deflate(0.75), outlinePaint);
      }
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
      old.colorE != colorE ||
      old.selectedIndex != selectedIndex;
}
