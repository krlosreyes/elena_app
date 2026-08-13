// SPEC-288 (rediseño del Perfil): "Consumo consciente" como fila de lista
// agrupada (ProfileRow). Entrada permanente al Protocolo de Consumo
// Consciente (SPEC-261.3) para activarlo cuando el usuario quiera.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/features/auth/presentation/widgets/profile_settings_group.dart';
import 'package:elena_app/src/features/alcohol/application/consumption_notifier.dart';

class AlcoholProtocolEntryCard extends ConsumerWidget {
  const AlcoholProtocolEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(consumptionProvider);
    final subtitle = session.isActive
        ? 'Activo · ${session.totalStandardUnits.toStringAsFixed(1)} UEA'
        : 'Actívalo para tus salidas';

    return ProfileRow(
      icon: Icons.wine_bar,
      title: 'Consumo consciente',
      value: subtitle,
      onTap: () => context.push('/protocolo-alcohol'),
    );
  }
}
