// SPEC-162: tile para un CausalInsight detectado.

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/analysis/domain/causal_insight.dart';

class InsightTile extends StatelessWidget {
  const InsightTile({super.key, required this.insight});

  final CausalInsight insight;

  IconData get _icon {
    switch (insight.type) {
      case CausalInsightType.sustainedImprovement:
        return Icons.trending_up_rounded;
      case CausalInsightType.criticalDrop:
        return Icons.trending_down_rounded;
      case CausalInsightType.bestPeriod:
        return Icons.bolt_rounded;
      case CausalInsightType.convergence:
        return Icons.merge_type_rounded;
      case CausalInsightType.dissociation:
        return Icons.compare_arrows_rounded;
      case CausalInsightType.weeklyDrop:
        return Icons.warning_amber_rounded;
    }
  }

  Color get _accent {
    switch (insight.type) {
      case CausalInsightType.sustainedImprovement:
      case CausalInsightType.bestPeriod:
      case CausalInsightType.convergence:
        return const Color(0xFF22C55E);
      case CausalInsightType.criticalDrop:
      case CausalInsightType.weeklyDrop:
        return const Color(0xFFF59E0B);
      case CausalInsightType.dissociation:
        return const Color(0xFF60A5FA);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_icon, color: _accent, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.headline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  insight.citation,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.40),
                    fontSize: 10,
                    fontStyle: FontStyle.italic,
                    fontWeight: FontWeight.w600,
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
