import 'package:flutter/material.dart';

/// ✅ METABOLIC MILESTONE (UI Ready Data)
class MetabolicMilestone {
  final String label;
  final double angle; // In radians
  final bool isReached;
  final IconData icon; // Direct usage of Flutter Icons
  final double hour; // Temporal marker in hours (relative to start)
  final double absoluteHour; // Hour of day (0-24)

  MetabolicMilestone({
    required this.label,
    required this.angle,
    this.isReached = false,
    required this.icon,
    this.hour = 0.0,
    this.absoluteHour = 0.0,
  });
}
