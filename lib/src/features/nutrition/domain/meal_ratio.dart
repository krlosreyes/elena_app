// SPEC-137: clasificación Tipo A / Tipo E del plato según marco
// operacional de Frank Suárez (docs/NUTRITION_BIBLIOGRAPHY.md §3).
//
// El usuario clasifica cada plato en una de 5 posiciones. La métrica
// del pilar Nutrición (Cociente A) se calcula sobre esta clasificación
// — no sobre macros ni calorías.
//
// Marco normativo: docs/NUTRITION_BIBLIOGRAPHY.md §2 (listas A/E) y §3
// (dietas 2x1 / 3x1). Defensa científica vía IG/CG en §4.

/// Proporción Tipo A : Tipo E que predomina en un plato registrado.
///
/// El criterio operacional para clasificar es la respuesta insulínica
/// estimada (proxy del índice glucémico × carga glucémica, ver
/// `NUTRITION_BIBLIOGRAPHY.md §4`). En la práctica el usuario lo elige
/// visualmente con un slider de 5 posiciones.
enum MealRatio {
  /// 100% alimentos Tipo A. Plato perfecto (proteína + verduras + grasa
  /// saludable, sin harinas/almidones/azúcar/lácteos).
  allA,

  /// 75% A, 25% E. Dieta 3x1 — recomendada para pérdida acelerada o
  /// perfil con resistencia a insulina.
  a3e1,

  /// 67% A, 33% E. Dieta 2x1 — mantenimiento estándar y default
  /// sugerido para perfil Pasivo.
  a2e1,

  /// 50% A, 50% E. Alerta amarilla — fuera del rango sostenible.
  a1e1,

  /// 100% alimentos Tipo E. Solo durante día de permitidos consciente
  /// (RF-137-07).
  allE;

  /// True si la proporción A es dominante (≥ 67%).
  ///
  /// Crítico: éste es el criterio binario que alimenta el cálculo del
  /// Cociente A diario en `cociente_a_service.dart`. Cualquier cambio
  /// aquí afecta la métrica del pilar Nutrición.
  bool get isADominant => switch (this) {
        allA || a3e1 || a2e1 => true,
        a1e1 || allE => false,
      };

  /// Fracción de Tipo A que representa esta proporción (0.0 – 1.0).
  ///
  /// Útil para visualizaciones (ej. arc chart en `PlateRatioSheet`).
  /// No se usa para el score — el score es binario via `isADominant`.
  double get aFraction => switch (this) {
        allA => 1.0,
        a3e1 => 0.75,
        a2e1 => 0.67,
        a1e1 => 0.50,
        allE => 0.0,
      };

  /// Etiqueta corta y localizada para UI (Hoy, sheets, heatmap).
  ///
  /// El usuario nunca ve "allA" en pantalla — siempre ve "Todo A",
  /// "3 a 1", "2 a 1", etc. Este es el contrato con el copy del
  /// producto definido en `NUTRITION_BIBLIOGRAPHY.md §11`.
  String get label => switch (this) {
        allA => 'Todo A',
        a3e1 => '3 a 1',
        a2e1 => '2 a 1',
        a1e1 => '1 a 1',
        allE => 'Todo E',
      };

  /// Clave estable para persistencia en Firestore.
  ///
  /// NO usar `name` directamente: si Dart cambia el nombre del enum
  /// en una versión futura, los logs ya escritos quedan desincronizados.
  /// Esta clave es independiente del nombre del símbolo.
  String get persistenceKey => switch (this) {
        allA => 'allA',
        a3e1 => 'a3e1',
        a2e1 => 'a2e1',
        a1e1 => 'a1e1',
        allE => 'allE',
      };

  /// Parsea desde el string persistido en Firestore.
  ///
  /// Si la clave es null, vacía o desconocida, cae a [MealRatio.a2e1].
  /// Esto cubre dos casos importantes:
  /// 1. Logs históricos pre-SPEC-137 sin campo `ratio` → default 2x1.
  /// 2. Forward compatibility: si en el futuro se agrega un MealRatio
  ///    nuevo y un cliente viejo lo lee, no falla.
  static MealRatio fromPersistenceKey(String? key) {
    return switch (key) {
      'allA' => MealRatio.allA,
      'a3e1' => MealRatio.a3e1,
      'a2e1' => MealRatio.a2e1,
      'a1e1' => MealRatio.a1e1,
      'allE' => MealRatio.allE,
      _ => MealRatio.a2e1,
    };
  }
}
