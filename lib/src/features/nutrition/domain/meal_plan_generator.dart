// SPEC-272 — Motor de generación de la Minuta Diaria.
//
// Corazón de la reestructuración: convierte el retrato dietético
// (`NutritionIntake`) en un plan del día (`MealPlan`) por REEMPLAZO SUAVE
// —parte de lo que el usuario ya come y corrige el eslabón más débil— sin
// imponer un menú ajeno. 100% DETERMINÍSTICO (decisión de Carlos §9): la
// misma entrada produce la misma minuta, sin IA en la decisión. Es Dart
// PURO (sin Riverpod, sin Firestore, sin Flutter) → fácil de testear.
//
// Reglas del plato (El Milagro Metabólico, Jaramillo cap. 10):
//   1. Base vegetal (garantiza ≥1 vegetal de alta calidad por comida).
//   2. Proteína por peso ideal (reparte el targetProteinG entre comidas).
//   3. Grasas saludables en cada comida (garantiza ≥1 grasa buena).
// Snacks: NO se proponen; se retiran gradualmente (decisión §9), por eso
// el plan no incluye snacks.
//
// Fases del reemplazo suave (§7.1): en fase 1 solo se toca lo peor
// (NOVA 4 / qualityScore < 15); fases mayores endurecen el umbral.

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';

class MealPlanGenerator {
  const MealPlanGenerator();

  /// Genera la minuta del día a partir del intake + la proteína objetivo
  /// (que el llamador deriva del UserModel vía ProteinTargetService) + la
  /// ventana circadiana + la fase de transición.
  ///
  /// [now] se inyecta para determinismo en tests; si es null, `generatedAt`
  /// queda null (el repositorio/So no depende de él para el id).
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
      final perMealProtein = weightSum == 0
          ? 0.0
          : targetProteinG * (weights[mi] / weightSum);
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

  // ─── Construcción de una comida ───────────────────────────────────────────

  MealPlanEntry _buildEntry(
    IntakeMeal meal,
    double perMealProtein,
    int phase,
    Set<String> banned,
    Set<String> avoid,
  ) {
    // 1) Base: solo items del catálogo (los de texto libre no se puntúan;
    //    el plan es prescriptivo y se arma con alimentos conocidos).
    final base = <Food>[];
    for (final it in meal.items) {
      final id = it.foodId;
      if (id == null || id.isEmpty) continue;
      final f = FoodCatalog.byId(id);
      if (f != null) base.add(f);
    }

    // 2) Reemplazo suave: corrige el PEOR item de la fase (uno por comida).
    final swappedFrom = <String>[];
    Food? swappedInto;
    final weakestIdx = _weakestIndex(base, phase);
    if (weakestIdx >= 0) {
      final weakest = base[weakestIdx];
      final alt = _bestInCategory(weakest.category, banned,
          avoidId: weakest.id, avoid: avoid);
      if (alt != null && alt.qualityScore > weakest.qualityScore) {
        swappedFrom.add(weakest.id);
        swappedInto = alt;
        base[weakestIdx] = alt;
      }
    }

    // 3) Garantías del plato (sin duplicar lo que ya hay).
    final hasProtein = base.any((f) => f.category == FoodCategory.protein);
    if (!hasProtein) {
      final p = _bestInCategory(FoodCategory.protein, banned, avoid: avoid);
      if (p != null) base.add(p);
    }
    final hasVeg = base.any(_isVegetable);
    if (!hasVeg) {
      final v = _bestVegetable(banned, avoid: avoid);
      if (v != null) base.add(v);
    }
    final hasFat = base.any((f) => f.category == FoodCategory.fat);
    if (!hasFat) {
      final g = _bestInCategory(FoodCategory.fat, banned, avoid: avoid);
      if (g != null) base.add(g);
    }

    // 4) A PlanItems (rol + porción de mano), sin duplicados por id.
    final seen = <String>{};
    final items = <PlanItem>[];
    for (final f in base) {
      if (!seen.add(f.id)) continue;
      items.add(PlanItem(
        foodId: f.id,
        role: _roleFor(f),
        portion: _portionFor(f),
      ));
    }

    return MealPlanEntry(
      slot: meal.slot,
      targetProteinG: _round1(perMealProtein),
      items: items,
      swappedFrom: swappedFrom,
      rationale: _rationale(swappedFrom.isNotEmpty ? swappedFrom.first : null,
          swappedInto, meal.slot),
    );
  }

  // ─── Selección de alimentos ───────────────────────────────────────────────

  /// Mejor alimento de una categoría (mayor qualityScore, desempate por id
  /// para determinismo), respetando exclusiones.
  Food? _bestInCategory(FoodCategory cat, Set<String> banned,
      {String? avoidId, Set<String> avoid = const {}}) {
    final candidates = FoodCatalog.byCategory(cat)
        .where((f) => f.id != avoidId && !_isBanned(f, banned))
        .toList()
      ..sort(_byQualityThenId);
    return _pick(candidates, avoid);
  }

  /// Mejor "vegetal": carbohidrato de alta calidad (verduras puntúan ≥70 en
  /// el catálogo; los almidones/harinas puntúan bajo).
  Food? _bestVegetable(Set<String> banned, {Set<String> avoid = const {}}) {
    final candidates = FoodCatalog.byCategory(FoodCategory.carb)
        .where((f) => f.qualityScore >= 70 && !_isBanned(f, banned))
        .toList()
      ..sort(_byQualityThenId);
    return _pick(candidates, avoid);
  }

  /// Elige el mejor candidato (lista ya ordenada) que NO esté en `avoid`
  /// (rotación / variedad, SPEC-275). Si TODOS están evitados, devuelve el
  /// mejor de todos modos — la variedad nunca sacrifica la calidad del plato.
  Food? _pick(List<Food> sorted, Set<String> avoid) {
    if (sorted.isEmpty) return null;
    if (avoid.isEmpty) return sorted.first;
    for (final f in sorted) {
      if (!avoid.contains(f.id)) return f;
    }
    return sorted.first;
  }

  bool _isVegetable(Food f) =>
      f.category == FoodCategory.carb && f.qualityScore >= 70;

  /// Índice del item más débil según la fase, o -1 si ninguno califica.
  int _weakestIndex(List<Food> base, int phase) {
    var idx = -1;
    var worst = 101; // qualityScore máx es 100
    for (var i = 0; i < base.length; i++) {
      final f = base[i];
      if (_isWeak(f, phase) && f.qualityScore < worst) {
        worst = f.qualityScore;
        idx = i;
      }
    }
    return idx;
  }

  /// Umbral de "debilidad" por fase (reemplazo gradual).
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

  // ─── Roles y porciones ────────────────────────────────────────────────────

  PlanItemRole _roleFor(Food f) => switch (f.category) {
        FoodCategory.protein => PlanItemRole.protein,
        FoodCategory.fat => PlanItemRole.fat,
        FoodCategory.carb =>
          _isVegetable(f) ? PlanItemRole.veg : PlanItemRole.other,
      };

  HandPortion _portionFor(Food f) => switch (_roleFor(f)) {
        PlanItemRole.protein => HandPortion.palm,
        PlanItemRole.veg => HandPortion.fist,
        PlanItemRole.fat => HandPortion.thumb,
        PlanItemRole.other => HandPortion.cupped,
      };

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

  String _rationale(String? fromId, Food? into, MealSlot slot) {
    if (fromId != null && into != null) {
      final fromName = FoodCatalog.byId(fromId)?.name ?? fromId;
      return 'Cambiamos $fromName por ${into.name}: te suma sin disparar la '
          'insulina.';
    }
    return 'Mantuvimos tu comida y la equilibramos con proteína, vegetales y '
        'una grasa buena.';
  }
}
