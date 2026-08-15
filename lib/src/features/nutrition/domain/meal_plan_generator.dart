// SPEC-272 + SPEC-276 — Motor de generación de la Minuta Diaria.
//
// Corazón de la reestructuración: convierte el retrato dietético
// (`NutritionIntake`) en un plan del día (`MealPlan`). 100% DETERMINÍSTICO
// (decisión de Carlos §9): la misma entrada produce la misma minuta, sin
// IA en la decisión. Es Dart PURO (sin Riverpod, Firestore ni Flutter) →
// fácil de testear.
//
// SPEC-276 (rediseño): el motor prescribe UN PLATO COHERENTE por comida,
// armado con el REPERTORIO del usuario para esa comida, NO la unión de
// todo lo que come. Reglas del plato (El Milagro Metabólico, Jaramillo
// cap. 10):
//   1. UNA proteína (porción palma).
//   2. Vegetales al 75% del plato (1–2 puños), preferidos de los que el
//      usuario ya come.
//   3. UNA grasa saludable (pulgar).
//   4. Un carbohidrato/almidón pequeño OPCIONAL, solo si el usuario ya lo
//      come (no se inyecta: el método prioriza vegetales).
// Si al usuario le falta un rol POR COMPLETO (p. ej. no come ningún
// vegetal), el motor sugiere uno y lo marca `newSuggestion` ("Nuevo").
// Además puede proponer UNA "mejora suave" por plato: cambiar el ítem más
// débil del usuario por una versión más sana de su misma categoría,
// marcada `upgrade` ("Mejora"). Snacks: NO se proponen (se retiran
// gradualmente, decisión §9).
//
// Fases (§7.1): en fase 1 solo se marca como mejorable lo peor (NOVA 4 /
// qualityScore < 15); fases mayores endurecen el umbral.

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:elena_app/src/features/nutrition/domain/recipe_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/recipe_match_service.dart';

class MealPlanGenerator {
  const MealPlanGenerator();

  static const RecipeMatchService _recipes = RecipeMatchService();

  /// Salto mínimo de calidad para justificar una mejora suave sugerida.
  static const int _kUpgradeDelta = 15;

  /// Máximo de vegetales distintos en un plato.
  static const int _kMaxVeg = 2;

  /// Cuántas de las mejores recetas se consideran para la variedad diaria
  /// (SPEC-284): entre esas rota el día, sin sacrificar demasiado el encaje.
  static const int _kRecipePool = 3;

  /// Genera la minuta del día a partir del intake + la proteína objetivo
  /// (que el llamador deriva del UserModel vía ProteinTargetService) + la
  /// ventana circadiana + la fase de transición.
  ///
  /// [now] se inyecta para determinismo en tests; si es null, `generatedAt`
  /// queda null (el repositorio no depende de él para el id).
  MealPlan generate({
    required NutritionIntake intake,
    required double targetProteinG,
    required String dateId,
    String windowFirst = '',
    String windowLast = '',
    int phase = 1,
    DateTime? now,
    Set<String> avoidFoodIds = const {},
  }) {
    final banned = _bannedSet(intake.restrictions.allBanned);

    // Comidas fuente. SPEC-289: si el usuario usó el modelo nuevo (repertorio
    // plano, sin asignar a comidas), generamos desayuno/almuerzo/cena desde
    // ese repertorio; si es un intake viejo con `meals`, se respeta.
    final sourceMeals = _sourceMeals(intake);

    final weights = _proteinWeights(sourceMeals.map((m) => m.slot).toList());
    final weightSum = weights.fold<double>(0, (a, b) => a + b);

    // SPEC-291/297: alimentos que el usuario realmente come, para (a) marcar
    // honestamente qué es suyo y qué es sugerencia en el plato, y (b) no
    // hace falta recalcularlo por comida.
    final userFoods = _userFoodIds(intake);

    // SPEC-297: memoria del día para NO repetir la misma receta entre comidas
    // (bug: muchas recetas encajan en almuerzo Y cena, y se elegían por
    // separado) y para preferir una proteína principal distinta cuando se pueda.
    final usedRecipeIds = <String>{};
    final usedProteinIds = <String>{};

    final entries = <MealPlanEntry>[];
    for (var mi = 0; mi < sourceMeals.length; mi++) {
      final meal = sourceMeals[mi];
      final perMealProtein =
          weightSum == 0 ? 0.0 : targetProteinG * (weights[mi] / weightSum);

      // SPEC-284: la comida ES una receta del recetario. El motor elige la que
      // mejor encaja con lo que el usuario ya come (matcher SPEC-278),
      // respetando dieta + vetos. Con variedad diaria (rota entre las mejores).
      // Si NINGUNA receta encaja (caso raro: vetos extremos), cae al plato
      // armado de SPEC-276 (_buildEntry, sin recipeId).
      final matches = _recipes.match(
        intake: intake,
        slot: meal.slot,
        // SPEC-297: pedimos TODAS las candidatas (no solo el top) para que el
        // dedup del día tenga de dónde elegir; la ventana de variedad se aplica
        // después, dentro de _pickRecipe.
        limit: RecipeCatalog.all.length,
        // SPEC-291: solo recetas cuya materia prima principal está en el
        // repertorio del usuario. Si ninguna califica, cae al plato armado
        // (que se construye 100% con lo que él escogió).
        requirePrincipal: true,
      );
      if (matches.isNotEmpty) {
        final recipe = _pickRecipe(
            matches, dateId, meal.slot, usedRecipeIds, usedProteinIds);
        usedRecipeIds.add(recipe.id);
        final prot = _principalProteinId(recipe);
        if (prot != null) usedProteinIds.add(prot);
        entries.add(
            _entryFromRecipe(meal.slot, perMealProtein, recipe, userFoods));
      } else {
        entries.add(
            _buildEntry(meal, perMealProtein, phase, banned, avoidFoodIds));
      }
    }

    return MealPlan(
      date: dateId,
      intakeVersion: intake.version,
      phase: phase,
      windowFirst: windowFirst,
      windowLast: windowLast,
      meals: entries,
      status: PlanStatus.proposed,
      generatedAt: now,
    );
  }

  /// SPEC-289: de dónde salen las comidas a generar.
  /// - Intake viejo (con `meals`): se respetan sus comidas con contenido.
  /// - Intake nuevo (repertorio plano): desayuno/almuerzo/cena, cada uno con
  ///   el repertorio completo (el matcher elige la receta; el fallback usa el
  ///   repertorio como base del plato).
  List<IntakeMeal> _sourceMeals(NutritionIntake intake) {
    final legacy =
        intake.meals.where((m) => m.items.any((i) => i.isMeaningful)).toList();
    if (legacy.isNotEmpty) return legacy;

    final rep =
        intake.repertoire.where((i) => i.isMeaningful).toList(growable: false);
    if (rep.isEmpty) return const [];
    return const [MealSlot.breakfast, MealSlot.lunch, MealSlot.dinner]
        .map((s) => IntakeMeal(slot: s, items: rep))
        .toList();
  }

  // ─── Comida = receta (SPEC-284) ─────────────────────────────────────────────

  /// Elige una receta entre las mejores, rotando de forma DETERMINÍSTICA por
  /// día + comida (variedad sin perder reproducibilidad). Mismo día → misma
  /// receta; días distintos → varía.
  ///
  /// SPEC-297: dos capas de variedad DENTRO del día:
  ///   1) [usedRecipeIds]: nunca repite una receta ya usada hoy (a menos que
  ///      no quede ninguna otra compatible).
  ///   2) [usedProteinIds]: preferencia SUAVE por una proteína principal
  ///      distinta a las ya servidas hoy (si el usuario solo tiene una, se
  ///      relaja y repite proteína, pero con otra receta).
  Recipe _pickRecipe(
    List<RecipeMatch> matches,
    String dateId,
    MealSlot slot,
    Set<String> usedRecipeIds,
    Set<String> usedProteinIds,
  ) {
    // 1) Fuera las recetas ya usadas hoy. Si todas están usadas (caso raro:
    //    repertorio mínimo), se permite repetir para no dejar la comida vacía.
    var pool =
        matches.where((m) => !usedRecipeIds.contains(m.recipe.id)).toList();
    if (pool.isEmpty) pool = matches;

    // 2) Preferencia suave: proteína principal distinta a las de hoy.
    final freshProtein = pool.where((m) {
      final p = _principalProteinId(m.recipe);
      return p == null || !usedProteinIds.contains(p);
    }).toList();
    if (freshProtein.isNotEmpty) pool = freshProtein;

    // 3) Variedad diaria determinística entre las mejores del pool.
    final k = pool.length < _kRecipePool ? pool.length : _kRecipePool;
    if (k <= 1) return pool.first.recipe;
    final seed = '$dateId|${slot.index}'.hashCode & 0x7fffffff;
    return pool[seed % k].recipe;
  }

  /// Id de la primera proteína (materia prima principal) de la receta, o null
  /// si la receta no tiene proteína de catálogo.
  String? _principalProteinId(Recipe r) {
    for (final ing in r.ingredients) {
      final id = ing.foodId;
      if (id == null || id.isEmpty) continue;
      final f = FoodCatalog.byId(id);
      if (f != null && f.category == FoodCategory.protein) return id;
    }
    return null;
  }

  /// Ids de todo lo que el usuario ya come (repertorio plano nuevo + modelo
  /// viejo por comidas + snacks). Fuente de verdad de "esto es suyo".
  Set<String> _userFoodIds(NutritionIntake intake) {
    final s = <String>{};
    for (final it in intake.repertoire) {
      final id = it.foodId;
      if (id != null && id.isNotEmpty) s.add(id);
    }
    for (final m in intake.meals) {
      for (final it in m.items) {
        final id = it.foodId;
        if (id != null && id.isNotEmpty) s.add(id);
      }
    }
    for (final sn in intake.snacks) {
      final id = sn.foodId;
      if (id != null && id.isNotEmpty) s.add(id);
    }
    return s;
  }

  /// Materializa una comida a partir de una receta: `recipeId` + los alimentos
  /// centrales de la receta como `PlanItem` editables (para cambiar/agregar,
  /// SPEC-280/287). Los ingredientes de texto libre (sal, especias) viven en la
  /// receta y se muestran desde ahí, no como ítems.
  MealPlanEntry _entryFromRecipe(
    MealSlot slot,
    double perMealProtein,
    Recipe recipe,
    Set<String> userFoods,
  ) {
    final seen = <String>{};
    final items = <PlanItem>[];
    for (final ing in recipe.ingredients) {
      final id = ing.foodId;
      if (id == null || id.isEmpty) continue;
      if (!seen.add(id)) continue;
      final f = FoodCatalog.byId(id);
      if (f == null) continue;
      final role = _roleFor(f);
      items.add(PlanItem(
        foodId: id,
        role: role,
        portion: _portionFor(role),
        // SPEC-297: honestidad. Solo lo que el usuario YA come es "suyo"; los
        // acompañamientos de la receta que él no eligió se muestran como
        // sugerencia ("Nuevo"), no como si los hubiera escogido.
        origin: userFoods.contains(id)
            ? PlanItemOrigin.fromUser
            : PlanItemOrigin.newSuggestion,
      ));
    }
    return MealPlanEntry(
      slot: slot,
      targetProteinG: _round1(perMealProtein),
      recipeId: recipe.id,
      items: items,
      rationale: 'Receta sugerida: ${recipe.name}.',
    );
  }

  PlanItemRole _roleFor(Food f) {
    if (f.category == FoodCategory.protein) return PlanItemRole.protein;
    if (_isVegetable(f)) return PlanItemRole.veg;
    if (f.category == FoodCategory.fat) return PlanItemRole.fat;
    return PlanItemRole.other;
  }

  HandPortion _portionFor(PlanItemRole role) => switch (role) {
        PlanItemRole.protein => HandPortion.palm,
        PlanItemRole.veg => HandPortion.fist,
        PlanItemRole.fat => HandPortion.thumb,
        PlanItemRole.other => HandPortion.cupped,
      };

  // ─── Construcción de UN plato coherente (fallback) ──────────────────────────

  MealPlanEntry _buildEntry(
    IntakeMeal meal,
    double perMealProtein,
    int phase,
    Set<String> banned,
    Set<String> avoid,
  ) {
    // Repertorio del usuario para ESTA comida, resuelto a catálogo (los de
    // texto libre no se puntúan; el plan es prescriptivo y se arma con
    // alimentos conocidos).
    final repertoire = <Food>[];
    for (final it in meal.items) {
      final id = it.foodId;
      if (id == null || id.isEmpty) continue;
      final f = FoodCatalog.byId(id);
      if (f != null && !_isBanned(f, banned)) repertoire.add(f);
    }

    List<Food> byRole(bool Function(Food) test) =>
        repertoire.where(test).toList()..sort(_byQualityThenId);
    final proteins = byRole((f) => f.category == FoodCategory.protein);
    final vegetables = byRole(_isVegetable);
    final fats = byRole((f) => f.category == FoodCategory.fat);
    final starches =
        byRole((f) => f.category == FoodCategory.carb && !_isVegetable(f));

    final plate = <_Picked>[];

    // 1) Proteína (palma) — exactamente UNA.
    final protein = _pick(proteins, avoid) ??
        _pickNew(
            FoodCatalog.byCategory(FoodCategory.protein), banned, avoid, plate);
    if (protein != null) {
      plate.add(_Picked(
        food: protein,
        role: PlanItemRole.protein,
        portion: HandPortion.palm,
        origin: proteins.contains(protein)
            ? PlanItemOrigin.fromUser
            : PlanItemOrigin.newSuggestion,
      ));
    }

    // 2) Vegetales (puño) — el 75% del plato. Hasta 2 de los tuyos; si no
    //    tienes ninguno, sugerimos uno marcado "Nuevo".
    final chosenVeg = _pickN(vegetables, avoid, _kMaxVeg);
    if (chosenVeg.isEmpty) {
      final v = _pickNew(_vegCatalog(), banned, avoid, plate);
      if (v != null) {
        plate.add(_Picked(
          food: v,
          role: PlanItemRole.veg,
          portion: HandPortion.fist,
          origin: PlanItemOrigin.newSuggestion,
        ));
      }
    } else {
      for (final v in chosenVeg) {
        plate.add(_Picked(
          food: v,
          role: PlanItemRole.veg,
          portion: HandPortion.fist,
          origin: PlanItemOrigin.fromUser,
        ));
      }
    }

    // 3) Grasa buena (pulgar) — UNA.
    final fat = _pick(fats, avoid);
    if (fat != null) {
      plate.add(_Picked(
        food: fat,
        role: PlanItemRole.fat,
        portion: HandPortion.thumb,
        origin: PlanItemOrigin.fromUser,
      ));
    } else {
      final g = _pickNew(
          FoodCatalog.byCategory(FoodCategory.fat), banned, avoid, plate);
      if (g != null) {
        plate.add(_Picked(
          food: g,
          role: PlanItemRole.fat,
          portion: HandPortion.thumb,
          origin: PlanItemOrigin.newSuggestion,
        ));
      }
    }

    // 4) Carbohidrato/almidón OPCIONAL, porción pequeña — solo si el usuario
    //    ya lo come. No se inyecta (el método prioriza vegetales).
    final starch = _pick(starches, avoid);
    if (starch != null) {
      plate.add(_Picked(
        food: starch,
        role: PlanItemRole.other,
        portion: HandPortion.cupped,
        origin: PlanItemOrigin.fromUser,
      ));
    }

    // 5) UNA mejora suave: sobre el ítem más débil del usuario, si existe
    //    una versión claramente mejor en su misma categoría.
    final swappedFrom = <String>[];
    _Picked? upgradedFromPick;
    _Picked? upgradedTo;
    final idsInPlate = plate.map((p) => p.food.id).toSet();
    _Picked? weakest;
    for (final p in plate) {
      if (p.origin != PlanItemOrigin.fromUser) continue;
      if (!_isWeak(p.food, phase)) continue;
      if (weakest == null || p.food.qualityScore < weakest.food.qualityScore) {
        weakest = p;
      }
    }
    if (weakest != null) {
      final better = _bestUpgrade(weakest.food, banned, idsInPlate);
      if (better != null &&
          better.qualityScore >= weakest.food.qualityScore + _kUpgradeDelta) {
        upgradedFromPick = weakest;
        upgradedTo = _Picked(
          food: better,
          role: weakest.role,
          portion: weakest.portion,
          origin: PlanItemOrigin.upgrade,
        );
      }
    }

    final finalPlate = <_Picked>[];
    for (final p in plate) {
      if (identical(p, upgradedFromPick)) {
        swappedFrom.add(p.food.id);
        finalPlate.add(upgradedTo!);
      } else {
        finalPlate.add(p);
      }
    }

    // A PlanItems, sin duplicados por id.
    final seen = <String>{};
    final items = <PlanItem>[];
    for (final p in finalPlate) {
      if (!seen.add(p.food.id)) continue;
      items.add(PlanItem(
        foodId: p.food.id,
        role: p.role,
        portion: p.portion,
        origin: p.origin,
      ));
    }

    return MealPlanEntry(
      slot: meal.slot,
      targetProteinG: _round1(perMealProtein),
      items: items,
      swappedFrom: swappedFrom,
      rationale: _rationale(
        items,
        swappedFrom.isNotEmpty ? swappedFrom.first : null,
        upgradedTo?.food,
      ),
    );
  }

  // ─── Selección de alimentos ───────────────────────────────────────────────

  /// Mejor candidato (lista ya ordenada por calidad) que NO esté en `avoid`
  /// (variedad, SPEC-275). Si todos están evitados, devuelve el mejor —
  /// la variedad nunca sacrifica calidad.
  Food? _pick(List<Food> sorted, Set<String> avoid) {
    if (sorted.isEmpty) return null;
    if (avoid.isEmpty) return sorted.first;
    for (final f in sorted) {
      if (!avoid.contains(f.id)) return f;
    }
    return sorted.first;
  }

  /// Hasta [n] mejores, prefiriendo los no-evitados.
  List<Food> _pickN(List<Food> sorted, Set<String> avoid, int n) {
    if (sorted.isEmpty || n <= 0) return const [];
    final notAvoided = sorted.where((f) => !avoid.contains(f.id)).toList();
    final avoided = sorted.where((f) => avoid.contains(f.id)).toList();
    return [...notAvoided, ...avoided].take(n).toList();
  }

  /// Mejor alimento del catálogo para completar un rol faltante: no baneado,
  /// no repetido en el plato, SIN cautelas (SPEC-282: no introducimos como
  /// sugerencia nueva un alimento con histamina/inflamación), preferentemente
  /// no-evitado.
  Food? _pickNew(List<Food> catalog, Set<String> banned, Set<String> avoid,
      List<_Picked> plate) {
    final inPlate = plate.map((p) => p.food.id).toSet();
    final cands = catalog
        .where((f) =>
            !_isBanned(f, banned) &&
            !inPlate.contains(f.id) &&
            f.cautions.isEmpty)
        .toList()
      ..sort(_byQualityThenId);
    return _pick(cands, avoid);
  }

  /// Catálogo de "vegetales": carbohidratos de alta calidad (verduras
  /// puntúan ≥70; almidones/harinas puntúan bajo).
  List<Food> _vegCatalog() =>
      FoodCatalog.byCategory(FoodCategory.carb).where(_isVegetable).toList()
        ..sort(_byQualityThenId);

  /// Mejor versión más sana de [from] dentro de su misma categoría, para la
  /// mejora suave. No baneada, no presente en el plato y SIN cautelas
  /// (SPEC-282: la mejora nunca propone un alimento con histamina/inflamación).
  Food? _bestUpgrade(Food from, Set<String> banned, Set<String> idsInPlate) {
    final cands = FoodCatalog.byCategory(from.category)
        .where((f) =>
            f.id != from.id &&
            !idsInPlate.contains(f.id) &&
            !_isBanned(f, banned) &&
            f.cautions.isEmpty)
        .toList()
      ..sort(_byQualityThenId);
    return cands.isEmpty ? null : cands.first;
  }

  bool _isVegetable(Food f) =>
      f.category == FoodCategory.carb && f.qualityScore >= 70;

  /// Umbral de "debilidad" por fase (mejora gradual).
  bool _isWeak(Food f, int phase) {
    if (phase <= 1) return f.nova.isUltraProcessed || f.qualityScore < 15;
    if (phase == 2) return f.qualityScore < 35;
    if (phase == 3) return f.qualityScore < 50;
    return f.qualityScore < 65;
  }

  bool _isBanned(Food f, Set<String> banned) {
    if (banned.isEmpty) return false;
    if (banned.contains(f.id.toLowerCase())) return true;
    final name = f.name.toLowerCase();
    for (final b in banned) {
      if (b.isNotEmpty && name.contains(b)) return true;
    }
    return false;
  }

  Set<String> _bannedSet(List<String> raw) =>
      raw.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet();

  // ─── Utilidades ────────────────────────────────────────────────────────────

  int _byQualityThenId(Food a, Food b) {
    final byScore = b.qualityScore.compareTo(a.qualityScore);
    if (byScore != 0) return byScore;
    return a.id.compareTo(b.id);
  }

  /// Pesos de proteína por comida (el desayuno pesa menos que almuerzo/cena).
  List<double> _proteinWeights(List<MealSlot> slots) {
    double w(MealSlot s) => switch (s) {
          MealSlot.breakfast => 0.25,
          MealSlot.lunch => 0.40,
          MealSlot.dinner => 0.35,
          MealSlot.other => 0.20,
        };
    return slots.map(w).toList();
  }

  double _round1(double v) => (v * 10).round() / 10;

  String _rationale(List<PlanItem> items, String? fromId, Food? into) {
    if (fromId != null && into != null) {
      final fromName = FoodCatalog.byId(fromId)?.name ?? fromId;
      return 'Mejora: cambia $fromName por ${into.name} — te suma sin '
          'disparar la insulina.';
    }
    final hasNew = items.any((i) => i.origin == PlanItemOrigin.newSuggestion);
    if (hasNew) {
      return 'Completamos tu plato con proteína, vegetales y una grasa '
          'buena. Lo marcado con "Nuevo" es una sugerencia para probar.';
    }
    return 'Tu plato ya está balanceado: una proteína, vegetales y una '
        'grasa buena.';
  }
}

/// Selección intermedia de un alimento con su rol/porción/origen, antes de
/// materializar a `PlanItem`.
class _Picked {
  final Food food;
  final PlanItemRole role;
  final HandPortion portion;
  final PlanItemOrigin origin;

  const _Picked({
    required this.food,
    required this.role,
    required this.portion,
    required this.origin,
  });
}
