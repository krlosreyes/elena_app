import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/dashboard/application/ui_interaction_notifier.dart';
import 'package:elena_app/src/features/engagement/application/engagement_service.dart';

/// Banner de Engagement (SPEC-07) con descarte por sesión (SPEC-72.2).
///
/// Se muestra cuando el `EngagementState.level` no es `neutro` y el usuario
/// no lo ha descartado en esta sesión. El descarte se almacena en
/// `uiInteractionProvider`. SPEC-58 invoca `resetDismissals()` cada día,
/// por lo que el banner reaparece naturalmente en el siguiente ciclo si la
/// condición que lo origina persiste.
class EngagementBanner extends ConsumerWidget {
  const EngagementBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engagement = ref.watch(engagementProvider);
    final dismissed = ref.watch(uiInteractionProvider).isEngagementBannerDismissed;

    if (engagement.level == EngagementLevel.neutro || dismissed) {
      return const SizedBox.shrink();
    }

    final (statusColor, statusIcon) = switch (engagement.level) {
      EngagementLevel.excelente => (
          const Color(0xFF10B981),
          Icons.stars_rounded,
        ),
      EngagementLevel.bueno => (
          const Color(0xFF34D399),
          Icons.check_circle_rounded,
        ),
      EngagementLevel.regular => (
          const Color(0xFFFBBF24),
          Icons.info_outline_rounded,
        ),
      EngagementLevel.critico => (
          const Color(0xFFF87171),
          Icons.error_outline_rounded,
        ),
      EngagementLevel.neutro => (
          Colors.grey,
          Icons.hourglass_empty_rounded,
        ),
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(statusIcon, color: statusColor, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'COMPROMISO: ${engagement.status.toUpperCase()}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: statusColor,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  engagement.message,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          // SPEC-72.2: botón cerrar.
          IconButton(
            tooltip: 'Ocultar por ahora',
            icon: Icon(
              Icons.close_rounded,
              color: statusColor.withValues(alpha: 0.7),
              size: 20,
            ),
            onPressed: () =>
                ref.read(uiInteractionProvider.notifier).dismissEngagementBanner(),
          ),
        ],
      ),
    );
  }
}
