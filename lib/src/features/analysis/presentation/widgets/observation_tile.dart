// SPEC-201: tile de una Observación honesta. Headline + detalle + micro-acción.
// Sin cita pegada (la ciencia vive en el explainer del pilar, no acá).

import 'package:flutter/material.dart';

import 'package:elena_app/src/features/analysis/domain/observation.dart';

class ObservationTile extends StatelessWidget {
  const ObservationTile({super.key, required this.observation});

  final Observation observation;

  IconData get _icon {
    switch (observation.type) {
      case ObservationType.streak:
        return Icons.local_fire_department_rounded;
      case ObservationType.goalProximity:
        return Icons.flag_rounded;
      case ObservationType.baseline:
        return Icons.insights_rounded;
    }
  }

  Color get _accent {
    switch (observation.type) {
      case ObservationType.streak:
        return const Color(0xFF22C55E);
      case ObservationType.goalProximity:
        return const Color(0xFF38BDF8);
      case ObservationType.baseline:
        return const Color(0xFF818CF8);
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
                  observation.headline,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.92),
                    fontSize: 13,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  observation.detail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (observation.action != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_forward_rounded,
                            color: _accent, size: 13),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            observation.action!,
                            style: TextStyle(
                              color: _accent,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
