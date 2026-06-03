// SPEC-163: card de gráfico de línea estilo Apple Fitness.
//
// Para OUTCOMES continuos (IMR, Peso). Línea sin gradient, grid
// horizontal sutil, eje Y con ticks, eje X con labels temporales.

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/chart_card_header.dart';

class LineChartCard extends StatelessWidget {
  const LineChartCard({
    super.key,
    required this.series,
    required this.accent,
    required this.periodLabel,
    required this.headline,
    this.deltaIsBetterIf = 'up',
  });

  final MetricSeries series;
  final Color accent;
  final String periodLabel;
  final String headline;
  final String deltaIsBetterIf;

  @override
  Widget build(BuildContext context) {
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
          const SizedBox(height: 22),
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
    return CustomPaint(
      size: Size.infinite,
      painter: _LinePainter(series: series, accent: accent),
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
}

class _LinePainter extends CustomPainter {
  _LinePainter({required this.series, required this.accent});

  final MetricSeries series;
  final Color accent;

  static const double _yAxisWidth = 32;
  static const double _xAxisHeight = 22;
  static const double _gridPaddingTop = 12;

  @override
  void paint(Canvas canvas, Size size) {
    final values = series.points.map((p) => p.value).toList();
    final minV = values.reduce((a, b) => a < b ? a : b);
    final maxV = values.reduce((a, b) => a > b ? a : b);

    // Eje Y dinámico con padding del 10% del rango.
    final range = (maxV - minV).abs();
    final padding = range > 0 ? range * 0.10 : (maxV.abs() * 0.10 + 1);
    final yMin = _floorToNice(minV - padding);
    final yMax = _ceilToNice(maxV + padding);
    final yRange = (yMax - yMin) == 0 ? 1.0 : (yMax - yMin);

    final plotLeft = _yAxisWidth;
    final plotTop = _gridPaddingTop;
    final plotRight = size.width;
    final plotBottom = size.height - _xAxisHeight;
    final plotHeight = plotBottom - plotTop;
    final plotWidth = plotRight - plotLeft;

    // Grid + labels Y.
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final ticks = _generateYTicks(yMin, yMax);
    for (final t in ticks) {
      final y = plotBottom - (t - yMin) / yRange * plotHeight;
      canvas.drawLine(Offset(plotLeft, y), Offset(plotRight, y), gridPaint);
      _drawYLabel(canvas, plotLeft - 6, y, _fmtTick(t));
    }

    // Línea + punto final.
    double xOf(int i) {
      if (values.length == 1) return plotLeft + plotWidth / 2;
      return plotLeft + (i / (values.length - 1)) * plotWidth;
    }

    double yOf(double v) =>
        plotBottom - (v - yMin) / yRange * plotHeight;

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

    // Eje X.
    _drawXLabels(canvas, plotLeft, plotBottom, plotWidth, values.length);
  }

  void _drawYLabel(Canvas canvas, double x, double y, String text) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.40),
          fontSize: 9,
          fontWeight: FontWeight.w600,
        ),
      ),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.right,
    )..layout(minWidth: 28, maxWidth: 28);
    tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
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
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String _fmtDate(DateTime dt) {
    if (series.points.isEmpty) return '';
    final span = series.points.last.weekStart
        .difference(series.points.first.weekStart);
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
      old.series != series || old.accent != accent;
}
