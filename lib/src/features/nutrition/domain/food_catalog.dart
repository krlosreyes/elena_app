// SPEC-137 E.3: catálogo curado de alimentos para el plato armable.
//
// 60 alimentos LatAm (sesgo Colombia) en 3 categorías visibles al
// usuario: Proteína / Grasa / Carbos. Lista provista por Carlos el
// 22-may-2026 — fuente única de verdad del MVP. Para extenderla, abrir
// SPEC nueva.
//
// Clasificación A/E (interna, invisible al usuario):
// - Proteínas → Tipo A (todas).
// - Grasas → Tipo A (todas).
// - Carbohidratos → Tipo E (todos).
//
// El usuario percibe la calidad por el color del sector del plato (verde
// = todo A, ámbar = todo E, mezcla en medio). Internamente el sistema
// deriva el `MealRatio` para alimentar el Cociente A del IMR.
//
// NOTA OPERACIONAL: la tabla NO incluye verduras. La filosofía del
// plato saludable (Harvard Healthy Eating Plate, Frank Suárez §3) suele
// destacar las verduras como la mitad del plato. Carlos decidió
// conscientemente trabajar con esta tabla — el sistema se adapta:
// los tips de mejora ya no apuntan a "cambiá arroz por brócoli" (no
// existe brócoli en el catálogo), sino a "agregá más proteína o grasa
// para balancear" o "reducí los carbohidratos". Si en el futuro se
// agregan verduras, abrir SPEC para reintroducir tips de sustitución.

/// Macro-categoría visible al usuario en el plato.
enum FoodCategory {
  /// Proteínas (animales, legumbres, lácteos proteicos). Sector grande.
  protein,

  /// Grasas saludables y densas (aceites, frutos secos, lácteos grasos,
  /// embutidos). Sector pequeño.
  fat,

  /// Carbohidratos (almidones, frutas dulces, harinas, dulces, panela).
  /// Internamente todos son Tipo E en este catálogo. Sector grande.
  carb;

  /// Peso visual del alimento en el plato. Refleja la regla nutricional
  /// "un trozo de pollo o de arroz ocupa más que un chorrito de aceite".
  int get slots => switch (this) {
        FoodCategory.protein => 2,
        FoodCategory.fat => 1,
        FoodCategory.carb => 2,
      };

  /// Etiqueta corta para UI.
  String get label => switch (this) {
        FoodCategory.protein => 'Proteína',
        FoodCategory.fat => 'Grasa',
        FoodCategory.carb => 'Carbos',
      };
}

/// Calidad metabólica del alimento (interna — no visible al usuario).
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

  /// Nombre visible al usuario.
  final String name;

  /// En qué sector del plato vive.
  final FoodCategory category;

  /// Calidad metabólica (interna).
  final FoodQuality quality;

  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.quality,
  });
}

/// Catálogo curado y FIJO en MVP. 60 alimentos provistos por Carlos.
class FoodCatalog {
  const FoodCatalog._();

  // ── Proteínas (todas Tipo A) ─────────────────────────────────────────
  static const List<Food> proteins = [
    Food(
      id: 'pollo',
      name: 'Pollo',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'huevo',
      name: 'Huevo',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'carne_res',
      name: 'Carne de res',
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
      id: 'cerdo',
      name: 'Cerdo',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'lentejas',
      name: 'Lentejas',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'frijoles',
      name: 'Fríjoles',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'garbanzos',
      name: 'Garbanzos',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'queso_campesino',
      name: 'Queso campesino',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'yogur_griego',
      name: 'Yogur griego',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'leche',
      name: 'Leche',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'jamon',
      name: 'Jamón',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'pechuga_pavo',
      name: 'Pechuga de pavo',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'sardinas',
      name: 'Sardinas',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'tofu',
      name: 'Tofu',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'suero_costeno',
      name: 'Suero costeño',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'quinua',
      name: 'Quinua',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'habichuelas',
      name: 'Habichuelas',
      category: FoodCategory.protein,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'mariscos',
      name: 'Mariscos',
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
      id: 'aceite_vegetal',
      name: 'Aceite vegetal',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'mantequilla',
      name: 'Mantequilla',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'margarina',
      name: 'Margarina',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'queso_amarillo',
      name: 'Queso amarillo',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'crema_de_leche',
      name: 'Crema de leche',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'tocino',
      name: 'Tocino',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'chicharron',
      name: 'Chicharrón',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'coco',
      name: 'Coco',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'mani',
      name: 'Maní',
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
      id: 'almendras',
      name: 'Almendras',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'semillas_girasol',
      name: 'Semillas de girasol',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'mayonesa',
      name: 'Mayonesa',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'aceitunas',
      name: 'Aceitunas',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'manteca',
      name: 'Manteca',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'queso_crema',
      name: 'Queso crema',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'chorizo',
      name: 'Chorizo',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'salchicha',
      name: 'Salchicha',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
    Food(
      id: 'leche_entera',
      name: 'Leche entera',
      category: FoodCategory.fat,
      quality: FoodQuality.typeA,
    ),
  ];

  // ── Carbohidratos (todos Tipo E) ────────────────────────────────────
  static const List<Food> carbs = [
    Food(
      id: 'arroz',
      name: 'Arroz',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'papa',
      name: 'Papa',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'yuca',
      name: 'Yuca',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'platano',
      name: 'Plátano',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'arepa',
      name: 'Arepa',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'pan',
      name: 'Pan',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'pasta',
      name: 'Pasta',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'avena',
      name: 'Avena',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'maiz',
      name: 'Maíz',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'tortilla',
      name: 'Tortilla',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'harina',
      name: 'Harina',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'galletas',
      name: 'Galletas',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'azucar',
      name: 'Azúcar',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'banano',
      name: 'Banano',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'mango',
      name: 'Mango',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'papa_criolla',
      name: 'Papa criolla',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'panela',
      name: 'Panela',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'cereal',
      name: 'Cereal',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'batata_camote',
      name: 'Batata / camote',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
    Food(
      id: 'tapioca',
      name: 'Tapioca',
      category: FoodCategory.carb,
      quality: FoodQuality.typeE,
    ),
  ];

  /// Lista completa unificada (orden: proteínas, grasas, carbs).
  static const List<Food> all = [
    ...proteins,
    ...fats,
    ...carbs,
  ];

  /// Devuelve los alimentos disponibles para una categoría.
  static List<Food> byCategory(FoodCategory category) =>
      all.where((f) => f.category == category).toList(growable: false);

  /// Búsqueda por id estable. Null si no existe.
  static Food? byId(String id) {
    for (final f in all) {
      if (f.id == id) return f;
    }
    return null;
  }
}
