import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/services/analytics_service.dart';
import '../core/services/app_logger.dart';
import '../features/authentication/application/auth_controller.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/register_screen.dart';
import '../features/dashboard/dashboard.dart'; // ✅ USAMOS FACHADA
import '../features/fasting/presentation/fasting_feeding_screen.dart';
import '../features/hydration/presentation/hydration_screen.dart';
import '../features/nutrition/presentation/registro_nutricion_screen.dart';
import '../features/onboarding/application/onboarding_controller.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/application/user_controller.dart';
import '../features/profile/presentation/profile_screen.dart';
import '../features/progress/presentation/progress_screen.dart';
import '../features/sleep/presentation/sleep_analysis_screen.dart';
import '../features/training/domain/entities/weekly_routine.dart';
import '../features/training/presentation/exercise_tracking_view.dart';
import '../features/training/presentation/weekly_routine_screen.dart';
import 'scaffold_with_nav_bar.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final routerNotifier = AppRouterNotifier(ref);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: routerNotifier,
    redirect: routerNotifier.redirect,
    observers: [AnalyticsService.observer],
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavBar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const Dashboard(), // ✅ FACHADA
                routes: [
                  GoRoute(
                    path: 'fasting',
                    builder: (context, state) => const FastingFeedingScreen(),
                  ),
                  GoRoute(
                    path: 'hydration',
                    builder: (context, state) => const HydrationScreen(),
                  ),
                  GoRoute(
                    path: 'exercise_log',
                    redirect: (context, state) => '/weekly_routine',
                  ),
                  GoRoute(
                    path: 'glucose_monitor',
                    builder: (context, state) => const Center(
                      child: Text('Monitor de glucosa — próximamente'),
                    ),
                  ),
                  GoRoute(
                    path: 'sleep_analysis',
                    builder: (context, state) => const SleepAnalysisScreen(),
                  ),
                  GoRoute(
                    path: 'nutrition_log',
                    builder: (context, state) =>
                        const RegistroNutricionScreen(),
                  ),
                  GoRoute(
                    path: 'weekly_routine',
                    builder: (context, state) => const WeeklyRoutineScreen(),
                    routes: [
                      GoRoute(
                        path: 'session',
                        builder: (context, state) {
                          final workoutDay = state.extra as WorkoutDay?;
                          return ExerciseTrackingView(
                            initialWorkoutDay: workoutDay,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/progress',
                builder: (context, state) => const ProgressScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
    ],
  );
});

class AppRouterNotifier extends ChangeNotifier {
  final Ref _ref;

  AppRouterNotifier(this._ref) {
    _ref.listen<AsyncValue>(
      authStateChangesProvider,
      (_, __) => notifyListeners(),
    );

    _ref.listen<AsyncValue<UserModel?>>(currentUserStreamProvider, (
      prev,
      next,
    ) {
      final prevStatus = prev?.valueOrNull?.onboardingCompleted;
      final nextStatus = next.valueOrNull?.onboardingCompleted;

      if (prevStatus != nextStatus ||
          (prev?.isLoading == true && next.isLoading == false)) {
        notifyListeners();
      }
    });

    _ref.listen<bool>(
      onboardingJustFinishedProvider,
      (_, __) => notifyListeners(),
    );

    _ref.listen<bool>(isDeletingAccountProvider, (_, __) => notifyListeners());
  }

  String? redirect(BuildContext context, GoRouterState state) {
    final authAsync = _ref.read(authStateChangesProvider);

    if (authAsync.isLoading) return null;

    final authUser = authAsync.valueOrNull;
    final isAuthenticated = authUser != null;
    final isAuthRoute =
        state.matchedLocation == '/login' ||
        state.matchedLocation == '/register';

    if (!isAuthenticated) {
      if (isAuthRoute) return null;
      AppLogger.logAuthEvent(
        'No autenticado. Redirigiendo a /login desde ${state.matchedLocation}',
      );
      return '/login';
    }

    final isDeleting = _ref.read(isDeletingAccountProvider);
    if (isDeleting) return null;

    final profileAsync = _ref.read(currentUserStreamProvider);

    if (profileAsync.isLoading) {
      if (isAuthRoute) return null;
      return null;
    }

    if (profileAsync.hasError) {
      AppLogger.error('Error cargando perfil en router: ${profileAsync.error}');
      return null;
    }

    final profile = profileAsync.valueOrNull;

    AppLogger.debug(
      'Router: [Auth=${authUser.uid.substring(0, 5)}...] [Profile=${profile != null ? "EXISTE" : "NULL"}] [Completed=${profile?.onboardingCompleted}] [Location=${state.matchedLocation}]',
    );

    final bool mustGoToOnboarding =
        profile == null || profile.onboardingCompleted == false;
    final isJustFinished = _ref.read(onboardingJustFinishedProvider);

    AppLogger.debug(
      'Router: [mustGoToOnboarding=$mustGoToOnboarding] [isJustFinished=$isJustFinished] [ProfileName=${profile?.name}] [Location=${state.matchedLocation}]',
    );

    if (!isJustFinished && mustGoToOnboarding) {
      if (state.matchedLocation == '/profile' && profile == null) {
        return null;
      }

      if (state.matchedLocation != '/onboarding') {
        AppLogger.info(
          'Router: Forzando Onboarding (ProfileNull=${profile == null})',
        );
        return '/onboarding';
      }

      return null;
    }

    if (isAuthRoute ||
        (state.matchedLocation == '/onboarding' &&
            (profile?.onboardingCompleted == true || isJustFinished))) {
      AppLogger.info(
        'Router: Onboarding completado/justFinished. Redirigiendo a /',
      );
      return '/';
    }

    if (state.matchedLocation == '/' && mustGoToOnboarding && !isJustFinished) {
      AppLogger.info(
        'Router: En Home pero Onboarding pendiente. Redirigiendo a /onboarding',
      );
      return '/onboarding';
    }

    return null;
  }
}