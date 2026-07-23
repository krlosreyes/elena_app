// Módulo "Tu Glucosa" — card de un insight del motor de análisis
// (propuesta §10.2/§13): siempre observación + mecanismo + acción,
// nunca un número suelto. `confidence == preliminar` se marca
// explícitamente como tal (propuesta R8) — nunca se presenta un
// patrón de 7-13 días con la misma seguridad que uno de 14+.

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/glucose/domain/glucose_insight.dart';

class GlucoseInsightCard extends StatelessWidget {
  const GlucoseInsightCard({super.key, required this.insight});

  final GlucoseInsight insight;

  @override
  Widget build(BuildContext context) {
    final isPreliminary =
        insight.confidence == GlucoseInsightConfidence.preliminar;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_rounded,
                  color: Color(0xFFE879F9), size: 16),
              const SizedBox(width: 6),
              if (isPreliminary)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'TENDENCIA PRELIMINAR',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            insight.observation,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            insight.mechanism,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.60),
              fontSize: 12.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFE879F9).withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded,
                    color: Color(0xFFE879F9), size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    insight.action,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
