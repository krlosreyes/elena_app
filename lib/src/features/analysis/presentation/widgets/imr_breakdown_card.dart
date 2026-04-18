import 'package:flutter/material.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';

/// IMRBreakdownCard
/// Muestra el desglose visual de los 3 bloques del IMR:
/// Estructura (50%), Metabólico (25%), Conducta y Circadiano (25%)
class IMRBreakdownCard extends StatelessWidget {
  final IMRv2Result result;
  final bool isHardcoded;

  const IMRBreakdownCard({
    super.key, 
    required this.result,
    this.isHardcoded = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'DESGLOSE IMR',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.5,
              color: Colors.white.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 16),
          _BlockRow(
            label: 'ESTRUCTURA',
            subtitle: 'Composición corporal',
            value: result.structureScore,
            weight: '50%',
            color: const Color(0xFF3B82F6),
            isHardcoded: isHardcoded,
          ),
          const SizedBox(height: 12),
          _BlockRow(
            label: 'METABÓLICO',
            subtitle: 'Ayuno + Adherencia',
            value: result.metabolicScore,
            weight: '25%',
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 12),
          _BlockRow(
            label: 'CONDUCTA',
            subtitle: 'Sueño + Ejercicio + Circadiano',
            value: result.behaviorScore,
            weight: '25%',
            color: const Color(0xFFF97316),
          ),
        ],
      ),
    );
  }
}

class _BlockRow extends StatelessWidget {
  final String label;
  final String subtitle;
  final double value; // 0.0 – 1.0
  final String weight;
  final Color color;
  final bool isHardcoded;

  const _BlockRow({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.weight,
    required this.color,
    this.isHardcoded = false,
  });

  @override
  Widget build(BuildContext context) {
    final pct = (value.clamp(0.0, 1.0) * 100).toStringAsFixed(0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (isHardcoded) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: Colors.amber.withOpacity(0.3), width: 1),
                        ),
                        child: const Text(
                          'ESTIMADO',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w900,
                            color: Colors.amber,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.45),
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  weight,
                  style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withOpacity(0.35),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$pct%',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: value.clamp(0.0, 1.0),
            backgroundColor: Colors.white.withOpacity(0.08),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
