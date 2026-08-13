// SPEC-288 (rediseño del Perfil): "Protocolo de ayuno" como fila de lista
// agrupada (ProfileRow). Tap navega a ProtocoloDetailScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/features/auth/presentation/widgets/profile_settings_group.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class ProtocoloEntryCard extends ConsumerWidget {
  const ProtocoloEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protocol = ref.watch(
      currentUserStreamProvider.select((a) => a.valueOrNull?.fastingProtocol),
    );
    final subtitle = protocol == null ? '' : 'Activo · $protocol';

    return ProfileRow(
      icon: Icons.hourglass_bottom_rounded,
      title: 'Protocolo de ayuno',
      value: subtitle,
      onTap: () => context.push('/profile/protocolo'),
    );
  }
}
