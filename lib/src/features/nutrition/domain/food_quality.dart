// SPEC-292 — Asesor de calidad de un alimento: nivel + por qué + qué hacer.
//
// Usa el `qualityScore` (respuesta insulínica/glucémica) y el grado NOVA
// (procesamiento) que ya tiene cada `Food`. Sirve para avisar al usuario
// cuando un alimento es poco ideal y ofrecerle cambiarlo — sin bloquearlo
// (autonomía total: puede dejarlo si quiere).

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';

enum FoodQualityLevel {
  /// Buena elección metabólica (score alto, natural).
  good,

  /// Aceptable, con matices (impacto medio).
  moderate,

  /// Poco ideal: ultraprocesado o de alto impacto glucémico.
  poor,
}

class FoodQuality {
  const FoodQuality._();

  /// Nivel del alimento. `poor` si es NOVA 4 (ultraprocesado) o su
  /// qualityScore es bajo (<35). `moderate` entre 35 y 64. `good` desde 65.
  static FoodQualityLevel levelOf(Food f) {
    if (f.nova.isUltraProcessed || f.qualityScore < 35) {
      return FoodQualityLevel.poor;
    }
    if (f.qualityScore < 65) return FoodQualityLevel.moderate;
    return FoodQualityLevel.good;
  }

  static bool isPoor(Food f) => levelOf(f) == FoodQualityLevel.poor;

  /// Etiqueta corta del motivo (para un chip/renglón). `null` si es bueno.
  static String? shortReason(Food f) {
    switch (levelOf(f)) {
      case FoodQualityLevel.poor:
        return f.nova.isUltraProcessed ? 'Ultraprocesado' : 'Alto en glucosa';
      case FoodQualityLevel.moderate:
        return 'Impacto medio';
      case FoodQualityLevel.good:
        return null;
    }
  }

  /// Explicación humana (para la hoja de cambio). `null` si es bueno.
  static String? explanation(Food f) {
    switch (levelOf(f)) {
      case FoodQualityLevel.poor:
        if (f.nova.isUltraProcessed) {
          return 'Es ultraprocesado: dispara la insulina y trae aditivos y '
              'grasas industriales. Cámbialo por algo natural y tu cuerpo '
              'lo agradece.';
        }
        return 'Tiene un impacto alto en tu glucosa. Una opción más natural '
            'te mantiene con energía estable y sin bajones.';
      case FoodQualityLevel.moderate:
        return 'Está bien de vez en cuando; hay opciones que te suman más sin '
            'disparar la insulina.';
      case FoodQualityLevel.good:
        return null;
    }
  }
}
