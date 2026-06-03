// SPEC-163: header compartido entre BarChartCard y LineChartCard.
//
// 3 líneas tipográficas estilo Apple Fitness:
//   PROMEDIO         (label 11pt gris)
//   4.2  días/sem    (valor 32pt blanco)
//   Ayuno · 3 MESES   ↑1.4 vs inicio   (contexto + delta)

import 'package:flutter/material.dart';

class ChartCardHeader extends StatelessWidget {
  const ChartCardHeader({
    super.key,
    required this.statLabel,
    required this.value,
    required this.unit,
    required this.metricLabel,
    required this.periodLabel,
    this.delta,
    this.deltaIsBetterIf = 'up',
    this.deltaFormatter,
  });

  /// Texto pequeño arriba (ej "PROMEDIO", "ACTUAL").
  final String statLabel;

  /// Valor principal grande. Null muestra "—".
  final double? value;

  /// Unidad acompañante (puede ser vacío).
  final String unit;

  /// Label del pilar/métrica (ej "Ayuno", "IMR").
  final String metricLabel;

  /// Periodo seleccionado en mayúsculas (ej "3 MESES").
  final String periodLabel;

  /// Delta vs inicio del rango. Null oculta el componente.
  final double? delta;

  /// "up" si subir es mejor (default); "down" si bajar es mejor.
  final String deltaIsBetterIf;

  /// Formato custom del delta. Default: 1 decimal con signo absoluto.
  final String Function(double)? deltaFormatter;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label "PROMEDIO" estilo Apple Fitness.
        Text(
          statLabel,
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 6),
        // Valor grande + unidad.
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value != null ? _fmtValue(value!) : '—',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 34,
                fontWeight: FontWeight.w700,
                height: 1.0,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 6),
              Text(
                unit,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.50),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        // Contexto + delta.
        Row(
          children: [
            Expanded(
              child: Text(
                '$metricLabel · $periodLabel',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (delta != null) _DeltaPill(
              delta: delta!,
              unit: unit,
              betterIf: deltaIsBetterIf,
              formatter: deltaFormatter ?? _fmtValue,
            ),
          ],
        ),
      ],
    );
  }

  static String _fmtValue(double v) {
    if (v.abs() >= 100) return v.toStringAsFixed(0);
    if (v.abs() >= 10) return v.toStringAsFixed(1);
    return v.toStringAsFixed(1);
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({
    required this.delta,
    required this.unit,
    required this.betterIf,
    required this.formatter,
  });

  final double delta;
  final String unit;
  final String betterIf;
  final String Function(double) formatter;

  @override
  Widget build(BuildContext context) {
    if (delta.abs() < 0.01) {
      return Text(
        'sin cambio',
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.35),
          fontSize: 11,
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
    final formatted = formatter(delta.abs());
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 12),
        const SizedBox(width: 2),
        Text(
          unit.isEmpty
              ? '$formatted vs inicio'
              : '$formatted $unit vs inicio',
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
