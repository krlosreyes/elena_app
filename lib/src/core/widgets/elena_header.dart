import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
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

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();
        final initial = user.name.isNotEmpty ? user.name[0].toUpperCase() : "U";

        return Row(
          children: [
            // El avatar lleva al perfil del usuario.
            InkWell(
              onTap: () => context.go('/profile'),
              customBorder: const CircleBorder(),
              child: CircleAvatar(
                backgroundColor:
                    AppColors.metabolicGreen.withValues(alpha: 0.1),
                child: Text(
                  initial,
                  style: const TextStyle(
                    color: AppColors.metabolicGreen,
                    fontWeight: FontWeight.bold,
                  ),
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
            // 22-jul: el badge de racha que vivía acá (`_StreakBadge`,
            // commit fb32b03, "un solo indicador") se quitó del header.
            // Carlos pidió consolidar la racha en un ÚNICO lugar y, al
            // mismo tiempo, resolver que el "puente visual" de
            // `DailyScoreHero` (card "PROGRESO HOY" del Dashboard)
            // mostraba 5 íconos de pilares redundantes con la fila de
            // abajo. Se resolvieron los dos hallazgos con un solo
            // movimiento: la racha se mudó a ese puente visual (ver
            // `DailyScoreHero.streakDays` en daily_score_hero.dart) y
            // este header dejó de mostrarla. El tap que antes abría acá
            // sigue existiendo — ahora vive en el bloque de racha dentro
            // de esa card (`/analysis/racha`, mismo destino).
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
