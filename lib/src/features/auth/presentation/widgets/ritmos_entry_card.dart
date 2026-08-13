// SPEC-288 (rediseño del Perfil): "Ritmos circadianos" como fila de lista
// agrupada (ProfileRow). Tap navega a RitmosCircadianosDetailScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/features/auth/presentation/widgets/profile_settings_group.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class RitmosEntryCard extends ConsumerWidget {
  const RitmosEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final subtitle = user == null
        ? ''
        : '${TimeOfDay.fromDateTime(user.profile.wakeUpTime).format(context)}'
            ' → ${TimeOfDay.fromDateTime(user.profile.sleepTime).format(context)}';

    return ProfileRow(
      icon: Icons.brightness_4_rounded,
      title: 'Ritmos circadianos',
      value: subtitle,
      onTap: () => context.push('/profile/ritmos'),
    );
  }
}
