// Propuesta módulo Ejercicio (2026-07-21): contrato de persistencia del
// perfil de hábitos de ejercicio. Sigue el mismo patrón de
// `exercise/domain/exercise_repository.dart` — abstracción sin
// dependencias de Firestore, para que la capa de dominio/aplicación no
// conozca la implementación concreta.

import 'package:elena_app/src/features/exercise/domain/exercise_profile.dart';

abstract class ExerciseProfileRepository {
  /// Persiste o sobrescribe el perfil del usuario.
  Future<void> save(String userId, ExerciseProfile profile);

  /// Lectura puntual (una sola vez) — usada al inicializar el motor de
  /// plan o el paso de onboarding si el usuario repite el flujo.
  Future<ExerciseProfile?> fetch(String userId);

  /// Stream en vivo — para que el Dashboard reaccione si el usuario
  /// edita su perfil desde otra pantalla.
  Stream<ExerciseProfile?> watch(String userId);
}
