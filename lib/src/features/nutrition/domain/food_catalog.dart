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
  /// Ej. "Aguacate" lleva ["palta"] para que usuarios de Argentina/Uruguay
  /// que buscan "palta" encuentren el item.
  final List<String> searchAliases;

  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.qualityScore,
    this.nova = NovaGroup.unprocessed,
    this.searchAliases = const [],
  });

  /// Conveniencia: ¿el alimento es de alta calidad (score ≥ 70)?
  bool get isHighQuality => qualityScore >= 70;

  /// SPEC-138: ¿el alimento es ultraprocesado (NOVA 4)?
  ///
  /// Único predicado usado en `PlateBuilder.upfSharePercent` y en
  /// `weeklyUpfShareProvider`. Cualquier cambio en NOVA 3 vs 4 de un
  /// alimento concreto afecta el % UPF semanal del usuario.
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
    // SPEC-138: jamón cocido típico cae en NOVA 3 (curado con sal/nitritos
    // pero sin reformulación industrial extensa). Monteiro 2019 §Tabla 1.
    Food(id: 'jamon', name: 'Jamón', category: FoodCategory.protein, qualityScore: 80, nova: NovaGroup.processed),

    // Lácteos proteicos — depende
    // SPEC-138: queso campesino y suero costeño son NOVA 3 (fermentación
    // tradicional). Yogur griego comercial es NOVA 3. Leche pasteurizada
    // es NOVA 1 (Monteiro 2019 explícito: "leche pasteurizada").
    Food(id: 'queso_campesino', name: 'Queso campesino', category: FoodCategory.protein, qualityScore: 85, nova: NovaGroup.processed),
    Food(id: 'yogur_griego', name: 'Yogur griego', category: FoodCategory.protein, qualityScore: 80, nova: NovaGroup.processed, searchAliases: ['yogurt griego']),
    Food(id: 'suero_costeno', name: 'Suero costeño', category: FoodCategory.protein, qualityScore: 75, nova: NovaGroup.processed),
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

    // SPEC-137 E.6: caldos — proteína animal diluida; score moderado-alto
    // (75) por dilución respecto a la pieza entera.
    Food(id: 'caldo_pollo', name: 'Caldo de pollo', category: FoodCategory.protein, qualityScore: 75, searchAliases: ['consome', 'consome de pollo', 'sopa de pollo']),
    Food(id: 'caldo_costilla', name: 'Caldo de costilla', category: FoodCategory.protein, qualityScore: 75, searchAliases: ['caldo de res', 'caldo de hueso', 'sancocho']),
    Food(id: 'caldo_pescado', name: 'Caldo de pescado', category: FoodCategory.protein, qualityScore: 75, searchAliases: ['sopa de pescado']),
  ];

  // ── GRASAS (22) ───────────────────────────────────────────────────────
  static const List<Food> fats = [
    // Grasas vegetales naturales — top
    Food(id: 'aguacate', name: 'Aguacate', category: FoodCategory.fat, qualityScore: 100, searchAliases: ['palta']),
    Food(id: 'aceite_oliva', name: 'Aceite de oliva', category: FoodCategory.fat, qualityScore: 100),
    Food(id: 'aceite_coco', name: 'Aceite de coco', category: FoodCategory.fat, qualityScore: 95),
    // SPEC-138: aceites vegetales refinados (soya, girasol, palma) entran
    // como NOVA 3 — fraccionados y desodorizados pero sin aditivos
    // cosméticos. Monteiro 2019 §Tabla 1.
    Food(id: 'aceite_vegetal', name: 'Aceite vegetal', category: FoodCategory.fat, qualityScore: 60, nova: NovaGroup.processed),

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
    // SPEC-138: mantequilla = NOVA 2 (ingrediente culinario derivado de
    // leche por batido). Quesos amarillos comerciales típicamente NOVA 3
    // (cuajado + maduración industrial). Queso crema NOVA 3 (estabilizado).
    // Leche entera pasteurizada = NOVA 1.
    Food(id: 'mantequilla', name: 'Mantequilla', category: FoodCategory.fat, qualityScore: 80, nova: NovaGroup.culinaryIngredient),
    Food(id: 'queso_amarillo', name: 'Queso amarillo', category: FoodCategory.fat, qualityScore: 75, nova: NovaGroup.processed),
    Food(id: 'queso_crema', name: 'Queso crema', category: FoodCategory.fat, qualityScore: 75, nova: NovaGroup.processed),
    Food(id: 'crema_de_leche', name: 'Crema de leche', category: FoodCategory.fat, qualityScore: 70, nova: NovaGroup.processed),
    Food(id: 'leche_entera', name: 'Leche entera', category: FoodCategory.fat, qualityScore: 50),

    // Carnes grasas / embutidos
    // SPEC-138: tocino, chicharrón y chorizo artesanales = NOVA 3
    // (curado/ahumado tradicional). Salchicha comercial = NOVA 4
    // (carne reconstituida + emulsionantes + colorantes + nitritos
    // estabilizadores). Monteiro 2019 cita "sausages" explícitamente
    // en lista UPF.
    Food(id: 'tocino', name: 'Tocino', category: FoodCategory.fat, qualityScore: 75, nova: NovaGroup.processed),
    Food(id: 'chicharron', name: 'Chicharrón', category: FoodCategory.fat, qualityScore: 70, nova: NovaGroup.processed),
    Food(id: 'chorizo', name: 'Chorizo', category: FoodCategory.fat, qualityScore: 60, nova: NovaGroup.processed),
    Food(id: 'salchicha', name: 'Salchicha', category: FoodCategory.fat, qualityScore: 50, nova: NovaGroup.ultraProcessed),

    // Procesadas - score bajo
    // SPEC-138: mayonesa industrial = NOVA 4 (emulsionantes EDTA,
    // estabilizadores, conservantes — formulación industrial extensa).
    // Manteca animal = NOVA 2 (grasa renderizada, ingrediente culinario).
    // Margarina = NOVA 4 prototípico (Monteiro 2019 §Tabla 1).
    Food(id: 'mayonesa', name: 'Mayonesa', category: FoodCategory.fat, qualityScore: 50, nova: NovaGroup.ultraProcessed),
    Food(id: 'manteca', name: 'Manteca', category: FoodCategory.fat, qualityScore: 55, nova: NovaGroup.culinaryIngredient),
    Food(id: 'margarina', name: 'Margarina', category: FoodCategory.fat, qualityScore: 30, nova: NovaGroup.ultraProcessed),

    // SPEC-137 E.6: semillas con omega-3 y fibra — alta calidad metabólica.
    Food(id: 'semillas_chia', name: 'Semillas de chía', category: FoodCategory.fat, qualityScore: 95, searchAliases: ['chia']),
    Food(id: 'linaza', name: 'Linaza', category: FoodCategory.fat, qualityScore: 95, searchAliases: ['lino', 'semillas de lino']),
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
    // SPEC-138: avena y arroz integral en grano = NOVA 1. Pan integral
    // comercial típico = NOVA 3 (fermentación + horneado industrial sin
    // emulsionantes ni dextrosa; cuando los lleva pasaría a NOVA 4 pero
    // sin etiqueta no podemos discriminar — clasificamos conservador).
    Food(id: 'avena', name: 'Avena', category: FoodCategory.carb, qualityScore: 35),
    Food(id: 'arroz_integral', name: 'Arroz integral', category: FoodCategory.carb, qualityScore: 30),
    Food(id: 'pan_integral', name: 'Pan integral', category: FoodCategory.carb, qualityScore: 30, nova: NovaGroup.processed),

    // Almidones densos
    Food(id: 'papa', name: 'Papa', category: FoodCategory.carb, qualityScore: 10),
    Food(id: 'papa_criolla', name: 'Papa criolla', category: FoodCategory.carb, qualityScore: 12),
    Food(id: 'yuca', name: 'Yuca', category: FoodCategory.carb, qualityScore: 10),
    Food(id: 'batata_camote', name: 'Batata / camote', category: FoodCategory.carb, qualityScore: 18),
    Food(id: 'tapioca', name: 'Tapioca', category: FoodCategory.carb, qualityScore: 10),
    Food(id: 'maiz', name: 'Maíz', category: FoodCategory.carb, qualityScore: 15),

    // Harinas y panes blancos
    // SPEC-138: arroz blanco = NOVA 1 (descascarillado mecánico). Harina
    // pura = NOVA 1 (molienda). Pan blanco comercial = NOVA 3 (sin
    // emulsionantes). Arepa y tortilla artesanal = NOVA 1. Galletas y
    // cereal de caja = NOVA 4 (Monteiro 2019 §Tabla 1 explícito).
    Food(id: 'arroz', name: 'Arroz', category: FoodCategory.carb, qualityScore: 10, searchAliases: ['arroz blanco']),
    Food(id: 'pan', name: 'Pan', category: FoodCategory.carb, qualityScore: 8, nova: NovaGroup.processed),
    Food(id: 'pasta', name: 'Pasta', category: FoodCategory.carb, qualityScore: 10),
    Food(id: 'arepa', name: 'Arepa', category: FoodCategory.carb, qualityScore: 15),
    Food(id: 'tortilla', name: 'Tortilla', category: FoodCategory.carb, qualityScore: 12),
    Food(id: 'harina', name: 'Harina', category: FoodCategory.carb, qualityScore: 8),
    Food(id: 'galletas', name: 'Galletas', category: FoodCategory.carb, qualityScore: 5, nova: NovaGroup.ultraProcessed),
    Food(id: 'cereal', name: 'Cereal', category: FoodCategory.carb, qualityScore: 10, nova: NovaGroup.ultraProcessed, searchAliases: ['cereal de caja']),

    // Azúcares puros
    // SPEC-138: azúcar refinada, panela tradicional y miel cruda = NOVA 2
    // (ingredientes culinarios). Chocolate amargo en barra = NOVA 3;
    // chocolate de leche industrial = NOVA 4, pero el catálogo no
    // discrimina — conservador NOVA 3.
    Food(id: 'azucar', name: 'Azúcar', category: FoodCategory.carb, qualityScore: 0, nova: NovaGroup.culinaryIngredient),
    Food(id: 'panela', name: 'Panela', category: FoodCategory.carb, qualityScore: 0, nova: NovaGroup.culinaryIngredient, searchAliases: ['piloncillo', 'rapadura']),
    Food(id: 'miel', name: 'Miel', category: FoodCategory.carb, qualityScore: 5, nova: NovaGroup.culinaryIngredient),
    Food(id: 'chocolate', name: 'Chocolate', category: FoodCategory.carb, qualityScore: 10, nova: NovaGroup.processed),

    // SPEC-137 E.6: comidas rápidas (harinas refinadas + ultraprocesados).
    // SPEC-138: pizza, hamburguesa, salchipapa, sandwich industrial,
    // empanada congelada = NOVA 4. Monteiro 2019 lista "pizzas, burgers,
    // hot-dogs, packaged snacks" como ejemplos canónicos de UPF.
    // Si el usuario hace pizza casera con ingredientes del catálogo,
    // registra los componentes (queso + tomate + pan) y el UPF% cae
    // naturalmente. Decisión: clasificación estricta (Carlos 2026-06-05).
    Food(id: 'pizza', name: 'Pizza', category: FoodCategory.carb, qualityScore: 5, nova: NovaGroup.ultraProcessed),
    Food(id: 'hamburguesa', name: 'Hamburguesa', category: FoodCategory.carb, qualityScore: 5, nova: NovaGroup.ultraProcessed, searchAliases: ['burger']),
    Food(id: 'salchipapa', name: 'Salchipapa', category: FoodCategory.carb, qualityScore: 3, nova: NovaGroup.ultraProcessed, searchAliases: ['salchipapas']),
    Food(id: 'sandwich', name: 'Sandwich', category: FoodCategory.carb, qualityScore: 10, nova: NovaGroup.ultraProcessed, searchAliases: ['sándwich', 'emparedado']),
    Food(id: 'empanada', name: 'Empanada', category: FoodCategory.carb, qualityScore: 5, nova: NovaGroup.ultraProcessed, searchAliases: ['empanadita']),

    // Galletas — variantes específicas además de "Galletas" genérico.
    // SPEC-138: galletas dulces = NOVA 4 (canon Monteiro). Saladas tipo
    // crackers también industriales con grasas hidrogenadas = NOVA 4.
    Food(id: 'galletas_dulces', name: 'Galletas dulces', category: FoodCategory.carb, qualityScore: 3, nova: NovaGroup.ultraProcessed, searchAliases: ['cookies']),
    Food(id: 'galletas_saladas', name: 'Galletas saladas', category: FoodCategory.carb, qualityScore: 8, nova: NovaGroup.ultraProcessed, searchAliases: ['crackers']),

    // Bebidas — neutras o E según composición.
    // SPEC-138: café solo = NOVA 1 (infusión). Café con leche y capuchino
    // preparados en casa = NOVA 1. Chocolate caliente comercial = NOVA 4
    // (mezclas en polvo con maltodextrina + colorantes). Jugos en agua
    // caseros = NOVA 1; jugos comerciales en caja serían NOVA 4 pero el
    // ítem se asume casero. Gaseosa y Coca-Cola = NOVA 4 canon.
    Food(id: 'tinto', name: 'Tinto', category: FoodCategory.carb, qualityScore: 100, searchAliases: ['café', 'cafe', 'café negro', 'café solo']),
    Food(id: 'cafe_leche', name: 'Café con leche', category: FoodCategory.carb, qualityScore: 35, searchAliases: ['cafe con leche', 'latte']),
    Food(id: 'capuchino', name: 'Capuchino', category: FoodCategory.carb, qualityScore: 35, searchAliases: ['cappuccino']),
    Food(id: 'chocolate_caliente', name: 'Chocolate caliente', category: FoodCategory.carb, qualityScore: 5, nova: NovaGroup.ultraProcessed, searchAliases: ['chocolate con leche', 'choco caliente']),
    Food(id: 'jugo_leche', name: 'Jugo en leche', category: FoodCategory.carb, qualityScore: 10, searchAliases: ['batido', 'licuado con leche']),
    Food(id: 'jugo_agua', name: 'Jugo en agua', category: FoodCategory.carb, qualityScore: 15, searchAliases: ['jugo natural', 'licuado con agua']),
    Food(id: 'gaseosa', name: 'Gaseosa', category: FoodCategory.carb, qualityScore: 0, nova: NovaGroup.ultraProcessed, searchAliases: ['refresco', 'soda', 'bebida gaseosa']),
    Food(id: 'cocacola', name: 'Coca-Cola', category: FoodCategory.carb, qualityScore: 0, nova: NovaGroup.ultraProcessed, searchAliases: ['coca', 'cola']),
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
