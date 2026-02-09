import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../common_widgets/scaffold_with_navbar.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/register_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/progress/presentation/progress_screen.dart';

import '../features/authentication/data/auth_repository.dart';

import '../features/profile/data/user_repository.dart';
import '../features/profile/domain/user_model.dart';

part 'app_router.g.dart';

// Key for the root navigator - REMOVED to avoid collision
// Key for the shell navigator - REMOVED to avoid collision

@riverpod
GoRouter goRouter(GoRouterRef ref) {
  final authState = ref.watch(authStateChangesProvider);
  
  // Si hay usuario autenticado, escuchamos su perfil de Firestore en tiempo real
  // Usamos .select para evitar reconstruir el Router con cada cambio del usuario (ej. peso),
  // lo cual regenera el Router y causa conflicto de GlobalKey. Solo nos importa onboarding y loading.
  final userRedirectionState = authState.valueOrNull != null
      ? ref.watch(userStreamProvider(authState.value!.uid).select((value) {
          return (
            isLoading: value.isLoading,
            onboardingCompleted: value.valueOrNull?.onboardingCompleted ?? false,
          );
        }))
      : null;

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      if (authState.isLoading || authState.hasError) return null;

      final isLoggedIn = authState.valueOrNull != null;
      final isLoggingIn = state.uri.path == '/login';
      final isRegistering = state.uri.path == '/register';

      // 1. No Logueado -> Login
      if (!isLoggedIn) {
        if (isLoggingIn || isRegistering) return null;
        return '/login';
      }

      // 2. Logueado -> Verificar Onboarding
      // Si el stream de usuario está cargando inicial, esperamos
      if (userRedirectionState == null || userRedirectionState.isLoading) return null;

      final onboardingCompleted = userRedirectionState.onboardingCompleted;

      if (!onboardingCompleted) {
        if (state.uri.path == '/onboarding') return null;
        return '/onboarding';
      }

      // 3. Onboarding Completo -> Dashboard (y proteger rutas de auth/onboarding)
      if (isLoggingIn || isRegistering || state.uri.path == '/onboarding') {
        return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      // ShellRoute wraps the main application screens
      ShellRoute(
        builder: (context, state, child) {
          return ScaffoldWithNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/dashboard',
            pageBuilder: (context, state) => const NoTransitionPage(child: DashboardScreen()),
          ),
          GoRoute(
            path: '/progress',
            pageBuilder: (context, state) => const NoTransitionPage(child: ProgressScreen()),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            pageBuilder: (context, state) => const NoTransitionPage(child: ProfileScreen()),
          ),
        ],
      ),
    ],
  );
}
