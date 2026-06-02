// SPEC-146 §RF-146-01: Splash screen mientras Firebase Auth hidrata
// la sesión del keychain.
//
// Vive como ruta `/splash` (initialLocation del GoRouter). Cuando el
// `authStateProvider` resuelve (deja de ser AsyncLoading), el router
// invoca su redirect y navega al destino correcto. El SplashScreen
// solo renderiza branding + progress indicator.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // No watcheamos authStateProvider explícitamente aquí — el redirect
    // del GoRouter se invoca con cada cambio del provider y navega
    // automáticamente cuando resuelve. Este widget solo renderiza el
    // loading visual mientras tanto.
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Branding — texto por MVP. SPEC posterior puede reemplazar
              // por asset image del logo.
              Text(
                'Metamorfosis Real',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.92),
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Elena · Salud metabólica',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 36),
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    AppColors.metabolicGreen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
