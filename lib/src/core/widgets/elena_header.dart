import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
            // Racha como protagonista del header (IMR removido por redundante;
            // vive en Análisis). Se oculta si aún no hay racha.
            //
            // 17-jul: antes convivía con StreakTodayWidget (card debajo del
            // header, mismo dato "X días de racha" repetido dos veces en
            // Dashboard) y el tap de ambos abría el mismo sheet de reglas
            // — ninguno llevaba a la data real. Carlos pidió dejar un solo
            // indicador: este badge absorbe el texto de StreakTodayWidget
            // (ya no "X DÍAS" sino "X días de racha") y el tap ahora navega
            // directo al detalle con el gráfico de 30 días
            // (RachaDetailScreen, /analysis/racha) en vez de abrir el
            // explainer. Las reglas de la racha se quitaron de acá — siguen
            // accesibles vía el ⓘ dentro de esa pantalla (StreakSummaryCard).
            InkWell(
              onTap: () => context.push('/analysis/racha'),
              borderRadius: BorderRadius.circular(16),
              child: _StreakBadge(
                days: streakState.currentStreak,
                protected: streakState.streakHasProtectedDay,
              ),
            ),
          ],
        );
      },
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

/// Racha de días consecutivos — protagonista del header. Se oculta cuando
/// aún no hay racha (0 días) para no desmotivar.
class _StreakBadge extends StatelessWidget {
  final int days;

  /// SPEC-255 RF-02: true si esta racha incluye un día perdonado por una
  /// reserva — muestra un pequeño escudo junto a la flama.
  final bool protected;

  const _StreakBadge({required this.days, this.protected = false});

  @override
  Widget build(BuildContext context) {
    if (days < 1) return const SizedBox.shrink();
    // 17-jul: texto heredado de StreakTodayWidget (el card que este badge
    // reemplaza) — "X días de racha" en vez del "X DÍAS" terso original.
    final String label = '$days ${days == 1 ? "día" : "días"} de racha';
    const color = Colors.orange;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.local_fire_department_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w800,
              height: 1.0,
            ),
          ),
          if (protected) ...[
            const SizedBox(width: 5),
            Icon(
              Icons.shield_rounded,
              color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
              size: 14,
            ),
          ],
        ],
      ),
    );
  }
}
