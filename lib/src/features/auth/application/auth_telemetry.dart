// SPEC-73 §RF-73-12 / SPEC-74 §RF-74-08: telemetría mínima del funnel de auth.
//
// Esta capa es un STUB intencional. El back-end concreto (Firebase
// Analytics, Mixpanel, Amplitude) se elige y enchufa en SPEC-80 del
// Sprint 5 (Sentry/Crashlytics + scrubbing PII). Hasta entonces, los
// eventos se loguean por `AppLogger` para verificar el funnel en debug.
//
// La interfaz se diseña ahora para que la migración de SPEC-80 sea un
// cambio de implementación, no de call sites.
//
// Reglas:
// - Ningún evento incluye email, uid, o cualquier PII.
// - El estado de perfil se reporta como enum, nunca como dump de doc.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/auth/domain/app_account.dart';

abstract class AuthTelemetry {
  void signInAttempt();
  void signInSuccess(
      {required AppProfileStatus status, required bool isFirstLogin});
  void signInFailure({required String reason});
  void mrUserFirstLogin();
  void appProfileStatusObserved(AppProfileStatus status);
  void onboardingStarted();
  void onboardingCompleted();
  void magicLinkSent();
  void passwordSetFromLink();
}

/// Implementación por defecto: emite eventos al AppLogger sin enviar a
/// ningún backend. Reemplazable por SPEC-80 sin cambiar call sites.
class LoggerAuthTelemetry implements AuthTelemetry {
  const LoggerAuthTelemetry();

  void _emit(String event, [Map<String, Object?>? props]) {
    final payload = props == null || props.isEmpty ? '' : ' $props';
    AppLogger.info('[auth_telemetry] $event$payload');
  }

  @override
  void signInAttempt() => _emit('auth_signin_attempt');

  @override
  void signInSuccess({
    required AppProfileStatus status,
    required bool isFirstLogin,
  }) =>
      _emit('auth_signin_success', {
        'profile_status': status.name,
        'first_login': isFirstLogin,
      });

  @override
  void signInFailure({required String reason}) =>
      _emit('auth_signin_failure', {'reason': reason});

  @override
  void mrUserFirstLogin() => _emit('mr_user_first_login');

  @override
  void appProfileStatusObserved(AppProfileStatus status) =>
      _emit('app_profile_status', {'value': status.name});

  @override
  void onboardingStarted() => _emit('onboarding_started');

  @override
  void onboardingCompleted() => _emit('onboarding_completed');

  @override
  void magicLinkSent() => _emit('auth_magic_link_sent');

  @override
  void passwordSetFromLink() => _emit('auth_password_set_from_link');
}

// SPEC-74: provider Riverpod para inyectar AuthTelemetry desde los
// consumidores (OnboardingScreen, AuthController). El default es
// LoggerAuthTelemetry; SPEC-80 lo overrideará con una implementación
// que envíe eventos a Sentry/Firebase Analytics.
final authTelemetryProvider = Provider<AuthTelemetry>((ref) {
  return const LoggerAuthTelemetry();
});
