// SPEC-270 (fase 2) — Builder mutable del intake para la UI de onboarding.
//
// La pantalla de 6 bloques (intake_onboarding_screen.dart) acumula el
// estado del usuario en un `IntakeDraft` y, al terminar, lo convierte a un
// `NutritionIntake` inmutable con `build()`. Extraer esta lógica del widget
// permite testearla sin montar la UI (mismo criterio que separar el score
// del notifier en SPEC-251): el widget solo maneja gestos y pinta; el
// mapeo draft → dominio vive aquí y está cubierto por tests.
//
// Es Dart puro (sin Flutter) a propósito.

import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';

/// Una comida en construcción: slot fijo (desayuno/almuerzo/cena/otro),
/// hora editable y lista mutable de items.
class DraftMeal {
  final MealSlot slot;
  String timeApprox;
  final List<IntakeItem> items;

  DraftMeal(this.slot, {this.timeApprox = '', List<IntakeItem>? items})
      : items = items ?? <IntakeItem>[];

  bool get hasContent => items.any((i) => i.isMeaningful);
}

class IntakeDraft {
  int mealsPerDay;
  final List<DraftMeal> meals;
  final List<IntakeSnack> snacks;

  // Bebidas (Bloque 5)
  ConsumptionFrequency sugary;
  bool coffeeSweetened;
  bool drinksAlcohol;

  // Restricciones (Bloque 6)
  DietType diet;
  final List<String> excludes;
  final List<String> allergies;

  // Contexto (Bloque 6)
  LevelLowMidHigh cookTime;
  LevelLowMidHigh budget;
  bool cooksAtHome;

  IntakeDraft({
    this.mealsPerDay = 3,
    required this.meals,
    List<IntakeSnack>? snacks,
    this.sugary = ConsumptionFrequency.sometimes,
    this.coffeeSweetened = false,
    this.drinksAlcohol = false,
    this.diet = DietType.omnivore,
    List<String>? excludes,
    List<String>? allergies,
    this.cookTime = LevelLowMidHigh.mid,
    this.budget = LevelLowMidHigh.mid,
    this.cooksAtHome = true,
  })  : snacks = snacks ?? <IntakeSnack>[],
        excludes = excludes ?? <String>[],
        allergies = allergies ?? <String>[];

  /// Estado inicial: tres comidas vacías (desayuno / almuerzo / cena) que
  /// el usuario irá llenando. Las horas se prellenan desde afuera (con la
  /// ventana circadiana) si están disponibles.
  factory IntakeDraft.initial({
    String breakfastTime = '',
    String lunchTime = '',
    String dinnerTime = '',
  }) {
    return IntakeDraft(
      meals: [
        DraftMeal(MealSlot.breakfast, timeApprox: breakfastTime),
        DraftMeal(MealSlot.lunch, timeApprox: lunchTime),
        DraftMeal(MealSlot.dinner, timeApprox: dinnerTime),
      ],
    );
  }

  /// Reconstruye el draft desde un intake ya guardado (para editar). Las
  /// comidas conocidas (desayuno/almuerzo/cena) se mapean a sus slots fijos
  /// preservando el orden; cualquier `other` se agrega al final.
  factory IntakeDraft.fromIntake(NutritionIntake i) {
    DraftMeal slotDraft(MealSlot s) {
      final match = i.meals.where((m) => m.slot == s);
      if (match.isEmpty) return DraftMeal(s);
      final m = match.first;
      return DraftMeal(s,
          timeApprox: m.timeApprox, items: List<IntakeItem>.of(m.items));
    }

    final drafts = <DraftMeal>[
      slotDraft(MealSlot.breakfast),
      slotDraft(MealSlot.lunch),
      slotDraft(MealSlot.dinner),
    ];
    for (final m in i.meals.where((m) => m.slot == MealSlot.other)) {
      drafts.add(DraftMeal(MealSlot.other,
          timeApprox: m.timeApprox, items: List<IntakeItem>.of(m.items)));
    }

    return IntakeDraft(
      mealsPerDay: i.mealsPerDay,
      meals: drafts,
      snacks: List<IntakeSnack>.of(i.snacks),
      sugary: i.drinks.sugary,
      coffeeSweetened: i.drinks.coffeeSweetened,
      drinksAlcohol: i.drinks.alcoholRef != null,
      diet: i.restrictions.diet,
      excludes: List<String>.of(i.restrictions.excludes),
      allergies: List<String>.of(i.restrictions.allergies),
      cookTime: i.context.cookTime,
      budget: i.context.budget,
      cooksAtHome: i.context.cooksAtHome,
    );
  }

  /// True si hay al menos una comida con contenido (lo mínimo para que el
  /// motor pueda generar una minuta).
  bool get isComplete => meals.any((m) => m.hasContent);

  /// Convierte el draft a un `NutritionIntake` inmutable. `derived` se deja
  /// por defecto: lo recalcula el notifier desde el UserModel al guardar.
  /// Solo se incluyen comidas con contenido (una comida vacía no aporta).
  NutritionIntake build() {
    final builtMeals = meals
        .where((m) => m.hasContent)
        .map((m) => IntakeMeal(
              slot: m.slot,
              timeApprox: m.timeApprox,
              items: List<IntakeItem>.of(m.items.where((i) => i.isMeaningful)),
            ))
        .toList(growable: false);

    return NutritionIntake(
      updatedAt: DateTime.now(),
      mealsPerDay: mealsPerDay,
      meals: builtMeals,
      snacks: List<IntakeSnack>.of(snacks),
      drinks: DrinksProfile(
        sugary: sugary,
        coffeeSweetened: coffeeSweetened,
        alcoholRef: drinksAlcohol ? 'consumo_consciente' : null,
      ),
      restrictions: IntakeRestrictions(
        diet: diet,
        excludes: List<String>.of(excludes),
        allergies: List<String>.of(allergies),
      ),
      context: IntakeContext(
        cookTime: cookTime,
        budget: budget,
        cooksAtHome: cooksAtHome,
      ),
    );
  }
}
