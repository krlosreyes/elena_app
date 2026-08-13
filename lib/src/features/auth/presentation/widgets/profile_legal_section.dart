// SPEC-288 (rediseño del Perfil): "Condiciones médicas" (Salud) y "Guía de la
// app" (Ayuda) como filas de lista agrupada (ProfileRow). Privacidad y
// términos se arman directo en profile_screen (solo navegan).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/features/auth/presentation/widgets/profile_settings_group.dart';
import 'package:elena_app/src/features/onboarding/application/app_tour_notifier.dart';

/// Declaración de salud del usuario — sección "Salud" del Perfil. Lo que él
/// mismo marcó (embarazo, diabetes, trastorno alimentario…) y que gatea los
/// protocolos de ayuno.
class ProfileHealthConditionsCard extends StatelessWidget {
  const ProfileHealthConditionsCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ProfileRow(
      icon: Icons.health_and_safety_outlined,
      title: 'Condiciones médicas',
      value: 'Tu declaración',
      onTap: () => context.push('/profile/disclaimer'),
    );
  }
}

/// "Guía de la app" (sección Ayuda) — reinicia y reactiva el tour interactivo.
class ProfileHelpGuideCard extends ConsumerWidget {
  const ProfileHelpGuideCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ProfileRow(
      icon: Icons.explore_outlined,
      title: 'Guía de la app',
      value: 'Ver el tour',
      onTap: () async {
        await ref.read(appTourProvider.notifier).forceReset();
        await ref.read(appTourProvider.notifier).tryActivate();
        if (context.mounted) context.go('/dashboard');
      },
    );
  }
}
