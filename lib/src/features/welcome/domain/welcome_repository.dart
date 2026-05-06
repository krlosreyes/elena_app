// SPEC-48: contrato del WelcomeRepository.
//
// Capa domain — Dart puro. No conoce ni a Firestore ni a SharedPreferences.
// La implementación concreta vive en `data/firebase_welcome_repository.dart`.
// La capa application/presentation consume esta interfaz, nunca la implementación.

/// Persiste el flag "el usuario ya completó el flujo de bienvenida".
///
/// La fuente de verdad es persistente (Firestore en la implementación
/// actual). Una caché local (SharedPreferences) acelera lecturas
/// frecuentes y soporta operación offline.
abstract class WelcomeRepository {
  /// Retorna `true` si el usuario ya vio/completó el flujo de bienvenida.
  /// Si no hay datos persistidos, retorna `false` (asume usuario nuevo).
  Future<bool> hasSeenWelcome(String userId);

  /// Marca el flujo de bienvenida como completado para `userId`.
  Future<void> markWelcomeSeen(String userId);

  /// Resetea el flag (útil para re-onboarding o testing).
  Future<void> resetWelcome(String userId);
}
