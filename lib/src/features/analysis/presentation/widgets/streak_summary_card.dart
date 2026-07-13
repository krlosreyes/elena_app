// SPEC-110: card "RACHA ACTIVA" en la pantalla Análisis. Reutiliza
// `streakProvider` existente para el cómputo.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/streak/presentation/widgets/streak_explainer_sheet.dart';

class StreakSummaryCard extends ConsumerWidget {
  const StreakSummaryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(streakProvider);
    final current = streak.currentStreak;
    final longest = streak.longestStreak;
    final freezes = streak.freezesAvailable;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.metabolicGreen.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.metabolicGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.metabolicGreen,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'RACHA ACTIVA',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.55),
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 4),
                        // SPEC-255 RF-01: explainer de la regla de racha.
                        InkWell(
                          onTap: () => showStreakExplainerSheet(context),
                          borderRadius: BorderRadius.circular(10),
                          child: Icon(
                            Icons.info_outline_rounded,
                            size: 13,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      current == 0
                          ? 'Sin racha activa hoy'
                          : '$current ${current == 1 ? "día" : "días"} consecutivos',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              if (longest > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'RÉCORD',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.35),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$longest',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          // SPEC-255 RF-02: reservas disponibles — solo si hay racha activa
          // o reservas ganadas (evita ruido para usuarios nuevos en 0).
          if (current > 0 && freezes > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  Icons.shield_outlined,
                  size: 14,
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.85),
                ),
                const SizedBox(width: 6),
                Text(
                  freezes == 1
                      ? 'Tienes 1 reserva disponible'
                      : 'Tienes $freezes reservas disponibles',
                  style: TextStyle(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
