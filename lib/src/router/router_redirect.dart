// SPEC-146: helper puro del redirect del GoRouter.
//
// La lógica del redirect vive en una función pura testeable sin
// dependencias de Flutter ni de GoRouter. El goRouterProvider la
// invoca desde su `redirect` con el authState y la location.
//
// CRITICAL: la función distingue AsyncLoading de AsyncData(null). El
// bug original (SPEC-146 §1.2) era que el redirect trataba ambos como
// "no autenticado" y mandaba a /login durante los 200-500ms que tarda
// Firebase Auth en hidratar la sesión persistida, causando un flash
// de login que algunos usuarios percibían como "se deslogueó solo".

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/domain/app_account.dart';

const String kSplashRoute = '/splash';
const String kLoginRoute = '/login';
const String kDashboardRoute = '/dashboard';
const String kOnboardingRoute = '/onboarding';

/// Calcula la ruta destino del redirect dado el estado del auth y la
/// location actual. Retorna `null` si no hay que redirigir.
///
/// Reglas (orden de evaluación):
///   1. Auth state loading + location != splash → `/splash`.
///   2. Auth state loading + location == splash → `null` (queda).
///   3. Auth resolved en /splash → destino correcto según account.
///   4. Auth resolved + sin account + ruta privada → `/login`.
///   5. Auth resolved + account en ruta de auth → destino correcto.
///   6. Auth resolved + needsOnboarding + no en /onboarding → `/onboarding`.
///   7. Auth resolved + complete + en /onboarding → `/dashboard`.
///   8. Default → `null` (no redirige).
String? computeRedirect({
  required AsyncValue<AppAccount?> authState,
  required String location,
}) {
  // SPEC-146 §RF-146-02: durante el loading, no redirigimos a /login.
  // Si no estamos en /splash, redirigimos ahí para mostrar el loading
  // controlado en lugar de cualquier pantalla.
  if (authState.isLoading) {
    return location == kSplashRoute ? null : kSplashRoute;
  }

  final account = authState.value;
  final isLegalDoc = location == '/legal/privacy' || location == '/legal/terms';
  final isPublic = location == kLoginRoute ||
      location == '/register' ||
      location == '/forgot-password' ||
      location == '/set-password' ||
      isLegalDoc ||
      location.startsWith('/open');

  // Si estamos en /splash y ya resolvimos: navegar al destino real.
  if (location == kSplashRoute) {
    if (account == null) return kLoginRoute;
    if (account.needsOnboarding) return kOnboardingRoute;
    return kDashboardRoute;
  }

  // No autenticado en ruta privada → /login.
  if (account == null) {
    return isPublic ? null : kLoginRoute;
  }

  // Autenticado en ruta pública (auth) → llevar a destino. Las legales
  // se excluyen porque debe poder leerlas el usuario autenticado desde
  // Perfil → Legal (SPEC-117).
  if (isPublic && !isLegalDoc) {
    return account.isComplete ? kDashboardRoute : kOnboardingRoute;
  }

  // Perfil incompleto (NEW o PARTIAL) → forzar onboarding.
  if (account.needsOnboarding && location != kOnboardingRoute) {
    return kOnboardingRoute;
  }

  // Perfil completo intentando entrar a /onboarding → al dashboard.
  if (account.isComplete && location == kOnboardingRoute) {
    return kDashboardRoute;
  }

  return null;
}
