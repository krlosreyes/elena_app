// SPEC-64: Catálogo local de datos nutricionales para alimentos comunes.
//
// Permite que el UI sugiera macros automáticamente cuando el usuario
// escribe un alimento conocido, en lugar de obligarlo a buscar etiquetas
// y teclear gramos manualmente. SPEC-70 (R2 final) documentará cada
// entrada con su fuente bibliográfica.
//
// Para R1 de SPEC-64 cargamos un catálogo mínimo de ~25 alimentos comunes
// en latinoamérica. Cada entry usa porciones estándar (100g o 1 unidad).
// Las cifras provienen de USDA FoodData Central (entrada genérica) y
// se han redondeado a un decimal.
//
// El catálogo es Dart puro y const — no hace I/O ni red. SPEC-66 v2 lo
// testea como función pura.

import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';

/// Una entrada del catálogo nutricional.
///
/// Las cifras son por la `servingDescription` indicada (ej. "100g de filete").
class NutritionFactsEntry {
  /// Texto canónico (en español, capitalización de título).
  final String name;

  /// Lista de alias (lowercased) que se mapean a esta entrada al buscar.
  final List<String> aliases;

  /// Descripción de la porción (ej. "100g", "1 huevo grande", "1 taza").
  final String servingDescription;

  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final double? fiber;
  final int? glycemicIndex;

  const NutritionFactsEntry({
    required this.name,
    required this.aliases,
    required this.servingDescription,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber,
    this.glycemicIndex,
  });
}

/// Servicio de búsqueda. Estático y puro — cualquier consumidor lo invoca
/// con `NutritionFactsLookup.findByName('huevo')`.
class NutritionFactsLookup {
  NutritionFactsLookup._();

  /// Catálogo canónico. Ordenado por categoría, redondeado a 1 decimal.
  static const List<NutritionFactsEntry> _catalog = [
    // ── Proteínas animales ─────────────────────────────────────────────
    NutritionFactsEntry(
      name: 'Huevo entero',
      aliases: ['huevo', 'huevos', 'huevo cocido', 'huevo frito'],
      servingDescription: '1 huevo grande (50g)',
      calories: 72,
      protein: 6.3,
      carbs: 0.4,
      fat: 4.8,
      glycemicIndex: 0,
    ),
    NutritionFactsEntry(
      name: 'Pechuga de pollo',
      aliases: ['pollo', 'pechuga', 'pechuga pollo'],
      servingDescription: '100g cocido',
      calories: 165,
      protein: 31.0,
      carbs: 0.0,
      fat: 3.6,
      glycemicIndex: 0,
    ),
    NutritionFactsEntry(
      name: 'Salmón',
      aliases: ['salmon'],
      servingDescription: '100g',
      calories: 208,
      protein: 20.4,
      carbs: 0.0,
      fat: 13.4,
      glycemicIndex: 0,
    ),
    NutritionFactsEntry(
      name: 'Atún en agua',
      aliases: ['atun', 'tuna'],
      servingDescription: '100g escurrido',
      calories: 116,
      protein: 25.5,
      carbs: 0.0,
      fat: 0.8,
      glycemicIndex: 0,
    ),
    NutritionFactsEntry(
      name: 'Carne de res magra',
      aliases: ['carne', 'res', 'bife', 'filete', 'lomo'],
      servingDescription: '100g cocida',
      calories: 250,
      protein: 26.0,
      carbs: 0.0,
      fat: 15.0,
      glycemicIndex: 0,
    ),

    // ── Cereales y panificados ─────────────────────────────────────────
    NutritionFactsEntry(
      name: 'Avena',
      aliases: ['avena', 'oatmeal', 'oats'],
      servingDescription: '40g secos',
      calories: 150,
      protein: 5.0,
      carbs: 27.0,
      fat: 2.5,
      fiber: 4.0,
      glycemicIndex: 55,
    ),
    NutritionFactsEntry(
      name: 'Arroz integral',
      aliases: ['arroz', 'arroz integral', 'brown rice'],
      servingDescription: '100g cocido',
      calories: 112,
      protein: 2.6,
      carbs: 24.0,
      fat: 0.9,
      fiber: 1.8,
      glycemicIndex: 50,
    ),
    NutritionFactsEntry(
      name: 'Arroz blanco',
      aliases: ['arroz blanco', 'white rice'],
      servingDescription: '100g cocido',
      calories: 130,
      protein: 2.7,
      carbs: 28.0,
      fat: 0.3,
      fiber: 0.4,
      glycemicIndex: 73,
    ),
    NutritionFactsEntry(
      name: 'Pan integral',
      aliases: ['pan', 'pan integral', 'bread'],
      servingDescription: '1 rebanada (28g)',
      calories: 70,
      protein: 4.0,
      carbs: 12.0,
      fat: 1.0,
      fiber: 2.0,
      glycemicIndex: 51,
    ),
    NutritionFactsEntry(
      name: 'Tortilla de maíz',
      aliases: ['tortilla', 'tortilla maiz', 'tortillas'],
      servingDescription: '1 tortilla (30g)',
      calories: 65,
      protein: 1.6,
      carbs: 13.0,
      fat: 0.7,
      fiber: 1.5,
      glycemicIndex: 52,
    ),
    NutritionFactsEntry(
      name: 'Quinoa',
      aliases: ['quinoa', 'kinwa'],
      servingDescription: '100g cocida',
      calories: 120,
      protein: 4.4,
      carbs: 21.3,
      fat: 1.9,
      fiber: 2.8,
      glycemicIndex: 53,
    ),

    // ── Frutas ─────────────────────────────────────────────────────────
    NutritionFactsEntry(
      name: 'Manzana',
      aliases: ['manzana', 'apple'],
      servingDescription: '1 mediana (180g)',
      calories: 95,
      protein: 0.5,
      carbs: 25.0,
      fat: 0.3,
      fiber: 4.4,
      glycemicIndex: 36,
    ),
    NutritionFactsEntry(
      name: 'Plátano',
      aliases: ['platano', 'banana', 'banano'],
      servingDescription: '1 mediano (118g)',
      calories: 105,
      protein: 1.3,
      carbs: 27.0,
      fat: 0.4,
      fiber: 3.1,
      glycemicIndex: 51,
    ),
    NutritionFactsEntry(
      name: 'Aguacate',
      aliases: ['aguacate', 'palta', 'avocado'],
      servingDescription: '1/2 unidad (100g)',
      calories: 160,
      protein: 2.0,
      carbs: 9.0,
      fat: 15.0,
      fiber: 7.0,
      glycemicIndex: 15,
    ),
    NutritionFactsEntry(
      name: 'Arándanos',
      aliases: ['arandanos', 'blueberries', 'mora azul'],
      servingDescription: '100g',
      calories: 57,
      protein: 0.7,
      carbs: 14.5,
      fat: 0.3,
      fiber: 2.4,
      glycemicIndex: 53,
    ),

    // ── Lácteos ────────────────────────────────────────────────────────
    NutritionFactsEntry(
      name: 'Yogur griego natural',
      aliases: ['yogur', 'yogurt', 'yogur griego'],
      servingDescription: '170g',
      calories: 100,
      protein: 17.0,
      carbs: 6.0,
      fat: 0.7,
      glycemicIndex: 11,
    ),
    NutritionFactsEntry(
      name: 'Leche entera',
      aliases: ['leche'],
      servingDescription: '1 taza (240ml)',
      calories: 150,
      protein: 8.0,
      carbs: 12.0,
      fat: 8.0,
      glycemicIndex: 31,
    ),
    NutritionFactsEntry(
      name: 'Queso fresco',
      aliases: ['queso', 'queso fresco', 'panela'],
      servingDescription: '50g',
      calories: 145,
      protein: 9.0,
      carbs: 1.5,
      fat: 11.5,
      glycemicIndex: 0,
    ),

    // ── Legumbres ──────────────────────────────────────────────────────
    NutritionFactsEntry(
      name: 'Frijoles negros',
      aliases: ['frijoles', 'frijoles negros', 'porotos'],
      servingDescription: '100g cocidos',
      calories: 132,
      protein: 8.9,
      carbs: 23.7,
      fat: 0.5,
      fiber: 8.7,
      glycemicIndex: 30,
    ),
    NutritionFactsEntry(
      name: 'Lentejas',
      aliases: ['lentejas', 'lenteja'],
      servingDescription: '100g cocidas',
      calories: 116,
      protein: 9.0,
      carbs: 20.0,
      fat: 0.4,
      fiber: 7.9,
      glycemicIndex: 29,
    ),
    NutritionFactsEntry(
      name: 'Garbanzos',
      aliases: ['garbanzos', 'garbanzo'],
      servingDescription: '100g cocidos',
      calories: 164,
      protein: 8.9,
      carbs: 27.4,
      fat: 2.6,
      fiber: 7.6,
      glycemicIndex: 28,
    ),

    // ── Frutos secos y semillas ────────────────────────────────────────
    NutritionFactsEntry(
      name: 'Almendras',
      aliases: ['almendras', 'almendra'],
      servingDescription: '28g (1 oz, ~23 unidades)',
      calories: 164,
      protein: 6.0,
      carbs: 6.0,
      fat: 14.0,
      fiber: 3.5,
      glycemicIndex: 0,
    ),
    NutritionFactsEntry(
      name: 'Nueces',
      aliases: ['nueces', 'walnuts'],
      servingDescription: '28g (1 oz)',
      calories: 185,
      protein: 4.3,
      carbs: 3.9,
      fat: 18.5,
      fiber: 1.9,
      glycemicIndex: 0,
    ),
    NutritionFactsEntry(
      name: 'Mantequilla de maní',
      aliases: ['mani', 'mantequilla mani', 'peanut butter', 'crema mani'],
      servingDescription: '2 cucharadas (32g)',
      calories: 188,
      protein: 8.0,
      carbs: 6.0,
      fat: 16.0,
      fiber: 2.0,
      glycemicIndex: 14,
    ),

    // ── Verduras ───────────────────────────────────────────────────────
    NutritionFactsEntry(
      name: 'Brócoli',
      aliases: ['brocoli', 'brocolí'],
      servingDescription: '100g cocido',
      calories: 35,
      protein: 2.4,
      carbs: 7.2,
      fat: 0.4,
      fiber: 3.3,
      glycemicIndex: 15,
    ),
    NutritionFactsEntry(
      name: 'Espinaca',
      aliases: ['espinaca', 'espinacas', 'spinach'],
      servingDescription: '100g',
      calories: 23,
      protein: 2.9,
      carbs: 3.6,
      fat: 0.4,
      fiber: 2.2,
      glycemicIndex: 15,
    ),
    NutritionFactsEntry(
      name: 'Zanahoria',
      aliases: ['zanahoria', 'zanahorias'],
      servingDescription: '1 mediana (61g)',
      calories: 25,
      protein: 0.6,
      carbs: 6.0,
      fat: 0.1,
      fiber: 1.7,
      glycemicIndex: 39,
    ),
  ];

  /// Devuelve el catálogo completo (vista de solo lectura).
  static List<NutritionFactsEntry> get all => List.unmodifiable(_catalog);

  /// Búsqueda case-insensitive por nombre o alias. Devuelve la primera
  /// entrada que matchee, o `null` si nada coincide.
  static NutritionFactsEntry? findByName(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return null;
    for (final entry in _catalog) {
      if (entry.name.toLowerCase() == q) return entry;
      if (entry.aliases.contains(q)) return entry;
    }
    return null;
  }

  /// Búsqueda fuzzy: devuelve todas las entradas cuyo nombre o alias
  /// CONTENGAN la query. Útil para sugerencias mientras el usuario tipea.
  static List<NutritionFactsEntry> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    return _catalog.where((entry) {
      if (entry.name.toLowerCase().contains(q)) return true;
      return entry.aliases.any((a) => a.contains(q));
    }).toList(growable: false);
  }

  /// Convierte una `NutritionFactsEntry` a un parche aplicable a un
  /// `NutritionLog` mediante `copyWith`. Marca el origen como `catalog`.
  static NutritionLog applyToLog(NutritionLog log, NutritionFactsEntry entry) {
    return log.copyWith(
      calories: entry.calories,
      protein: entry.protein,
      carbs: entry.carbs,
      fat: entry.fat,
      fiber: entry.fiber,
      glycemicIndex: entry.glycemicIndex,
      source: NutritionLogSource.catalog,
    );
  }
}
