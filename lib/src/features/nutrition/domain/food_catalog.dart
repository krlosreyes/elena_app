// SPEC-137 E.4: catálogo curado con score numérico de calidad.
//
// Cada alimento tiene un `qualityScore` continuo (0-100) basado en su
// respuesta insulínica esperada y carga glucémica (literatura primaria:
// Jenkins 1981, Wolever 1991, Brand-Miller meta-análisis). NO se usa
// la nomenclatura binaria "Tipo A / Tipo E" que está asociada a marca
// registrada (NaturalSlim® / Frank Suárez®) — esta app es producto
// independiente con scoring propio derivado de fuentes científicas.
//
// SPEC-138 (2026-06-05): cada alimento lleva además un grado de
// procesamiento NOVA (1-4) según Monteiro et al. 2019 (Public Health
// Nutrition 22(5):936-941). Es un eje ortogonal al qualityScore:
// - qualityScore mide respuesta metabólica (insulínica/glucémica).
// - NOVA mide grado de procesamiento industrial.
// La clasificación de cada alimento está justificada en
// docs/NUTRITION_BIBLIOGRAPHY.md §16. NOVA 4 = ultraprocesado.
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
// Catálogo: 157 alimentos cubriendo cocina LatAm con énfasis Colombia/
// Caribe. Curado con tabla de Carlos (22-may-2026) + alimentos críticos
// faltantes (verduras, mariscos, frutas, bebidas, productos típicos).

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

/// Grado de procesamiento según sistema NOVA (Monteiro et al. 2019,
/// Public Health Nutrition 22(5):936-941).
///
/// El sistema NOVA clasifica alimentos por GRADO DE PROCESAMIENTO
/// industrial, no por composición nutricional. Es ortogonal al
/// [Food.qualityScore] (que mide respuesta metabólica).
///
/// Ejemplo aclaratorio: leche entera y margarina son ambas "media"
/// en qualityScore (50 y 30 respectivamente), pero NOVA las discrimina
/// — leche entera es NOVA 1 (mínimamente procesado) y margarina es
/// NOVA 4 (ultraprocesado con emulsionantes y grasas industriales).
enum NovaGroup {
  /// NOVA 1 — Sin procesar o mínimamente procesados.
  /// Ej: pollo, huevo, espinaca, manzana, almendras.
  unprocessed,

  /// NOVA 2 — Ingredientes culinarios procesados.
  /// Ej: aceite de oliva, mantequilla, azúcar, miel, panela.
  culinaryIngredient,

  /// NOVA 3 — Alimentos procesados (combinación NOVA1+NOVA2 con
  /// técnica artesanal o industrial conservadora).
  /// Ej: jamón, queso campesino, pan integral, tocino.
  processed,

  /// NOVA 4 — Ultraprocesados (UPF). Formulaciones industriales con
  /// aditivos cosméticos, ingredientes no culinarios y/o procesos
  /// extruidos. Asociados con +14% mortalidad por cada 10% más de
  /// consumo (Srour 2019, JAMA Intern Med 179(4):490-498).
  /// Ej: galletas, gaseosa, margarina, salchicha, cereal de caja.
  ultraProcessed;

  /// True si es NOVA 4 (ultraprocesado).
  bool get isUltraProcessed => this == NovaGroup.ultraProcessed;

  /// Etiqueta corta para tooltips/UI cuando se necesita.
  String get label => switch (this) {
        NovaGroup.unprocessed => 'Natural',
        NovaGroup.culinaryIngredient => 'Ingrediente culinario',
        NovaGroup.processed => 'Procesado',
        NovaGroup.ultraProcessed => 'Ultraprocesado',
      };

  /// Número NOVA (1..4) para persistencia y testing.
  int get number => switch (this) {
        NovaGroup.unprocessed => 1,
        NovaGroup.culinaryIngredient => 2,
        NovaGroup.processed => 3,
        NovaGroup.ultraProcessed => 4,
      };

  /// Reconstrucción desde el entero persistido.
  /// Default NOVA 1 si la clave es null/inválida (forward compat).
  static NovaGroup fromNumber(int? n) => switch (n) {
        2 => NovaGroup.culinaryIngredient,
        3 => NovaGroup.processed,
        4 => NovaGroup.ultraProcessed,
        _ => NovaGroup.unprocessed,
      };
}

// ── Unidad de medida para el selector de porciones ───────────────────────────

/// Cómo se mide una porción de este alimento en el picker de cantidad.
/// Determina las opciones del CupertinoPicker y cuántas copias se agregan
/// al PlateBuilder por selección.
enum ServingUnit {
  /// Piezas contables: huevos, frutas enteras, pechugas individuales.
  /// Picker: 1 · 2 · 3 · 4 · 5 · 6
  unit,

  /// Porción de 100g — carnes, pescados, embutidos.
  /// Picker: ½ · 1 · 1½ · 2 · 2½ → copias: 1·1·2·2·3
  portion100g,

  /// Cucharadas — aceites, mantequilla, salsas, semillas.
  /// Picker: 1 · 2 · 3 · 4
  tablespoon,

  /// Tazas — cereales cocidos, legumbres, sopas.
  /// Picker: ¼ · ½ · 1 · 1½ · 2 → copias: 1·1·1·2·2
  cup,

  /// Rebanadas — pan, queso en lonchas.
  /// Picker: 1 · 2 · 3 · 4
  slice,

  /// Puñados — frutos secos, semillas.
  /// Picker: 1 · 2 · 3
  handful,
}

extension ServingUnitExt on ServingUnit {
  /// Opciones legibles del picker para este tipo de unidad.
  /// El [foodName] se usa para personalizar la etiqueta.
  List<String> pickerLabels(String foodName) => switch (this) {
        ServingUnit.unit => [
            '1 $foodName',
            '2 ${foodName}s',
            '3 ${foodName}s',
            '4 ${foodName}s',
            '5 ${foodName}s',
            '6 ${foodName}s',
          ],
        ServingUnit.portion100g => [
            '½ porción (~50g)',
            '1 porción (~100g)',
            '1½ porciones (~150g)',
            '2 porciones (~200g)',
            '2½ porciones (~250g)',
          ],
        ServingUnit.tablespoon => [
            '1 cucharada',
            '2 cucharadas',
            '3 cucharadas',
            '4 cucharadas',
          ],
        ServingUnit.cup => [
            '¼ taza',
            '½ taza',
            '1 taza',
            '1½ tazas',
            '2 tazas',
          ],
        ServingUnit.slice => [
            '1 rebanada',
            '2 rebanadas',
            '3 rebanadas',
            '4 rebanadas',
          ],
        ServingUnit.handful => [
            '1 puñado',
            '2 puñados',
            '3 puñados',
          ],
      };

  /// Cuántas copias del Food se agregan al PlateBuilder por cada opción.
  List<int> get copyCounts => switch (this) {
        ServingUnit.unit => [1, 2, 3, 4, 5, 6],
        ServingUnit.portion100g => [1, 1, 2, 2, 3],
        ServingUnit.tablespoon => [1, 1, 1, 1],
        ServingUnit.cup => [1, 1, 1, 2, 2],
        ServingUnit.slice => [1, 1, 2, 2],
        ServingUnit.handful => [1, 1, 2],
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

  /// SPEC-138: grado de procesamiento industrial.
  ///
  /// Default [NovaGroup.unprocessed] (NOVA 1) — el catálogo MVP
  /// arranca asumiendo "alimento natural" salvo evidencia contraria
  /// documentada en docs/NUTRITION_BIBLIOGRAPHY.md §6.
  final NovaGroup nova;

  /// Términos alternativos para el buscador (búsqueda flexible).
  final List<String> searchAliases;

  /// Referencia visual de porción estándar. Ej: "1 huevo mediano",
  /// "100g (palma de la mano)", "½ aguacate". Se muestra en el picker
  /// de cantidad para que el usuario entienda cuánto es "1 porción".
  final String portionLabel;

  /// Cómo se mide la cantidad de este alimento. Determina las opciones
  /// del CupertinoPicker y cuántas copias se agregan al PlateBuilder.
  final ServingUnit servingUnit;

  /// Tipo A (metabolicamente activo, qualityScore ≥ 70) o Tipo E.
  /// Derivado del qualityScore — no se almacena por separado.
  bool get isTipoA => qualityScore >= 70;

  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.qualityScore,
    this.nova = NovaGroup.unprocessed,
    this.searchAliases = const [],
    this.portionLabel = '1 porción',
    this.servingUnit = ServingUnit.unit,
  });

  /// Conveniencia: ¿el alimento es de alta calidad (score ≥ 70)?
  bool get isHighQuality => qualityScore >= 70;

  /// SPEC-138: ¿el alimento es ultraprocesado (NOVA 4)?
  bool get isUltraProcessed => nova.isUltraProcessed;

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

  /// SPEC-251: especificidad de este alimento frente a [normalizedQuery]
  /// (ya normalizado — ver [_normalize]). Menor valor = coincidencia más
  /// específica. Se usa como desempate cuando dos alimentos tienen el
  /// mismo [qualityScore]: sin esto, buscar "aguacate" podía devolver
  /// "Aceite de aguacate" antes que "Aguacate" — ambos con score 100,
  /// desempatados solo alfabéticamente ("Aceite..." < "Aguacate").
  int matchSpecificity(String normalizedQuery) {
    final normalizedName = _normalize(name);
    if (normalizedName == normalizedQuery) return 0;
    if (normalizedName.startsWith(normalizedQuery)) return 1;
    for (final alias in searchAliases) {
      if (_normalize(alias) == normalizedQuery) return 2;
    }
    for (final alias in searchAliases) {
      if (_normalize(alias).startsWith(normalizedQuery)) return 3;
    }
    return 4;
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

/// Catálogo curado. 157 alimentos cubriendo cocina LatAm con énfasis
/// Colombia/Caribe. Todos los alimentos llevan portionLabel y servingUnit
/// para el picker de cantidad del plato.
class FoodCatalog {
  const FoodCatalog._();

  // ── PROTEÍNAS (34) ────────────────────────────────────────────────────
  static const List<Food> proteins = [
    // Aves y huevo — alta calidad
    Food(
      id: 'pollo',
      name: 'Pollo',
      category: FoodCategory.protein,
      qualityScore: 95,
      portionLabel: '100g (palma de la mano)',
      servingUnit: ServingUnit.portion100g,
    ),
    Food(
      id: 'pechuga_pavo',
      name: 'Pechuga de pavo',
      category: FoodCategory.protein,
      qualityScore: 95,
      portionLabel: '100g (palma de la mano)',
      servingUnit: ServingUnit.portion100g,
    ),
    Food(
      id: 'muslo_pollo',
      name: 'Muslo de pollo',
      category: FoodCategory.protein,
      qualityScore: 90,
      portionLabel: '1 muslo (~120g)',
      servingUnit: ServingUnit.unit,
    ),
    Food(
      id: 'huevo',
      name: 'Huevo',
      category: FoodCategory.protein,
      qualityScore: 95,
      portionLabel: '1 huevo mediano (~50g)',
      servingUnit: ServingUnit.unit,
    ),
    Food(
      id: 'clara_huevo',
      name: 'Clara de huevo',
      category: FoodCategory.protein,
      qualityScore: 98,
      portionLabel: '3 claras (~90g)',
      servingUnit: ServingUnit.unit,
      searchAliases: ['claras', 'albumina', 'clara'],
    ),

    // Carnes rojas — alta calidad
    Food(
      id: 'carne_res',
      name: 'Carne de res',
      category: FoodCategory.protein,
      qualityScore: 90,
      portionLabel: '100g (palma de la mano)',
      servingUnit: ServingUnit.portion100g,
    ),
    Food(
      id: 'cerdo',
      name: 'Cerdo',
      category: FoodCategory.protein,
      qualityScore: 88,
      portionLabel: '100g (palma de la mano)',
      servingUnit: ServingUnit.portion100g,
    ),

    // Pescados y mariscos — alta calidad
    Food(
      id: 'pescado',
      name: 'Pescado',
      category: FoodCategory.protein,
      qualityScore: 95,
      portionLabel: '100g (palma de la mano)',
      servingUnit: ServingUnit.portion100g,
    ),
    Food(
      id: 'atun',
      name: 'Atún',
      category: FoodCategory.protein,
      qualityScore: 95,
      portionLabel: '½ lata (~80g)',
      servingUnit: ServingUnit.portion100g,
    ),
    Food(
      id: 'sardinas',
      name: 'Sardinas',
      category: FoodCategory.protein,
      qualityScore: 95,
      portionLabel: '½ lata (~85g)',
      servingUnit: ServingUnit.portion100g,
    ),
    Food(
      id: 'salmon',
      name: 'Salmón',
      category: FoodCategory.protein,
      qualityScore: 95,
      portionLabel: '100g (palma de la mano)',
      servingUnit: ServingUnit.portion100g,
    ),
    Food(
      id: 'trucha',
      name: 'Trucha',
      category: FoodCategory.protein,
      qualityScore: 95,
      portionLabel: '100g (palma de la mano)',
      servingUnit: ServingUnit.portion100g,
      searchAliases: ['trucha arcoiris', 'trucha arcoíris'],
    ),
    Food(
      id: 'tilapia',
      name: 'Tilapia',
      category: FoodCategory.protein,
      qualityScore: 95,
      portionLabel: '100g (palma de la mano)',
      servingUnit: ServingUnit.portion100g,
      searchAliases: ['mojarra', 'tilapia roja'],
    ),
    Food(
      id: 'mariscos',
      name: 'Mariscos',
      category: FoodCategory.protein,
      qualityScore: 90,
      portionLabel: '100g (~12 unidades)',
      servingUnit: ServingUnit.portion100g,
      searchAliases: ['camarones', 'camaron', 'langostinos'],
    ),
    Food(
      id: 'camaron',
      name: 'Camarón',
      category: FoodCategory.protein,
      qualityScore: 92,
      portionLabel: '100g (~10 camarones)',
      servingUnit: ServingUnit.portion100g,
      searchAliases: ['camarones', 'shrimp', 'gambas'],
    ),
    Food(
      id: 'langostino',
      name: 'Langostino',
      category: FoodCategory.protein,
      qualityScore: 92,
      portionLabel: '100g (~6 langostinos)',
      servingUnit: ServingUnit.portion100g,
      searchAliases: ['langostinos', 'prawns'],
    ),

    // Embutidos — calidad media-alta (NOVA 3: curado con sal/nitritos)
    Food(
      id: 'jamon',
      name: 'Jamón',
      category: FoodCategory.protein,
      qualityScore: 80,
      nova: NovaGroup.processed,
      portionLabel: '2 rebanadas (~40g)',
      servingUnit: ServingUnit.slice,
    ),

    // Lácteos proteicos
    Food(
      id: 'queso_campesino',
      name: 'Queso campesino',
      category: FoodCategory.protein,
      qualityScore: 85,
      nova: NovaGroup.processed,
      portionLabel: '1 trozo (~50g)',
      servingUnit: ServingUnit.portion100g,
    ),
    Food(
      id: 'queso_mozzarella',
      name: 'Queso mozzarella',
      category: FoodCategory.protein,
      qualityScore: 80,
      nova: NovaGroup.processed,
      portionLabel: '30g (~2 rebanadas)',
      servingUnit: ServingUnit.slice,
      searchAliases: ['mozzarella', 'mozarela'],
    ),
    Food(
      id: 'yogur_griego',
      name: 'Yogur griego',
      category: FoodCategory.protein,
      qualityScore: 80,
      nova: NovaGroup.processed,
      portionLabel: '1 taza (~200g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['yogurt griego'],
    ),
    Food(
      id: 'kefir',
      name: 'Kéfir',
      category: FoodCategory.protein,
      qualityScore: 80,
      nova: NovaGroup.processed,
      portionLabel: '1 taza (~240ml)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['kefir', 'yogur kéfir', 'yogur kefir'],
    ),
    Food(
      id: 'ricotta',
      name: 'Ricotta',
      category: FoodCategory.protein,
      qualityScore: 75,
      nova: NovaGroup.processed,
      portionLabel: '¼ taza (~60g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['requesón', 'requeson'],
    ),
    Food(
      id: 'suero_costeno',
      name: 'Suero costeño',
      category: FoodCategory.protein,
      qualityScore: 75,
      nova: NovaGroup.processed,
      portionLabel: '2 cucharadas (~30g)',
      servingUnit: ServingUnit.tablespoon,
    ),
    Food(
      id: 'leche',
      name: 'Leche',
      category: FoodCategory.protein,
      qualityScore: 40,
      portionLabel: '1 taza (~250ml)',
      servingUnit: ServingUnit.cup,
    ),

    // Legumbres — proteína + carbo lento, score 70
    Food(
      id: 'lentejas',
      name: 'Lentejas',
      category: FoodCategory.protein,
      qualityScore: 70,
      portionLabel: '½ taza cocida',
      servingUnit: ServingUnit.cup,
    ),
    Food(
      id: 'frijoles',
      name: 'Fríjoles',
      category: FoodCategory.protein,
      qualityScore: 70,
      portionLabel: '½ taza cocida',
      servingUnit: ServingUnit.cup,
      searchAliases: ['frijoles'],
    ),
    Food(
      id: 'garbanzos',
      name: 'Garbanzos',
      category: FoodCategory.protein,
      qualityScore: 70,
      portionLabel: '½ taza cocida',
      servingUnit: ServingUnit.cup,
    ),
    Food(
      id: 'habichuelas',
      name: 'Habichuelas',
      category: FoodCategory.protein,
      qualityScore: 80,
      portionLabel: '1 taza cocida',
      servingUnit: ServingUnit.cup,
    ),

    // Proteínas vegetales
    Food(
      id: 'tofu',
      name: 'Tofu',
      category: FoodCategory.protein,
      qualityScore: 85,
      portionLabel: '100g (~¼ bloque)',
      servingUnit: ServingUnit.portion100g,
    ),
    Food(
      id: 'tempeh',
      name: 'Tempeh',
      category: FoodCategory.protein,
      qualityScore: 85,
      nova: NovaGroup.processed,
      portionLabel: '100g',
      servingUnit: ServingUnit.portion100g,
      searchAliases: ['tempe'],
    ),

    // Quinua — pseudocereal con proteína completa
    Food(
      id: 'quinua',
      name: 'Quinua',
      category: FoodCategory.protein,
      qualityScore: 65,
      portionLabel: '½ taza cocida',
      servingUnit: ServingUnit.cup,
      searchAliases: ['quinoa'],
    ),

    // Caldos — proteína animal diluida; score moderado por dilución
    Food(
      id: 'caldo_pollo',
      name: 'Caldo de pollo',
      category: FoodCategory.protein,
      qualityScore: 75,
      portionLabel: '1 taza (~240ml)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['consome', 'consome de pollo', 'sopa de pollo'],
    ),
    Food(
      id: 'caldo_costilla',
      name: 'Caldo de costilla',
      category: FoodCategory.protein,
      qualityScore: 75,
      portionLabel: '1 taza (~240ml)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['caldo de res', 'caldo de hueso', 'sancocho'],
    ),
    Food(
      id: 'caldo_pescado',
      name: 'Caldo de pescado',
      category: FoodCategory.protein,
      qualityScore: 75,
      portionLabel: '1 taza (~240ml)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['sopa de pescado'],
    ),
  ];

  // ── GRASAS (34) ───────────────────────────────────────────────────────
  static const List<Food> fats = [
    // Grasas vegetales naturales — top
    Food(
      id: 'aguacate',
      name: 'Aguacate',
      category: FoodCategory.fat,
      qualityScore: 100,
      portionLabel: '½ aguacate mediano (~100g)',
      servingUnit: ServingUnit.portion100g,
      searchAliases: ['palta'],
    ),
    Food(
      id: 'aceite_oliva',
      name: 'Aceite de oliva',
      category: FoodCategory.fat,
      qualityScore: 100,
      portionLabel: '1 cucharada (~15ml)',
      servingUnit: ServingUnit.tablespoon,
    ),
    Food(
      id: 'aceite_coco',
      name: 'Aceite de coco',
      category: FoodCategory.fat,
      qualityScore: 95,
      portionLabel: '1 cucharada (~14g)',
      servingUnit: ServingUnit.tablespoon,
    ),
    Food(
      id: 'aceite_aguacate',
      name: 'Aceite de aguacate',
      category: FoodCategory.fat,
      qualityScore: 100,
      nova: NovaGroup.processed,
      portionLabel: '1 cucharada (~15ml)',
      servingUnit: ServingUnit.tablespoon,
      searchAliases: ['avocado oil'],
    ),
    Food(
      id: 'aceite_vegetal',
      name: 'Aceite vegetal',
      category: FoodCategory.fat,
      qualityScore: 60,
      nova: NovaGroup.processed,
      portionLabel: '1 cucharada (~15ml)',
      servingUnit: ServingUnit.tablespoon,
    ),

    // Frutos secos — alta calidad
    Food(
      id: 'almendras',
      name: 'Almendras',
      category: FoodCategory.fat,
      qualityScore: 95,
      portionLabel: '1 puñado (~28g)',
      servingUnit: ServingUnit.handful,
    ),
    Food(
      id: 'nueces',
      name: 'Nueces',
      category: FoodCategory.fat,
      qualityScore: 95,
      portionLabel: '1 puñado (~30g, ~7 nueces)',
      servingUnit: ServingUnit.handful,
    ),
    Food(
      id: 'macadamia',
      name: 'Macadamia',
      category: FoodCategory.fat,
      qualityScore: 95,
      portionLabel: '1 puñado (~28g, ~11 nueces)',
      servingUnit: ServingUnit.handful,
      searchAliases: ['nueces macadamia', 'nuez de macadamia'],
    ),
    Food(
      id: 'avellanas',
      name: 'Avellanas',
      category: FoodCategory.fat,
      qualityScore: 90,
      portionLabel: '1 puñado (~28g)',
      servingUnit: ServingUnit.handful,
      searchAliases: ['hazelnuts'],
    ),
    Food(
      id: 'mani',
      name: 'Maní',
      category: FoodCategory.fat,
      qualityScore: 80,
      portionLabel: '1 puñado (~28g)',
      servingUnit: ServingUnit.handful,
      searchAliases: ['cacahuete'],
    ),
    Food(
      id: 'pistachos',
      name: 'Pistachos',
      category: FoodCategory.fat,
      qualityScore: 90,
      portionLabel: '1 puñado (~28g)',
      servingUnit: ServingUnit.handful,
    ),
    Food(
      id: 'semillas_girasol',
      name: 'Semillas de girasol',
      category: FoodCategory.fat,
      qualityScore: 90,
      portionLabel: '2 cucharadas (~20g)',
      servingUnit: ServingUnit.tablespoon,
    ),
    Food(
      id: 'semillas_calabaza',
      name: 'Semillas de calabaza',
      category: FoodCategory.fat,
      qualityScore: 90,
      portionLabel: '2 cucharadas (~20g)',
      servingUnit: ServingUnit.tablespoon,
      searchAliases: ['pepitas', 'pipas de calabaza'],
    ),
    Food(
      id: 'coco',
      name: 'Coco',
      category: FoodCategory.fat,
      qualityScore: 85,
      portionLabel: '¼ taza rallado (~25g)',
      servingUnit: ServingUnit.cup,
    ),

    // Pastas y cremas de frutos secos
    Food(
      id: 'mantequilla_almendras',
      name: 'Mantequilla de almendras',
      category: FoodCategory.fat,
      qualityScore: 85,
      nova: NovaGroup.processed,
      portionLabel: '2 cucharadas (~32g)',
      servingUnit: ServingUnit.tablespoon,
      searchAliases: ['crema de almendras', 'almond butter'],
    ),
    Food(
      id: 'tahini',
      name: 'Tahini',
      category: FoodCategory.fat,
      qualityScore: 85,
      nova: NovaGroup.processed,
      portionLabel: '2 cucharadas (~30g)',
      servingUnit: ServingUnit.tablespoon,
      searchAliases: [
        'pasta de ajonjoli',
        'pasta de sesamo',
        'pasta de sésamo'
      ],
    ),
    Food(
      id: 'ajonjoli',
      name: 'Ajonjolí',
      category: FoodCategory.fat,
      qualityScore: 90,
      portionLabel: '1 cucharada (~9g)',
      servingUnit: ServingUnit.tablespoon,
      searchAliases: ['sesamo', 'sésamo', 'sesame'],
    ),

    // Aceitunas
    Food(
      id: 'aceitunas',
      name: 'Aceitunas',
      category: FoodCategory.fat,
      qualityScore: 95,
      portionLabel: '10 aceitunas (~35g)',
      servingUnit: ServingUnit.handful,
    ),

    // Lácteos grasos
    Food(
      id: 'mantequilla',
      name: 'Mantequilla',
      category: FoodCategory.fat,
      qualityScore: 80,
      nova: NovaGroup.culinaryIngredient,
      portionLabel: '1 cucharada (~14g)',
      servingUnit: ServingUnit.tablespoon,
    ),
    Food(
      id: 'ghee',
      name: 'Ghee',
      category: FoodCategory.fat,
      qualityScore: 85,
      nova: NovaGroup.culinaryIngredient,
      portionLabel: '1 cucharada (~14g)',
      servingUnit: ServingUnit.tablespoon,
      searchAliases: ['mantequilla clarificada', 'manteca clarificada'],
    ),
    Food(
      id: 'leche_coco',
      name: 'Leche de coco',
      category: FoodCategory.fat,
      qualityScore: 85,
      nova: NovaGroup.processed,
      portionLabel: '½ taza (~120ml)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['coconut milk', 'crema de coco'],
    ),
    Food(
      id: 'queso_amarillo',
      name: 'Queso amarillo',
      category: FoodCategory.fat,
      qualityScore: 75,
      nova: NovaGroup.processed,
      portionLabel: '1 rebanada (~20g)',
      servingUnit: ServingUnit.slice,
    ),
    Food(
      id: 'queso_crema',
      name: 'Queso crema',
      category: FoodCategory.fat,
      qualityScore: 75,
      nova: NovaGroup.processed,
      portionLabel: '2 cucharadas (~30g)',
      servingUnit: ServingUnit.tablespoon,
    ),
    Food(
      id: 'crema_de_leche',
      name: 'Crema de leche',
      category: FoodCategory.fat,
      qualityScore: 70,
      nova: NovaGroup.processed,
      portionLabel: '2 cucharadas (~30ml)',
      servingUnit: ServingUnit.tablespoon,
    ),
    Food(
      id: 'leche_entera',
      name: 'Leche entera',
      category: FoodCategory.fat,
      qualityScore: 50,
      portionLabel: '1 taza (~250ml)',
      servingUnit: ServingUnit.cup,
    ),

    // Carnes grasas / embutidos
    Food(
      id: 'tocino',
      name: 'Tocino',
      category: FoodCategory.fat,
      qualityScore: 75,
      nova: NovaGroup.processed,
      portionLabel: '2 tiras (~30g)',
      servingUnit: ServingUnit.slice,
    ),
    Food(
      id: 'chicharron',
      name: 'Chicharrón',
      category: FoodCategory.fat,
      qualityScore: 70,
      nova: NovaGroup.processed,
      portionLabel: '100g',
      servingUnit: ServingUnit.portion100g,
    ),
    Food(
      id: 'chorizo',
      name: 'Chorizo',
      category: FoodCategory.fat,
      qualityScore: 60,
      nova: NovaGroup.processed,
      portionLabel: '1 chorizo (~80g)',
      servingUnit: ServingUnit.unit,
    ),
    Food(
      id: 'salchicha',
      name: 'Salchicha',
      category: FoodCategory.fat,
      qualityScore: 50,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '1 salchicha (~50g)',
      servingUnit: ServingUnit.unit,
    ),

    // Procesadas — score bajo
    Food(
      id: 'mayonesa',
      name: 'Mayonesa',
      category: FoodCategory.fat,
      qualityScore: 50,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '1 cucharada (~15g)',
      servingUnit: ServingUnit.tablespoon,
    ),
    Food(
      id: 'manteca',
      name: 'Manteca',
      category: FoodCategory.fat,
      qualityScore: 55,
      nova: NovaGroup.culinaryIngredient,
      portionLabel: '1 cucharada (~15g)',
      servingUnit: ServingUnit.tablespoon,
    ),
    Food(
      id: 'margarina',
      name: 'Margarina',
      category: FoodCategory.fat,
      qualityScore: 30,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '1 cucharada (~14g)',
      servingUnit: ServingUnit.tablespoon,
    ),

    // Semillas con omega-3 y fibra — alta calidad metabólica
    Food(
      id: 'semillas_chia',
      name: 'Semillas de chía',
      category: FoodCategory.fat,
      qualityScore: 95,
      portionLabel: '1 cucharada (~12g)',
      servingUnit: ServingUnit.tablespoon,
      searchAliases: ['chia'],
    ),
    Food(
      id: 'linaza',
      name: 'Linaza',
      category: FoodCategory.fat,
      qualityScore: 95,
      portionLabel: '1 cucharada (~10g)',
      servingUnit: ServingUnit.tablespoon,
      searchAliases: ['lino', 'semillas de lino'],
    ),
  ];

  // ── CARBOHIDRATOS (89) ────────────────────────────────────────────────
  static const List<Food> carbs = [
    // Verduras — máxima calidad
    Food(
      id: 'brocoli',
      name: 'Brócoli',
      category: FoodCategory.carb,
      qualityScore: 100,
      portionLabel: '1 taza (~91g)',
      servingUnit: ServingUnit.cup,
    ),
    Food(
      id: 'espinaca',
      name: 'Espinaca',
      category: FoodCategory.carb,
      qualityScore: 100,
      portionLabel: '1 taza cruda (~30g)',
      servingUnit: ServingUnit.cup,
    ),
    Food(
      id: 'lechuga',
      name: 'Lechuga',
      category: FoodCategory.carb,
      qualityScore: 100,
      portionLabel: '2 tazas (~85g)',
      servingUnit: ServingUnit.cup,
    ),
    Food(
      id: 'tomate',
      name: 'Tomate',
      category: FoodCategory.carb,
      qualityScore: 95,
      portionLabel: '1 tomate mediano (~123g)',
      servingUnit: ServingUnit.unit,
    ),
    Food(
      id: 'pepino',
      name: 'Pepino',
      category: FoodCategory.carb,
      qualityScore: 100,
      portionLabel: '½ pepino (~150g)',
      servingUnit: ServingUnit.unit,
    ),
    Food(
      id: 'calabacin',
      name: 'Calabacín',
      category: FoodCategory.carb,
      qualityScore: 100,
      portionLabel: '1 taza en cubos (~113g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['zucchini', 'zapallito'],
    ),
    Food(
      id: 'coliflor',
      name: 'Coliflor',
      category: FoodCategory.carb,
      qualityScore: 100,
      portionLabel: '1 taza en floretes (~100g)',
      servingUnit: ServingUnit.cup,
    ),
    Food(
      id: 'pimiento',
      name: 'Pimiento',
      category: FoodCategory.carb,
      qualityScore: 95,
      portionLabel: '1 pimiento mediano (~119g)',
      servingUnit: ServingUnit.unit,
      searchAliases: ['morron', 'aji dulce'],
    ),
    Food(
      id: 'zanahoria',
      name: 'Zanahoria',
      category: FoodCategory.carb,
      qualityScore: 75,
      portionLabel: '1 zanahoria mediana (~61g)',
      servingUnit: ServingUnit.unit,
    ),
    Food(
      id: 'cebolla',
      name: 'Cebolla',
      category: FoodCategory.carb,
      qualityScore: 90,
      portionLabel: '½ cebolla mediana (~55g)',
      servingUnit: ServingUnit.unit,
    ),
    Food(
      id: 'apio',
      name: 'Apio',
      category: FoodCategory.carb,
      qualityScore: 100,
      portionLabel: '2 ramas (~80g)',
      servingUnit: ServingUnit.unit,
    ),
    Food(
      id: 'champinones',
      name: 'Champiñones',
      category: FoodCategory.carb,
      qualityScore: 95,
      portionLabel: '1 taza (~70g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['hongos', 'setas', 'mushrooms', 'champiñones'],
    ),
    Food(
      id: 'berenjena',
      name: 'Berenjena',
      category: FoodCategory.carb,
      qualityScore: 95,
      portionLabel: '1 taza en cubos (~82g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['aubergine', 'eggplant'],
    ),
    Food(
      id: 'kale',
      name: 'Kale',
      category: FoodCategory.carb,
      qualityScore: 100,
      portionLabel: '1 taza (~67g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['col rizada', 'berza'],
    ),
    Food(
      id: 'acelga',
      name: 'Acelga',
      category: FoodCategory.carb,
      qualityScore: 100,
      portionLabel: '1 taza (~36g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['chard'],
    ),
    Food(
      id: 'cilantro',
      name: 'Cilantro',
      category: FoodCategory.carb,
      qualityScore: 100,
      portionLabel: '¼ taza (~4g)',
      servingUnit: ServingUnit.handful,
      searchAliases: ['coriander'],
    ),
    Food(
      id: 'ajo',
      name: 'Ajo',
      category: FoodCategory.carb,
      qualityScore: 95,
      portionLabel: '1 diente (~3g)',
      servingUnit: ServingUnit.unit,
      searchAliases: ['garlic'],
    ),
    Food(
      id: 'jengibre',
      name: 'Jengibre',
      category: FoodCategory.carb,
      qualityScore: 95,
      portionLabel: '1 cucharadita (~5g)',
      servingUnit: ServingUnit.tablespoon,
      searchAliases: ['ginger', 'gengibre'],
    ),
    Food(
      id: 'remolacha',
      name: 'Remolacha',
      category: FoodCategory.carb,
      qualityScore: 45,
      portionLabel: '1 remolacha mediana (~100g)',
      servingUnit: ServingUnit.unit,
      searchAliases: ['betabel', 'beet', 'betarraga'],
    ),

    // Frutas de bajo índice glucémico
    Food(
      id: 'fresa',
      name: 'Fresa',
      category: FoodCategory.carb,
      qualityScore: 80,
      portionLabel: '1 taza (~150g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['frutilla'],
    ),
    Food(
      id: 'frambuesa',
      name: 'Frambuesa',
      category: FoodCategory.carb,
      qualityScore: 80,
      portionLabel: '1 taza (~123g)',
      servingUnit: ServingUnit.cup,
    ),
    Food(
      id: 'arandanos',
      name: 'Arándanos',
      category: FoodCategory.carb,
      qualityScore: 70,
      portionLabel: '1 taza (~148g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['blueberries'],
    ),
    Food(
      id: 'mora',
      name: 'Mora',
      category: FoodCategory.carb,
      qualityScore: 70,
      portionLabel: '1 taza (~144g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['blackberry', 'zarzamora', 'moras'],
    ),
    Food(
      id: 'uchuva',
      name: 'Uchuva',
      category: FoodCategory.carb,
      qualityScore: 60,
      portionLabel: '1 taza (~100g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['uvilla', 'physalis', 'cape gooseberry'],
    ),
    Food(
      id: 'manzana',
      name: 'Manzana',
      category: FoodCategory.carb,
      qualityScore: 65,
      portionLabel: '1 manzana mediana (~182g)',
      servingUnit: ServingUnit.unit,
    ),
    Food(
      id: 'pera',
      name: 'Pera',
      category: FoodCategory.carb,
      qualityScore: 50,
      portionLabel: '1 pera mediana (~178g)',
      servingUnit: ServingUnit.unit,
      searchAliases: ['pear'],
    ),
    Food(
      id: 'durazno',
      name: 'Durazno',
      category: FoodCategory.carb,
      qualityScore: 50,
      portionLabel: '1 durazno mediano (~150g)',
      servingUnit: ServingUnit.unit,
      searchAliases: ['melocoton', 'melocotón', 'peach'],
    ),
    Food(
      id: 'kiwi',
      name: 'Kiwi',
      category: FoodCategory.carb,
      qualityScore: 60,
      portionLabel: '1 kiwi mediano (~77g)',
      servingUnit: ServingUnit.unit,
    ),
    Food(
      id: 'guayaba',
      name: 'Guayaba',
      category: FoodCategory.carb,
      qualityScore: 55,
      portionLabel: '1 guayaba mediana (~90g)',
      servingUnit: ServingUnit.unit,
      searchAliases: ['guava'],
    ),
    Food(
      id: 'limon',
      name: 'Limón',
      category: FoodCategory.carb,
      qualityScore: 90,
      portionLabel: '1 limón mediano (~58g)',
      servingUnit: ServingUnit.unit,
      searchAliases: ['lima', 'lemon'],
    ),
    Food(
      id: 'uvas',
      name: 'Uvas',
      category: FoodCategory.carb,
      qualityScore: 35,
      portionLabel: '1 taza (~150g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['grapes', 'uva'],
    ),
    Food(
      id: 'mandarina',
      name: 'Mandarina',
      category: FoodCategory.carb,
      qualityScore: 45,
      portionLabel: '1 mandarina mediana (~88g)',
      servingUnit: ServingUnit.unit,
      searchAliases: ['tangerina'],
    ),
    Food(
      id: 'naranja',
      name: 'Naranja',
      category: FoodCategory.carb,
      qualityScore: 40,
      portionLabel: '1 naranja mediana (~131g)',
      servingUnit: ServingUnit.unit,
      searchAliases: ['china', 'orange'],
    ),

    // Frutas tropicales dulces — IG moderado-alto
    Food(
      id: 'banano',
      name: 'Banano',
      category: FoodCategory.carb,
      qualityScore: 25,
      portionLabel: '1 banano mediano (~118g)',
      servingUnit: ServingUnit.unit,
      searchAliases: ['banana', 'guineo'],
    ),
    Food(
      id: 'mango',
      name: 'Mango',
      category: FoodCategory.carb,
      qualityScore: 20,
      portionLabel: '1 taza en cubos (~165g)',
      servingUnit: ServingUnit.cup,
    ),
    Food(
      id: 'papaya',
      name: 'Papaya',
      category: FoodCategory.carb,
      qualityScore: 30,
      portionLabel: '1 taza en cubos (~140g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['lechosa', 'fruta bomba', 'mamon'],
    ),
    Food(
      id: 'pina',
      name: 'Piña',
      category: FoodCategory.carb,
      qualityScore: 25,
      portionLabel: '1 taza en cubos (~165g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['ananas', 'pina'],
    ),
    Food(
      id: 'maracuya',
      name: 'Maracuyá',
      category: FoodCategory.carb,
      qualityScore: 40,
      portionLabel: '1 maracuyá (~18g pulpa)',
      servingUnit: ServingUnit.unit,
      searchAliases: ['passion fruit', 'parchita'],
    ),
    Food(
      id: 'melon',
      name: 'Melón',
      category: FoodCategory.carb,
      qualityScore: 25,
      portionLabel: '1 taza en cubos (~160g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['cantalupo', 'cantaloupe'],
    ),
    Food(
      id: 'sandia',
      name: 'Sandía',
      category: FoodCategory.carb,
      qualityScore: 20,
      portionLabel: '1 taza en cubos (~154g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['patilla', 'watermelon'],
    ),
    Food(
      id: 'platano',
      name: 'Plátano',
      category: FoodCategory.carb,
      qualityScore: 20,
      portionLabel: '½ plátano (~75g)',
      servingUnit: ServingUnit.unit,
    ),

    // Cereales integrales
    Food(
      id: 'avena',
      name: 'Avena',
      category: FoodCategory.carb,
      qualityScore: 35,
      portionLabel: '½ taza cruda (~40g)',
      servingUnit: ServingUnit.cup,
    ),
    Food(
      id: 'arroz_integral',
      name: 'Arroz integral',
      category: FoodCategory.carb,
      qualityScore: 30,
      portionLabel: '½ taza cocido',
      servingUnit: ServingUnit.cup,
    ),
    Food(
      id: 'pan_integral',
      name: 'Pan integral',
      category: FoodCategory.carb,
      qualityScore: 30,
      nova: NovaGroup.processed,
      portionLabel: '1 rebanada (~30g)',
      servingUnit: ServingUnit.slice,
    ),

    // Almidones densos
    Food(
      id: 'papa',
      name: 'Papa',
      category: FoodCategory.carb,
      qualityScore: 10,
      portionLabel: '1 papa mediana (~150g)',
      servingUnit: ServingUnit.unit,
    ),
    Food(
      id: 'papa_criolla',
      name: 'Papa criolla',
      category: FoodCategory.carb,
      qualityScore: 12,
      portionLabel: '3 papas criollas (~100g)',
      servingUnit: ServingUnit.unit,
    ),
    Food(
      id: 'yuca',
      name: 'Yuca',
      category: FoodCategory.carb,
      qualityScore: 10,
      portionLabel: '½ taza cocida (~75g)',
      servingUnit: ServingUnit.cup,
    ),
    Food(
      id: 'batata_camote',
      name: 'Batata / camote',
      category: FoodCategory.carb,
      qualityScore: 18,
      portionLabel: '½ batata mediana (~100g)',
      servingUnit: ServingUnit.unit,
    ),
    Food(
      id: 'tapioca',
      name: 'Tapioca',
      category: FoodCategory.carb,
      qualityScore: 10,
      portionLabel: '¼ taza seca (~40g)',
      servingUnit: ServingUnit.cup,
    ),
    Food(
      id: 'maiz',
      name: 'Maíz',
      category: FoodCategory.carb,
      qualityScore: 15,
      portionLabel: '½ taza / ½ mazorca',
      servingUnit: ServingUnit.cup,
    ),
    Food(
      id: 'mazorca',
      name: 'Mazorca',
      category: FoodCategory.carb,
      qualityScore: 15,
      portionLabel: '1 mazorca (~200g)',
      servingUnit: ServingUnit.unit,
      searchAliases: ['elote', 'choclo', 'corn'],
    ),

    // Harinas, panes y derivados
    Food(
      id: 'arroz',
      name: 'Arroz',
      category: FoodCategory.carb,
      qualityScore: 10,
      portionLabel: '½ taza cocido',
      servingUnit: ServingUnit.cup,
      searchAliases: ['arroz blanco'],
    ),
    Food(
      id: 'pan',
      name: 'Pan',
      category: FoodCategory.carb,
      qualityScore: 8,
      nova: NovaGroup.processed,
      portionLabel: '1 tajada (~35g)',
      servingUnit: ServingUnit.slice,
    ),
    Food(
      id: 'pasta',
      name: 'Pasta',
      category: FoodCategory.carb,
      qualityScore: 10,
      portionLabel: '½ taza cocida (~80g)',
      servingUnit: ServingUnit.cup,
    ),
    Food(
      id: 'arepa',
      name: 'Arepa',
      category: FoodCategory.carb,
      qualityScore: 15,
      portionLabel: '1 arepa mediana (~80g)',
      servingUnit: ServingUnit.unit,
    ),
    Food(
      id: 'tortilla',
      name: 'Tortilla',
      category: FoodCategory.carb,
      qualityScore: 12,
      portionLabel: '1 tortilla mediana (~45g)',
      servingUnit: ServingUnit.unit,
    ),
    Food(
      id: 'harina',
      name: 'Harina',
      category: FoodCategory.carb,
      qualityScore: 8,
      portionLabel: '¼ taza (~30g)',
      servingUnit: ServingUnit.cup,
    ),
    Food(
      id: 'galletas',
      name: 'Galletas',
      category: FoodCategory.carb,
      qualityScore: 5,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '4-5 galletas (~30g)',
      servingUnit: ServingUnit.handful,
    ),
    Food(
      id: 'cereal',
      name: 'Cereal',
      category: FoodCategory.carb,
      qualityScore: 10,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '1 taza (~30g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['cereal de caja'],
    ),
    Food(
      id: 'granola',
      name: 'Granola',
      category: FoodCategory.carb,
      qualityScore: 20,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '¼ taza (~30g)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['muesli'],
    ),
    Food(
      id: 'pandebono',
      name: 'Pandebono',
      category: FoodCategory.carb,
      qualityScore: 8,
      nova: NovaGroup.processed,
      portionLabel: '1 pandebono (~50g)',
      servingUnit: ServingUnit.unit,
    ),
    Food(
      id: 'bunuelo',
      name: 'Buñuelo',
      category: FoodCategory.carb,
      qualityScore: 8,
      nova: NovaGroup.processed,
      portionLabel: '1 buñuelo mediano (~50g)',
      servingUnit: ServingUnit.unit,
      searchAliases: ['buñuelo'],
    ),
    Food(
      id: 'patacon',
      name: 'Patacón',
      category: FoodCategory.carb,
      qualityScore: 10,
      nova: NovaGroup.processed,
      portionLabel: '2 patacones (~80g)',
      servingUnit: ServingUnit.unit,
      searchAliases: ['tostones', 'patacon pisao'],
    ),
    Food(
      id: 'tostadas',
      name: 'Tostadas',
      category: FoodCategory.carb,
      qualityScore: 10,
      nova: NovaGroup.processed,
      portionLabel: '2 tostadas (~30g)',
      servingUnit: ServingUnit.slice,
      searchAliases: ['toast'],
    ),

    // Azúcares, dulces y postres típicos
    Food(
      id: 'azucar',
      name: 'Azúcar',
      category: FoodCategory.carb,
      qualityScore: 0,
      nova: NovaGroup.culinaryIngredient,
      portionLabel: '1 cucharada (~12g)',
      servingUnit: ServingUnit.tablespoon,
    ),
    Food(
      id: 'panela',
      name: 'Panela',
      category: FoodCategory.carb,
      qualityScore: 0,
      nova: NovaGroup.culinaryIngredient,
      portionLabel: '1 cucharada rallada (~15g)',
      servingUnit: ServingUnit.tablespoon,
      searchAliases: ['piloncillo', 'rapadura'],
    ),
    Food(
      id: 'miel',
      name: 'Miel',
      category: FoodCategory.carb,
      qualityScore: 5,
      nova: NovaGroup.culinaryIngredient,
      portionLabel: '1 cucharada (~21g)',
      servingUnit: ServingUnit.tablespoon,
    ),
    Food(
      id: 'chocolate',
      name: 'Chocolate',
      category: FoodCategory.carb,
      qualityScore: 10,
      nova: NovaGroup.processed,
      portionLabel: '1 cuadro (~28g)',
      servingUnit: ServingUnit.handful,
    ),
    Food(
      id: 'bocadillo',
      name: 'Bocadillo',
      category: FoodCategory.carb,
      qualityScore: 5,
      nova: NovaGroup.processed,
      portionLabel: '1 cuadro (~30g)',
      servingUnit: ServingUnit.unit,
      searchAliases: ['bocadillo de guayaba', 'dulce de guayaba'],
    ),
    Food(
      id: 'arequipe',
      name: 'Arequipe',
      category: FoodCategory.carb,
      qualityScore: 0,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '2 cucharadas (~40g)',
      servingUnit: ServingUnit.tablespoon,
      searchAliases: ['dulce de leche', 'manjar', 'cajeta'],
    ),

    // Saludables transformados
    Food(
      id: 'hummus',
      name: 'Hummus',
      category: FoodCategory.carb,
      qualityScore: 70,
      nova: NovaGroup.processed,
      portionLabel: '2 cucharadas (~30g)',
      servingUnit: ServingUnit.tablespoon,
      searchAliases: ['pure de garbanzo', 'pasta de garbanzo'],
    ),

    // Comidas rápidas / ultraprocesados
    Food(
      id: 'pizza',
      name: 'Pizza',
      category: FoodCategory.carb,
      qualityScore: 5,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '1 porción (1/8 pizza)',
      servingUnit: ServingUnit.slice,
    ),
    Food(
      id: 'hamburguesa',
      name: 'Hamburguesa',
      category: FoodCategory.carb,
      qualityScore: 5,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '1 hamburguesa',
      servingUnit: ServingUnit.unit,
      searchAliases: ['burger'],
    ),
    Food(
      id: 'salchipapa',
      name: 'Salchipapa',
      category: FoodCategory.carb,
      qualityScore: 3,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '1 porción',
      servingUnit: ServingUnit.unit,
      searchAliases: ['salchipapas'],
    ),
    Food(
      id: 'sandwich',
      name: 'Sandwich',
      category: FoodCategory.carb,
      qualityScore: 10,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '1 sándwich',
      servingUnit: ServingUnit.unit,
      searchAliases: ['sandwch', 'emparedado'],
    ),
    Food(
      id: 'empanada',
      name: 'Empanada',
      category: FoodCategory.carb,
      qualityScore: 5,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '1 empanada',
      servingUnit: ServingUnit.unit,
      searchAliases: ['empanadita'],
    ),
    Food(
      id: 'chips',
      name: 'Chips',
      category: FoodCategory.carb,
      qualityScore: 5,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '1 paquete pequeño (~30g)',
      servingUnit: ServingUnit.handful,
      searchAliases: ['papas fritas', 'crisps', 'papas de paquete'],
    ),
    Food(
      id: 'galletas_dulces',
      name: 'Galletas dulces',
      category: FoodCategory.carb,
      qualityScore: 3,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '3-4 galletas (~30g)',
      servingUnit: ServingUnit.handful,
      searchAliases: ['cookies'],
    ),
    Food(
      id: 'galletas_saladas',
      name: 'Galletas saladas',
      category: FoodCategory.carb,
      qualityScore: 8,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '5-6 galletas (~30g)',
      servingUnit: ServingUnit.handful,
      searchAliases: ['crackers'],
    ),

    // Bebidas
    Food(
      id: 'tinto',
      name: 'Tinto',
      category: FoodCategory.carb,
      qualityScore: 100,
      portionLabel: '1 taza (240ml)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['café', 'cafe', 'café negro', 'café solo'],
    ),
    Food(
      id: 'cafe_leche',
      name: 'Café con leche',
      category: FoodCategory.carb,
      qualityScore: 35,
      portionLabel: '1 taza (240ml)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['cafe con leche', 'latte'],
    ),
    Food(
      id: 'capuchino',
      name: 'Capuchino',
      category: FoodCategory.carb,
      qualityScore: 35,
      portionLabel: '1 taza (240ml)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['cappuccino'],
    ),
    Food(
      id: 'chocolate_caliente',
      name: 'Chocolate caliente',
      category: FoodCategory.carb,
      qualityScore: 5,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '1 taza (240ml)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['chocolate con leche', 'choco caliente'],
    ),
    Food(
      id: 'jugo_leche',
      name: 'Jugo en leche',
      category: FoodCategory.carb,
      qualityScore: 10,
      portionLabel: '1 vaso (240ml)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['batido', 'licuado con leche'],
    ),
    Food(
      id: 'jugo_agua',
      name: 'Jugo en agua',
      category: FoodCategory.carb,
      qualityScore: 15,
      portionLabel: '1 vaso (240ml)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['jugo natural', 'licuado con agua'],
    ),
    Food(
      id: 'agua_de_panela',
      name: 'Agua de panela',
      category: FoodCategory.carb,
      qualityScore: 5,
      nova: NovaGroup.culinaryIngredient,
      portionLabel: '1 vaso (240ml)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['agua panela', 'guarapo de panela'],
    ),
    Food(
      id: 'limonada',
      name: 'Limonada',
      category: FoodCategory.carb,
      qualityScore: 10,
      portionLabel: '1 vaso (240ml)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['limonada de panela', 'lemonade'],
    ),
    Food(
      id: 'gaseosa',
      name: 'Gaseosa',
      category: FoodCategory.carb,
      qualityScore: 0,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '1 lata (355ml)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['refresco', 'soda', 'bebida gaseosa'],
    ),
    Food(
      id: 'cocacola',
      name: 'Coca-Cola',
      category: FoodCategory.carb,
      qualityScore: 0,
      nova: NovaGroup.ultraProcessed,
      portionLabel: '1 lata (355ml)',
      servingUnit: ServingUnit.cup,
      searchAliases: ['coca', 'cola'],
    ),
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
    final normalizedQuery = Food._normalize(query);
    final matches = all.where((f) => f.matchesQuery(query)).toList();
    matches.sort((a, b) {
      final byScore = b.qualityScore.compareTo(a.qualityScore);
      if (byScore != 0) return byScore;
      // SPEC-251: entre alimentos con el mismo score, prioriza la
      // coincidencia más específica (nombre exacto > nombre empieza-con
      // > alias exacto > alias empieza-con > substring) antes de caer
      // al orden alfabético.
      final bySpecificity = a
          .matchSpecificity(normalizedQuery)
          .compareTo(b.matchSpecificity(normalizedQuery));
      if (bySpecificity != 0) return bySpecificity;
      return a.name.compareTo(b.name);
    });
    return matches.take(limit).toList(growable: false);
  }
}
