// SPEC-163: card de gráfico de barras estilo Apple Fitness.
//
// Para métricas de COMPORTAMIENTO discreto (hábitos): días/semana de
// ayuno, % A-dominante, minutos de ejercicio, etc. Una barra por
// semana.
//
// Layout: header (3 líneas) + área de chart con barras + eje Y
// (3-4 ticks) + eje X (labels temporales).

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/chart_card_header.dart';

class BarChartCard extends StatelessWidget {
  const BarChartCard({
    super.key,
    required this.series,
    required this.accent,
    required this.periodLabel,
    this.statLabel = 'PROMEDIO',
    this.deltaIsBetterIf = 'up',
  });

  final MetricSeries series;
  final Color accent;
  final String periodLabel;
  final String statLabel;

  /// 'up' si más es mejor (ejercicio, ayuno, hidratación, etc.)
  /// 'down' si menos es mejor (caso raro en hábitos).
  final String deltaIsBetterIf;

  @override
  Widget build(BuildContext context) {
    final avg = series.points.isEmpty
        ? null
        : series.points.map((p) => p.value).reduce((a, b) => a + b) /
            series.points.length;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ChartCardHeader(
            statLabel: statLabel,
            value: avg,
            unit: series.unit,
            metricLabel: series.label,
            periodLabel: periodLabel,
            delta: series.delta,
            deltaIsBetterIf: deltaIsBetterIf,
          ),
          const SizedBox(height: 20),
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
      painter: _BarsPainter(series: series, accent: accent),
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

class _BarsPainter extends CustomPainter {
  _BarsPainter({required this.series, required this.accent});

  final MetricSeries series;
  final Color accent;

  // Padding interno del área del chart.
  static const double _yAxisWidth = 28;
  static const double _xAxisHeight = 22;
  static const double _gridPaddingTop = 8;
  static const double _barGap = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final values = series.points.map((p) => p.value).toList();
    final maxV = values.reduce((a, b) => a > b ? a : b);

    // El eje Y arranca en 0 para barras (Apple Fitness lo hace para
    // métricas de conteo). Si la métrica nunca es 0, el padding inferior
    // queda visualmente bien igualmente.
    const yMin = 0.0;
    final yMax = _niceUpperBound(maxV);

    final plotLeft = _yAxisWidth;
    final plotTop = _gridPaddingTop;
    final plotRight = size.width;
    final plotBottom = size.height - _xAxisHeight;
    final plotHeight = plotBottom - plotTop;
    final plotWidth = plotRight - plotLeft;

    // Grid horizontal + labels eje Y.
    final gridPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.06)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final ticks = _generateYTicks(yMax);
    for (final t in ticks) {
      final y = plotBottom - (t - yMin) / (yMax - yMin) * plotHeight;
      canvas.drawLine(
        Offset(plotLeft, y),
        Offset(plotRight, y),
        gridPaint,
      );
      _drawYLabel(canvas, plotLeft - 6, y, _fmtTick(t));
    }

    // Barras.
    final n = values.length;
    final totalGap = _barGap * (n - 1);
    final barWidth = (plotWidth - totalGap) / n;
    final barPaint = Paint()..color = accent;
    for (int i = 0; i < n; i++) {
      final v = values[i].clamp(0.0, yMax);
      final barHeight = (v - yMin) / (yMax - yMin) * plotHeight;
      final x = plotLeft + i * (barWidth + _barGap);
      final y = plotBottom - barHeight;
      final rect = RRect.fromRectAndCorners(
        Rect.fromLTWH(x, y, barWidth, barHeight),
        topLeft: const Radius.circular(3),
        topRight: const Radius.circular(3),
      );
      canvas.drawRRect(rect, barPaint);
    }

    // Eje X: labels temporales.
    _drawXLabels(canvas, plotLeft, plotBottom, plotWidth, n);
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
    )..layout(minWidth: 24, maxWidth: 24);
    tp.paint(canvas, Offset(x - tp.width, y - tp.height / 2));
  }

  void _drawXLabels(
    Canvas canvas,
    double plotLeft,
    double plotBottom,
    double plotWidth,
    int n,
  ) {
    // Hasta 4 labels en el eje X. Tomamos índices equiespaciados.
    final labels = _xAxisLabels(n);
    for (final entry in labels) {
      final i = entry.key;
      final label = entry.value;
      final barWidth = (plotWidth - _barGap * (n - 1)) / n;
      final x = plotLeft + i * (barWidth + _barGap) + barWidth / 2;
      final tp = TextPainter(
        text: TextSpan(
          text: label,
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

  /// Devuelve hasta 4 pares (índice, label) bien distribuidos.
  /// Labels: mes corto + día si la serie es larga, solo mes si es 3+ meses.
  List<MapEntry<int, String>> _xAxisLabels(int n) {
    if (n <= 1) return const [];
    final maxLabels = n >= 6 ? 4 : (n >= 3 ? 3 : 2);
    final indices = <int>[];
    for (int i = 0; i < maxLabels; i++) {
      indices.add(((n - 1) * i / (maxLabels - 1)).round());
    }
    final out = <MapEntry<int, String>>[];
    for (final i in indices) {
      final dt = series.points[i].weekStart;
      out.add(MapEntry(i, _fmtDate(dt)));
    }
    return out;
  }

  static const _monthsShort = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  String _fmtDate(DateTime dt) {
    // Si la serie cubre <2 meses, mostramos día + mes ("5 jun").
    // Si cubre más, solo mes ("jun").
    if (series.points.isEmpty) return '';
    final span = series.points.last.weekStart
        .difference(series.points.first.weekStart);
    if (span.inDays > 60) {
      return _monthsShort[dt.month - 1];
    }
    return '${dt.day} ${_monthsShort[dt.month - 1]}';
  }

  /// Ticks bonitos en el eje Y. Retorna 3-4 valores.
  List<double> _generateYTicks(double maxV) {
    if (maxV <= 0) return const [0];
    final step = _niceStep(maxV / 3);
    final ticks = <double>[];
    for (double v = 0; v <= maxV + 0.0001; v += step) {
      ticks.add(v);
    }
    return ticks;
  }

  double _niceStep(double rough) {
    // Snap a múltiplos legibles: 1, 2, 5, 10, 20, 50, 100, etc.
    if (rough <= 0) return 1;
    final magnitude = _pow10(rough);
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

  double _pow10(double v) {
    final log = v.abs() <= 0 ? 0 : (v.abs()).toString().length - 1;
    return _power(10, log.toDouble() - 1).clamp(0.001, 1e9);
  }

  double _power(num base, double exp) {
    if (exp == 0) return 1;
    double r = 1;
    final e = exp.toInt();
    for (int i = 0; i < e.abs(); i++) {
      r *= base;
    }
    return exp < 0 ? 1 / r : r;
  }

  double _niceUpperBound(double v) {
    if (v <= 0) return 1;
    final step = _niceStep(v / 3);
    return ((v / step).ceil()) * step;
  }

  String _fmtTick(double v) {
    if (v.abs() >= 100) return v.toStringAsFixed(0);
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  @override
  bool shouldRepaint(covariant _BarsPainter old) =>
      old.series != series || old.accent != accent;
}
