// SPEC-168.1 (2026-06-03): bloque hero estilo Apple Health/Fitness que
// aparece arriba del chart, debajo del headline conversacional.
//
// Layout:
//   PROMEDIO                      ← 11pt UPPERCASE white alpha 0.50
//   177 g                          ← 34pt bold white + 14pt unit alpha 0.50
//   7 a 13 jun. de 2026            ← 13pt white alpha 0.50
//
// La línea inferior (date range) se calcula a partir de los buckets
// de la serie en el caller — este widget solo renderiza.

import 'package:flutter/material.dart';

class ChartHeroBlock extends StatelessWidget {
  const ChartHeroBlock({
    super.key,
    required this.label,
    required this.value,
    required this.unit,
    required this.dateRange,
    this.achievementLabel,
    this.achievementColor,
  });

  /// Label en MAYÚSCULAS arriba del valor. "PROMEDIO", "TOTAL", etc.
  final String label;

  /// Valor agregado ya formateado como string ("177", "76.4", "5").
  final String value;

  /// Unidad pequeña a la derecha del valor ("g", "kg", "%"). Puede ser
  /// vacío si la métrica no tiene unidad (IMR).
  final String unit;

  /// Rango de fechas en formato humano ("7 a 13 jun. de 2026").
  /// Vacío oculta la línea.
  final String dateRange;

  /// SPEC-168.3: indicador de cumplimiento del objetivo ("12 de 30
  /// días"). Si es null, no se renderiza. Solo aplica cuando hay
  /// target activo del usuario.
  final String? achievementLabel;

  /// SPEC-168.3: color del achievement label (típicamente el accent
  /// del pilar). Default: blanco 50%.
  final Color? achievementColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: Colors.white.withValues(alpha: 0.50),
              ),
            ),
            // SPEC-168.3: achievement alineado a la derecha del label.
            if (achievementLabel != null) ...[
              const Spacer(),
              Text(
                achievementLabel!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                  color: (achievementColor ?? Colors.white)
                      .withValues(alpha: 0.85),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              value,
              style: const TextStyle(
                fontSize: 34,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.0,
                letterSpacing: -0.5,
              ),
            ),
            if (unit.isNotEmpty) ...[
              const SizedBox(width: 4),
              Text(
                unit,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.50),
                ),
              ),
            ],
          ],
        ),
        if (dateRange.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            dateRange,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.50),
            ),
          ),
        ],
      ],
    );
  }
}
