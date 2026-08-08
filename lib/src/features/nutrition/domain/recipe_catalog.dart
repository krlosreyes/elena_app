// SPEC-278 — Recetario ORIGINAL de Elena.
//
// Recetas propias, escritas para esta app, alineadas al método metabólico
// (proteína magra + MUCHOS vegetales + grasa buena; sin azúcar, sin harinas
// refinadas, sin ultraprocesados). NO son copia de ninguna fuente: las
// obras de Jaramillo (El Milagro Metabólico) y Suárez (El Poder del
// Metabolismo) se usaron solo como REFERENCIA de principios, no de texto.
//
// Cada receta referencia ids reales de `FoodCatalog` en sus ingredientes
// centrales (`foodId`), para que el motor de cruce (recipe_match_service)
// pueda recomendar recetas según lo que el usuario YA come (su intake) y
// respetar sus restricciones/dieta. Ingredientes de uso común en LatAm.
//
// Dart PURO (sin Flutter/Riverpod/Firestore). Ver specs/SPEC-278-*.md.

import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart'
    show MealSlot, DietType;

/// Un ingrediente de la receta. `text` es lo que se muestra (con cantidad);
/// `foodId` referencia `FoodCatalog.all` cuando es un alimento central
/// (sirve para el cruce con el repertorio del usuario y la lista de mercado).
class RecipeIngredient {
  final String text;
  final String? foodId;

  const RecipeIngredient(this.text, {this.foodId});
}

/// Una receta del recetario.
class Recipe {
  final String id;
  final String name;

  /// En qué comidas encaja (desayuno/almuerzo/cena; `other` = snack).
  final List<MealSlot> slots;

  final int servings;
  final int prepMinutes;
  final List<RecipeIngredient> ingredients;
  final List<String> steps;

  /// Dietas con las que la receta es compatible.
  final List<DietType> diets;

  const Recipe({
    required this.id,
    required this.name,
    required this.slots,
    required this.servings,
    required this.prepMinutes,
    required this.ingredients,
    required this.steps,
    required this.diets,
  });

  /// Ids de catálogo de los ingredientes centrales (para el cruce).
  Set<String> get foodIds => {
        for (final i in ingredients)
          if (i.foodId != null && i.foodId!.isNotEmpty) i.foodId!
      };

  bool fitsSlot(MealSlot slot) => slots.contains(slot);
  bool fitsDiet(DietType diet) => diets.contains(diet);
}

/// Atajos de dieta.
const _omni = DietType.omnivore;
const _pesc = DietType.pescatarian;
const _vege = DietType.vegetarian;
const _vegan = DietType.vegan;

// Conjuntos de compatibilidad frecuentes.
const List<DietType> _all = [_omni, _pesc, _vege, _vegan];
const List<DietType> _veggie = [_omni, _pesc, _vege]; // con huevo/lácteo
const List<DietType> _fish = [_omni, _pesc]; // pescado/mariscos
const List<DietType> _meat = [_omni]; // carne/pollo/pavo/cerdo
const List<DietType> _veganOk = [_omni, _pesc, _vege, _vegan];

/// Recetario curado. Original, ingredientes fáciles, método metabólico.
class RecipeCatalog {
  const RecipeCatalog._();

  static const List<Recipe> all = [
    // ─── Desayunos ──────────────────────────────────────────────────────────
    Recipe(
      id: 'huevos_pericos_espinaca',
      name: 'Huevos pericos con espinaca y aguacate',
      slots: [MealSlot.breakfast],
      servings: 1,
      prepMinutes: 10,
      diets: _veggie,
      ingredients: [
        RecipeIngredient('2 huevos', foodId: 'huevo'),
        RecipeIngredient('1 taza de espinaca', foodId: 'espinaca'),
        RecipeIngredient('½ aguacate', foodId: 'aguacate'),
        RecipeIngredient('1 tomate picado', foodId: 'tomate'),
        RecipeIngredient('¼ de cebolla', foodId: 'cebolla'),
        RecipeIngredient('1 cucharadita de aceite de oliva', foodId: 'aceite_oliva'),
        RecipeIngredient('Sal y pimienta al gusto'),
      ],
      steps: [
        'Sofríe la cebolla y el tomate en el aceite 2 minutos.',
        'Agrega la espinaca hasta que baje de volumen.',
        'Añade los huevos y revuelve a fuego bajo hasta cuajar.',
        'Sirve con el aguacate en tajadas al lado.',
      ],
    ),
    Recipe(
      id: 'omelette_claras_brocoli',
      name: 'Omelette de claras con brócoli y queso campesino',
      slots: [MealSlot.breakfast],
      servings: 1,
      prepMinutes: 12,
      diets: _veggie,
      ingredients: [
        RecipeIngredient('4 claras de huevo', foodId: 'clara_huevo'),
        RecipeIngredient('1 taza de brócoli picado', foodId: 'brocoli'),
        RecipeIngredient('30 g de queso campesino', foodId: 'queso_campesino'),
        RecipeIngredient('1 cucharadita de aceite de oliva', foodId: 'aceite_oliva'),
        RecipeIngredient('Sal y pimienta'),
      ],
      steps: [
        'Cocina el brócoli al vapor 3 minutos.',
        'Bate las claras con sal y viértelas en el sartén con aceite.',
        'Reparte el brócoli y el queso, dobla el omelette y cocina 2 minutos.',
      ],
    ),
    Recipe(
      id: 'yogur_griego_fresas_nueces',
      name: 'Yogur griego con fresas, nueces y chía',
      slots: [MealSlot.breakfast, MealSlot.other],
      servings: 1,
      prepMinutes: 5,
      diets: _veggie,
      ingredients: [
        RecipeIngredient('1 taza de yogur griego sin azúcar', foodId: 'yogur_griego'),
        RecipeIngredient('½ taza de fresas', foodId: 'fresa'),
        RecipeIngredient('1 cucharada de nueces', foodId: 'nueces'),
        RecipeIngredient('1 cucharadita de semillas de chía', foodId: 'semillas_chia'),
      ],
      steps: [
        'Sirve el yogur en un tazón.',
        'Agrega las fresas en trozos, las nueces y la chía por encima.',
      ],
    ),
    Recipe(
      id: 'aguacate_relleno_atun',
      name: 'Aguacate relleno de atún',
      slots: [MealSlot.breakfast, MealSlot.lunch],
      servings: 1,
      prepMinutes: 8,
      diets: _fish,
      ingredients: [
        RecipeIngredient('1 aguacate', foodId: 'aguacate'),
        RecipeIngredient('1 lata de atún en agua', foodId: 'atun'),
        RecipeIngredient('Jugo de ½ limón', foodId: 'limon'),
        RecipeIngredient('Cilantro fresco', foodId: 'cilantro'),
        RecipeIngredient('Sal y pimienta'),
      ],
      steps: [
        'Parte el aguacate y retira un poco de pulpa para agrandar el hueco.',
        'Mezcla el atún con el limón, el cilantro, sal y pimienta.',
        'Rellena las mitades de aguacate con la mezcla.',
      ],
    ),
    Recipe(
      id: 'pudin_chia_coco',
      name: 'Pudín de chía con leche de coco y arándanos',
      slots: [MealSlot.breakfast, MealSlot.other],
      servings: 1,
      prepMinutes: 5,
      diets: _veganOk,
      ingredients: [
        RecipeIngredient('3 cucharadas de semillas de chía', foodId: 'semillas_chia'),
        RecipeIngredient('1 taza de leche de coco sin azúcar', foodId: 'leche_coco'),
        RecipeIngredient('½ taza de arándanos', foodId: 'arandanos'),
        RecipeIngredient('Estevia al gusto (opcional)'),
      ],
      steps: [
        'Mezcla la chía con la leche de coco y la estevia.',
        'Refrigera al menos 2 horas (o de un día para otro) hasta que gelifique.',
        'Sirve con los arándanos encima.',
      ],
    ),
    Recipe(
      id: 'revuelto_tofu_champinones',
      name: 'Revuelto de tofu con champiñones y pimiento',
      slots: [MealSlot.breakfast, MealSlot.lunch],
      servings: 1,
      prepMinutes: 12,
      diets: _veganOk,
      ingredients: [
        RecipeIngredient('150 g de tofu firme', foodId: 'tofu'),
        RecipeIngredient('1 taza de champiñones', foodId: 'champinones'),
        RecipeIngredient('½ pimiento', foodId: 'pimiento'),
        RecipeIngredient('¼ de cebolla', foodId: 'cebolla'),
        RecipeIngredient('1 cucharadita de aceite de oliva', foodId: 'aceite_oliva'),
        RecipeIngredient('Cúrcuma, sal y pimienta'),
      ],
      steps: [
        'Desmenuza el tofu con un tenedor.',
        'Sofríe cebolla, pimiento y champiñones en el aceite 4 minutos.',
        'Agrega el tofu y la cúrcuma; cocina 4 minutos revolviendo.',
      ],
    ),
    // ─── Almuerzos ──────────────────────────────────────────────────────────
    Recipe(
      id: 'pollo_plancha_ensalada',
      name: 'Pollo a la plancha con ensalada de aguacate',
      slots: [MealSlot.lunch, MealSlot.dinner],
      servings: 1,
      prepMinutes: 20,
      diets: _meat,
      ingredients: [
        RecipeIngredient('1 pechuga de pollo', foodId: 'pollo'),
        RecipeIngredient('2 tazas de lechuga', foodId: 'lechuga'),
        RecipeIngredient('1 tomate', foodId: 'tomate'),
        RecipeIngredient('½ aguacate', foodId: 'aguacate'),
        RecipeIngredient('1 cucharada de aceite de oliva', foodId: 'aceite_oliva'),
        RecipeIngredient('Jugo de limón', foodId: 'limon'),
      ],
      steps: [
        'Salpimienta el pollo y ásalo a la plancha 6-7 minutos por lado.',
        'Arma la ensalada con lechuga, tomate y aguacate.',
        'Aliña con aceite de oliva y limón; sirve el pollo al lado.',
      ],
    ),
    Recipe(
      id: 'salmon_brocoli_vapor',
      name: 'Salmón con brócoli al vapor y ajonjolí',
      slots: [MealSlot.lunch, MealSlot.dinner],
      servings: 1,
      prepMinutes: 20,
      diets: _fish,
      ingredients: [
        RecipeIngredient('1 filete de salmón', foodId: 'salmon'),
        RecipeIngredient('2 tazas de brócoli', foodId: 'brocoli'),
        RecipeIngredient('1 cucharada de aceite de oliva', foodId: 'aceite_oliva'),
        RecipeIngredient('1 cucharadita de ajonjolí', foodId: 'ajonjoli'),
        RecipeIngredient('Ajo, sal y pimienta', foodId: 'ajo'),
      ],
      steps: [
        'Cocina el brócoli al vapor 4-5 minutos.',
        'Sella el salmón en el aceite con ajo, 3-4 minutos por lado.',
        'Sirve el salmón sobre el brócoli y espolvorea ajonjolí.',
      ],
    ),
    Recipe(
      id: 'lentejas_guisadas_verduras',
      name: 'Lentejas guisadas con verduras',
      slots: [MealSlot.lunch, MealSlot.dinner],
      servings: 2,
      prepMinutes: 35,
      diets: _veganOk,
      ingredients: [
        RecipeIngredient('1 taza de lentejas', foodId: 'lentejas'),
        RecipeIngredient('1 zanahoria', foodId: 'zanahoria'),
        RecipeIngredient('½ cebolla', foodId: 'cebolla'),
        RecipeIngredient('½ pimiento', foodId: 'pimiento'),
        RecipeIngredient('1 tomate', foodId: 'tomate'),
        RecipeIngredient('1 cucharada de aceite de oliva', foodId: 'aceite_oliva'),
      ],
      steps: [
        'Sofríe cebolla, pimiento, zanahoria y tomate en el aceite.',
        'Agrega las lentejas y agua que las cubra.',
        'Cocina a fuego medio 25-30 minutos hasta que ablanden.',
      ],
    ),
    Recipe(
      id: 'pavo_kale_almendras',
      name: 'Pechuga de pavo con ensalada de kale y almendras',
      slots: [MealSlot.lunch, MealSlot.dinner],
      servings: 1,
      prepMinutes: 18,
      diets: _meat,
      ingredients: [
        RecipeIngredient('1 filete de pechuga de pavo', foodId: 'pechuga_pavo'),
        RecipeIngredient('2 tazas de kale', foodId: 'kale'),
        RecipeIngredient('1 cucharada de almendras', foodId: 'almendras'),
        RecipeIngredient('Jugo de limón', foodId: 'limon'),
        RecipeIngredient('1 cucharada de aceite de oliva', foodId: 'aceite_oliva'),
      ],
      steps: [
        'Masajea el kale con aceite y limón para suavizarlo.',
        'Asa el pavo a la plancha 5-6 minutos por lado.',
        'Sirve el pavo sobre el kale y agrega las almendras.',
      ],
    ),
    Recipe(
      id: 'garbanzos_espinaca',
      name: 'Ensalada tibia de garbanzos y espinaca',
      slots: [MealSlot.lunch],
      servings: 2,
      prepMinutes: 15,
      diets: _veganOk,
      ingredients: [
        RecipeIngredient('1 taza de garbanzos cocidos', foodId: 'garbanzos'),
        RecipeIngredient('2 tazas de espinaca', foodId: 'espinaca'),
        RecipeIngredient('1 tomate', foodId: 'tomate'),
        RecipeIngredient('1 cucharada de aceite de oliva', foodId: 'aceite_oliva'),
        RecipeIngredient('Ajo y limón', foodId: 'ajo'),
      ],
      steps: [
        'Saltea el ajo en el aceite y agrega los garbanzos 3 minutos.',
        'Añade la espinaca y el tomate hasta que la espinaca baje.',
        'Termina con limón, sal y pimienta.',
      ],
    ),
    Recipe(
      id: 'arroz_coliflor_pollo',
      name: '"Arroz" de coliflor con pollo y vegetales',
      slots: [MealSlot.lunch, MealSlot.dinner],
      servings: 2,
      prepMinutes: 25,
      diets: _meat,
      ingredients: [
        RecipeIngredient('1 coliflor rallada', foodId: 'coliflor'),
        RecipeIngredient('1 pechuga de pollo en cubos', foodId: 'pollo'),
        RecipeIngredient('1 zanahoria', foodId: 'zanahoria'),
        RecipeIngredient('½ pimiento', foodId: 'pimiento'),
        RecipeIngredient('¼ de cebolla', foodId: 'cebolla'),
        RecipeIngredient('1 cucharada de aceite de oliva', foodId: 'aceite_oliva'),
      ],
      steps: [
        'Ralla la coliflor hasta que parezca arroz.',
        'Saltea el pollo en el aceite hasta dorar; reserva.',
        'Sofríe las verduras, agrega la coliflor 5 minutos y devuelve el pollo.',
      ],
    ),
    Recipe(
      id: 'quinua_bowl_aguacate',
      name: 'Bowl de quinua con aguacate y vegetales',
      slots: [MealSlot.lunch],
      servings: 1,
      prepMinutes: 20,
      diets: _veganOk,
      ingredients: [
        RecipeIngredient('½ taza de quinua cocida', foodId: 'quinua'),
        RecipeIngredient('½ aguacate', foodId: 'aguacate'),
        RecipeIngredient('1 tomate', foodId: 'tomate'),
        RecipeIngredient('½ pepino', foodId: 'pepino'),
        RecipeIngredient('1 cucharada de aceite de oliva', foodId: 'aceite_oliva'),
        RecipeIngredient('Limón y cilantro', foodId: 'limon'),
      ],
      steps: [
        'Cocina la quinua y déjala templar.',
        'Pica el tomate, el pepino y el aguacate.',
        'Mezcla todo con aceite, limón y cilantro.',
      ],
    ),
    // ─── Cenas ──────────────────────────────────────────────────────────────
    Recipe(
      id: 'salmon_pure_coliflor',
      name: 'Salmón sobre puré de coliflor',
      slots: [MealSlot.dinner],
      servings: 1,
      prepMinutes: 25,
      diets: _fish,
      ingredients: [
        RecipeIngredient('1 filete de salmón', foodId: 'salmon'),
        RecipeIngredient('2 tazas de coliflor', foodId: 'coliflor'),
        RecipeIngredient('1 cucharada de ghee', foodId: 'ghee'),
        RecipeIngredient('Ajo, sal y pimienta', foodId: 'ajo'),
      ],
      steps: [
        'Hierve la coliflor 10 minutos y tritúrala con el ghee y ajo.',
        'Sella el salmón 3-4 minutos por lado.',
        'Sirve el salmón sobre el puré.',
      ],
    ),
    Recipe(
      id: 'fideos_calabacin_champinones',
      name: 'Fideos de calabacín con champiñones',
      slots: [MealSlot.dinner],
      servings: 1,
      prepMinutes: 15,
      diets: _veganOk,
      ingredients: [
        RecipeIngredient('2 calabacines en tiras', foodId: 'calabacin'),
        RecipeIngredient('1 taza de champiñones', foodId: 'champinones'),
        RecipeIngredient('1 diente de ajo', foodId: 'ajo'),
        RecipeIngredient('1 cucharada de aceite de oliva', foodId: 'aceite_oliva'),
        RecipeIngredient('Albahaca, sal y pimienta'),
      ],
      steps: [
        'Haz tiras el calabacín con un pelador (fideos).',
        'Saltea ajo y champiñones en el aceite 4 minutos.',
        'Agrega el calabacín 2 minutos (que quede al dente) y la albahaca.',
      ],
    ),
    Recipe(
      id: 'sopa_pollo_verduras',
      name: 'Sopa de pollo con verduras',
      slots: [MealSlot.dinner, MealSlot.lunch],
      servings: 2,
      prepMinutes: 30,
      diets: _meat,
      ingredients: [
        RecipeIngredient('2 tazas de caldo de pollo', foodId: 'caldo_pollo'),
        RecipeIngredient('1 pechuga de pollo desmechada', foodId: 'pollo'),
        RecipeIngredient('1 zanahoria', foodId: 'zanahoria'),
        RecipeIngredient('2 tallos de apio', foodId: 'apio'),
        RecipeIngredient('¼ de cebolla', foodId: 'cebolla'),
      ],
      steps: [
        'Lleva el caldo a ebullición con la cebolla y el apio.',
        'Agrega la zanahoria en cubos y cocina 10 minutos.',
        'Añade el pollo desmechado y calienta 5 minutos.',
      ],
    ),
    Recipe(
      id: 'berenjena_rellena_carne',
      name: 'Berenjena rellena de carne y vegetales',
      slots: [MealSlot.dinner],
      servings: 2,
      prepMinutes: 35,
      diets: _meat,
      ingredients: [
        RecipeIngredient('2 berenjenas', foodId: 'berenjena'),
        RecipeIngredient('200 g de carne molida magra', foodId: 'carne_res'),
        RecipeIngredient('1 tomate', foodId: 'tomate'),
        RecipeIngredient('¼ de cebolla', foodId: 'cebolla'),
        RecipeIngredient('1 cucharada de aceite de oliva', foodId: 'aceite_oliva'),
      ],
      steps: [
        'Parte las berenjenas a lo largo y retira parte de la pulpa.',
        'Sofríe cebolla, tomate y la pulpa; agrega la carne y cocina.',
        'Rellena las berenjenas y hornea 20 minutos a 180 °C.',
      ],
    ),
    Recipe(
      id: 'camaron_aguacate_ensalada',
      name: 'Ensalada tibia de camarón y aguacate',
      slots: [MealSlot.dinner, MealSlot.lunch],
      servings: 1,
      prepMinutes: 15,
      diets: _fish,
      ingredients: [
        RecipeIngredient('150 g de camarón', foodId: 'camaron'),
        RecipeIngredient('1 aguacate', foodId: 'aguacate'),
        RecipeIngredient('2 tazas de lechuga', foodId: 'lechuga'),
        RecipeIngredient('Jugo de limón', foodId: 'limon'),
        RecipeIngredient('1 cucharada de aceite de oliva', foodId: 'aceite_oliva'),
      ],
      steps: [
        'Saltea el camarón en el aceite 2-3 minutos con ajo y sal.',
        'Arma la cama de lechuga con aguacate en tajadas.',
        'Coloca el camarón encima y aliña con limón.',
      ],
    ),
    Recipe(
      id: 'tofu_salteado_brocoli',
      name: 'Tofu salteado con brócoli y ajonjolí',
      slots: [MealSlot.dinner, MealSlot.lunch],
      servings: 1,
      prepMinutes: 15,
      diets: _veganOk,
      ingredients: [
        RecipeIngredient('150 g de tofu firme', foodId: 'tofu'),
        RecipeIngredient('2 tazas de brócoli', foodId: 'brocoli'),
        RecipeIngredient('½ pimiento', foodId: 'pimiento'),
        RecipeIngredient('1 cucharadita de ajonjolí', foodId: 'ajonjoli'),
        RecipeIngredient('1 cucharada de aceite de oliva', foodId: 'aceite_oliva'),
      ],
      steps: [
        'Corta el tofu en cubos y dóralo en el aceite.',
        'Agrega brócoli y pimiento; saltea 5 minutos.',
        'Termina con ajonjolí y sal.',
      ],
    ),
    Recipe(
      id: 'tilapia_espinaca',
      name: 'Tilapia al ajillo con espinaca',
      slots: [MealSlot.dinner, MealSlot.lunch],
      servings: 1,
      prepMinutes: 18,
      diets: _fish,
      ingredients: [
        RecipeIngredient('1 filete de tilapia', foodId: 'tilapia'),
        RecipeIngredient('2 tazas de espinaca', foodId: 'espinaca'),
        RecipeIngredient('2 dientes de ajo', foodId: 'ajo'),
        RecipeIngredient('1 cucharada de aceite de oliva', foodId: 'aceite_oliva'),
        RecipeIngredient('Limón, sal y pimienta', foodId: 'limon'),
      ],
      steps: [
        'Dora el ajo en el aceite y añade la tilapia 3 minutos por lado.',
        'Retira el pescado y saltea la espinaca en el mismo sartén.',
        'Sirve la tilapia sobre la espinaca con limón.',
      ],
    ),
    // ─── Snacks ─────────────────────────────────────────────────────────────
    Recipe(
      id: 'apio_hummus',
      name: 'Palitos de apio con hummus',
      slots: [MealSlot.other],
      servings: 1,
      prepMinutes: 5,
      diets: _veganOk,
      ingredients: [
        RecipeIngredient('3 tallos de apio', foodId: 'apio'),
        RecipeIngredient('3 cucharadas de hummus', foodId: 'hummus'),
      ],
      steps: [
        'Corta el apio en bastones.',
        'Sírvelos con el hummus para untar.',
      ],
    ),
    Recipe(
      id: 'huevos_duros_aguacate',
      name: 'Huevos duros con aguacate',
      slots: [MealSlot.other, MealSlot.breakfast],
      servings: 1,
      prepMinutes: 12,
      diets: _veggie,
      ingredients: [
        RecipeIngredient('2 huevos', foodId: 'huevo'),
        RecipeIngredient('½ aguacate', foodId: 'aguacate'),
        RecipeIngredient('Sal y pimienta'),
      ],
      steps: [
        'Cocina los huevos en agua hirviendo 9 minutos y pélalos.',
        'Sírvelos partidos con el aguacate, sal y pimienta.',
      ],
    ),
    Recipe(
      id: 'frutos_secos_mix',
      name: 'Puñado de almendras y nueces',
      slots: [MealSlot.other],
      servings: 1,
      prepMinutes: 1,
      diets: _veganOk,
      ingredients: [
        RecipeIngredient('1 puñado de almendras', foodId: 'almendras'),
        RecipeIngredient('1 puñado de nueces', foodId: 'nueces'),
      ],
      steps: [
        'Mezcla un puñado pequeño de cada uno y disfruta.',
      ],
    ),
    Recipe(
      id: 'yogur_semillas_calabaza',
      name: 'Yogur griego con semillas de calabaza',
      slots: [MealSlot.other, MealSlot.breakfast],
      servings: 1,
      prepMinutes: 3,
      diets: _veggie,
      ingredients: [
        RecipeIngredient('1 taza de yogur griego sin azúcar', foodId: 'yogur_griego'),
        RecipeIngredient('1 cucharada de semillas de calabaza', foodId: 'semillas_calabaza'),
      ],
      steps: [
        'Sirve el yogur y espolvorea las semillas de calabaza.',
      ],
    ),
  ];

  /// Búsqueda directa por id.
  static Recipe? byId(String id) {
    for (final r in all) {
      if (r.id == id) return r;
    }
    return null;
  }
}
