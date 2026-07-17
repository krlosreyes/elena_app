// 17-jul: ver comentario en results_entry_card.dart — mismo patrón de
// card colapsada. Esta resume "Tu racha" (StreakSummaryCard +
// StreakBarChart, que antes vivían inline en Progreso) y navega a
// RachaDetailScreen (/analysis/racha). Ícono/color calcan a
// StreakSummaryCard (fuego + metabolicGreen) para que se reconozca de
// inmediato como la misma feature.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';

class RachaEntryCard extends ConsumerWidget {
  const RachaEntryCard({super.key});

  static const _color = AppColors.metabolicGreen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(streakProvider.select((s) => s.currentStreak));
    final subtitle = current == 0
        ? 'Sin racha activa hoy'
        : '$current ${current == 1 ? "día" : "días"} consecutivos';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/analysis/racha'),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _color.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _color.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.local_fire_department_rounded,
                  color: _color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tu racha',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.white.withValues(alpha: 0.3),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
