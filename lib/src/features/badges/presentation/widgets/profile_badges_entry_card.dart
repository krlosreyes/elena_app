// Card de entrada compacta para la sección "Insignias" de Perfil (15-jul,
// rediseño "pantalla independiente" — ver comentario en badges_screen.dart
// para el porqué). Reemplaza al bloque de 3 widgets (AvancesHeader +
// TuCaminoTimeline + BadgeGallery) que antes vivía inline en el ListView
// de Perfil. Esta card solo resume el estado (insignias ganadas + racha
// actual) y navega a la pantalla completa — el resto de Perfil vuelve a
// ser una lista corta de configuración.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/features/badges/application/badge_notifier.dart';
import 'package:elena_app/src/features/badges/domain/badge_definition.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';

class ProfileBadgesEntryCard extends ConsumerWidget {
  const ProfileBadgesEntryCard({super.key});

  static const _color = Color(0xFFFBBF24);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnedCount = ref.watch(badgeProvider.select((s) => s.earned.length));
    final totalBadges = BadgeCatalog.all.length;
    final currentStreak = ref.watch(streakProvider.select((s) => s.currentStreak));

    final streakLabel = currentStreak == 1
        ? '1 día de racha'
        : '$currentStreak días de racha';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => context.push('/profile/badges'),
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
              child: const Icon(Icons.emoji_events_rounded,
                  color: _color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Insignias',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$earnedCount/$totalBadges ganadas · $streakLabel',
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
