// SPEC-288 (rediseño del Perfil): "Datos biométricos" como fila de lista
// agrupada (ProfileRow) en vez de tarjeta con borde de color. Tap navega a
// BiometricosDetailScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/features/auth/presentation/widgets/profile_settings_group.dart';
import 'package:elena_app/src/features/profile/application/biometric_lock_provider.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class BiometricosEntryCard extends ConsumerWidget {
  const BiometricosEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserStreamProvider).valueOrNull;
    final lock = ref.watch(biometricLockProvider);

    String subtitle;
    if (user == null) {
      subtitle = '';
    } else if (lock.isLocked) {
      subtitle = '🔒 ${lock.unlockLabel}';
    } else {
      final weight = '${user.weight.toInt()} kg';
      final bodyFat = user.bodyFatPercentage;
      subtitle = bodyFat == null
          ? weight
          : '$weight · ${bodyFat.toStringAsFixed(1)}% grasa';
    }

    return ProfileRow(
      icon: Icons.monitor_weight_outlined,
      title: 'Datos biométricos',
      value: subtitle,
      onTap: () => context.push('/profile/biometricos'),
    );
  }
}
