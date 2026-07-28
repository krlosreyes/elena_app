// 17-jul (Propuesta "un Perfil que da orgullo abrir", P1): vitrina de
// logros en el Perfil — el patrón "trophy case" de Duolingo (ver
// investigación en la propuesta). Antes de esto, el Perfil no mostraba
// ni una sola cosa que el usuario hubiera ganado: insignias y racha
// vivían únicamente en Progreso. No se duplica el sistema — se
// reutilizan `badgeProvider` y `streakProvider` tal cual, solo se
// arma una vista compacta con las últimas insignias ganadas (círculos
// con el ícono/color de su categoría, mismo `kBadgeCategoryMeta` que
// usa la galería) + el estado de la racha. Tap navega a la galería
// completa (/profile/badges).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/badges/application/badge_notifier.dart';
import 'package:elena_app/src/features/badges/domain/badge_definition.dart';
import 'package:elena_app/src/features/badges/domain/earned_badge.dart';
import 'package:elena_app/src/features/badges/presentation/badge_category_meta.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';

class AchievementShowcaseCard extends ConsumerWidget {
  const AchievementShowcaseCard({super.key});

  static const _maxPreview = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final badgeState = ref.watch(badgeProvider);
    final streak = ref.watch(streakProvider);
    final totalBadges = BadgeCatalog.all.length;

    // Más recientes primero — lo último que ganaste es lo más relevante
    // para mostrar de entrada.
    final recent = [...badgeState.earned]
      ..sort((a, b) => b.unlockedAt.compareTo(a.unlockedAt));
    final preview = recent.take(_maxPreview).toList();
    final hasEarned = preview.isNotEmpty;

    final streakLabel = streak.currentStreak == 0
        ? 'Sin racha activa hoy'
        : '${streak.currentStreak} ${streak.currentStreak == 1 ? "día" : "días"} de racha'
            '${streak.longestStreak > streak.currentStreak ? " · récord ${streak.longestStreak}" : ""}';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => context.push('/profile/badges'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Tus logros',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white.withValues(alpha: 0.3),
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (hasEarned)
              Row(
                children: [
                  ...preview.map((b) => Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _BadgeCircle(badge: b),
                      )),
                  if (badgeState.earned.length > preview.length)
                    _MoreCircle(
                        count: badgeState.earned.length - preview.length),
                ],
              )
            else
              Row(
                children: List.generate(
                  4,
                  (i) => Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.05),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.10),
                        ),
                      ),
                      child: Icon(
                        Icons.emoji_events_outlined,
                        color: Colors.white.withValues(alpha: 0.20),
                        size: 18,
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 12),
            Text(
              hasEarned
                  ? '${badgeState.earned.length}/$totalBadges insignias · $streakLabel'
                  : 'Tus primeras insignias van a aparecer acá',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 12.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BadgeCircle extends StatelessWidget {
  const _BadgeCircle({required this.badge});
  final EarnedBadge badge;

  @override
  Widget build(BuildContext context) {
    final meta = kBadgeCategoryMeta[badge.category];
    final color = meta?.color ?? AppColors.metabolicGreen;
    final icon = meta?.icon ?? Icons.emoji_events_rounded;
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.16),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Icon(icon, color: color, size: 18),
    );
  }
}

class _MoreCircle extends StatelessWidget {
  const _MoreCircle({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.06),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.70),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
