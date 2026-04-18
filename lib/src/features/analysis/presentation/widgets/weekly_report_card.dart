import 'package:flutter/material.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_models.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';

class WeeklyReportCard extends StatelessWidget {
  final WeeklyAnalysis current;
  final WeeklyAnalysis previous;

  const WeeklyReportCard({super.key, required this.current, required this.previous});

  @override
  Widget build(BuildContext context) {
    final imrDiff = current.avgImr - previous.avgImr;
    final adhDiff = current.adherence - previous.adherence;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildRow(
            'IMR PROMEDIO',
            current.avgImr.toStringAsFixed(1),
            imrDiff,
            isPercentage: false,
          ),
          const Divider(height: 32, color: Colors.white10),
          _buildRow(
            'ADHERENCIA METABÓLICA',
            '${(current.adherence * 100).toStringAsFixed(0)}%',
            adhDiff,
            isPercentage: true,
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0F172A),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFEAB308), size: 16),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Pilar más influyente: ${current.topPilarName}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white70,
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

  Widget _buildRow(String label, String value, double diff, {required bool isPercentage}) {
    final bool isPositive = diff > 0;
    final color = isPositive ? const Color(0xFF10B981) : const Color(0xFFF87171);
    final sign = isPositive ? '+' : '';
    final diffText = isPercentage 
        ? '$sign${(diff * 100).toStringAsFixed(0)}%' 
        : '$sign${diff.toStringAsFixed(1)} pts';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.white.withOpacity(0.35),
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
          ],
        ),
        if (diff != 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(
                  isPositive ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                  color: color,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  diffText,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
