// SPEC-165: header de chart card con headline conversacional.
//
// Reemplaza el header tripartito frío de SPEC-163 por una frase
// declarativa en segunda persona, estilo Apple Fitness.
//
// Layout:
//   Headline conversacional · 17pt regular · blanco 92%
//   Período  ·  Delta opcional · 13pt gris 55%

import 'package:flutter/material.dart';

class ChartCardHeader extends StatelessWidget {
  const ChartCardHeader({
    super.key,
    required this.headline,
    required this.periodLabel,
    this.delta,
    this.deltaUnit = '',
    this.deltaIsBetterIf = 'up',
  });

  /// Frase conversacional ya armada por el caller. Ej:
  /// "Dormiste un promedio de 7.1 h por noche."
  final String headline;

  /// Período en humano. Ej: "Últimos 3 meses".
  final String periodLabel;

  /// Delta numérico vs inicio del rango. Null oculta el pill.
  final double? delta;

  /// Unidad del delta (ej: "kg", "%", "min"). Puede ser vacío.
  final String deltaUnit;

  /// "up" si subir es mejor; "down" si bajar es mejor.
  final String deltaIsBetterIf;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
        const SizedBox(height: 6),
        Row(
          children: [
            Text(
              periodLabel,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.50),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            if (delta != null && delta!.abs() >= 0.01) ...[
              Text(
                '  ·  ',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.30),
                  fontSize: 13,
                ),
              ),
              _DeltaPill(
                delta: delta!,
                unit: deltaUnit,
                betterIf: deltaIsBetterIf,
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _DeltaPill extends StatelessWidget {
  const _DeltaPill({
    required this.delta,
    required this.unit,
    required this.betterIf,
  });

  final double delta;
  final String unit;
  final String betterIf;

  @override
  Widget build(BuildContext context) {
    final isUp = delta > 0;
    final isGood = betterIf == 'up' ? isUp : !isUp;
    final color = isGood ? const Color(0xFF34D399) : const Color(0xFFFB923C);
    final icon =
        isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;
    final formatted = _fmt(delta.abs());
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 2),
        Text(
          unit.isEmpty ? formatted : '$formatted $unit',
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  static String _fmt(double v) {
    if (v.abs() >= 100) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
}
