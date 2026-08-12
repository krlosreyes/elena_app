// SPEC-137 E.5: banner countdown "alístate para la próxima comida".
//
// Aparece en el Dashboard cuando faltan ≤ 30 min para la próxima comida
// sugerida (regla del intervalo de 3h documentada en
// NUTRITION_BIBLIOGRAPHY.md §15). Se oculta durante día de permitidos y
// cuando no hay comidas registradas hoy.
//
// El banner refresca solo cada 10s vía metabolicPulseProvider (a través
// del nextMealProvider).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/nutrition/application/next_meal_provider.dart';

class NextMealBanner extends ConsumerWidget {
  const NextMealBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final next = ref.watch(nextMealProvider);
    if (!next.shouldShowBanner) return const SizedBox.shrink();

    final minutes = next.minutesUntilNext.clamp(0, 30);
    final hh = next.nextMealAt!.hour.toString().padLeft(2, '0');
    final mm = next.nextMealAt!.minute.toString().padLeft(2, '0');

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: AppColors.accent.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: () => context.push('/nutrition/minuta'),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.20),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.restaurant_rounded,
                    color: AppColors.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        minutes <= 0
                            ? 'Es hora de tu próxima comida'
                            : 'Próxima comida en $minutes min',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        minutes <= 0
                            ? 'Tocá para registrar tu plato.'
                            : 'A las $hh:$mm. Alístate.',
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
