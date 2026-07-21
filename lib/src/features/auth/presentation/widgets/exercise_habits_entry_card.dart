// Propuesta módulo Ejercicio (2026-07-21) — punto de entrada para
// usuarios YA EXISTENTES. El paso de hábitos de ejercicio se agregó al
// onboarding (SPEC nuevo, ver ExerciseProfile), pero un perfil completo
// nunca vuelve a pasar por /onboarding (ver router_redirect.dart) — sin
// esta card, ningún usuario existente tiene forma de generar su
// ExerciseProfile ni, por lo tanto, su plan semanal. Mismo patrón que
// ProtocoloEntryCard/RitmosEntryCard — tap navega a la pantalla de
// detalle que reusa el mismo formulario del onboarding.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/exercise/application/exercise_profile_providers.dart';

class ExerciseHabitsEntryCard extends ConsumerWidget {
  const ExerciseHabitsEntryCard({super.key});

  static const _color = AppColors.pillarEjercicio;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(exerciseProfileStreamProvider);
    final hasProfile = profileAsync.valueOrNull != null &&
        !(profileAsync.valueOrNull!.isInitial);
    final subtitle = hasProfile
        ? 'Configurado · tu plan semanal ya está activo'
        : 'Sin configurar · arma tu plan de fuerza + cardio';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/profile/ejercicio'),
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
              child: const Icon(Icons.fitness_center_rounded,
                  color: _color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Hábitos de ejercicio',
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
