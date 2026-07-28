// SPEC-163: card de gráfico de línea estilo Apple Fitness.
//
// Para OUTCOMES continuos (IMR, Peso). Línea sin gradient, grid
// horizontal sutil, eje Y con ticks, eje X con labels temporales.

import 'dart:async';

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/analysis/application/chart_hero_computer.dart';
import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/domain/hero_aggregation.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/chart_card_header.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/chart_hero_block.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/chart_tooltip.dart';

class LineChartCard extends StatefulWidget {
  const LineChartCard({
    super.key,
    required this.series,
    required this.accent,
    required this.periodLabel,
    required this.headline,
    required this.aggregationMode,
    this.deltaIsBetterIf = 'up',
    this.heroAggregation = HeroAggregation.avg,
    this.heroUnit,
    this.targetValue,
    this.targetLabel,
  });

  final MetricSeries series;
  final Color accent;
  final String periodLabel;
  final String headline;
  final String deltaIsBetterIf;

  /// SPEC-168.1: agregación del bloque hero arriba del chart.
  final HeroAggregation heroAggregation;

  /// SPEC-168.1: unit override (null usa `series.unit`).
  final String? heroUnit;

  /// SPEC-168.1: necesario para formatear la fecha-range del hero.
  final AggregationMode aggregationMode;

  /// SPEC-168.2 (2026-06-03): valor del objetivo del usuario en la
  /// unidad del chart. Null = sin línea dashed.
  final double? targetValue;

  /// SPEC-168.2: label "Objetivo X".
  final String? targetLabel;

  @override
  State<LineChartCard> createState() => _LineChartCardState();
}

class _LineChartCardState extends State<LineChartCard> {
  // SPEC-168.7 (2026-06-04): índice del punto seleccionado por tap.
  int? _selectedIndex;
  Timer? _dismissTimer;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  MetricSeries get series => widget.series;
  Color get accent => widget.accent;
  String get periodLabel => widget.periodLabel;
  String get headline => widget.headline;
  HeroAggregation get heroAggregation => widget.heroAggregation;
  String? get heroUnit => widget.heroUnit;
  AggregationMode get aggregationMode => widget.aggregationMode;
  double? get targetValue => widget.targetValue;
  String? get targetLabel => widget.targetLabel;
  String get deltaIsBetterIf => widget.deltaIsBetterIf;

  // Geometría duplicada del painter para mantener tap y render alineados.
  static const double _yAxisRightWidth = 36;
  static const double _xAxisHeight = 22;

  /// Devuelve la x (en pixels del chart) donde se planta el punto `i`.
  double _xOf(int i, double plotLeft, double plotWidth) {
    final n = series.points.length;
    if (n == 1) return plotLeft + plotWidth / 2;
    return plotLeft + (i / (n - 1)) * plotWidth;
  }

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
    // Encontrar el punto más cercano por distancia en x.
    final plotWidth = plotRight - plotLeft;
    var bestIdx = 0;
    var bestDist = double.infinity;
    for (int i = 0; i < n; i++) {
      final dx = (_xOf(i, plotLeft, plotWidth) - localPos.dx).abs();
      if (dx < bestDist) {
        bestDist = dx;
        bestIdx = i;
      }
    }
    setState(() => _selectedIndex = bestIdx);
    _dismissTimer?.cancel();
    _dismissTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _selectedIndex = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final heroValue = ChartHeroComputer.aggregateValue(series, heroAggregation);
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
          ChartCardHeader(
            headline: headline,
            periodLabel: periodLabel,
            delta: series.delta,
            deltaUnit: series.unit,
            deltaIsBetterIf: deltaIsBetterIf,
          ),
          if (heroValue != null) ...[
            const SizedBox(height: 18),
            ChartHeroBlock(
              label: labelForHeroAggregation(heroAggregation),
              value: ChartHeroComputer.formatValue(heroValue),
              unit: heroUnit ?? series.unit,
              dateRange: dateRange,
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            height: 170,
            child: _renderChart(),
          ),
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
                painter: _LinePainter(
                  series: series,
                  accent: accent,
                  targetValue: targetValue,
                  targetLabel: targetLabel,
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
    final anchorX = _xOf(idx, plotLeft, plotWidth);
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: chartSize.height - plotBottom,
      child: IgnorePointer(
        child: ChartTooltip(
          anchorX: anchorX,
          plotRight: plotRight,
          unit: heroUnit ?? series.unit,
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
}

class _LinePainter extends CustomPainter {
  _LinePainter({
    required this.series,
    required this.accent,
    this.targetValue,
    this.targetLabel,
    this.selectedIndex,
  });

  final MetricSeries series;
  final Color accent;

  /// SPEC-168.2: nivel del objetivo en la unidad del chart.
  final double? targetValue;

  /// SPEC-168.2: label "Objetivo X" para mostrar junto a la línea.
  final String? targetLabel;

  /// SPEC-168.7 (2026-06-04): índice del punto seleccionado por tap.
  /// Si != null, se pinta un marker grande (anillo blanco + dot accent)
  /// sobre ese punto.
  final int? selectedIndex;

  // SPEC-168.1 (2026-06-03): eje Y movido al lado derecho del plot
  // (patrón Apple Health/Fitness). Coherente con BarChartCard.
  static const double _yAxisRightWidth = 36;
  static const double _xAxisHeight = 22;
  static const double _gridPaddingTop = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final values = series.points.map((p) => p.value).toList();
    var minV = values.reduce((a, b) => a < b ? a : b);
    var maxV = values.reduce((a, b) => a > b ? a : b);

    // SPEC-168.2: si el target del usuario está fuera del rango
    // observado, expandimos el eje Y para que la línea dashed siempre
    // quede dentro del plot.
    if (targetValue != null) {
      if (targetValue! < minV) minV = targetValue!;
      if (targetValue! > maxV) maxV = targetValue!;
    }

    // Eje Y dinámico con padding del 10% del rango.
    final range = (maxV - minV).abs();
    final padding = range > 0 ? range * 0.10 : (maxV.abs() * 0.10 + 1);
    final yMin = _floorToNice(minV - padding);
    final yMax = _ceilToNice(maxV + padding);
    final yRange = (yMax - yMin) == 0 ? 1.0 : (yMax - yMin);

    // SPEC-168.1: plot ocupa x=0 a x=width-_yAxisRightWidth.
    final plotLeft = 0.0;
    final plotTop = _gridPaddingTop;
    final plotRight = size.width - _yAxisRightWidth;
    final plotBottom = size.height - _xAxisHeight;
    final plotHeight = plotBottom - plotTop;
    final plotWidth = plotRight - plotLeft;

    // Grid + labels Y (lado derecho).
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final ticks = _generateYTicks(yMin, yMax);
    for (final t in ticks) {
      final y = plotBottom - (t - yMin) / yRange * plotHeight;
      canvas.drawLine(Offset(plotLeft, y), Offset(plotRight, y), gridPaint);
      _drawYLabel(canvas, plotRight + 6, y, _fmtTick(t));
    }

    // Línea + punto final.
    double xOf(int i) {
      if (values.length == 1) return plotLeft + plotWidth / 2;
      return plotLeft + (i / (values.length - 1)) * plotWidth;
    }

    double yOf(double v) => plotBottom - (v - yMin) / yRange * plotHeight;

    final path = Path();
    for (int i = 0; i < values.length; i++) {
      final x = xOf(i);
      final y = yOf(values[i]);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    final linePaint = Paint()
      ..color = accent
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, linePaint);

    final lastX = xOf(values.length - 1);
    final lastY = yOf(values.last);
    canvas.drawCircle(Offset(lastX, lastY), 4.0, Paint()..color = accent);
    canvas.drawCircle(
      Offset(lastX, lastY),
      7.0,
      Paint()..color = accent.withValues(alpha: 0.25),
    );

    // SPEC-168.7: marker del punto seleccionado por tap. Va encima del
    // dot final si coinciden — anillo blanco para que el ojo aterrice.
    if (selectedIndex != null &&
        selectedIndex! >= 0 &&
        selectedIndex! < values.length) {
      final selX = xOf(selectedIndex!);
      final selY = yOf(values[selectedIndex!]);
      canvas.drawCircle(
        Offset(selX, selY),
        6.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..color = Colors.white.withValues(alpha: 0.95),
      );
      canvas.drawCircle(Offset(selX, selY), 3.0, Paint()..color = accent);
    }

    // SPEC-168.2: línea dashed del objetivo (encima de la grid, debajo
    // de la línea principal sería visualmente confuso — la pintamos
    // sobre la línea de datos a alpha bajo para que se diferencie).
    if (targetValue != null) {
      _drawTargetLine(
        canvas,
        plotLeft: plotLeft,
        plotRight: plotRight,
        plotBottom: plotBottom,
        plotHeight: plotHeight,
        yMin: yMin,
        yRange: yRange,
        target: targetValue!,
      );
    }

    // Eje X.
    _drawXLabels(canvas, plotLeft, plotBottom, plotWidth, values.length);
  }

  /// SPEC-168.2: dashed horizontal line del objetivo + label.
  void _drawTargetLine(
    Canvas canvas, {
    required double plotLeft,
    required double plotRight,
    required double plotBottom,
    required double plotHeight,
    required double yMin,
    required double yRange,
    required double target,
  }) {
    final y = plotBottom - (target - yMin) / yRange * plotHeight;
    if (y < 0 || y > plotBottom) return; // fuera del plot, no pintamos.

    final paint = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dash = 4.0, gap = 3.0;
    double x = plotLeft;
    while (x < plotRight) {
      final end = (x + dash) > plotRight ? plotRight : (x + dash);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }

    final labelText = targetLabel != null
        ? 'Objetivo ${targetLabel!}'
        : 'Objetivo ${_fmtTick(target)}';
    final tp = TextPainter(
      text: TextSpan(
        text: labelText,
        style: TextStyle(
          color: accent.withValues(alpha: 0.85),
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    final labelX = plotRight - tp.width - 6;
    final adjustedY = (y - tp.height - 2) < 0 ? y + 2 : (y - tp.height - 2);
    tp.paint(canvas, Offset(labelX, adjustedY));
  }

  void _drawYLabel(Canvas canvas, double x, double y, String text) {
    // SPEC-168.1: labels a la derecha del axis, alineados a la izquierda.
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
      textAlign: TextAlign.left,
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
      final x = plotLeft + (i / (n - 1)) * plotWidth;
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
      tp.paint(
        canvas,
        Offset(x - tp.width / 2, plotBottom + 6),
      );
    }
  }

  static const _monthsShort = [
    'ene',
    'feb',
    'mar',
    'abr',
    'may',
    'jun',
    'jul',
    'ago',
    'sep',
    'oct',
    'nov',
    'dic',
  ];

  String _fmtDate(DateTime dt) {
    if (series.points.isEmpty) return '';
    final span =
        series.points.last.weekStart.difference(series.points.first.weekStart);
    if (span.inDays > 60) {
      return _monthsShort[dt.month - 1];
    }
    return '${dt.day} ${_monthsShort[dt.month - 1]}';
  }

  List<double> _generateYTicks(double yMin, double yMax) {
    final range = yMax - yMin;
    final step = _niceStep(range / 3);
    final start = (yMin / step).floor() * step;
    final ticks = <double>[];
    for (double v = start; v <= yMax + 0.0001; v += step) {
      if (v >= yMin - 0.001) ticks.add(v);
    }
    return ticks;
  }

  double _niceStep(double rough) {
    if (rough <= 0) return 1;
    final magnitude = _magnitudeOf(rough);
    final normalized = rough / magnitude;
    double nice;
    if (normalized < 1.5) {
      nice = 1;
    } else if (normalized < 3) {
      nice = 2;
    } else if (normalized < 7) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * magnitude;
  }

  double _magnitudeOf(double v) {
    if (v <= 0) return 1;
    double m = 1;
    if (v >= 1) {
      while (v / m >= 10) {
        m *= 10;
      }
    } else {
      while (v / m < 1) {
        m /= 10;
      }
    }
    return m;
  }

  double _floorToNice(double v) {
    final step = _niceStep((v.abs()).clamp(0.1, double.maxFinite) / 3);
    return (v / step).floor() * step;
  }

  double _ceilToNice(double v) {
    final step = _niceStep((v.abs()).clamp(0.1, double.maxFinite) / 3);
    return (v / step).ceil() * step;
  }

  String _fmtTick(double v) {
    if (v.abs() >= 100) return v.toStringAsFixed(0);
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(covariant _LinePainter old) =>
      old.series != series ||
      old.accent != accent ||
      old.selectedIndex != selectedIndex ||
      old.targetValue != targetValue;
}
