// SPEC-270 — Contrato de persistencia del intake dietético.
// Capa domain pura, sin Firestore (mismo patrón que MealPresetRepository).

import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';

abstract class NutritionIntakeRepository {
  /// Stream del intake del usuario. Emite `null` mientras no exista
  /// documento (usuario que aún no hizo el onboarding del pilar).
  Stream<NutritionIntake?> watchIntake(String userId);

  /// Lectura puntual (una sola vez) del intake. `null` si no existe.
  Future<NutritionIntake?> getIntake(String userId);

  /// Crea o actualiza (upsert) el intake. Es un único documento por
  /// usuario — llamar de nuevo sobreescribe (merge).
  Future<void> saveIntake(String userId, NutritionIntake intake);
}
