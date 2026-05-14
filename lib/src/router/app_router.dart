// SPEC-73: el router redirige por `AppAccount.profileStatus` y deja de
// consultar `users/{uid}` por su cuenta (antes hacía 3 llamadas a
// `isUserOnboarded` por cada cambio de ruta).

import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/auth/presentation/login_screen.dart';
import 'package:elena_app/src/features/auth/presentation/register_screen.dart';
import 'package:elena_app/src/features/auth/presentation/forgot_password_screen.dart';
import 'package:elena_app/src/features/auth/presentation/set_password_screen.dart';
import 'package:elena_app/src/features/auth/presentation/disclaimer_screen.dart';
import 'package:elena_app/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:elena_app/src/features/dashboard/presentation/dashboard_screen.dart';
import 'package:elena_app/src/features/auth/presentation/profile_screen.dart';
import 'package:elena_app/src/features/analysis/presentation/analysis_screen.dart';
// SPEC-12: Composición Corporal
import 'package:elena_app/src/features/profile/presentation/body_composition_screen.dart';
// SPEC-14: Objetivos del Usuario
import 'package:elena_app/src/features/goals/presentation/goal_setup_screen.dart';
// SPEC-15: Road Map de Avance Personal
import 'package:elena_app/src/features/progress/presentation/progress_screen.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/dashboard',
    redirect: (context, state) {
      final account = authState.value;
      final loc = state.matchedLocation;

      final isPublic = loc == '/login' ||
          loc == '/register' ||
          loc == '/forgot-password' ||
          loc == '/set-password';

      // 1. No autenticado.
      if (account == null) {
        return isPublic ? null : '/login';
      }

      // 2. Autenticado en ruta pública → llevar a destino correcto.
      if (isPublic) {
        return account.isComplete ? '/dashboard' : '/onboarding';
      }

      // 3. Perfil incompleto (NEW o PARTIAL) → forzar onboarding,
      //    excepto si ya está allí.
      if (account.needsOnboarding && loc != '/onboarding') {
        return '/onboarding';
      }

      // 4. Perfil completo intentando entrar a /onboarding → al dashboard.
      if (account.isComplete && loc == '/onboarding') {
        return '/dashboard';
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
      // SPEC-73 §RF-73-09: flujo de magic link.
      GoRoute(
        path: '/set-password',
        name: 'set-password',
        builder: (context, state) {
          final emailLink = state.uri.toString();
          final email = state.uri.queryParameters['email'];
          return SetPasswordScreen(
            emailLink: emailLink,
            initialEmail: email,
          );
        },
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
      GoRoute(
        path: '/profile/body-composition',
        name: 'body-composition',
        builder: (context, state) => const BodyCompositionScreen(),
      ),
      // SPEC-76: pantalla read-only del disclaimer médico.
      GoRoute(
        path: '/profile/disclaimer',
        name: 'disclaimer',
        builder: (context, state) => const DisclaimerScreen(),
      ),
      GoRoute(
        path: '/goals/setup',
        name: 'goals-setup',
        builder: (context, state) => const GoalSetupScreen(),
      ),
      GoRoute(
        path: '/progress',
        name: 'progress',
        builder: (context, state) => const ProgressScreen(),
      ),
    ],
  );
});
