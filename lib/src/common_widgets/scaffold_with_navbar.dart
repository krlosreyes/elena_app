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

    // Calculate current index for BottomNavigationBar based on current location
    final String location = GoRouterState.of(context).uri.path;
    
    // Default to 0 (Home)
    int currentIndex = 0;
    if (location.startsWith('/progress')) {
      currentIndex = 1;
    } else if (location.startsWith('/profile')) {
      // Profile usually doesn't have a tab, but if we want to show it as "active" or just valid
      // For now, let's say it keeps the last tab or creates a phantom state.
      // Requirements say: "ensure when on profile, avatar doesn't do anything redundant".
      // We will leave index as is or maybe not highlight any if on profile?
      // Let's stick to Home/Progress tabs. 
      // If we are on profile, maybe we don't highlight bottom nav or highlight home?
      // Let's keep it simple: Home=0, Progress=1. If Profile, maybe unselected?
      // NavigationBar requires valid index. 
      // Let's assume Profile is a separate pushed screen usually, BUT user said:
      // "Mover la lógica de la AppBar... eliminar AppBar de ProfileScreen".
      // This implies ProfileScreen is INSIDE the shell.
      // If Profile is inside shell, it needs a way to NOT crash nav bar index.
      // Let's just default to 0 if unknown, or maybe make index nullable? NavigationBar index must be non-null.
      // Actually, standard pattern with ShellRoute is that Profile might cover the shell or be part of it.
      // If part of it, we need a tab for it OR we accept that one tab is selected while unrelated content is shown.
      // HOWEVER, the user asked for BottomNavBar to be part of GLOBAL Scaffold.
      // Let's implement it such that:
      // 0: Dashboard
      // 1: Progress
      // If on Profile, we can either hide BottomNav or just let it sit there.
      // Let's stick to 0/1.
      currentIndex = location.startsWith('/progress') ? 1 : 0;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        backgroundColor: Colors.white,
        elevation: 2,
        onDestinationSelected: (index) {
          if (index == 0) {
            context.go('/dashboard');
          } else if (index == 1) {
            context.go('/progress');
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.show_chart),
            selectedIcon: Icon(Icons.show_chart),
            label: 'Progreso',
          ),
        ],
      ),
    );
  }
}
