// SPEC-163: card de gráfico de barras estilo Apple Fitness.
//
// Para métricas de COMPORTAMIENTO discreto (hábitos): días/semana de
// ayuno, % A-dominante, minutos de ejercicio, etc. Una barra por
// semana.
//
// Layout: header (3 líneas) + área de chart con barras + eje Y
// (3-4 ticks) + eje X (labels temporales).

import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/analysis/application/chart_hero_computer.dart';
import 'package:elena_app/src/features/analysis/domain/aggregation_mode.dart';
import 'package:elena_app/src/features/analysis/domain/hero_aggregation.dart';
import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/chart_card_header.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/chart_hero_block.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/chart_tooltip.dart';

class BarChartCard extends StatefulWidget {
  const BarChartCard({
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

  /// Frase conversacional para el header (SPEC-165). Ej:
  /// "Cumpliste 5 días de ayuno por semana en promedio."
  final String headline;

  /// SPEC-168.1: agregación del bloque hero arriba del chart.
  /// "PROMEDIO" (avg), "TOTAL" (sum), etc. Default: avg.
  final HeroAggregation heroAggregation;

  /// SPEC-168.1: unit override para el bloque hero. Cuando el `series.unit`
  /// no coincide con la unidad de presentación deseada (ej. "d/sem" en
  /// series pero "d" en hero para sum), el caller la pasa explícita.
  /// Null usa `series.unit`.
  final String? heroUnit;

  /// SPEC-168.1: modo de agregación temporal (daily/weekly/monthly).
  /// Necesario para formatear correctamente la fecha-range del hero.
  final AggregationMode aggregationMode;

  /// SPEC-168.2 (2026-06-03): valor del objetivo del usuario en la
  /// unidad del chart. Si es null, NO se pinta línea de objetivo
  /// (el goal correspondiente no está activo en `userGoals`).
  final double? targetValue;

  /// SPEC-168.2: label formateado del objetivo ("Objetivo 5 d/sem").
  /// Solo se renderiza si `targetValue != null`.
  final String? targetLabel;

  /// 'up' si más es mejor (ejercicio, ayuno, hidratación, etc.)
  /// 'down' si menos es mejor (caso raro en hábitos).
  final String deltaIsBetterIf;

  @override
  State<BarChartCard> createState() => _BarChartCardState();
}

class _BarChartCardState extends State<BarChartCard> {
  // SPEC-168.7 (2026-06-04): índice de la barra seleccionada por tap.
  // Null = ninguna seleccionada. Reset a null al toque fuera del plot
  // o tras 3 s sin nuevo tap.
  int? _selectedIndex;
  Timer? _dismissTimer;

  @override
  void dispose() {
    _dismissTimer?.cancel();
    super.dispose();
  }

  // Atajos a los campos del Widget — mantiene el resto del cuerpo legible.
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

  void _handleTap(Offset localPos, Size chartSize) {
    final n = series.points.length;
    if (n < 2) return;
    // Geometría coherente con _BarsPainter.paint.
    const yAxisRightWidth = 36.0;
    const xAxisHeight = 22.0;
    final plotLeft = 0.0;
    final plotRight = chartSize.width - yAxisRightWidth;
    final plotBottom = chartSize.height - xAxisHeight;
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
    // SPEC-168.1: hero block arriba del chart. Si no hay valor (serie
    // vacía), no renderizamos el bloque — el chart muestra "Sin datos"
    // y eso es suficiente.
    final heroValue = ChartHeroComputer.aggregateValue(series, heroAggregation);
    final dateRange =
        ChartHeroComputer.formatDateRange(series, aggregationMode);
    // SPEC-168.3: cómputo del achievement del objetivo. Solo se
    // calcula si hay target activo; si no, queda null y el hero no
    // pinta el indicador.
    final achievement =
        ChartHeroComputer.computeAchievement(series, targetValue);
    final achievementLabel = achievement == null
        ? null
        : ChartHeroComputer.formatAchievementLabel(
            achievement.achieved,
            achievement.total,
            aggregationMode,
          );

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
              achievementLabel: achievementLabel,
              achievementColor: accent,
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
                painter: _BarsPainter(
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
    // Mismo cálculo de x que el painter — centrado del slot.
    const yAxisRightWidth = 36.0;
    const xAxisHeight = 22.0;
    final plotLeft = 0.0;
    final plotRight = chartSize.width - yAxisRightWidth;
    final plotBottom = chartSize.height - xAxisHeight;
    final plotWidth = plotRight - plotLeft;
    final slotWidth = plotWidth / series.points.length;
    final barCenterX = plotLeft + (idx + 0.5) * slotWidth;
    // plotBottom queda definido por el Positioned.fill; el delegate del
    // tooltip planta el pin desde top:2 hacia abajo.
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
      bottom: chartSize.height - plotBottom,
      child: IgnorePointer(
        child: ChartTooltip(
          anchorX: barCenterX,
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

class _BarsPainter extends CustomPainter {
  _BarsPainter({
    required this.series,
    required this.accent,
    this.targetValue,
    this.targetLabel,
    this.selectedIndex,
  });

  final MetricSeries series;
  final Color accent;

  /// SPEC-168.2: nivel del objetivo en la unidad del chart. Null = sin
  /// línea dashed.
  final double? targetValue;

  /// SPEC-168.2: label "Objetivo X" que aparece junto a la línea dashed.
  final String? targetLabel;

  /// SPEC-168.7 (2026-06-04): índice de la barra seleccionada por tap.
  /// Si != null se pinta con un outline blanco encima del fill. Las
  /// barras no seleccionadas mantienen su look (bright o dim).
  final int? selectedIndex;

  // Padding interno del área del chart.
  // SPEC-168.1 (2026-06-03): eje Y movido al lado derecho del plot,
  // siguiendo el patrón Apple Health/Fitness (la lectura LTR aterriza
  // sobre el axis al final, así el ojo encuentra los números sin saltar).
  // El reservado a la izquierda es 0; el de la derecha aloja los labels.
  static const double _yAxisRightWidth = 36;
  static const double _xAxisHeight = 22;
  static const double _gridPaddingTop = 8;
  static const double _barGap = 2.5;

  @override
  void paint(Canvas canvas, Size size) {
    final values = series.points.map((p) => p.value).toList();
    final dataMaxV = values.reduce((a, b) => a > b ? a : b);

    // SPEC-168.2: si el target del usuario está por encima del máximo
    // observado, expandimos el rango del eje Y para que la línea dashed
    // siempre quede dentro del plot con 5% de headroom visual.
    final maxV = targetValue != null && targetValue! > dataMaxV
        ? targetValue! * 1.05
        : dataMaxV;

    // El eje Y arranca en 0 para barras (Apple Fitness lo hace para
    // métricas de conteo). Si la métrica nunca es 0, el padding inferior
    // queda visualmente bien igualmente.
    const yMin = 0.0;
    final yMax = _niceUpperBound(maxV);

    // SPEC-168.1: el plot ocupa de x=0 a x=size.width - _yAxisRightWidth.
    // Los labels del axis se pintan a la derecha del plot.
    final plotLeft = 0.0;
    final plotTop = _gridPaddingTop;
    final plotRight = size.width - _yAxisRightWidth;
    final plotBottom = size.height - _xAxisHeight;
    final plotHeight = plotBottom - plotTop;
    final plotWidth = plotRight - plotLeft;

    // Grid horizontal + labels eje Y (lado derecho).
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
      // SPEC-168.1: label a la derecha del plot, alineado a la izquierda
      // (los números se leen de izquierda a derecha empezando justo
      // después del axis).
      _drawYLabel(canvas, plotRight + 6, y, _fmtTick(t));
    }

    // Barras.
    // SPEC-168.8: si hay target, las barras que NO lo alcanzan se
    // pintan opacas (alpha 0.35); las que sí lo alcanzan se pintan
    // brillantes (alpha 1.0). Sin target todas se pintan brillantes.
    // Umbral exacto: value >= target. Sin medias tintas (consistente
    // con Apple Fitness).
    final n = values.length;
    final totalGap = _barGap * (n - 1);
    final barWidth = (plotWidth - totalGap) / n;
    final brightPaint = Paint()..color = accent;
    final dimPaint = Paint()..color = accent.withValues(alpha: 0.35);
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
      // SPEC-168.8: usar value original (no clamp) para evaluar vs target.
      final reachedTarget = targetValue == null || values[i] >= targetValue!;
      canvas.drawRRect(rect, reachedTarget ? brightPaint : dimPaint);

      // SPEC-168.7: outline blanco sobre la barra seleccionada.
      if (selectedIndex != null && selectedIndex == i) {
        final outlinePaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = Colors.white.withValues(alpha: 0.95);
        canvas.drawRRect(rect.deflate(0.75), outlinePaint);
      }
    }

    // SPEC-168.2: línea dashed del objetivo del usuario. Se pinta
    // ENCIMA de las barras (sobrepuesta) para que el contraste sea
    // claro: las barras que la rebasan la cruzan visualmente.
    if (targetValue != null) {
      _drawTargetLine(
        canvas,
        plotLeft: plotLeft,
        plotRight: plotRight,
        plotBottom: plotBottom,
        plotHeight: plotHeight,
        yMin: yMin,
        yMax: yMax,
        target: targetValue!,
      );
    }

    // Eje X: labels temporales.
    _drawXLabels(canvas, plotLeft, plotBottom, plotWidth, n);
  }

  /// SPEC-168.2: pinta la línea horizontal dashed del objetivo + label
  /// "Objetivo X" a la derecha (debajo del axis Y).
  void _drawTargetLine(
    Canvas canvas, {
    required double plotLeft,
    required double plotRight,
    required double plotBottom,
    required double plotHeight,
    required double yMin,
    required double yMax,
    required double target,
  }) {
    if (yMax - yMin == 0) return;
    final yClamped = target.clamp(yMin, yMax);
    final y = plotBottom - (yClamped - yMin) / (yMax - yMin) * plotHeight;

    // Trazo dashed manual (4px on / 3px off) en color del pilar con
    // alpha reducido — diferencia clara con barras pero sin gritar.
    final paint = Paint()
      ..color = accent.withValues(alpha: 0.55)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    const dash = 4.0, gap = 3.0;
    double x = plotLeft;
    while (x < plotRight) {
      final end = math.min(x + dash, plotRight);
      canvas.drawLine(Offset(x, y), Offset(end, y), paint);
      x += dash + gap;
    }

    // Label "Objetivo X" sobre el axis derecho. Si el label es null,
    // formateamos con el helper de ticks (consistente con axis).
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
    // Plantado pegado al final del plot (ANTES del axis numérico), con
    // background sutil para que sobresalga sobre la grid.
    final labelX = plotRight - tp.width - 6;
    final labelY = y - tp.height - 2; // 2px sobre la línea
    // Si el label se sale por arriba, lo ponemos debajo de la línea.
    final adjustedY = labelY < 0 ? y + 2 : labelY;
    tp.paint(canvas, Offset(labelX, adjustedY));
  }

  void _drawYLabel(Canvas canvas, double x, double y, String text) {
    // SPEC-168.1: labels alineados a la izquierda y plantados justo a la
    // derecha del axis. minWidth/maxWidth se aflojan a 32 para acomodar
    // valores con 4 dígitos ("1.000") sin partir el texto en líneas.
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
    // Si la serie cubre <2 meses, mostramos día + mes ("5 jun").
    // Si cubre más, solo mes ("jun").
    if (series.points.isEmpty) return '';
    final span =
        series.points.last.weekStart.difference(series.points.first.weekStart);
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

  // SPEC-167 (2026-06-03): magnitud por log10 real.
  //
  // La versión previa estimaba log10 con `v.toString().length` (1 dígito
  // ≈ 1 orden de magnitud). Funcionaba para enteros, pero al introducir
  // modos daily/weekly/monthly con divisiones como `maxV / 3`, valores
  // como 7/3 = 2.3333333333333335 (IEEE 754) producían strings de 18
  // chars → magnitud estimada 1e17 → clamp a 1e9 → step gigante → yMax
  // en mil millones → barras sub-pixel invisibles.
  //
  // Calculamos log10 real con dart:math y devolvemos 10^floor(log10).
  double _pow10(double v) {
    if (v.abs() < 1e-12) return 1;
    final log10 = (math.log(v.abs()) / math.ln10).floor();
    return math.pow(10, log10).toDouble();
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
      old.series != series ||
      old.accent != accent ||
      old.selectedIndex != selectedIndex ||
      old.targetValue != targetValue;
}
