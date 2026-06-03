// SPEC-162: fila reusable para mostrar una métrica con sparkline.
//
// Layout: label + valor + delta arriba, sparkline debajo.

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/analysis/domain/metric_series.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/sparkline_chart.dart';

class MetricRow extends StatelessWidget {
  const MetricRow({
    super.key,
    required this.series,
    required this.accent,
    this.showDelta = true,
    this.valueFormatter,
    this.deltaIsBetterIf,
  });

  final MetricSeries series;
  final Color accent;
  final bool showDelta;

  /// Formato custom del valor. Default: 1 decimal.
  final String Function(double value)? valueFormatter;

  /// Para colorear el delta: 'up' si subir es mejor, 'down' si bajar
  /// es mejor. Si null, usa default por label (Peso = down, otros = up).
  final String? deltaIsBetterIf;

  @override
  Widget build(BuildContext context) {
    final fmt = valueFormatter ?? _defaultFmt;
    final current = series.currentValue;
    final delta = series.delta;
    final betterIf = deltaIsBetterIf ?? _defaultBetterIf(series.label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            // Label.
            Expanded(
              child: Text(
                series.label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.80),
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            // Valor + unidad.
            if (current != null)
              Text(
                series.unit.isEmpty
                    ? fmt(current)
                    : '${fmt(current)} ${series.unit}',
                style: TextStyle(
                  color: accent,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              )
            else
              Text(
                '—',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.30),
                  fontSize: 15,
                ),
              ),
          ],
        ),
        if (showDelta && delta != null) ...[
          const SizedBox(height: 2),
          _DeltaLabel(
            delta: delta,
            unit: series.unit,
            betterIf: betterIf,
            fmt: fmt,
          ),
        ],
        const SizedBox(height: 6),
        SparklineChart(series: series, color: accent),
      ],
    );
  }

  static String _defaultFmt(double v) {
    if (v.abs() >= 100) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  static String _defaultBetterIf(String label) {
    // Peso: bajar es mejor (asumimos pérdida). Resto: subir.
    if (label.toLowerCase() == 'peso') return 'down';
    return 'up';
  }
}

class _DeltaLabel extends StatelessWidget {
  const _DeltaLabel({
    required this.delta,
    required this.unit,
    required this.betterIf,
    required this.fmt,
  });

  final double delta;
  final String unit;
  final String betterIf;
  final String Function(double) fmt;

  @override
  Widget build(BuildContext context) {
    if (delta.abs() < 0.01) {
      return Text(
        'sin cambio',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      );
    }
    final isUp = delta > 0;
    final isGood = betterIf == 'up' ? isUp : !isUp;
    final color = isGood
        ? const Color(0xFF22C55E)
        : const Color(0xFFF59E0B);
    final icon = isUp
        ? Icons.arrow_upward_rounded
        : Icons.arrow_downward_rounded;
    final formatted = fmt(delta.abs());
    return Row(
      children: [
        Icon(icon, color: color, size: 11),
        const SizedBox(width: 2),
        Text(
          unit.isEmpty
              ? '$formatted vs inicio'
              : '$formatted $unit vs inicio',
          style: TextStyle(
            color: color,
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
