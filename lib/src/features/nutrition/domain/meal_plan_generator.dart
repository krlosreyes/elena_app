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

class MealPlanGenerator {
  const MealPlanGenerator();

  /// Salto mínimo de calidad para justificar una mejora suave sugerida.
  static const int _kUpgradeDelta = 15;

  /// Máximo de vegetales distintos en un plato.
  static const int _kMaxVeg = 2;

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

    // Comidas con contenido (una comida vacía no aporta base). Orden
    // estable: el del intake.
    final sourceMeals =
        intake.meals.where((m) => m.items.any((i) => i.isMeaningful)).toList();

    final weights = _proteinWeights(sourceMeals.map((m) => m.slot).toList());
    final weightSum = weights.fold<double>(0, (a, b) => a + b);

    final entries = <MealPlanEntry>[];
    for (var mi = 0; mi < sourceMeals.length; mi++) {
      final meal = sourceMeals[mi];
      final perMealProtein =
          weightSum == 0 ? 0.0 : targetProteinG * (weights[mi] / weightSum);
      entries.add(_buildEntry(meal, perMealProtein, phase, banned, avoidFoodIds));
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

  // ─── Construcción de UN plato coherente ─────────────────────────────────────

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
        _pickNew(FoodCatalog.byCategory(FoodCategory.protein), banned, avoid,
            plate);
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
      if (weakest == null ||
          p.food.qualityScore < weakest.food.qualityScore) {
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
  List<Food> _vegCatalog() => FoodCatalog.byCategory(FoodCategory.carb)
      .where(_isVegetable)
      .toList()
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
    final hasNew =
        items.any((i) => i.origin == PlanItemOrigin.newSuggestion);
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
