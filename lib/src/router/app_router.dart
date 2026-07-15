// SPEC-73: el router redirige por `AppAccount.profileStatus` y deja de
// consultar `users/{uid}` por su cuenta (antes hacía 3 llamadas a
// `isUserOnboarded` por cada cambio de ruta).

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/auth/presentation/login_screen.dart';
import 'package:elena_app/src/features/auth/presentation/register_screen.dart';
import 'package:elena_app/src/features/auth/presentation/forgot_password_screen.dart';
import 'package:elena_app/src/features/auth/presentation/set_password_screen.dart';
import 'package:elena_app/src/features/auth/presentation/splash_screen.dart';
import 'package:elena_app/src/features/auth/presentation/disclaimer_screen.dart';
import 'package:elena_app/src/features/auth/presentation/privacy_policy_screen.dart';
import 'package:elena_app/src/features/auth/presentation/terms_of_service_screen.dart';
import 'package:elena_app/src/router/router_redirect.dart';
import 'package:elena_app/src/features/onboarding/presentation/onboarding_screen.dart';
import 'package:elena_app/src/features/dashboard/presentation/dashboard_screen.dart';
// SPEC-137: vista semanal del pilar Nutrición (Cociente A + heatmap).
import 'package:elena_app/src/features/nutrition/presentation/nutrition_weekly_screen.dart';
import 'package:elena_app/src/features/auth/presentation/profile_screen.dart';
import 'package:elena_app/src/features/analysis/presentation/analysis_screen.dart';
// SPEC-168.4: pantalla detalle de un pilar (overview → chart completo).
import 'package:elena_app/src/features/analysis/presentation/analysis_pillar_detail_screen.dart';
import 'package:elena_app/src/features/analysis/presentation/daily_score_detail_screen.dart';
import 'package:elena_app/src/features/analysis/domain/chart_metric.dart';
// SPEC-12: Composición Corporal
import 'package:elena_app/src/features/profile/presentation/body_composition_screen.dart';
// SPEC-14: Objetivos del Usuario
import 'package:elena_app/src/features/goals/presentation/goal_setup_screen.dart';
// SPEC-15: Road Map de Avance Personal
import 'package:elena_app/src/features/progress/presentation/progress_screen.dart';
// 15-jul: pantalla independiente de insignias/gamificación — antes vivía
// embebida en Perfil (ver comentario en badges_screen.dart).
import 'package:elena_app/src/features/badges/presentation/badges_screen.dart';
// SPEC-234: rutina nocturna guiada
import 'package:elena_app/src/features/coaching/presentation/sleep_routine_screen.dart';

/// SPEC-222: llave global del navigator raíz para deeplink routing
/// desde notificaciones (cold start + foreground).
final rootNavigatorKey = GlobalKey<NavigatorState>();

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    navigatorKey: rootNavigatorKey,
    // SPEC-146: initialLocation cambiado de '/dashboard' a '/splash'
    // para evitar flash de pantallas privadas mientras Firebase Auth
    // hidrata la sesión del keychain en cold start. La lógica completa
    // del redirect vive en `computeRedirect` (función pura testeable).
    initialLocation: '/splash',
    redirect: (context, state) => computeRedirect(
      authState: authState,
      location: state.matchedLocation,
    ),
    routes: [
      // SPEC-146: ruta inicial mientras Firebase Auth hidrata la sesión.
      // El redirect navega desde aquí al destino correcto cuando el
      // authState resuelve.
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
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
      // SPEC-168.4: detalle de un pilar — desde el overview de Análisis.
      GoRoute(
        path: '/analysis/pillar/:metric',
        name: 'analysis-pillar',
        builder: (context, state) {
          final metricName = state.pathParameters['metric'] ?? '';
          final metric = ChartMetric.values.firstWhere(
            (m) => m.name == metricName,
            orElse: () => ChartMetric.imr,
          );
          return AnalysisPillarDetailScreen(metric: metric);
        },
      ),
      // SPEC-200: detalle del Score del Día (HOY) — tile propio en Resultados.
      GoRoute(
        path: '/analysis/daily-score',
        name: 'analysis-daily-score',
        builder: (context, state) => const DailyScoreDetailScreen(),
      ),
      // SPEC-137 §RF-137-12: vista semanal del pilar Nutrición.
      // Navegable desde el botón "Ver semana →" del card "Nutrición
      // Científica" en el Dashboard.
      GoRoute(
        path: '/nutrition/weekly',
        name: 'nutrition-weekly',
        builder: (context, state) => const NutritionWeeklyScreen(),
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
      // 15-jul: insignias/gamificación — empujada desde la card de
      // resumen en Perfil (mismo patrón que /profile/body-composition).
      GoRoute(
        path: '/profile/badges',
        name: 'profile-badges',
        builder: (context, state) => const BadgesScreen(),
      ),
      // SPEC-77: pantallas legales (privacy + terms).
      GoRoute(
        path: '/legal/privacy',
        name: 'privacy-policy',
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: '/legal/terms',
        name: 'terms-of-service',
        builder: (context, state) => const TermsOfServiceScreen(),
      ),
      // SPEC-78: deep links / universal links desde el sitio
      // Metamorfosis Real. Estas rutas resuelven con un redirect
      // interno hacia el destino real según el auth state.
      GoRoute(
        path: '/open',
        name: 'open-app',
        redirect: (context, state) {
          final account = ref.read(authStateProvider).value;
          return account == null ? '/login' : '/dashboard';
        },
      ),
      GoRoute(
        path: '/open/imr',
        name: 'open-imr',
        redirect: (context, state) {
          final account = ref.read(authStateProvider).value;
          if (account == null) return '/login';
          return account.needsOnboarding ? '/onboarding' : '/dashboard';
        },
      ),
      GoRoute(
        path: '/open/welcome',
        name: 'open-welcome',
        redirect: (context, state) {
          final account = ref.read(authStateProvider).value;
          if (account == null) return '/login';
          return account.needsOnboarding ? '/onboarding' : '/dashboard';
        },
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
      // SPEC-234: pantalla de rutina nocturna (deeplink desde notificación).
      GoRoute(
        path: '/sleep-routine',
        name: 'sleep-routine',
        builder: (context, state) => const SleepRoutineScreen(),
      ),
    ],
  );
});
