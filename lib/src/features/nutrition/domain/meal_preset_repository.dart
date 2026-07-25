// "Mis platos frecuentes" (25-jul-2026) — contrato de persistencia.
// Mismo patrón que BadgeRepository: capa domain pura, sin Firestore.

import 'package:elena_app/src/features/nutrition/domain/meal_preset.dart';

abstract class MealPresetRepository {
  /// Stream de TODOS los presets guardados por el usuario, sin recorte
  /// temporal — un preset guardado hace meses sigue siendo tan válido
  /// como uno de ayer (a diferencia de nutrition_history, acá no hay
  /// ventana de "hoy"/ciclo).
  Stream<List<MealPreset>> watchPresets(String userId);

  /// Crea o actualiza (upsert) un preset. Usa `preset.id` como clave del
  /// documento — llamar esto de nuevo con el mismo id (ej. al marcar
  /// `lastUsedAt`/`useCount`) sobreescribe en vez de duplicar.
  Future<void> savePreset(String userId, MealPreset preset);

  /// Elimina un preset por su id. No-op si no existe.
  Future<void> deletePreset(String userId, String presetId);
}
