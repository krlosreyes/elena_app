/// 🔐 SECURITY CONFIG FILE
///
/// Este archivo contiene configuraciones sensibles de seguridad.
/// EN PRODUCCIÓN: Estas keys deben inyectarse desde variables de entorno o CI/CD.
///
/// ⚠️ NUNCA commitear keys reales en el repositorio
/// 🔒 Usar Flutter Environment Variables o Secrets en CI/CD pipeline
library;

class SecurityConfig {
  /// ReCaptcha V3 Site Key (Web)
  ///
  /// En producción, cargar desde:
  /// - Environment variable: RECAPTCHA_V3_SITE_KEY
  /// - Firebase Remote Config
  /// - Secure backend API
  static String get recaptchaV3SiteKey {
    // TODO: Cargar desde entorno
    // const String.fromEnvironment('RECAPTCHA_V3_SITE_KEY', defaultValue: '')

    // Retornar string vacío en desarrollo/testing
    return '';
  }

  /// Firebase API Key (ya configurado en firebase_options.dart)
  ///
  /// ✅ BIEN: Firebase API keys se generan automáticamente
  /// y están restringidas por dominio/app en Google Cloud Console
  static const String firebaseProjectId = 'elena-app-2026-v1';

  /// 🔐 Bandera para habilitar App Check en release builds
  static const bool enableAppCheckInRelease = true;

  /// 🔐 Bandera para debug de seguridad
  static const bool enableSecurityDebugLogs = true;
}
