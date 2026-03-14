import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../profile/application/user_controller.dart';

class DashboardHeader extends ConsumerWidget {
  const DashboardHeader({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 1. Escuchamos al usuario en tiempo real
    final userAsync = ref.watch(currentUserStreamProvider);

    return userAsync.when(
      data: (user) {
        final name = user?.name ?? 'Usuario';
        final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
        final firstName = name.split(' ').first;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Hola, $firstName",
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              "Vamos a cumplir tus metas hoy",
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[400],
                  ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        );
      },
      loading: () => const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           Text("Cargando perfil..."),
           CircularProgressIndicator()
        ]
      ),
      error: (err, stack) => const Text("Hola, Campeón"), // Fallback seguro
    );
  }
}
