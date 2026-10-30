import 'package:flutter/material.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/dashboard_bottom_nav.dart';

/// SPEC-119: extraído de `_buildBottomNav` en `profile_screen.dart`
/// (ARCH-03). Sin cambios de comportamiento.
class ProfileBottomNav extends StatelessWidget {
  const ProfileBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    // Rediseño (2026-10-30): misma barra de 3 pestañas que el resto.
    return const DashboardBottomNav();
  }
}
