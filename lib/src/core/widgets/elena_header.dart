import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/engine/imr_persistence_provider.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class ElenaHeader extends ConsumerWidget {
  final String title;

  const ElenaHeader({
    super.key,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final streakState = ref.watch(streakProvider);
    // SPEC-118: chip de IMR del día en el header. Mismo provider que
    // usa el Perfil para mantener consistencia visual.
    final displayedImr = ref.watch(displayedImrProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : "U";

        return Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColors.metabolicGreen.withValues(alpha: 0.1),
              child: Text(
                initial,
                style: const TextStyle(
                  color: AppColors.metabolicGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    title,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.metabolicGreen,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            // SPEC-118: chip IMR de HOY. Tap → Análisis.
            _ImrChip(score: displayedImr.score, zone: displayedImr.zone),
            const SizedBox(width: 8),
            _StreakBadge(days: streakState.currentStreak),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// SPEC-118: chip que comunica el IMR del día actual sin invadir la
/// jerarquía visual del Dashboard. Color según zona del IMR. Tap
/// lleva a Análisis donde el usuario ve la métrica con su contexto
/// histórico completo.
class _ImrChip extends StatelessWidget {
  final int score;
  final String zone;

  const _ImrChip({required this.score, required this.zone});

  Color get _color {
    switch (zone) {
      case 'OPTIMIZADO':
        return const Color(0xFF10B981);
      case 'EFICIENTE':
        return const Color(0xFF22BB33);
      case 'FUNCIONAL':
        return const Color(0xFFFFD700);
      case 'INESTABLE':
        return const Color(0xFFFF8C00);
      default:
        return const Color(0xFFFF4444);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return InkWell(
      onTap: () => context.go('/analysis'),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$score',
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.0,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              'IMR',
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakBadge extends StatelessWidget {
  final int days;
  const _StreakBadge({required this.days});

  @override
  Widget build(BuildContext context) {
    final String label = days == 1 ? "DÍA" : "DÍAS";
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "$days $label",
            style: const TextStyle(
              color: Colors.orange,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 4),
          const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.orange,
            size: 12,
          ),
        ],
      ),
    );
  }
}
