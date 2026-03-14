import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../features/authentication/data/auth_repository.dart';
import '../features/profile/data/user_repository.dart';
import '../features/profile/domain/user_model.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  final Widget child;

  const ScaffoldWithNavBar({required this.child, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Get current user for Avatar
    final authUser = ref.watch(authRepositoryProvider).currentUser;
    final userAsync = authUser != null
        ? ref.watch(userStreamProvider(authUser.uid))
        : const AsyncValue<UserModel?>.loading();

    // Calculate current index based on current location
    final String location = GoRouterState.of(context).uri.path;
    int currentIndex = 0;
    if (location.startsWith('/progress')) {
      currentIndex = 1;
    } else if (location.startsWith('/profile')) {
      currentIndex = 2;
    }

    // Build avatar widget helper
    Widget buildAvatar({required bool selected}) {
      return userAsync.when(
        data: (user) {
          final initial = (user?.name?.isNotEmpty == true)
              ? user!.name![0].toUpperCase()
              : 'P';
          return Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: const Color(0xFF009688), width: 2)
                  : null,
            ),
            child: CircleAvatar(
              radius: 14,
              backgroundColor: selected ? const Color(0xFF009688) : const Color(0xFF1565C0),
              child: Text(
                initial,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
        loading: () => const CircleAvatar(radius: 14, backgroundColor: Color(0xFF1565C0)),
        error: (_, __) => const CircleAvatar(radius: 14, backgroundColor: Color(0xFF1565C0)),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: Theme.of(context).cardTheme.color,
        indicatorColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        elevation: 0,
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go('/dashboard');
          } else if (index == 1) {
            context.go('/progress');
          } else if (index == 2) {
            context.push('/profile');
          }
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined, color: Colors.white),
            selectedIcon: Icon(Icons.home, color: Theme.of(context).colorScheme.primary),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: const Icon(Icons.show_chart, color: Colors.white),
            selectedIcon: Icon(Icons.show_chart, color: Theme.of(context).colorScheme.primary),
            label: 'Progreso',
          ),
          NavigationDestination(
            icon: buildAvatar(selected: false),
            selectedIcon: buildAvatar(selected: true),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
