// 17-jul (2da vuelta, rediseño Perfil): card de entrada para "Datos
// biométricos" — mismo patrón que BadgesEntryCard (icono + título +
// subtítulo + chevron), coherente con el resto de la app. Tap navega
// a BiometricosDetailScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/features/profile/application/biometric_lock_provider.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class BiometricosEntryCard extends ConsumerWidget {
  const BiometricosEntryCard({super.key});

  static const _color = Color(0xFF38BDF8);

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

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/profile/biometricos'),
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
              child: const Icon(Icons.monitor_weight_outlined,
                  color: _color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Datos biométricos',
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
