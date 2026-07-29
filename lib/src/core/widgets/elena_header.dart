import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/widgets/page_hero.dart';
import 'package:elena_app/src/core/widgets/profile_avatar.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// Encabezado del Dashboard: el hero "Hoy" + el avatar que lleva a Perfil.
///
/// 29-jul: el Dashboard era la única pestaña raíz SIN título — mostraba
/// el nombre del usuario en mayúsculas y "Metamorfosis Real" debajo,
/// mientras Progreso tenía un hero de 34 px y Perfil un AppBar de 18.
/// Al unificar los tres heroes, este espacio pasa a decir en qué
/// pestaña estás, que es lo que hacía falta; el nombre del usuario sale
/// de acá porque el avatar ya comunica identidad y es el que navega a
/// Perfil, donde el nombre sí se muestra completo.
class ElenaHeader extends ConsumerWidget {
  const ElenaHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) return const SizedBox.shrink();

        return Row(
          children: [
            Expanded(
              child: PageHero(
                title: 'Hoy',
                subtitle: heroTodayLabel(),
              ),
            ),
            const SizedBox(width: 12),
            // El avatar lleva al perfil del usuario.
            //
            // 29-jul: era un CircleAvatar con la inicial calculada acá
            // (`user.name[0]`) — una segunda implementación del mismo
            // avatar que hay en Perfil, con reglas distintas y sin la
            // foto del proveedor. Se reemplaza por `ProfileAvatar`, que
            // ahora es la fuente única: misma foto de Google, misma
            // inicial de respaldo, en las dos pantallas.
            InkWell(
              onTap: () => context.go('/profile'),
              customBorder: const CircleBorder(),
              child: ProfileAvatar(name: user.name, size: 44),
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
