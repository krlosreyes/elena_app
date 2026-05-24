// SPEC-137 E.4: catálogo curado con score numérico de calidad.
//
// Cada alimento tiene un `qualityScore` continuo (0-100) basado en su
// respuesta insulínica esperada y carga glucémica (literatura primaria:
// Jenkins 1981, Wolever 1991, Brand-Miller meta-análisis). NO se usa
// la nomenclatura binaria "Tipo A / Tipo E" que está asociada a marca
// registrada (NaturalSlim® / Frank Suárez®) — esta app es producto
// independiente con scoring propio derivado de fuentes científicas.
//
// Categorías visibles al usuario (3): Proteína / Grasa / Carbos. Cada
// alimento vive en una categoría según su macronutriente predominante
// (decisión de UI), pero su score refleja su impacto metabólico real.
//
// Score 0-100 convencional:
// - 95-100: óptimo. Casi cero respuesta insulínica (proteínas magras,
//   grasas saludables, verduras puras, endulzantes 0 cal).
// - 85-94: muy bueno. Proteínas con grasa, quesos firmes, frutos secos.
// - 65-84: bueno-moderado. Legumbres (proteína + carbo lento), pseudo-
//   cereales completos, lácteos firmes sin azúcar.
// - 35-64: medio-bajo. Avena, frutas bajas, leche, lácteos con azúcar
//   moderada, chocolate amargo.
// - 15-34: bajo. Cereales integrales, frutas tropicales dulces,
//   tubérculos densos, harinas integrales.
// - 0-14: muy bajo. Azúcar, panela, miel, harinas blancas, papa, yuca,
//   bebidas dulces.
//
// Catálogo: 80 alimentos cubriendo cocina LatAm con énfasis Colombia/
// Caribe. Curado con tabla de Carlos (22-may-2026, 60 items) + alimentos
// críticos faltantes (verduras, pavo, mariscos, endulzantes neutros).
//
// Discrepancias resueltas vs. tabla original de Carlos:
// - Fríjoles, Garbanzos, Lentejas, Habichuelas: quedan en categoría
//   Proteína (decisión de Carlos), score 70 (reconoce carbo lento).
// - Leche: categoría Proteína (decisión de Carlos), score 40 (lactosa).
// - Margarina: categoría Grasa (decisión de Carlos), score 30 (procesada).

/// Macro-categoría visible al usuario en el plato.
enum FoodCategory {
  /// Proteínas (animales, legumbres, lácteos proteicos).
  protein,

  /// Grasas (aceites, frutos secos, lácteos grasos, embutidos).
  fat,

  /// Carbohidratos (verduras, frutas, almidones, harinas, dulces, lácteos
  /// con lactosa alta).
  carb;

  /// Peso visual del alimento en el plato. Refleja "un trozo de pollo
  /// o de arroz ocupa más que un chorrito de aceite".
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

/// Un alimento del catálogo.
class Food {
  /// Slug estable para persistencia. NUNCA cambia.
  final String id;

  /// Nombre visible al usuario (LatAm-neutro, sesgo Colombia).
  final String name;

  /// En qué sector del plato vive.
  final FoodCategory category;

  /// Score de calidad metabólica (0-100). Ver §header del archivo.
  final int qualityScore;

  /// Términos alternativos para el buscador (búsqueda flexible).
  /// Ej. "Aguacate" lleva ["palta"] para que usuarios de Argentina/Uruguay
  /// que buscan "palta" encuentren el item.
  final List<String> searchAliases;

  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.qualityScore,
    this.searchAliases = const [],
  });

  /// Conveniencia: ¿el alimento es de alta calidad (score ≥ 70)?
  bool get isHighQuality => qualityScore >= 70;

  /// True si el alimento matchea el query del buscador. Comparación
  /// case-insensitive, ignorando tildes, tanto en el nombre como en
  /// los aliases.
  bool matchesQuery(String query) {
    final q = _normalize(query);
    if (q.isEmpty) return true;
    if (_normalize(name).contains(q)) return true;
    for (final alias in searchAliases) {
      if (_normalize(alias).contains(q)) return true;
    }
    return false;
  }

  static String _normalize(String s) {
    final lower = s.toLowerCase().trim();
    const accents = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ñ': 'n',
      'ü': 'u',
    };
    var result = lower;
    accents.forEach((from, to) {
      result = result.replaceAll(from, to);
    });
    return result;
  }
}

/// Catálogo curado y FIJO en MVP. 80 alimentos cubriendo cocina LatAm.
class FoodCatalog {
  const FoodCatalog._();

  // ── PROTEÍNAS (24) ────────────────────────────────────────────────────
  static const List<Food> proteins = [
    // Aves y huevo — alta calidad
    Food(id: 'pollo', name: 'Pollo', category: FoodCategory.protein, qualityScore: 95),
    Food(id: 'pechuga_pavo', name: 'Pechuga de pavo', category: FoodCategory.protein, qualityScore: 95),
    Food(id: 'huevo', name: 'Huevo', category: FoodCategory.protein, qualityScore: 95),

    // Carnes rojas — alta calidad
    Food(id: 'carne_res', name: 'Carne de res', category: FoodCategory.protein, qualityScore: 90),
    Food(id: 'cerdo', name: 'Cerdo', category: FoodCategory.protein, qualityScore: 88),

    // Pescados y mariscos — alta calidad
    Food(id: 'pescado', name: 'Pescado', category: FoodCategory.protein, qualityScore: 95),
    Food(id: 'atun', name: 'Atún', category: FoodCategory.protein, qualityScore: 95),
    Food(id: 'sardinas', name: 'Sardinas', category: FoodCategory.protein, qualityScore: 95),
    Food(id: 'salmon', name: 'Salmón', category: FoodCategory.protein, qualityScore: 95),
    Food(id: 'mariscos', name: 'Mariscos', category: FoodCategory.protein, qualityScore: 90, searchAliases: ['camarones', 'camaron', 'langostinos']),

    // Embutidos — calidad media-alta (procesados pero proteína)
    Food(id: 'jamon', name: 'Jamón', category: FoodCategory.protein, qualityScore: 80),

    // Lácteos proteicos — depende
    Food(id: 'queso_campesino', name: 'Queso campesino', category: FoodCategory.protein, qualityScore: 85),
    Food(id: 'yogur_griego', name: 'Yogur griego', category: FoodCategory.protein, qualityScore: 80, searchAliases: ['yogurt griego']),
    Food(id: 'suero_costeno', name: 'Suero costeño', category: FoodCategory.protein, qualityScore: 75),
    Food(id: 'leche', name: 'Leche', category: FoodCategory.protein, qualityScore: 40),

    // Legumbres — proteína + carbo lento, score 70
    Food(id: 'lentejas', name: 'Lentejas', category: FoodCategory.protein, qualityScore: 70),
    Food(id: 'frijoles', name: 'Fríjoles', category: FoodCategory.protein, qualityScore: 70, searchAliases: ['frijoles']),
    Food(id: 'garbanzos', name: 'Garbanzos', category: FoodCategory.protein, qualityScore: 70),
    Food(id: 'habichuelas', name: 'Habichuelas', category: FoodCategory.protein, qualityScore: 80),

    // Proteínas vegetales
    Food(id: 'tofu', name: 'Tofu', category: FoodCategory.protein, qualityScore: 85),

    // Quinua — pseudocereal con proteína completa
    Food(id: 'quinua', name: 'Quinua', category: FoodCategory.protein, qualityScore: 65, searchAliases: ['quinoa']),
  ];

  // ── GRASAS (22) ───────────────────────────────────────────────────────
  static const List<Food> fats = [
    // Grasas vegetales naturales — top
    Food(id: 'aguacate', name: 'Aguacate', category: FoodCategory.fat, qualityScore: 100, searchAliases: ['palta']),
    Food(id: 'aceite_oliva', name: 'Aceite de oliva', category: FoodCategory.fat, qualityScore: 100),
    Food(id: 'aceite_coco', name: 'Aceite de coco', category: FoodCategory.fat, qualityScore: 95),
    Food(id: 'aceite_vegetal', name: 'Aceite vegetal', category: FoodCategory.fat, qualityScore: 60),

    // Frutos secos — alta calidad
    Food(id: 'almendras', name: 'Almendras', category: FoodCategory.fat, qualityScore: 95),
    Food(id: 'nueces', name: 'Nueces', category: FoodCategory.fat, qualityScore: 95),
    Food(id: 'mani', name: 'Maní', category: FoodCategory.fat, qualityScore: 80, searchAliases: ['cacahuete']),
    Food(id: 'pistachos', name: 'Pistachos', category: FoodCategory.fat, qualityScore: 90),
    Food(id: 'semillas_girasol', name: 'Semillas de girasol', category: FoodCategory.fat, qualityScore: 90),
    Food(id: 'coco', name: 'Coco', category: FoodCategory.fat, qualityScore: 85),

    // Aceitunas
    Food(id: 'aceitunas', name: 'Aceitunas', category: FoodCategory.fat, qualityScore: 95),

    // Lácteos grasos — calidad media-alta sin azúcar
    Food(id: 'mantequilla', name: 'Mantequilla', category: FoodCategory.fat, qualityScore: 80),
    Food(id: 'queso_amarillo', name: 'Queso amarillo', category: FoodCategory.fat, qualityScore: 75),
    Food(id: 'queso_crema', name: 'Queso crema', category: FoodCategory.fat, qualityScore: 75),
    Food(id: 'crema_de_leche', name: 'Crema de leche', category: FoodCategory.fat, qualityScore: 70),
    Food(id: 'leche_entera', name: 'Leche entera', category: FoodCategory.fat, qualityScore: 50),

    // Carnes grasas / embutidos
    Food(id: 'tocino', name: 'Tocino', category: FoodCategory.fat, qualityScore: 75),
    Food(id: 'chicharron', name: 'Chicharrón', category: FoodCategory.fat, qualityScore: 70),
    Food(id: 'chorizo', name: 'Chorizo', category: FoodCategory.fat, qualityScore: 60),
    Food(id: 'salchicha', name: 'Salchicha', category: FoodCategory.fat, qualityScore: 50),

    // Procesadas - score bajo
    Food(id: 'mayonesa', name: 'Mayonesa', category: FoodCategory.fat, qualityScore: 50),
    Food(id: 'manteca', name: 'Manteca', category: FoodCategory.fat, qualityScore: 55),
    Food(id: 'margarina', name: 'Margarina', category: FoodCategory.fat, qualityScore: 30),
  ];

  // ── CARBOHIDRATOS (34) ────────────────────────────────────────────────
  static const List<Food> carbs = [
    // Verduras — máxima calidad
    Food(id: 'brocoli', name: 'Brócoli', category: FoodCategory.carb, qualityScore: 100),
    Food(id: 'espinaca', name: 'Espinaca', category: FoodCategory.carb, qualityScore: 100),
    Food(id: 'lechuga', name: 'Lechuga', category: FoodCategory.carb, qualityScore: 100),
    Food(id: 'tomate', name: 'Tomate', category: FoodCategory.carb, qualityScore: 95),
    Food(id: 'pepino', name: 'Pepino', category: FoodCategory.carb, qualityScore: 100),
    Food(id: 'calabacin', name: 'Calabacín', category: FoodCategory.carb, qualityScore: 100, searchAliases: ['zucchini', 'zapallito']),
    Food(id: 'coliflor', name: 'Coliflor', category: FoodCategory.carb, qualityScore: 100),
    Food(id: 'pimiento', name: 'Pimiento', category: FoodCategory.carb, qualityScore: 95, searchAliases: ['morron', 'aji dulce']),
    Food(id: 'zanahoria', name: 'Zanahoria', category: FoodCategory.carb, qualityScore: 75),
    Food(id: 'cebolla', name: 'Cebolla', category: FoodCategory.carb, qualityScore: 90),
    Food(id: 'apio', name: 'Apio', category: FoodCategory.carb, qualityScore: 100),

    // Frutas bajas
    Food(id: 'fresa', name: 'Fresa', category: FoodCategory.carb, qualityScore: 80, searchAliases: ['frutilla']),
    Food(id: 'manzana', name: 'Manzana', category: FoodCategory.carb, qualityScore: 65),
    Food(id: 'frambuesa', name: 'Frambuesa', category: FoodCategory.carb, qualityScore: 80),
    Food(id: 'arandanos', name: 'Arándanos', category: FoodCategory.carb, qualityScore: 70, searchAliases: ['blueberries']),

    // Frutas dulces tropicales — bajo
    Food(id: 'banano', name: 'Banano', category: FoodCategory.carb, qualityScore: 25, searchAliases: ['banana', 'guineo']),
    Food(id: 'mango', name: 'Mango', category: FoodCategory.carb, qualityScore: 20),
    Food(id: 'platano', name: 'Plátano', category: FoodCategory.carb, qualityScore: 20),

    // Cereales integrales — score 30-40
    Food(id: 'avena', name: 'Avena', category: FoodCategory.carb, qualityScore: 35),
    Food(id: 'arroz_integral', name: 'Arroz integral', category: FoodCategory.carb, qualityScore: 30),
    Food(id: 'pan_integral', name: 'Pan integral', category: FoodCategory.carb, qualityScore: 30),

    // Almidones densos
    Food(id: 'papa', name: 'Papa', category: FoodCategory.carb, qualityScore: 10),
    Food(id: 'papa_criolla', name: 'Papa criolla', category: FoodCategory.carb, qualityScore: 12),
    Food(id: 'yuca', name: 'Yuca', category: FoodCategory.carb, qualityScore: 10),
    Food(id: 'batata_camote', name: 'Batata / camote', category: FoodCategory.carb, qualityScore: 18),
    Food(id: 'tapioca', name: 'Tapioca', category: FoodCategory.carb, qualityScore: 10),
    Food(id: 'maiz', name: 'Maíz', category: FoodCategory.carb, qualityScore: 15),

    // Harinas y panes blancos
    Food(id: 'arroz', name: 'Arroz', category: FoodCategory.carb, qualityScore: 10, searchAliases: ['arroz blanco']),
    Food(id: 'pan', name: 'Pan', category: FoodCategory.carb, qualityScore: 8),
    Food(id: 'pasta', name: 'Pasta', category: FoodCategory.carb, qualityScore: 10),
    Food(id: 'arepa', name: 'Arepa', category: FoodCategory.carb, qualityScore: 15),
    Food(id: 'tortilla', name: 'Tortilla', category: FoodCategory.carb, qualityScore: 12),
    Food(id: 'harina', name: 'Harina', category: FoodCategory.carb, qualityScore: 8),
    Food(id: 'galletas', name: 'Galletas', category: FoodCategory.carb, qualityScore: 5),
    Food(id: 'cereal', name: 'Cereal', category: FoodCategory.carb, qualityScore: 10, searchAliases: ['cereal de caja']),

    // Azúcares puros
    Food(id: 'azucar', name: 'Azúcar', category: FoodCategory.carb, qualityScore: 0),
    Food(id: 'panela', name: 'Panela', category: FoodCategory.carb, qualityScore: 0, searchAliases: ['piloncillo', 'rapadura']),
    Food(id: 'miel', name: 'Miel', category: FoodCategory.carb, qualityScore: 5),
    Food(id: 'chocolate', name: 'Chocolate', category: FoodCategory.carb, qualityScore: 10),
  ];

  /// Lista completa unificada (orden: proteínas, grasas, carbos).
  static const List<Food> all = [
    ...proteins,
    ...fats,
    ...carbs,
  ];

  /// Devuelve los alimentos de una categoría.
  static List<Food> byCategory(FoodCategory category) =>
      all.where((f) => f.category == category).toList(growable: false);

  /// Búsqueda por id estable.
  static Food? byId(String id) {
    for (final f in all) {
      if (f.id == id) return f;
    }
    return null;
  }

  /// Búsqueda libre por nombre/alias. Devuelve hasta [limit] resultados
  /// ordenados por score descendente (primero los más saludables) y por
  /// alfabético como tiebreaker. Útil para el TextField del buscador.
  static List<Food> search(String query, {int limit = 8}) {
    if (query.trim().isEmpty) return const [];
    final matches = all.where((f) => f.matchesQuery(query)).toList();
    matches.sort((a, b) {
      final byScore = b.qualityScore.compareTo(a.qualityScore);
      if (byScore != 0) return byScore;
      return a.name.compareTo(b.name);
    });
    return matches.take(limit).toList(growable: false);
  }
}
