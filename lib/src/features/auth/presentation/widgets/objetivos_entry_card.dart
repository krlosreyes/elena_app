// SPEC-288 (rediseño del Perfil): "Mis objetivos" como fila de lista
// agrupada (ProfileRow). Tap navega a ObjetivosDetailScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/features/auth/presentation/widgets/profile_settings_group.dart';
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';

class ObjetivosEntryCard extends ConsumerWidget {
  const ObjetivosEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(goalsProvider).values;
    final activeCount = goals.where((g) => g.isActive).length;
    final subtitle = goals.isEmpty
        ? 'Aún sin configurar'
        : '$activeCount ${activeCount == 1 ? "objetivo activo" : "objetivos activos"}';

    return ProfileRow(
      icon: Icons.flag_rounded,
      title: 'Mis objetivos',
      value: subtitle,
      onTap: () => context.push('/profile/objetivos'),
    );
  }
}
