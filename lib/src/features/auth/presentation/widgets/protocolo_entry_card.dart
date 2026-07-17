// 17-jul (2da vuelta, rediseño Perfil): card de entrada para
// "Protocolo de ayuno" — ver comentario en biometricos_entry_card.dart,
// mismo patrón. Tap navega a ProtocoloDetailScreen.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class ProtocoloEntryCard extends ConsumerWidget {
  const ProtocoloEntryCard({super.key});

  static const _color = AppColors.pillarAyuno;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protocol = ref.watch(
      currentUserStreamProvider.select((a) => a.valueOrNull?.fastingProtocol),
    );
    final subtitle = protocol == null ? '' : 'Activo · $protocol';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/profile/protocolo'),
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
              child: const Icon(Icons.hourglass_bottom_rounded,
                  color: _color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Protocolo de ayuno',
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
