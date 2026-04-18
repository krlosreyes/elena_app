import 'package:flutter/material.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_models.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';

class InsightCard extends StatelessWidget {
  final CorrelationResult correlation;

  const InsightCard({super.key, required this.correlation});

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(correlation.type);
    final icon = _getStatusIcon(correlation.type);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2), width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Detección de Patrón',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white.withOpacity(0.3),
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  correlation.insight,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      '${correlation.pilarA} ↔ ${correlation.pilarB}',
                      style: TextStyle(
                        fontSize: 11,
                        color: color.withOpacity(0.8),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Correlación: ${(correlation.score * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.white.withOpacity(0.3),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(CorrelationType type) {
    switch (type) {
      case CorrelationType.positive:
        return const Color(0xFF10B981);
      case CorrelationType.negative:
        return const Color(0xFFF87171);
      case CorrelationType.neutral:
        return const Color(0xFFFBBF24);
    }
  }

  IconData _getStatusIcon(CorrelationType type) {
    switch (type) {
      case CorrelationType.positive:
        return Icons.trending_up_rounded;
      case CorrelationType.negative:
        return Icons.trending_down_rounded;
      case CorrelationType.neutral:
        return Icons.trending_flat_rounded;
    }
  }
}
