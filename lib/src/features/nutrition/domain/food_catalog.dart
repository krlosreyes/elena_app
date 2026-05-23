// SPEC-137 E.3: catálogo curado de alimentos para el plato armable.
//
// Lista corta (~35 alimentos) cubierta por NUTRITION_BIBLIOGRAPHY.md §2.
// Tres categorías visibles al usuario (Proteína / Grasa / Carbos);
// cada alimento tiene además una `quality` (typeA o typeE) que NO se
// muestra como tal — el usuario percibe la calidad a través del color
// del sector del plato (verde = todo A, ámbar = predomina E).
//
// Nombres elegidos para máxima universalidad LatAm + España neutral
// (ej. "Aguacate" en vez de "Palta", "Banana" en vez de "Plátano" para
// evitar confusión con plátano-plantain).
//
// IMPORTANTE: el catálogo es FIJO en MVP. No se permite que el usuario
// agregue alimentos personalizados — eso vive en SPEC-138 post-MVP.

/// Macro-categoría visible al usuario en el plato.
enum FoodCategory {
  /// Proteínas (animales + queso). Sector grande del plato.
  protein,

  /// Grasas saludables (aguacate, frutos secos, aceite). Sector pequeño.
  fat,

  /// Carbohidratos (verduras, frutas, granos, lácteos). Sector grande.
  /// Internamente mezcla calidad A (verduras, frutas bajas) y E
  /// (almidones, dulces, lácteos azucarados).
  carb;

  /// Peso visual del alimento en el plato. Refleja la regla nutricional
  /// "un trozo de pollo o una porción de arroz ocupa más que una hoja
  /// de lechuga o un chorrito de aceite".
  int get slots => switch (this) {
        FoodCategory.protein => 2,
        FoodCategory.fat => 1,
        FoodCategory.carb => 2,
      };

  /// Etiqueta corta para UI (chips de categoría, label en el plato).
  String get label => switch (this) {
        FoodCategory.protein => 'Proteína',
        FoodCategory.fat => 'Grasa',
        FoodCategory.carb => 'Carbos',
      };
}

/// Calidad metabólica del alimento (interna — no visible al usuario).
///
/// Determina el color del sector del plato y el cómputo del Cociente A.
/// Documentado en `NUTRITION_BIBLIOGRAPHY.md §2`.
enum FoodQuality {
  /// Tipo A — baja respuesta insulínica. Verde en el plato.
  typeA,

  /// Tipo E — alta respuesta insulínica. Ámbar en el plato.
  typeE,
}

/// Un alimento del catálogo.
class Food {
  /// Slug estable para persistencia futura. NUNCA cambia.
  final String id;

  /// Nombre visible al usuario (LatAm-neutro).
  final String name;

  /// En qué sector del plato vive.
  final FoodCategory category;

  /// Calidad metabólica (interna).
  final FoodQuality quality;

  /// Sugerencia textual para reemplazo cuando este alimento Tipo E
  /// está rebajando la calidad del plato. Null para alimentos Tipo A
  /// (no necesitan reemplazo) o para Tipo E sin sustituto natural en
  /// el catálogo (la app sugerirá "reducir" en lugar de "cambiar").
  final String? substituteHint;

  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.quality,
    this.substituteHint,
  });
}

/// Catálogo curado y FIJO en MVP. ~35 alimentos cubriendo el 80% de
/// platos típicos LatAm.
class FoodCatalog {
  const FoodCatalog._();

  // ── Proteínas (todas Tipo A) ─────────────────────────────────────────
  static const List<Food> proteins = [
    Food(
      id: 'huevo',
      name: 'Huevo',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'pollo',
      name: 'Pollo',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'pavo',
      name: 'Pavo',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'pescado',
      name: 'Pescado',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'atun',
      name: 'Atún',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'camaron',
      name: 'Camarón',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'carne',
      name: 'Carne',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'cerdo',
      name: 'Cerdo',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'queso',
      name: 'Queso',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
  ];

  // ── Grasas (todas Tipo A) ────────────────────────────────────────────
  static const List<Food> fats = [
    Food(
      id: 'aguacate',
      name: 'Aguacate',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'almendras',
      name: 'Almendras',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'nueces',
      name: 'Nueces',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'aceite_oliva',
      name: 'Aceite de oliva',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'pistachos',
      name: 'Pistachos',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'mantequilla',
      name: 'Mantequilla',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
  ];

  // ── Carbohidratos Tipo A (verduras + frutas bajas) ──────────────────
  static const List<Food> carbsA = [
    Food(
      id: 'espinaca',
      name: 'Espinaca',
      category: FoodCategory.carb,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'brocoli',
      name: 'Brócoli',
      category: FoodCategory.carb,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'lechuga',
      name: 'Lechuga',
      category: FoodCategory.carb,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'tomate',
      name: 'Tomate',
      category: FoodCategory.carb,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'pepino',
      name: 'Pepino',
      category: FoodCategory.carb,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'calabacin',
      name: 'Calabacín',
      category: FoodCategory.carb,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'coliflor',
      name: 'Coliflor',
      category: FoodCategory.carb,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'pimiento',
      name: 'Pimiento',
      category: FoodCategory.carb,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'fresa',
      name: 'Fresa',
      category: FoodCategory.carb,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'manzana',
      name: 'Manzana',
      category: FoodCategory.carb,
      quality: FoodQuality.typeA,
    ),
  ];

  // ── Carbohidratos Tipo E (almidones, dulces, lácteos azucarados) ────
  static const List<Food> carbsE = [
    Food(
      id: 'arroz',
      name: 'Arroz',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
      substituteHint: 'brócoli o espinaca',
    ),
    Food(
      id: 'pan',
      name: 'Pan',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
      substituteHint: 'lechuga o calabacín',
    ),
    Food(
      id: 'pasta',
      name: 'Pasta',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
      substituteHint: 'calabacín o pimiento',
    ),
    Food(
      id: 'papa',
      name: 'Papa',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
      substituteHint: 'coliflor o pepino',
    ),
    Food(
      id: 'maiz',
      name: 'Maíz',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
      substituteHint: 'pimiento o brócoli',
    ),
    Food(
      id: 'banana',
      name: 'Banana',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
      substituteHint: 'manzana o fresa',
    ),
    Food(
      id: 'mango',
      name: 'Mango',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
      substituteHint: 'fresa o manzana',
    ),
    Food(
      id: 'leche',
      name: 'Leche',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'yogur_azucarado',
      name: 'Yogur con azúcar',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'chocolate',
      name: 'Chocolate',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
  ];

  /// Lista completa unificada (orden: proteínas, grasas, carbs A, carbs E).
  static const List<Food> all = [
    ...proteins,
    ...fats,
    ...carbsA,
    ...carbsE,
  ];

  /// Devuelve los alimentos disponibles para una categoría.
  /// Mantiene primero los Tipo A, después los Tipo E para que la lista
  /// del picker presente lo más saludable arriba (efecto pre-suasivo
  /// suave — los primeros en la lista se eligen más).
  static List<Food> byCategory(FoodCategory category) =>
      all.where((f) => f.category == category).toList(growable: false);

  /// Búsqueda por id estable. Null si no existe (food borrado del
  /// catálogo en alguna versión futura).
  static Food? byId(String id) {
    for (final f in all) {
      if (f.id == id) return f;
    }
    return null;
  }
}
