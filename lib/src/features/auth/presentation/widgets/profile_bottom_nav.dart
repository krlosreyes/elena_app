import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';

/// SPEC-119: extraído de `_buildBottomNav` en `profile_screen.dart`
/// (ARCH-03). Sin cambios de comportamiento.
class ProfileBottomNav extends StatelessWidget {
  const ProfileBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.backgroundDark,
      selectedItemColor: const Color(0xFF10B981),
      unselectedItemColor: Colors.grey.withValues(alpha: 0.5),
      currentIndex: 3,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 0) context.go('/dashboard');
        if (index == 1) context.go('/analysis');
        if (index == 2) context.go('/retos');
        if (index == 3) context.go('/profile');
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded), label: 'Hoy'),
        BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded), label: 'Progreso'),
        BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_rounded), label: 'Retos'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
}
