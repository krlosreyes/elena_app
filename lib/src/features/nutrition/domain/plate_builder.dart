// SPEC-137 E.4: lógica del plato armable con scoring numérico continuo.
//
// El plato se evalúa como un PROMEDIO PONDERADO por slots de los
// qualityScore de los alimentos agregados:
//
//   qualityPercent = Σ(food.qualityScore × food.category.slots)
//                  / Σ(food.category.slots)
//
// La meta del usuario es **75% (efecto 3x1)** — 3 partes alimentos
// óptimos por 1 parte permisiva. Decisión validada por Carlos.
//
// Niveles cualitativos visibles al usuario (sin números crudos):
//
//   ≥ 75% → Excelente plato     (cumple meta 3x1)
//   60-74 → Buen plato          (cerca de la meta)
//   35-59 → Plato mejorable     (espacio para mejorar)
//   < 35  → Día de permitidos   (decisión consciente o muy bajo)
//
// Si `cheatDayActive` está en true, el plato se considera Día de
// permitidos automáticamente — el usuario eligió libre y respetamos.
//
// El builder también deriva un `MealRatio` para la persistencia interna
// (compatible con CocienteAService y el resto de la cadena del IMR).

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';

/// Nivel cualitativo visible al usuario.
enum PlateQuality {
  excellent,
  good,
  needsWork,
  cheatDay;

  String get label => switch (this) {
        PlateQuality.excellent => 'Excelente plato',
        PlateQuality.good => 'Buen plato',
        PlateQuality.needsWork => 'Plato mejorable',
        PlateQuality.cheatDay => 'Día de permitidos',
      };

  PlateQuality? get nextLevelUp => switch (this) {
        PlateQuality.cheatDay => PlateQuality.needsWork,
        PlateQuality.needsWork => PlateQuality.good,
        PlateQuality.good => PlateQuality.excellent,
        PlateQuality.excellent => null,
      };
}

/// Builder mutable que acumula alimentos seleccionados.
class PlateBuilder {
  final List<Food> _items = [];

  List<Food> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get itemCount => _items.length;

  void add(Food food) => _items.add(food);

  /// Elimina la primera ocurrencia de [food].
  void remove(Food food) {
    final idx = _items.indexOf(food);
    if (idx >= 0) _items.removeAt(idx);
  }

  void clear() => _items.clear();

  // ── distribución por categoría ─────────────────────────────────────

  /// Peso total del plato en slots (sumatoria de [FoodCategory.slots]).
  int get totalSlots =>
      _items.fold(0, (sum, f) => sum + f.category.slots);

  /// Slots ocupados por una categoría específica.
  int slotsForCategory(FoodCategory category) => _items
      .where((f) => f.category == category)
      .fold(0, (sum, f) => sum + f.category.slots);

  /// Score promedio de una categoría (ponderado por slots dentro de la
  /// categoría). Útil para colorear el sector del plato: si todos los
  /// alimentos de la categoría son score 90+, el sector se ve verde
  /// fuerte; si bajan a 30, ámbar.
  ///
  /// Devuelve 0 si no hay alimentos de esa categoría.
  int qualityScoreForCategory(FoodCategory category) {
    final cats = _items.where((f) => f.category == category).toList();
    if (cats.isEmpty) return 0;
    final totalSlotsCat = cats.fold(0, (sum, f) => sum + f.category.slots);
    final weighted = cats.fold(
        0, (sum, f) => sum + (f.qualityScore * f.category.slots));
    return (weighted / totalSlotsCat).round();
  }

  // ── calidad global del plato ───────────────────────────────────────

  /// Score promedio ponderado del plato (0-100). 0 si vacío.
  int get qualityPercent {
    if (totalSlots == 0) return 0;
    final weighted = _items.fold(
        0, (sum, f) => sum + (f.qualityScore * f.category.slots));
    return (weighted / totalSlots).round();
  }

  /// Nivel cualitativo visible al usuario.
  ///
  /// [cheatDayActive] fuerza [PlateQuality.cheatDay] independientemente
  /// de la composición.
  PlateQuality quality({bool cheatDayActive = false}) {
    if (cheatDayActive) return PlateQuality.cheatDay;
    if (totalSlots == 0) return PlateQuality.cheatDay;
    final p = qualityPercent;
    if (p >= 75) return PlateQuality.excellent;
    if (p >= 60) return PlateQuality.good;
    if (p >= 35) return PlateQuality.needsWork;
    return PlateQuality.cheatDay;
  }

  // ── tip accionable ─────────────────────────────────────────────────

  /// Sugerencia textual de mejora. Null si el plato ya está en el
  /// nivel máximo, si está vacío o si es cheat day.
  ///
  /// Estrategia:
  /// 1. Identifica el alimento de score MÁS BAJO en el plato — es el
  ///    que más rebaja el promedio.
  /// 2. Si su score < 35, sugiere reducirlo o quitarlo.
  /// 3. Si su categoría no está balanceada (ej. solo carbos), sugiere
  ///    agregar la categoría faltante.
  String? tip({bool cheatDayActive = false}) {
    if (cheatDayActive || isEmpty) return null;
    final currentLevel = quality(cheatDayActive: false);
    if (currentLevel == PlateQuality.excellent) return null;
    final nextLevel = currentLevel.nextLevelUp;
    if (nextLevel == null) return null;

    final hasProtein = slotsForCategory(FoodCategory.protein) > 0;
    final hasFat = slotsForCategory(FoodCategory.fat) > 0;
    final hasCarbs = slotsForCategory(FoodCategory.carb) > 0;

    // Caso 1: faltan categorías esenciales.
    if (hasCarbs && !hasProtein && !hasFat) {
      return 'Tu plato solo tiene carbos. Agregá una proteína '
          '(pollo, huevo, lentejas) y una grasa (aguacate, almendras).';
    }
    if (hasCarbs && !hasProtein) {
      return 'Agregá una proteína (pollo, huevo, lentejas) para '
          'balancear tu plato.';
    }
    if (hasCarbs && !hasFat) {
      return 'Agregá una grasa saludable (aguacate, almendras) para '
          'balancear tu plato.';
    }

    // Caso 2: hay de todo pero el promedio baja por algún item específico.
    final lowest = _items.reduce(
        (a, b) => a.qualityScore <= b.qualityScore ? a : b);

    if (lowest.qualityScore < 35) {
      return 'Reducí ${_articleFor(lowest.name)} '
          '${lowest.name.toLowerCase()} para subir a ${nextLevel.label}.';
    }

    return 'Reducí los alimentos con menos puntaje (ej. '
        '${lowest.name.toLowerCase()}) para subir a ${nextLevel.label}.';
  }

  /// Artículo gramatical aproximado para el copy ("el" / "la").
  /// Lista cerrada para el catálogo MVP — más confiable que heurística.
  static String _articleFor(String name) {
    final lower = name.toLowerCase();
    const feminine = {
      'manzana', 'fresa', 'pasta', 'papa', 'papa criolla', 'banana',
      'leche', 'leche entera', 'espinaca', 'lechuga', 'mantequilla',
      'carne', 'carne de res', 'coliflor', 'avena', 'arepa', 'tortilla',
      'harina', 'panela', 'mayonesa', 'crema de leche', 'manteca',
      'margarina', 'salchicha', 'frambuesa', 'pechuga de pavo',
      'quinua', 'tapioca', 'yuca', 'sardinas', 'cebolla', 'zanahoria',
    };
    if (feminine.contains(lower)) return 'la';
    return 'el';
  }

  // ── persistencia: derivar MealRatio ────────────────────────────────

  /// Mapea la composición actual al [MealRatio] que persiste el
  /// `NutritionLog`. Es el puente entre la UX visual (score) y el
  /// cálculo del Cociente A (que sigue siendo la métrica del IMR).
  ///
  /// Thresholds alineados con los del MealRatio histórico:
  ///   ≥99 → allA  (todo óptimo)
  ///   ≥70 → a3e1  (cumple meta 3x1)
  ///   ≥55 → a2e1  (cumple 2x1)
  ///   ≥35 → a1e1  (mejorable)
  ///   <35 → allE  (cheat-like)
  MealRatio get derivedMealRatio {
    if (totalSlots == 0) return MealRatio.a2e1;
    final p = qualityPercent;
    if (p >= 99) return MealRatio.allA;
    if (p >= 70) return MealRatio.a3e1;
    if (p >= 55) return MealRatio.a2e1;
    if (p >= 35) return MealRatio.a1e1;
    return MealRatio.allE;
  }
}
