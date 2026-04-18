// SPEC-13: IMR Explicado al Usuario — Tarjeta compacta del Dashboard
// Muestra el score IMR actual, la zona coloreada y un resumen de 1 línea.
// Al tocarse abre IMRDetailSheet con el desglose completo.
// Recibe IMRv2Result como parámetro: el cálculo ya lo hace el dashboard.

import 'package:flutter/material.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/features/analysis/domain/imr_explanation.dart';
import 'package:elena_app/src/features/analysis/presentation/imr_detail_sheet.dart';

class IMRScoreCard extends StatelessWidget {
  const IMRScoreCard({
    super.key,
    required this.result,
    this.fastingHours = 0,
    this.sleepHours = 0,
    this.exerciseMin = 0,
  });

  final IMRv2Result result;
  final double fastingHours;
  final double sleepHours;
  final double exerciseMin;

  @override
  Widget build(BuildContext context) {
    final Color zoneColor = IMRZoneColors.forZone(result.zone);
    final String emoji    = IMRZoneColors.emojiForZone(result.zone);

    return GestureDetector(
      onTap: () => showIMRDetailSheet(
        context,
        result: result,
        fastingHours: fastingHours,
        sleepHours: sleepHours,
        exerciseMin: exerciseMin,
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: zoneColor.withOpacity(0.35),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: zoneColor.withOpacity(0.06),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Score grande ─────────────────────────────────────────────────
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${result.totalScore}',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: zoneColor,
                    height: 1.0,
                  ),
                ),
                Text(
                  'IMR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                    color: Colors.white.withOpacity(0.35),
                  ),
                ),
              ],
            ),

            const SizedBox(width: 20),

            // Separador vertical
            Container(
              width: 1,
              height: 60,
              color: Colors.white.withOpacity(0.08),
            ),

            const SizedBox(width: 20),

            // ── Info derecha ──────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Zona badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: zoneColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: zoneColor.withOpacity(0.4)),
                    ),
                    child: Text(
                      '$emoji  ${result.zone}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: zoneColor,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Descripción corta
                  Text(
                    result.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.55),
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  // CTA
                  Row(
                    children: [
                      Text(
                        'Ver desglose',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: zoneColor.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: zoneColor.withOpacity(0.6),
                        size: 14,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
