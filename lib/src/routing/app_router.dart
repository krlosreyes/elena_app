import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../common_widgets/common_widgets.dart';
import '../features/authentication/presentation/login_screen.dart';
import '../features/authentication/presentation/register_screen.dart';
import '../features/dashboard/presentation/dashboard_screen.dart';
import '../features/onboarding/presentation/onboarding_screen.dart';
import '../features/profile/presentation/profile_screen.dart';

import '../features/authentication/data/auth_repository.dart';

import '../features/profile/data/user_repository.dart';
import '../features/profile/domain/user_model.dart';

part 'app_router.g.dart';

@riverpod
GoRouter goRouter(GoRouterRef ref) {
  final authState = ref.watch(authStateChangesProvider);
  
  // Si hay usuario autenticado, escuchamos su perfil de Firestore en tiempo real
  final userValue = authState.valueOrNull != null
      ? ref.watch(userStreamProvider(authState.value!.uid))
      : const AsyncValue<UserModel?>.loading();

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
      // Si estamos cargando el perfil, esperamos (return null suele mantener la pantalla actual, 
      // pero si venimos de login, idealmente mostraríamos un splash. Por ahora, dejamos pasar 
      // si es dashboard para que muestre loading allí, o null para esperar).
      if (userValue.isLoading) return null;

      final user = userValue.valueOrNull;
      // Si no hay doc de usuario (user == null), asumimos que es nuevo y falta onboarding.
      final onboardingCompleted = user?.onboardingCompleted ?? false;

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
        path: '/dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile', // Named route for easier navigation
        builder: (context, state) => const ProfileScreen(),
      ),
    ],
  );
}
