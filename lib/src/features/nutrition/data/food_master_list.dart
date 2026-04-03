import 'package:cloud_firestore/cloud_firestore.dart';

import '../domain/entities/food_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MASTER FOOD DATABASE — Professional Nutrition Dataset
// Metamorfosis Real Protocol — Sarcopenia + Metabolic Health Focus
// ─────────────────────────────────────────────────────────────────────────────
//
// All values normalized to 100g serving for mathematical consistency
// IMR Score: 1-10 (1=Inflammatory Alert, 10=Optimal Metabolic Resilience)
// Dataset Authority: Peer-reviewed nutrition science + local food profiles
//
// Categories:
// • Proteína 🐟 / 🥩 / 🍗 (Sarcopenia reversal)
// • Grasas 🥑 / 🫒 (Metabolic fuel + hormone support)
// • Vegetales 🥬 / 🥦 (Glycemic control + micronutrients)
// • Carbohidratos 🍚 / 🌽 / 🍞 (Strategic post-workout carbs)
// • ⚠️ Inflamatorio (Alert foods to avoid)

class FoodMasterList {
  /// Complete professional dataset with 35+ entries
  /// All values per 100g serving
  static final List<FoodModel> foods = [
    // ═════════════════════════════════════════════════════════════════════════
    // FASTING BREAK / RUPTURA — Optimized insulin recovery meals
    // ═════════════════════════════════════════════════════════════════════════

    /// Huevos Revueltos con Aguacate — Pro-Metabolic Fasting Break
    FoodModel(
      id: 'huevos-revueltos-aguacate',
      name: 'Huevos Revueltos con Aguacate',
      category: 'Ruptura 🍳',
      searchTags: [
        'ruptura suave',
        'grasas saludables',
        'low gi',
        'prediabetes',
        'fs_001'
      ],
      protein: 18.0,
      fat: 28.0,
      netCarbs: 6.0,
      calories: 370.0,
      imrScore: 10.0,
      tip:
          'Combinación perfecta de colina, grasas monoinsaturadas y proteína biodisponible. '
          'Evita picos de insulina post-ayuno y protege la masa muscular.',
      impact: 'insulina',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    // ═════════════════════════════════════════════════════════════════════════
    // PROTEINS — Sarcopenia Reversal Focus (Leucine-rich, high bioavailability)
    // ═════════════════════════════════════════════════════════════════════════

    /// Sardinas Atlánticas — Omega-3 powerhouse + mineral density
    FoodModel(
      id: 'sardinas-atlanticas',
      name: 'Sardinas (Atlánticas)',
      category: 'Proteína 🐟',
      searchTags: ['sardina', 'pez', 'omega-3', 'calcio', 'vitamina-d'],
      protein: 22.0,
      fat: 12.0,
      netCarbs: 0.0,
      calories: 208.0,
      imrScore: 10.0,
      tip: 'Alta en Omega-3 y Calcio; antiinflamatorio sistémico. '
          'Excelente para permeabilidad intestinal y función cerebral.',
      impact: 'sarcopenia',
      level: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Pechuga de Pollo — Reference protein (complete amino acid profile)
    FoodModel(
      id: 'pechuga-pollo',
      name: 'Pechuga de Pollo',
      category: 'Proteína 🥩',
      searchTags: ['pollo', 'pechuga', 'proteína-magra', 'biodisponibilidad'],
      protein: 31.0,
      fat: 3.6,
      netCarbs: 0.0,
      calories: 165.0,
      imrScore: 10.0,
      tip: 'Proteína de referencia con máxima biodisponibilidad. '
          'Alto en leucina (~2.7g por 100g) para síntesis proteica muscular.',
      impact: 'sarcopenia',
      level: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Pata de Res (Colágeno) — Joint + gut barrier restoration
    FoodModel(
      id: 'pata-de-res',
      name: 'Pata de Res (Colágeno)',
      category: 'Proteína 🥩',
      searchTags: ['res', 'pata', 'colágeno', 'glicina', 'permeabilidad'],
      protein: 18.0,
      fat: 5.0,
      netCarbs: 0.5,
      calories: 125.0,
      imrScore: 9.0,
      tip: 'Colágeno tipo I y II puro. Restaura salud articular, '
          'permeabilidad intestinal y elasticidad de piel. Glicina neuromoduladora.',
      impact: 'sarcopenia',
      level: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Huevo Entero — Leucine + choline for muscle + brain
    FoodModel(
      id: 'huevo-entero',
      name: 'Huevo Entero',
      category: 'Proteína 🥩',
      searchTags: ['huevo', 'colina', 'luteína', 'zeaxantina', 'leucina'],
      protein: 13.0,
      fat: 11.0,
      netCarbs: 1.1,
      calories: 155.0,
      imrScore: 10.0,
      tip: 'Proteína de referencia PDCAAS 1.0. Contiene colina (682mg) '
          'para salud cerebral, memoria y síntesis de acetilcolina.',
      impact: 'sarcopenia',
      level: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Trucha Arcoíris (Local) — Andean altitude-adapted protein
    FoodModel(
      id: 'trucha-arcoiris-local',
      name: 'Trucha Arcoíris (Local)',
      category: 'Proteína 🐟',
      searchTags: ['trucha', 'andina', 'omega-3', 'selenio', 'local'],
      protein: 21.0,
      fat: 6.0,
      netCarbs: 0.0,
      calories: 141.0,
      imrScore: 9.0,
      tip: 'Proteína de origen andino con excelente perfil de aminoácidos. '
          'Selenio y Omega-3 para función tiroidea y antioxidación.',
      impact: 'sarcopenia',
      level: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Carne de Res Magra — Iron heme + zinc + B12 trinity
    FoodModel(
      id: 'carne-res-magra',
      name: 'Carne de Res Magra',
      category: 'Proteína 🥩',
      searchTags: ['res', 'carne', 'hierro-hemo', 'zinc', 'vitamina-b12'],
      protein: 26.0,
      fat: 7.0,
      netCarbs: 0.0,
      calories: 171.0,
      imrScore: 9.0,
      tip:
          'Rica en Hierro Hemo (biodisponibilidad 15-35%), Zinc y Vitamina B12. '
          'Creatina natural para cognición y energía muscular.',
      impact: 'sarcopenia',
      level: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Hígado de Res — Nature\'s multivitamin
    FoodModel(
      id: 'higado-res',
      name: 'Hígado de Res',
      category: 'Proteína 🥩',
      searchTags: [
        'hígado',
        'multivitamina',
        'vitamina-a',
        'folatos',
        'colina'
      ],
      protein: 20.0,
      fat: 4.0,
      netCarbs: 4.0,
      calories: 135.0,
      imrScore: 10.0,
      tip: 'El multivitamínico de la naturaleza. Vitamina A retinol puro '
          '(12000 IU), folatos (240mcg), y colina (355mg). Densidad de micronutrientes incomparable.',
      impact: 'sarcopenia',
      level: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Muslo de Pollo — Glicina-rich collagen source
    FoodModel(
      id: 'muslo-pollo',
      name: 'Muslo de Pollo',
      category: 'Proteína 🍗',
      searchTags: [
        'pollo',
        'muslo',
        'glicina',
        'colágeno',
        'proteína-completa'
      ],
      protein: 23.0,
      fat: 12.0,
      netCarbs: 0.0,
      calories: 209.0,
      imrScore: 8.0,
      tip: 'Proteína con mayor contenido de glicina (~2g/100g) que la pechuga. '
          'Colágeno endógeno para síntesis de cartílago y absorción intestinal.',
      impact: 'sarcopenia',
      level: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Atún Enlatado en Agua — Convenient taurine + omega-3
    FoodModel(
      id: 'atun-enlatado-agua',
      name: 'Atún Enlatado en Agua',
      category: 'Proteína 🐟',
      searchTags: ['atún', 'enlatado', 'taurina', 'omega-3', 'conveniente'],
      protein: 29.0,
      fat: 0.7,
      netCarbs: 0.0,
      calories: 132.0,
      imrScore: 9.0,
      tip: 'Taurina pura (338mg) para función cardíaca y ocular. '
          'Proteína de fácil acceso; mantener en despensa para emergencias metabólicas.',
      impact: 'sarcopenia',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Bacalao (Fresco o Congelado) — Selenio + niacina powerhouse
    FoodModel(
      id: 'bacalao-fresco',
      name: 'Bacalao (Fresco o Congelado)',
      category: 'Proteína 🐟',
      searchTags: ['bacalao', 'selenio', 'niacina', 'blanco', 'bajo-grasa'],
      protein: 24.0,
      fat: 0.8,
      netCarbs: 0.0,
      calories: 104.0,
      imrScore: 9.0,
      tip: 'Selenio ultra-concentrado (44mcg) para función tiroidea. '
          'Niacina (2.1mg) para metabolismo energético y reparación de ADN.',
      impact: 'sarcopenia',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // FATS & METABOLIC FUEL — Hormon-supportive lipids
    // ═════════════════════════════════════════════════════════════════════════

    /// Aguacate Hass — Monounsaturated fat + insulin sensitivity
    FoodModel(
      id: 'aguacate-hass',
      name: 'Aguacate Hass',
      category: 'Grasas 🥑',
      searchTags: [
        'aguacate',
        'monoinsaturada',
        'potasio',
        'luteína',
        'sensibilidad-insulina'
      ],
      protein: 2.7,
      fat: 15.0,
      netCarbs: 2.0,
      calories: 160.0,
      imrScore: 10.0,
      tip:
          'Grasas monoinsaturadas (10g) que mejoran la sensibilidad a la insulina. '
          'Potasio (485mg) para regulación electrolítica y presión arterial.',
      impact: 'energía',
      level: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Aceite de Oliva EV — Polifenol antioxidant arsenal
    FoodModel(
      id: 'aceite-oliva-ev',
      name: 'Aceite de Oliva EV',
      category: 'Grasas 🫒',
      searchTags: [
        'oliva',
        'extravirgen',
        'polifenoles',
        'oleocantal',
        'antioxidante'
      ],
      protein: 0.0,
      fat: 92.0,
      netCarbs: 0.0,
      calories: 820.0,
      imrScore: 10.0,
      tip:
          'Polifenoles potentes (oleocantal, oleuropeína) que reducen el estrés oxidativo. '
          'EVOO ralentiza envejecimiento vascular y neuronal; dosis: 1-2 cucharadas/día.',
      impact: 'inflamación',
      level: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Nueces — Magnesio + ALA omega-3 plant-based
    FoodModel(
      id: 'nueces',
      name: 'Nueces',
      category: 'Grasas 🥜',
      searchTags: [
        'nuez',
        'magnesio',
        'ala-omega-3',
        'polifenoles',
        'saciedad'
      ],
      protein: 9.0,
      fat: 66.0,
      netCarbs: 7.0,
      calories: 654.0,
      imrScore: 8.0,
      tip: 'Magnesio (158mg) para relajación muscular y sueño profundo. '
          'ALA omega-3 (2.5g) para salud cardiovascular. Porción: 30g (7 nueces).',
      impact: 'energía',
      level: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Almendras — Vitamina E + fibra prebiotic
    FoodModel(
      id: 'almendras',
      name: 'Almendras',
      category: 'Grasas 🥜',
      searchTags: [
        'almendra',
        'vitamina-e',
        'fibra',
        'prebiótica',
        'polifenoles'
      ],
      protein: 21.0,
      fat: 50.0,
      netCarbs: 6.0,
      calories: 579.0,
      imrScore: 8.0,
      tip: 'Vitamina E (25mg) para protección de membranas lipídicas. '
          'Fibra prebióptica (3.5g) que alimenta Bifidobacterias. Porción: 23 almendras.',
      impact: 'energía',
      level: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Chontaduro (Local) — Andean low-GI energy + carotenoids
    FoodModel(
      id: 'chontaduro-local',
      name: 'Chontaduro (Local)',
      category: 'Grasas 🥑',
      searchTags: ['chontaduro', 'andino', 'bajo-gi', 'betacaroteno', 'local'],
      protein: 2.5,
      fat: 8.0,
      netCarbs: 9.0,
      calories: 120.0,
      imrScore: 9.0,
      tip: 'Energía andina de bajo índice glucémico. Alto en carotenos '
          '(β-caroteno 1470mcg) que se convierten en Vitamina A. Sostiende energía 4 horas.',
      impact: 'energía',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Aceite de Coco MCT — Ketone body precursor (moderate use)
    FoodModel(
      id: 'aceite-coco-mct',
      name: 'Aceite de Coco MCT',
      category: 'Grasas 🥥',
      searchTags: ['coco', 'mct', 'cetonas', 'energía-rápida', 'mct-c8-c10'],
      protein: 0.0,
      fat: 92.0,
      netCarbs: 0.0,
      calories: 820.0,
      imrScore: 7.0,
      tip:
          'MCT C8 y C10 son precursores de cuerpos cetónicos (energía cerebral). '
          'Uso moderado: 1 cucharadita en café matutino para ayuno cognitivo. ⚠️ Exceso causa diarrea.',
      impact: 'energía',
      level: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // VEGETABLES — Glycemic Control + Micronutrient Density
    // ═════════════════════════════════════════════════════════════════════════

    /// Zucchini — Pasta replacement + low oxalate
    FoodModel(
      id: 'zucchini',
      name: 'Zucchini',
      category: 'Vegetales 🥬',
      searchTags: [
        'zucchini',
        'calabacín',
        'bajo-oxalato',
        'pasta-replacement',
        'silicio'
      ],
      protein: 1.2,
      fat: 0.3,
      netCarbs: 3.1,
      calories: 21.0,
      imrScore: 10.0,
      tip: 'Bajo en oxalatos (ideal para nefrolítasis). '
          'Sustituto de pasta: espiralizados para salsa. Silicio para colágeno óseo.',
      impact: 'energía',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Brócoli — Sulforaphane hepatic phase II detox
    FoodModel(
      id: 'brocoli',
      name: 'Brócoli',
      category: 'Vegetales 🥦',
      searchTags: [
        'brócoli',
        'sulforafano',
        'fase-ii',
        'glutatión',
        'desintoxicación'
      ],
      protein: 2.8,
      fat: 0.4,
      netCarbs: 7.0,
      calories: 55.0,
      imrScore: 10.0,
      tip:
          'Contiene sulforafano que activa enzimas de desintoxicación hepática fase II. '
          'Consumir crudo o al vapor <5min para maximizar actividad. Glutatión endógeno.',
      impact: 'desintoxicación',
      level: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Espárragos — Prebiótica + inulin + folatos
    FoodModel(
      id: 'esparragos',
      name: 'Espárragos',
      category: 'Vegetales 🥦',
      searchTags: [
        'espárrago',
        'inulina',
        'prebiótica',
        'folatos',
        'glutatión'
      ],
      protein: 2.2,
      fat: 0.1,
      netCarbs: 3.9,
      calories: 27.0,
      imrScore: 9.0,
      tip:
          'Prebiótico natural con inulina que alimenta Akkermansia muciniphila. '
          'Alto en folatos (91mcg). Glutatión para conjugación de xenobióticos.',
      impact: 'microbiota',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Pimentón Rojo — 3x más Vitamina C que naranja
    FoodModel(
      id: 'pimenton-rojo',
      name: 'Pimentón Rojo',
      category: 'Vegetales 🌶',
      searchTags: [
        'pimentón',
        'vitamina-c',
        'colágeno',
        'betacaroteno',
        'licopeno'
      ],
      protein: 1.0,
      fat: 0.3,
      netCarbs: 6.0,
      calories: 37.0,
      imrScore: 9.0,
      tip: '3 veces más Vitamina C que la naranja (80mg). '
          'Cofactor esencial para síntesis de colágeno tipo I. Licopeno para peroxidación lipídica.',
      impact: 'colágeno',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Coliflor — Choline + indole-3-carbinol hormone metabolism
    FoodModel(
      id: 'coliflor',
      name: 'Coliflor',
      category: 'Vegetales 🥬',
      searchTags: ['coliflor', 'colina', 'i3c', 'estrógeno', 'detox'],
      protein: 1.9,
      fat: 0.3,
      netCarbs: 4.7,
      calories: 34.0,
      imrScore: 9.0,
      tip:
          'Indole-3-carbinol favorece metabolismo de estrógeno hacia vías desintoxicantes. '
          'Colina (65mg) para síntesis de acetilcolina. Arroz de coliflor reduce carga glucémica.',
      impact: 'hormonal',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Espinaca — Oxalato concentrado pero magnesio + K2
    FoodModel(
      id: 'espinaca-cruda',
      name: 'Espinaca (Cruda)',
      category: 'Vegetales 🥬',
      searchTags: ['espinaca', 'magnesio', 'vitamina-k2', 'luteína', 'oxalato'],
      protein: 2.7,
      fat: 0.4,
      netCarbs: 3.6,
      calories: 23.0,
      imrScore: 8.0,
      tip:
          'Magnesio (79mg) para relajación muscular. Vitamina K2 para mineralización ósea. '
          '⚠️ Alto en oxalatos; evitar si cálculos renales. Mejor cocida.',
      impact: 'ósea',
      level: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Kale — Calcio + vitamina K1 anti-coagulant
    FoodModel(
      id: 'kale',
      name: 'Kale',
      category: 'Vegetales 🥬',
      searchTags: ['kale', 'calcio', 'vitamina-k1', 'coagulación', 'brassica'],
      protein: 3.3,
      fat: 0.6,
      netCarbs: 6.2,
      calories: 49.0,
      imrScore: 9.0,
      tip:
          'Calcio bio-disponible (150mg) rival del lácteo. Vitamina K1 (145mcg) para cascada coagulante. '
          'Glucosinolatos para desintoxicación. Hervir reduce oxalatos.',
      impact: 'ósea',
      level: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Rúcula — Glucosinolato anti-cancer compound
    FoodModel(
      id: 'rucula',
      name: 'Rúcula',
      category: 'Vegetales 🥬',
      searchTags: [
        'rúcula',
        'glucosinolato',
        'anti-cancerígeno',
        'sulforafano',
        'picante'
      ],
      protein: 2.6,
      fat: 0.7,
      netCarbs: 3.7,
      calories: 25.0,
      imrScore: 9.0,
      tip: 'Glucosinolatos (erucina) con potencial anti-cancerígeno. '
          'Sabor picante activa TRPV1 para saciedad. Perfecto en ensaladas crudas.',
      impact: 'desintoxicación',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Champiñones — Ergotioneína antioxidante + vitamina D
    FoodModel(
      id: 'champinones',
      name: 'Champiñones',
      category: 'Vegetales 🍄',
      searchTags: [
        'champiñón',
        'ergotioneína',
        'vitamina-d',
        'lentinano',
        'inmunidad'
      ],
      protein: 3.3,
      fat: 0.3,
      netCarbs: 3.3,
      calories: 22.0,
      imrScore: 8.0,
      tip: 'Ergotioneína (único antioxidante que transporta proteasa SLC22A4). '
          'Vitamina D2 (0.8mcg). Lentinano para inmunidad innata NK (natural killer).',
      impact: 'inmunidad',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // STRATEGIC CARBOHYDRATES — Post-Workout Recovery + Resistant Starch
    // ═════════════════════════════════════════════════════════════════════════

    /// Arroz Integral — Fibra + glycemic buffer
    FoodModel(
      id: 'arroz-integral',
      name: 'Arroz Integral',
      category: 'Carbohidratos 🍚',
      searchTags: [
        'arroz',
        'integral',
        'fibra',
        'magnesio',
        'almidón-resistente'
      ],
      protein: 2.6,
      fat: 1.0,
      netCarbs: 23.0,
      calories: 115.0,
      imrScore: 6.0,
      tip: 'Carga de glucógeno con fibra (1.8g) para evitar picos bruscos. '
          'Magnesio (43mg). Cocinado y enfriado = almidón resistente prebióptico.',
      impact: 'energía',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Papa Pastusa (Ensalada Fría) — Almidón resistente para microbiota
    FoodModel(
      id: 'papa-pastusa-fria',
      name: 'Papa Pastusa (Ensalada Fría)',
      category: 'Carbohidratos 🥔',
      searchTags: ['papa', 'pastusa', 'almidón-resistente', 'potasio', 'fría'],
      protein: 2.0,
      fat: 0.1,
      netCarbs: 17.0,
      calories: 80.0,
      imrScore: 7.0,
      tip:
          'Almidón resistente que alimenta Akkermansia muciniphila cuando se consume fría. '
          'Potasio (358mg) para balance electrolítico post-ayuno. ⚠️ Caliente = glucosa rápida.',
      impact: 'microbiota',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Arepa de Maíz (Tela) — Limpia + sin gluten
    FoodModel(
      id: 'arepa-maiz-tela',
      name: 'Arepa de Maíz (Tela)',
      category: 'Carbohidratos 🌽',
      searchTags: ['arepa', 'maíz', 'tela', 'sin-gluten', 'local'],
      protein: 2.5,
      fat: 1.0,
      netCarbs: 25.0,
      calories: 130.0,
      imrScore: 5.0,
      tip: 'Opción local limpia de gluten y grasas vegetales. '
          'Harina de maíz puro (masa harina). Post-workout: 1-2 arepas con proteína.',
      impact: 'energía',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Batata Púrpura — Antocianinas + beta-caroteno
    FoodModel(
      id: 'batata-purpura',
      name: 'Batata Púrpura',
      category: 'Carbohidratos 🍠',
      searchTags: [
        'batata',
        'púrpura',
        'antocianina',
        'betacaroteno',
        'antoxidante'
      ],
      protein: 1.6,
      fat: 0.1,
      netCarbs: 20.0,
      calories: 86.0,
      imrScore: 7.0,
      tip: 'Antocianinas (C3G) para función cognitiva y memoria visual. '
          'Beta-caroteno (8500 IU) para vision nocturna. Mejor cocida al vapor.',
      impact: 'energía',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Plátano Verde — Almidón resistente crudo vs. maduro
    FoodModel(
      id: 'platano-verde',
      name: 'Plátano Verde',
      category: 'Carbohidratos 🍌',
      searchTags: ['plátano', 'verde', 'almidón-resistente', 'pectin', 'local'],
      protein: 1.3,
      fat: 0.3,
      netCarbs: 27.0,
      calories: 122.0,
      imrScore: 6.0,
      tip:
          '⚠️ Verde = almidón resistente (prebióptico). Amarillo/maduro = glucosa rápida. '
          'Para microbiota: consumir verde cocido. Para energía: plátano maduro post-entreno.',
      impact: 'energía',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // INFLAMMATORY ALERT — Foods to Minimize (IMR 1-3)
    // ═════════════════════════════════════════════════════════════════════════

    /// Empanada — Oxidized oils + refined carbs
    FoodModel(
      id: 'empanada-alerta',
      name: 'Empanada / Pan Tajado / Galletas',
      category: '⚠️ Inflamatorio',
      searchTags: [
        'empanada',
        'pan',
        'galleta',
        'inflamatorio',
        'aceites-oxidados'
      ],
      protein: 5.0,
      fat: 15.0,
      netCarbs: 40.0,
      calories: 320.0,
      imrScore: 2.0,
      tip:
          '⚠️ ALTAMENTE INFLAMATORIO. Aceites vegetales oxidados (linoleico 18:2), '
          'harinas refinadas (IG 75+), HFCS. Triggerea estrés oxidativo sistémico.',
      impact: 'inflamación',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Pan Blanco — Amilosa rápida + falta de fibra
    FoodModel(
      id: 'pan-blanco',
      name: 'Pan Blanco',
      category: '⚠️ Inflamatorio',
      searchTags: ['pan', 'blanco', 'refinado', 'amilosa', 'pico-glucémico'],
      protein: 7.0,
      fat: 1.0,
      netCarbs: 41.0,
      calories: 205.0,
      imrScore: 2.0,
      tip:
          '⚠️ Pico glucémico agudo (IG 100). Sin fibra. Gluten industrial = zonulina. '
          'Causa inflamación intestinal, dysbiosis y resistencia a la insulina.',
      impact: 'inflamación',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Yogur Sabor (Comercial) — HFCS + probióticos destruidos
    FoodModel(
      id: 'yogur-sabor-comercial',
      name: 'Yogur con Sabor (Comercial)',
      category: '⚠️ Inflamatorio',
      searchTags: ['yogur', 'sabor', 'hfcs', 'azúcar', 'falso-probiótico'],
      protein: 3.0,
      fat: 0.5,
      netCarbs: 18.0,
      calories: 100.0,
      imrScore: 2.0,
      tip: '⚠️ 18g azúcar + HFCS. Pasteurización = probióticos destruidos. '
          'Edulcorantes artificiales disruptan microbiota. Solo yogur natural sin azúcar.',
      impact: 'inflamación',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Refrescos Azucarados — Obesógeno + fructosa lipogénica
    FoodModel(
      id: 'refresco-azucarado',
      name: 'Refrescos Azucarados',
      category: '⚠️ Inflamatorio',
      searchTags: ['refresco', 'soda', 'azúcar', 'fructosa', 'obesógeno'],
      protein: 0.0,
      fat: 0.0,
      netCarbs: 11.0,
      calories: 45.0,
      imrScore: 1.0,
      tip:
          '⚠️ MÁXIMA ALERTA. Fructosa (hepatotoxina) genera hígado graso (NAFLD). '
          'Obesógeno de clase 1 (IARC). Ácido fosfórico = desmineralización ósea.',
      impact: 'inflamación',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Cereales Azucarados — Marketing infantil + pesticidas
    FoodModel(
      id: 'cereal-azucarado',
      name: 'Cereales Azucarados',
      category: '⚠️ Inflamatorio',
      searchTags: ['cereal', 'azucarado', 'gluten', 'pesticida', 'glicación'],
      protein: 2.0,
      fat: 1.0,
      netCarbs: 40.0,
      calories: 180.0,
      imrScore: 2.0,
      tip:
          '⚠️ Glicación acelerada (AGEs). Trigo convencional = pesticidas (glifosato). '
          'Lectinas que rompen barrera intestinal. Evitar completamente.',
      impact: 'inflamación',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    // ═════════════════════════════════════════════════════════════════════════
    // STRATEGIC ADDITIONS — High-Value Density Foods
    // ═════════════════════════════════════════════════════════════════════════

    /// Jengibre Fresco — Gingerol anti-inflamatorio
    FoodModel(
      id: 'jengibre-fresco',
      name: 'Jengibre Fresco',
      category: 'Vegetales 🥬',
      searchTags: [
        'jengibre',
        'gingerol',
        'antiinflamatorio',
        'digestión',
        'termogénico'
      ],
      protein: 1.8,
      fat: 0.8,
      netCarbs: 17.0,
      calories: 80.0,
      imrScore: 9.0,
      tip: '6-gingerol inhibe IL-6 y TNF-α. 1-2 cucharadas en té matutino. '
          'Termogénico: acelera metabolismo 5-10%. Protector gástrico.',
      impact: 'inflamación',
      level: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Cúrcuma + Pimienta Negra — Curcumina + piperina (20x absorción)
    FoodModel(
      id: 'curcuma-pimienta',
      name: 'Cúrcuma + Pimienta Negra',
      category: 'Especias 🌿',
      searchTags: ['cúrcuma', 'curcumina', 'pimienta', 'piperina', 'sinergia'],
      protein: 8.0,
      fat: 3.0,
      netCarbs: 65.0,
      calories: 354.0,
      imrScore: 10.0,
      tip:
          'Curcumina + piperina = sinergia 20x. NF-κB inhibidor. Anti-cancerígeno. '
          'Dosis: 1/2 cucharadita con grasa (biodisponibilidad). BioPerine para absorción.',
      impact: 'inflamación',
      level: 3,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Té Verde Matcha — EGCG anti-aging + L-teanina
    FoodModel(
      id: 'te-verde-matcha',
      name: 'Té Verde Matcha',
      category: 'Bebidas 🍵',
      searchTags: ['té', 'matcha', 'egcg', 'l-teanina', 'antioxidante'],
      protein: 3.5,
      fat: 1.0,
      netCarbs: 3.0,
      calories: 35.0,
      imrScore: 9.0,
      tip: 'EGCG (138mg/taza) inhibe telomerasa en células cancerosas. '
          'L-teanina para calma cognitiva. 3 tazas/día reduce mortalidad cardiovascular 31%.',
      impact: 'envejecimiento',
      level: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Chocolate Negro 85%+ — Epicatequina neuroprotectora
    FoodModel(
      id: 'chocolate-negro-85',
      name: 'Chocolate Negro 85%+',
      category: 'Indulgencia 🍫',
      searchTags: [
        'chocolate',
        'negro',
        'epicatequina',
        'polifenol',
        'neuroprotector'
      ],
      protein: 7.0,
      fat: 52.0,
      netCarbs: 13.0,
      calories: 604.0,
      imrScore: 8.0,
      tip: 'Epicatequina (12.7mg) mejora flujo sanguíneo cerebral. '
          'Teobromina para vasodilatación. Porción: 30g (1 onza). Synergist con té verde.',
      impact: 'envejecimiento',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Miso Fermentado — Probiótico + koji
    FoodModel(
      id: 'miso-fermentado',
      name: 'Miso Fermentado',
      category: 'Fermentados 🍶',
      searchTags: ['miso', 'fermentado', 'koji', 'probiótico', 'soya-viva'],
      protein: 12.0,
      fat: 5.0,
      netCarbs: 9.0,
      calories: 137.0,
      imrScore: 8.0,
      tip: 'Koji (Aspergillus oryzae) fermenta proteínas a aminoácidos. '
          'Probióticos vivos (no pasteurizados). Cucharadita en agua caliente pre-desayuno.',
      impact: 'microbiota',
      level: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Kombucha Casera (Sin Azúcar Añadida) — Acetobacter aceti + SCFAs
    FoodModel(
      id: 'kombucha-casera',
      name: 'Kombucha Casera (Sin Azúcar)',
      category: 'Fermentados 🍶',
      searchTags: ['kombucha', 'casera', 'acetobacter', 'scfa', 'probiótico'],
      protein: 0.1,
      fat: 0.0,
      netCarbs: 1.0,
      calories: 8.0,
      imrScore: 7.0,
      tip: 'Acetobacter aceti produce ácidos acéticos (acético + láctico). '
          'Casera fermentada 7-14 días. ⚠️ Comprada = azúcar industrial + pasteurizada.',
      impact: 'sarcopenia',
      level: 2,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),

    /// Levadura Nutricional — B12 + folatos biosintetizados
    FoodModel(
      id: 'levadura-nutricional',
      name: 'Levadura Nutricional',
      category: 'Suplementos 🍲',
      searchTags: ['levadura', 'nutricional', 'b12', 'folatos', 'niacina'],
      protein: 8.0,
      fat: 1.0,
      netCarbs: 4.0,
      calories: 80.0,
      imrScore: 8.0,
      tip:
          'B12 (3mcg/cucharada) + folatos (400mcg). Saccharomyces cerevisiae inactivada. '
          'Sprinkle on salads. Veganos + déficit metilación: 1-2 cucharadas/día.',
      impact: 'energía',
      level: 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  // ─────────────────────────────────────────────────────────────────────────
  // DEEP CLEAN + 4-NODE INJECTION PROTOCOL
  // ─────────────────────────────────────────────────────────────────────────

  static const String _collection = 'master_food_db';

  /// 🧹 PURGE PHASE — Deletes EVERY document in master_food_db via WriteBatch.
  /// Returns the number of documents deleted.
  static Future<int> clearMasterDatabase() async {
    final firestore = FirebaseFirestore.instance;
    print(
        '[SEED] 🧹 PURGE PHASE — Deleting ALL documents from $_collection...');

    int totalDeleted = 0;
    QuerySnapshot<Map<String, dynamic>> snapshot;

    // Paginate deletes in batches of 400 (safe under 500 op limit)
    do {
      snapshot = await firestore.collection(_collection).limit(400).get();

      if (snapshot.docs.isEmpty) break;

      final batch = firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      totalDeleted += snapshot.docs.length;
      print(
          '[SEED] 🗑️  Batch deleted: ${snapshot.docs.length} docs (total: $totalDeleted)');
    } while (snapshot.docs.length == 400);

    print(
        '[SEED] 🧹 DB Cleared — $totalDeleted documents removed. Collection is now empty.');
    return totalDeleted;
  }

  /// 🚀 FULL DEEP CLEAN — Purge + Re-seed with 4-node schema.
  /// This is the primary entry point for database maintenance.
  static Future<void> deepCleanAndSeed() async {
    print('[SEED] ════════════════════════════════════════════════');
    print('[SEED] 🚀 DEEP CLEAN PROTOCOL — master_food_db');
    print('[SEED] Total foods in dataset: ${foods.length}');
    print('[SEED] ════════════════════════════════════════════════');

    // Phase 1: Purge
    await clearMasterDatabase();

    // Phase 2: Inject
    await _injectAllFoods();

    print('[SEED] ════════════════════════════════════════════════');
    print(
        '[SEED] ✅ DEEP CLEAN COMPLETE — ${foods.length} foods in 4-node schema');
    print('[SEED] ════════════════════════════════════════════════');
  }

  /// Legacy entry point — now calls deepCleanAndSeed for full reset.
  static Future<void> seedMasterDatabase() => deepCleanAndSeed();

  /// 🚀 INJECTION PHASE — Writes all foods in normalized 4-node format.
  static Future<void> _injectAllFoods() async {
    final firestore = FirebaseFirestore.instance;
    print('[SEED] 🚀 INJECTION PHASE — Writing ${foods.length} foods...');

    const batchSize = 100;

    for (int i = 0; i < foods.length; i += batchSize) {
      final end = (i + batchSize < foods.length) ? i + batchSize : foods.length;
      final slice = foods.sublist(i, end);

      final batch = firestore.batch();

      for (final food in slice) {
        final docRef = firestore.collection(_collection).doc(food.id);

        // ── Build the exact 4-node nested map ──────────────────────
        final nestedData = <String, dynamic>{
          'metadata': {
            'name': food.name,
            'category': food.displayCategory, // Plain text, no emojis
            'imrScore': food.imrScore.toInt(),
            'tags': food.searchTags,
          },
          'content': {
            'tip': food.tip,
            'impact': food.impact,
            'level': food.level,
          },
          'app_integration': {
            'macros': {
              'p': food.protein,
              'g': food.fat,
              'c': food.netCarbs,
              'kcal': food.calories,
            },
            'food_id': food.id,
          },
          'quiz': {
            'last_reviewed': null,
          },
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };

        batch.set(docRef, nestedData);
        print(
            '[SEED] 🚀 Injecting [${food.name}] into 4-node schema (IMR: ${food.imrScore.toInt()})');
      }

      await batch.commit();
      print(
          '[SEED] ✅ Batch committed: ${slice.length} documents ($i → ${end - 1})');
    }
  }
}
