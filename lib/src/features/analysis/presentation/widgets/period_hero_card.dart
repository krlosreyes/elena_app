// SPEC-113: card "hero" con IMR promedio, delta vs período anterior,
// y mejor/peor día.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/domain/period_comparison.dart';

class PeriodHeroCard extends StatelessWidget {
  final PeriodComparison data;
  final String periodLabel;

  const PeriodHeroCard({
    super.key,
    required this.data,
    required this.periodLabel,
  });

  @override
  Widget build(BuildContext context) {
    final delta = data.delta;
    Color deltaColor = Colors.white.withValues(alpha: 0.5);
    IconData deltaIcon = Icons.remove_rounded;
    String deltaLabel = 'sin comparación';
    if (delta != null) {
      if (delta > 0) {
        deltaColor = AppColors.metabolicGreen;
        deltaIcon = Icons.arrow_upward_rounded;
        deltaLabel = '+$delta';
      } else if (delta < 0) {
        deltaColor = const Color(0xFFEF4444);
        deltaIcon = Icons.arrow_downward_rounded;
        deltaLabel = '$delta';
      } else {
        deltaLabel = 'igual';
      }
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'IMR PROMEDIO · ${periodLabel.toUpperCase()}',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${data.imrAverage}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 48,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                  fontFamily: 'monospace',
                ),
              ),
              const SizedBox(width: 14),
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(deltaIcon, color: deltaColor, size: 16),
                    const SizedBox(width: 2),
                    Text(
                      deltaLabel,
                      style: TextStyle(
                        color: deltaColor,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (delta != null)
            Text(
              'vs período anterior',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          const SizedBox(height: 16),
          if (data.bestDayDate != null && data.worstDayDate != null)
            Row(
              children: [
                Expanded(
                  child: _StatTile(
                    label: 'Mejor día',
                    value:
                        '${_humanDate(data.bestDayDate!)} · ${data.bestDayImr}',
                    color: AppColors.metabolicGreen,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: _StatTile(
                    label: 'Peor día',
                    value:
                        '${_humanDate(data.worstDayDate!)} · ${data.worstDayImr}',
                    color: const Color(0xFFFB923C),
                  ),
                ),
              ],
            )
          else
            Text(
              'Aún recopilando datos del período…',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12,
              ),
            ),
        ],
      ),
    );
  }

  static String _humanDate(DateTime d) {
    const months = [
      'ene', 'feb', 'mar', 'abr', 'may', 'jun',
      'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
    ];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.45),
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}
