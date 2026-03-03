import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hola, $firstName", // <--- CORRECCIÓN 1: NOMBRE
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  "Vamos a cumplir tus metas hoy",
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey,
                      ),
                ),
              ],
            ),
            GestureDetector(
              onTap: () {
                 // Navegación al perfil
                 context.pushNamed('profile');
              },
              child: CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blueAccent,
                child: Text(
                  initial, // <--- CORRECCIÓN 2: INICIAL
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
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
