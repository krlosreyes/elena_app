import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';

/// SPEC-119: extraído de `_buildBottomNav` en `dashboard_screen.dart`
/// (ARCH-03). Lógica de navegación intacta, sin cambios de comportamiento.
class DashboardBottomNav extends StatelessWidget {
  const DashboardBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith('/analysis')) currentIndex = 1;
    if (location.startsWith('/retos')) currentIndex = 2;
    if (location.startsWith('/profile')) currentIndex = 3;
    return BottomNavigationBar(
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: AppColors.metabolicGreen,
        unselectedItemColor: Colors.grey.withValues(alpha: 0.5),
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) context.go('/dashboard');
          // SPEC-197: gate vive dentro de AnalysisScreen (blur overlay).
          // Todos los usuarios navegan; free users ven el soft gate allí.
          if (index == 1) context.go('/analysis');
          if (index == 2) context.go('/retos');
          if (index == 3) context.go('/profile');
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_rounded), label: "Hoy"),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights_rounded), label: "Progreso"),
          BottomNavigationBarItem(
              icon: Icon(Icons.emoji_events_rounded), label: "Retos"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Perfil")
        ]);
  }
}
