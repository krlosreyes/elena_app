import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/auth/presentation/login_screen.dart';
import 'package:elena_app/src/features/auth/presentation/register_screen.dart';
import 'package:elena_app/src/features/auth/presentation/forgot_password_screen.dart';
import 'package:elena_app/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:elena_app/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:elena_app/src/features/auth/presentation/profile_screen.dart';
import 'package:elena_app/src/features/analysis/presentation/analysis_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  // Escuchamos el estado de autenticación
  final authState = ref.watch(authStateProvider);
  final authRepository = ref.watch(authRepositoryProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    // IMPORTANTE: Esto obliga al router a re-evaluar el redirect 
    // cuando el estado de autenticación cambia.
    refreshListenable: Listenable.merge([
      // Si tu authStateProvider fuera un ChangeNotifier, lo pondrías aquí.
      // Como es un AsyncValue, GoRouter lo maneja por el flujo del Provider.
    ]),
    redirect: (context, state) async {
      final user = authState.value;
      final loc = state.matchedLocation;
      
      final isPublic = loc == '/login' || 
                       loc == '/register' || 
                       loc == '/forgot-password';

      // 1. Si no hay usuario logueado
      if (user == null) {
        return isPublic ? null : '/login';
      }

      // 2. Si el usuario está logueado pero intenta ir a rutas públicas,
      // lo mandamos al flujo interno (Onboarding o Dashboard)
      if (isPublic) {
        final isOnboarded = await authRepository.isUserOnboarded(user.id);
        return isOnboarded ? '/dashboard' : '/onboarding';
      }

      // 3. Verificación de Onboarding obligatoria
      // Solo consultamos la DB si no estamos ya en la pantalla de onboarding
      if (loc != '/onboarding') {
        final isOnboarded = await authRepository.isUserOnboarded(user.id);
        if (!isOnboarded) return '/onboarding';
      }

      // 4. Si ya está onboarded e intenta entrar a /onboarding de nuevo
      if (loc == '/onboarding') {
        final isOnboarded = await authRepository.isUserOnboarded(user.id);
        if (isOnboarded) return '/dashboard';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/dashboard',
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/analysis',
        name: 'analysis',
        builder: (context, state) => const AnalysisScreen(),
      ),
    ],
  );
});