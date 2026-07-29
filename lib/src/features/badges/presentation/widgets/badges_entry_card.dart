// Card de entrada compacta al sistema de insignias (15-jul, segunda
// vuelta de feedback de Carlos). Primero vivió en Perfil (ver
// project_badges_dedicated_screen); Carlos pidió sacarla de ahí también y
// ponerla como primera card del tab "Progreso" (AnalysisScreen,
// /analysis) — es el lugar donde ya vive la sección "Tu racha", así que
// insignias queda junto a su pariente conceptual más cercana en vez de
// en un settings screen. Resume el estado (insignias ganadas + racha
// actual) y navega a la pantalla completa (badges_screen.dart,
// /profile/badges — la ruta no cambió, solo quién enlaza a ella).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/features/badges/application/badge_notifier.dart';
import 'package:elena_app/src/features/badges/domain/badge_definition.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';

class BadgesEntryCard extends ConsumerWidget {
  const BadgesEntryCard({super.key});

  static const _color = Color(0xFFFBBF24);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final earnedCount = ref.watch(badgeProvider.select((s) => s.earned.length));
    final totalBadges = BadgeCatalog.all.length;
    final currentStreak =
        ref.watch(streakProvider.select((s) => s.currentStreak));

    final streakLabel =
        currentStreak == 1 ? '1 día de racha' : '$currentStreak días de racha';

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
                    'Tus insignias',
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
