// SPEC-270 (fase 2): card de entrada al onboarding del Pilar de
// Alimentación en Perfil > Configuración. Mismo patrón que
// AlcoholProtocolEntryCard / ProtocoloEntryCard.
//
// Abre la evaluación dietética (6 bloques) con la que se arma la Minuta
// Diaria. El subtítulo refleja si el usuario ya la configuró.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_intake_notifier.dart';

class AlimentacionMinutaEntryCard extends ConsumerWidget {
  const AlimentacionMinutaEntryCard({super.key});

  static const _color = AppColors.pillarNutricion; // ámbar del pilar

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nutritionIntakeNotifierProvider);
    final subtitle = state.hasIntake
        ? 'Configurada · ${state.intake!.meals.length} comidas'
        : 'Cuéntanos cómo comes para armar tu minuta';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/nutrition/intake'),
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
              child: const Icon(Icons.restaurant_menu, color: _color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mi minuta diaria',
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
