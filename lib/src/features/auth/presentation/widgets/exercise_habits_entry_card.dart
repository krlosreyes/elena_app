// SPEC-288 (rediseño del Perfil): "Hábitos de ejercicio" como fila de lista
// agrupada (ProfileRow). Punto de entrada para usuarios YA EXISTENTES a su
// ExerciseProfile (un perfil completo no vuelve a pasar por /onboarding).
// Tap navega a la pantalla de detalle que reusa el formulario del onboarding.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/features/auth/presentation/widgets/profile_settings_group.dart';
import 'package:elena_app/src/features/exercise/application/exercise_profile_providers.dart';

class ExerciseHabitsEntryCard extends ConsumerWidget {
  const ExerciseHabitsEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(exerciseProfileStreamProvider);
    final hasProfile = profileAsync.valueOrNull != null &&
        !(profileAsync.valueOrNull!.isInitial);
    final subtitle = hasProfile ? 'Configurado' : 'Sin configurar';

    return ProfileRow(
      icon: Icons.fitness_center_rounded,
      title: 'Hábitos de ejercicio',
      value: subtitle,
      onTap: () => context.push('/profile/ejercicio'),
    );
  }
}
