import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../common_widgets/scaffold_with_navbar.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/register_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/training/presentation/screens/daily_workout_screen.dart';
import '../features/training/presentation/screens/workout_summary_screen.dart';
import '../features/nutrition/presentation/screens/nutrition_dashboard_screen.dart';
import '../features/fasting/presentation/fasting_screen.dart';

import '../features/training/domain/entities/workout_log.dart';

import '../features/authentication/application/auth_controller.dart';

import '../features/profile/data/user_repository.dart';
import '../features/profile/domain/user_model.dart';

part 'app_router.g.dart';

// Key for the root navigator - REMOVED to avoid collision
// Key for the shell navigator - REMOVED to avoid collision

@riverpod
GoRouter goRouter(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  
  // Si hay usuario autenticado, escuchamos su perfil de Firestore en tiempo real
  // Usamos .select para evitar reconstruir el Router con cada cambio del usuario (ej. peso),
  // lo cual regenera el Router y causa conflicto de GlobalKey. Solo nos importa onboarding y loading.
  // Simplification to fix build error: watch the full provider
  final userAsync = authState.asData?.value != null
      ? ref.watch(userStreamProvider(authState.asData!.value!.uid))
      : const AsyncValue<UserModel?>.loading();

  final userRedirectionState = (
    isLoading: userAsync.isLoading,
    onboardingCompleted: userAsync.asData?.value?.onboardingCompleted ?? false,
  );

  return GoRouter(
    initialLocation: '/login',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      if (authState.isLoading) return null;
      if (authState.hasError) return null;

      final isLoggedIn = authState.asData?.value != null;
      final isLoggingIn = state.uri.path == '/login';
      final isRegistering = state.uri.path == '/register';

      // 1. NO LOGUEADO -> Forzar Login (a menos que ya esté en login/register)
      if (!isLoggedIn) {
        if (isLoggingIn || isRegistering) return null;
        return '/login';
      }

      // 2. LOGUEADO -> Verificar Perfil de Usuario
      // Si el stream del usuario está cargando o tiene error (latencia de red),
      // NO redirigimos agresivamente para evitar bucles.
      if (userAsync.isLoading) return null;
      
      // Si hay error de red (visto en logs), permitimos que se quede donde está
      // para que el usuario pueda intentar reintentar o cerrar sesión.
      if (userAsync.hasError) {
         debugPrint('Router Error: ${userAsync.error}');
         return null; 
      }

      final user = userAsync.value;
      
      // 3. LOGUEADO PERO SIN PERFIL EN FIRESTORE (Nuevo Usuario)
      if (user == null) {
        if (state.uri.path == '/onboarding') return null;
        return '/onboarding';
      }

      final onboardingCompleted = user.onboardingCompleted;

      // 4. LOGUEADO -> ONBOARDING INCOMPLETO
      if (!onboardingCompleted) {
        if (state.uri.path == '/onboarding') return null;
        return '/onboarding';
      }

      // 5. LOGUEADO -> ONBOARDING COMPLETO -> DASHBOARD
      // Proteger rutas de Auth y Onboarding para que no vuelva atrás
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
          GoRoute(
            path: '/nutrition',
            pageBuilder: (context, state) => const NoTransitionPage(child: NutritionDashboardScreen()),
          ),
          GoRoute(
            path: '/fasting',
            pageBuilder: (context, state) => const NoTransitionPage(child: FastingScreen()),
          ),
        ],
      ),
      GoRoute(
        path: '/daily-workout',
        builder: (context, state) => const DailyWorkoutScreen(),
      ),
      GoRoute(
        path: '/workout-summary',
        name: WorkoutSummaryScreen.routeName,
        builder: (context, state) {
          final log = state.extra as WorkoutLog;
          return WorkoutSummaryScreen(log: log);
        },
      ),
    ],
  );
}
