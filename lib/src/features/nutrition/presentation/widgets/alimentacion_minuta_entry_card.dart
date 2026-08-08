// SPEC-270 (fase 2) + SPEC-280.1: card de PREFERENCIAS de alimentación en
// Perfil > Configuración. Muestra lo que el usuario declaró (dieta, nº de
// comidas) y lleva a EDITARLAS (evaluación dietética de 6 bloques). NO abre
// la Minuta — esa vive en el dashboard (pilar Comidas). Al editar y guardar,
// la Minuta se regenera sola (meal_plan_notifier escucha el cambio).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_intake_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';

class AlimentacionMinutaEntryCard extends ConsumerWidget {
  const AlimentacionMinutaEntryCard({super.key});

  static const _color = AppColors.pillarNutricion; // ámbar del pilar

  static String _dietLabel(DietType d) => switch (d) {
        DietType.omnivore => 'Omnívoro',
        DietType.pescatarian => 'Pescetariano',
        DietType.vegetarian => 'Vegetariano',
        DietType.vegan => 'Vegano',
        DietType.other => 'Personalizado',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(nutritionIntakeNotifierProvider);
    final intake = state.intake;
    final configured = intake != null && intake.isComplete;

    final foodCount = configured
        ? intake.meals
            .expand((m) => m.items)
            .where((i) => i.isMeaningful)
            .length
        : 0;
    final restrictions = configured ? intake.restrictions.allBanned.length : 0;

    final subtitle = !configured
        ? 'Cuéntanos cómo comes para armar tu minuta'
        : '${_dietLabel(intake.restrictions.diet)} · '
            '${intake.meals.length} comidas · $foodCount alimentos'
            '${restrictions > 0 ? ' · $restrictions restricciones' : ''}';

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
              child: const Icon(Icons.tune_rounded, color: _color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mis preferencias de alimentación',
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
                  if (configured) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Toca para editar · tu minuta se adapta',
                      style: TextStyle(
                        color: _color.withValues(alpha: 0.85),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
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
