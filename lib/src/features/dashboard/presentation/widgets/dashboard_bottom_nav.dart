import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';

/// SPEC-119: extraído de `_buildBottomNav` en `dashboard_screen.dart`
/// (ARCH-03). Lógica de navegación intacta, sin cambios de comportamiento.
class DashboardBottomNav extends StatelessWidget {
  const DashboardBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    // Rediseño (2026-10-30): 3 pestañas — Hoy, Progreso, Perfil. "Retos"
    // salió de la barra y se abre desde Progreso, por eso /retos marca
    // Progreso como activa. Es la ÚNICA barra de la app: Progreso y Perfil
    // también la usan.
    final String location = GoRouterState.of(context).matchedLocation;
    int currentIndex = 0;
    if (location.startsWith('/analysis') || location.startsWith('/retos')) {
      currentIndex = 1;
    }
    if (location.startsWith('/profile')) currentIndex = 2;
    return BottomNavigationBar(
        backgroundColor: const Color(0xFF0F172A),
        selectedItemColor: AppColors.metabolicGreen,
        unselectedItemColor: Colors.grey.withValues(alpha: 0.5),
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) context.go('/dashboard');
          if (index == 1) context.go('/analysis');
          if (index == 2) context.go('/profile');
        },
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.wb_sunny_outlined), label: "Hoy"),
          BottomNavigationBarItem(
              icon: Icon(Icons.insights_rounded), label: "Progreso"),
          BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded), label: "Perfil"),
        ]);
  }
}
