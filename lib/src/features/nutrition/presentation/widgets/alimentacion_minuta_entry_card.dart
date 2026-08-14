// SPEC-270 (fase 2) + SPEC-280.1 + SPEC-288: "Alimentación" como fila de lista
// agrupada (ProfileRow). Muestra lo que el usuario declaró (dieta, nº de
// comidas) y lleva a EDITARLAS (evaluación dietética de 6 bloques). NO abre la
// Minuta — esa vive en el dashboard. Al editar y guardar, la Minuta se
// regenera sola (meal_plan_notifier escucha el cambio).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/features/auth/presentation/widgets/profile_settings_group.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_intake_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';

class AlimentacionMinutaEntryCard extends ConsumerWidget {
  const AlimentacionMinutaEntryCard({super.key});

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

    // SPEC-289: contar alimentos del repertorio (modelo nuevo); si es un
    // intake viejo, contar los items de sus comidas.
    final foodCount = intake == null
        ? 0
        : (intake.repertoireFoodIds.isNotEmpty
            ? intake.repertoireFoodIds.length
            : intake.meals
                .expand((m) => m.items)
                .where((i) => i.isMeaningful)
                .length);

    final subtitle = !configured
        ? 'Sin configurar'
        : '${_dietLabel(intake.restrictions.diet)} · $foodCount alimentos';

    return ProfileRow(
      icon: Icons.tune_rounded,
      title: 'Alimentación',
      value: subtitle,
      onTap: () => context.push('/nutrition/intake'),
    );
  }
}
