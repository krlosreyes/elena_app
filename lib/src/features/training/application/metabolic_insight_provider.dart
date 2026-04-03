import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/health/providers/health_snapshot_provider.dart';

part 'metabolic_insight_provider.g.dart';

class MetabolicInsight {
  final String message;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  MetabolicInsight({
    required this.message,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });
}

@riverpod
MetabolicInsight? metabolicInsight(MetabolicInsightRef ref) {
  // Moved to DecisionEngine in Phase 3
  final decision = ref.watch(healthSnapshotProvider).valueOrNull?.decision;
  if (decision == null) return null;

  final visual = _visualForState(decision.metabolicState);
  return MetabolicInsight(
    message: '${decision.primaryAction}\n${decision.explanation}',
    icon: visual.icon,
    color: visual.color,
    backgroundColor: visual.background,
  );
}

({IconData icon, Color color, Color background}) _visualForState(String state) {
  switch (state) {
    case 'fat_burning':
      return (
        icon: Icons.local_fire_department,
        color: Colors.orange.shade800,
        background: Colors.orange.shade50,
      );
    case 'recovery':
      return (
        icon: Icons.hotel,
        color: Colors.indigo.shade700,
        background: Colors.indigo.shade50,
      );
    case 'energy_boost':
      return (
        icon: Icons.bolt,
        color: Colors.blue.shade800,
        background: Colors.blue.shade50,
      );
    default:
      return (
        icon: Icons.insights,
        color: Colors.teal.shade800,
        background: Colors.teal.shade50,
      );
  }
}
