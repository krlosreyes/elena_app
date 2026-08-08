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
import 'package:elena_app/src/features/nutrition/presentation/intake_onboarding_screen.dart';
import 'package:elena_app/src/features/nutrition/presentation/meal_plan_screen.dart';
import 'package:elena_app/src/features/auth/presentation/profile_screen.dart';
import 'package:elena_app/src/features/analysis/presentation/analysis_screen.dart';
// SPEC-168.4: pantalla detalle de un pilar (overview → chart completo).
import 'package:elena_app/src/features/analysis/presentation/analysis_pillar_detail_screen.dart';
import 'package:elena_app/src/features/analysis/presentation/daily_score_detail_screen.dart';
// 17-jul: pantallas de detalle de las cards colapsadas de Progreso.
import 'package:elena_app/src/features/analysis/presentation/resultados_detail_screen.dart';
import 'package:elena_app/src/features/analysis/presentation/habitos_detail_screen.dart';
import 'package:elena_app/src/features/analysis/presentation/racha_detail_screen.dart';
import 'package:elena_app/src/features/glucose/presentation/glucose_detail_screen.dart';
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
// 17-jul: "Para ti" (SPEC-205) rebautizado "Aprende con Elena" y colapsado
// en Dashboard — ver aprende_entry_card.dart.
import 'package:elena_app/src/features/content/presentation/aprende_detail_screen.dart';
// 17-jul (2da vuelta, rediseño Perfil): pantallas de detalle de las cards
// colapsadas de "Configuración" en Perfil — ver comentario en
// biometricos_detail_screen.dart.
import 'package:elena_app/src/features/auth/presentation/biometricos_detail_screen.dart';
import 'package:elena_app/src/features/auth/presentation/ritmos_circadianos_detail_screen.dart';
import 'package:elena_app/src/features/auth/presentation/protocolo_detail_screen.dart';
import 'package:elena_app/src/features/auth/presentation/objetivos_detail_screen.dart';
// Propuesta módulo Ejercicio (2026-07-21): punto de entrada para
// usuarios existentes — configurar/editar ExerciseProfile desde Perfil.
import 'package:elena_app/src/features/exercise/presentation/exercise_habits_detail_screen.dart';
// SPEC-261: Protocolo de Consumo Consciente (alcohol).
import 'package:elena_app/src/features/alcohol/presentation/alcohol_history_screen.dart';
import 'package:elena_app/src/features/alcohol/presentation/alcohol_protocol_screen.dart';
// SPEC-263: Retos de constancia (competencia social sana).
import 'package:elena_app/src/features/challenges/presentation/challenges_screen.dart';
import 'package:elena_app/src/features/challenges/presentation/challenge_detail_screen.dart';

/// SPEC-222: llave global del navigator raíz para deeplink routing
/// desde notificaciones (cold start + foreground).
final rootNavigatorKey = GlobalKey<NavigatorState>();

/// I-02 (auditoría 2026-07-27): puente entre Riverpod y GoRouter.
///
/// Antes, `goRouterProvider` hacía `ref.watch(authStateProvider)` y devolvía
/// un `GoRouter` NUEVO en cada emisión. Como `MaterialApp.router` recibe ese
/// objeto como `routerConfig`, cada emisión reconstruía el Navigator entero:
/// se perdía la pila de navegación (un usuario en `/profile/badges` acababa
/// en `/dashboard`) y la instancia anterior nunca se liberaba, dejando sus
/// listeners vivos. `authStateChanges` emite al menos dos veces en cada
/// arranque en frío (loading → data), más una vez por login y por logout.
///
/// El patrón correcto es una única instancia de router con un `Listenable`
/// que le diga cuándo reevaluar el redirect. `computeRedirect` ya era una
/// función pura y bien testeada; no hace falta tocarla.
class _RefreshListenable extends ChangeNotifier {
  /// Expuesto para que el provider dispare la reevaluación del redirect.
  void refresh() => notifyListeners();
}

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _RefreshListenable();
  ref.onDispose(refresh.dispose);

  // `listen`, no `watch`: reaccionamos al cambio de sesión SIN reconstruir
  // el provider —y con él, el router—. La suscripción se cierra sola cuando
  // el provider se dispone.
  ref.listen(authStateProvider, (_, __) => refresh.refresh());

  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    refreshListenable: refresh,
    // SPEC-146: initialLocation cambiado de '/dashboard' a '/splash'
    // para evitar flash de pantallas privadas mientras Firebase Auth
    // hidrata la sesión del keychain en cold start. La lógica completa
    // del redirect vive en `computeRedirect` (función pura testeable).
    initialLocation: '/splash',
    // El authState se LEE en cada evaluación del redirect, no se captura
    // en el closure. Así el router es estable y el redirect siempre ve el
    // estado vigente (I-02).
    redirect: (context, state) => computeRedirect(
      authState: ref.read(authStateProvider),
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
      // 17-jul: Progreso se colapsó a 4 cards (Insignias, Tus Resultados,
      // Tus Hábitos, Tu racha) — estas 3 rutas son el detalle de cada una
      // (Insignias ya tenía la suya: /profile/badges).
      GoRoute(
        path: '/analysis/resultados',
        name: 'analysis-resultados',
        builder: (context, state) => const ResultadosDetailScreen(),
      ),
      GoRoute(
        path: '/analysis/habitos',
        name: 'analysis-habitos',
        builder: (context, state) => const HabitosDetailScreen(),
      ),
      GoRoute(
        path: '/analysis/racha',
        name: 'analysis-racha',
        builder: (context, state) => const RachaDetailScreen(),
      ),
      // 23-jul: módulo "Tu Glucosa" (Protocolo de Seguimiento de
      // Glucosa) — mismo patrón que las 3 rutas de detalle de arriba.
      // Solo se llega acá desde GlucoseEntryCard, que ya se autooculta
      // si el protocolo no está activo.
      GoRoute(
        path: '/analysis/glucosa',
        name: 'analysis-glucosa',
        builder: (context, state) => const GlucoseDetailScreen(),
      ),
      // 17-jul: detalle de "Aprende con Elena" (antes "Para ti") — card
      // colapsada en Dashboard, ver aprende_entry_card.dart.
      GoRoute(
        path: '/aprende',
        name: 'aprende',
        builder: (context, state) => const AprendeDetailScreen(),
      ),
      // SPEC-261: Protocolo de Consumo Consciente. Se llega desde
      // AlcoholProtocolCard en el dashboard (widget autocontenido).
      GoRoute(
        path: '/protocolo-alcohol',
        name: 'protocolo-alcohol',
        builder: (context, state) => const AlcoholProtocolScreen(),
      ),
      // SPEC-261.9: historial de salidas (tendencia + lista).
      GoRoute(
        path: '/protocolo-alcohol/historial',
        name: 'protocolo-alcohol-historial',
        builder: (context, state) => const AlcoholHistoryScreen(),
      ),
      // SPEC-262: Tus estadísticas (gamificación: estrellas, congeladores,
      // nivel/XP, ayuno de por vida, tienda).
      // SPEC-263: "Tus estadísticas" se fusionó dentro de "Tu racha"
      // (/analysis/racha). Se conserva la ruta como redirect para no romper
      // deep-links viejos (notificaciones, accesos guardados).
      GoRoute(
        path: '/estadisticas',
        name: 'estadisticas',
        redirect: (context, state) => '/analysis/racha',
      ),
      // SPEC-263: Retos de constancia. Lista y detalle por código.
      GoRoute(
        path: '/retos',
        name: 'retos',
        builder: (context, state) => const ChallengesScreen(),
        routes: [
          GoRoute(
            path: ':code',
            name: 'reto-detalle',
            builder: (context, state) => ChallengeDetailScreen(
              code: state.pathParameters['code']!,
            ),
          ),
        ],
      ),
      // SPEC-137 §RF-137-12: vista semanal del pilar Nutrición.
      // Navegable desde el botón "Ver semana →" del card "Nutrición
      // Científica" en el Dashboard.
      GoRoute(
        path: '/nutrition/weekly',
        name: 'nutrition-weekly',
        builder: (context, state) => const NutritionWeeklyScreen(),
      ),
      // SPEC-270: onboarding del Pilar de Alimentación (evaluación
      // dietética en 6 bloques). Accesible desde Perfil > "Mi minuta diaria".
      GoRoute(
        path: '/nutrition/intake',
        name: 'nutrition-intake',
        builder: (context, state) => const IntakeOnboardingScreen(),
      ),
      // SPEC-273: Minuta Diaria + ciclo diario (Comí / Cambié / Me salté).
      GoRoute(
        path: '/nutrition/minuta',
        name: 'nutrition-minuta',
        builder: (context, state) => const MealPlanScreen(),
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
      // 17-jul (2da vuelta, rediseño Perfil): "Datos biométricos", "Ritmos
      // circadianos", "Protocolo de ayuno" y "Mis objetivos" pasaron de
      // secciones siempre expandidas en Perfil a cards colapsadas + estas
      // 4 pantallas de detalle propias — mismo patrón que /profile/badges.
      GoRoute(
        path: '/profile/biometricos',
        name: 'profile-biometricos',
        builder: (context, state) => const BiometricosDetailScreen(),
      ),
      GoRoute(
        path: '/profile/ritmos',
        name: 'profile-ritmos',
        builder: (context, state) => const RitmosCircadianosDetailScreen(),
      ),
      GoRoute(
        path: '/profile/protocolo',
        name: 'profile-protocolo',
        builder: (context, state) => const ProtocoloDetailScreen(),
      ),
      GoRoute(
        path: '/profile/objetivos',
        name: 'profile-objetivos',
        builder: (context, state) => const ObjetivosDetailScreen(),
      ),
      // Propuesta módulo Ejercicio (2026-07-21): configurar/editar
      // ExerciseProfile — mismo patrón que las 4 rutas de arriba.
      GoRoute(
        path: '/profile/ejercicio',
        name: 'profile-ejercicio',
        builder: (context, state) => const ExerciseHabitsDetailScreen(),
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

  // I-02: sin esto, cada router descartado dejaba vivos sus listeners.
  ref.onDispose(router.dispose);
  return router;
});
