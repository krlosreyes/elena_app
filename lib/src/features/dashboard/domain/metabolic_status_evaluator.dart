import 'package:flutter/material.dart';

enum MetabolicStatus { optimal, stable, fatigued }

class MetabolicStatusEvaluator {
  final double score;

  MetabolicStatusEvaluator(this.score);

  MetabolicStatus get status {
    if (score >= 80) return MetabolicStatus.optimal;
    if (score >= 50) return MetabolicStatus.stable;
    return MetabolicStatus.fatigued;
  }

  String get label {
    switch (status) {
      case MetabolicStatus.optimal: return 'Óptimo';
      case MetabolicStatus.stable: return 'Estable';
      case MetabolicStatus.fatigued: return 'Fatiga';
    }
  }

  Color get color {
    switch (status) {
      case MetabolicStatus.optimal: return Colors.greenAccent;
      case MetabolicStatus.stable: return Colors.orangeAccent;
      case MetabolicStatus.fatigued: return Colors.redAccent;
    }
  }
}

class DashboardInsight {
  final String message;
  final IconData icon;
  final List<String> riskFlags;

  DashboardInsight({
    required this.message,
    required this.icon,
    this.riskFlags = const [],
  });
}