// SPEC-137 E.3: lógica pura del plato armable.
//
// El usuario va agregando alimentos del catálogo y este builder
// calcula en tiempo real:
// - Distribución por categoría (slots de Proteína / Grasa / Carbos).
// - Calidad metabólica del plato (verde si predomina Tipo A, ámbar si E).
// - Nivel cualitativo visible ("Excelente / Bueno / Mejorable / Día de
//   permitidos") — sin números abstractos.
// - Tip accionable de mejora (ej. "Cambiá el arroz por brócoli").
// - MealRatio derivado para persistencia interna (compatible con
//   CocienteAService y el resto de la cadena del IMR).
//
// Diseño: clase mutable con métodos add/remove/clear. La sheet (UI) la
// instancia en su State y rebuildea al cambiar. No es un StateNotifier
// — vive solo durante la sesión de registro.

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';

/// Nivel cualitativo visible al usuario en el plato.
///
/// Determinado por la fracción del peso del plato que es Tipo A
/// (alimentos que no disparan insulina). Thresholds documentados en
/// NUTRITION_BIBLIOGRAPHY.md §1.2 (filosofía "qué tan saludable", no
/// "cuánta calidad").
enum PlateQuality {
  /// ≥ 85% del peso del plato es Tipo A. "¡Buen trabajo, así se ve un
  /// plato metabólicamente óptimo!"
  excellent,

  /// 60–84% del peso. "Bien encaminado; hay margen para mejorar".
  good,

  /// 35–59% del peso. "Esto puede ser mejor; tienes demasiado E".
  needsWork,

  /// < 35% del peso o usuario marcó día de permitidos. "Sin culpa, hoy
  /// elegiste libre — mañana volvemos al ritmo".
  cheatDay;

  /// Etiqueta visible al usuario en el badge bajo el plato.
  String get label => switch (this) {
        PlateQuality.excellent => 'Excelente plato',
        PlateQuality.good => 'Buen plato',
        PlateQuality.needsWork => 'Plato mejorable',
        PlateQuality.cheatDay => 'Día de permitidos',
      };

  /// Próximo nivel arriba (para el tip de mejora).
  /// `null` si ya está en el tope.
  PlateQuality? get nextLevelUp => switch (this) {
        PlateQuality.cheatDay => PlateQuality.needsWork,
        PlateQuality.needsWork => PlateQuality.good,
        PlateQuality.good => PlateQuality.excellent,
        PlateQuality.excellent => null,
      };
}

/// Builder mutable que acumula alimentos seleccionados.
///
/// Uso típico desde la sheet:
/// ```dart
/// final builder = PlateBuilder();
/// builder.add(FoodCatalog.byId('pollo')!);
/// builder.add(FoodCatalog.byId('brocoli')!);
/// final quality = builder.quality;
/// final tip = builder.tip;
/// final ratio = builder.derivedMealRatio;
/// ```
class PlateBuilder {
  final List<Food> _items = [];

  /// Lista inmutable de alimentos agregados (en orden de selección).
  /// Cada food puede repetirse — agregar "Pollo" dos veces cuenta como
  /// 2 porciones (4 slots de proteína).
  List<Food> get items => List.unmodifiable(_items);

  bool get isEmpty => _items.isEmpty;
  bool get isNotEmpty => _items.isNotEmpty;
  int get itemCount => _items.length;

  void add(Food food) => _items.add(food);

  /// Elimina la primera ocurrencia de [food]. Útil cuando el usuario
  /// quita un chip de la sheet.
  void remove(Food food) {
    final idx = _items.indexOf(food);
    if (idx >= 0) _items.removeAt(idx);
  }

  void clear() => _items.clear();

  // ── distribución por categoría ─────────────────────────────────────

  /// Peso total del plato en slots (sumatoria de [Food.category.slots]).
  int get totalSlots =>
      _items.fold(0, (sum, f) => sum + f.category.slots);

  /// Slots ocupados por una categoría específica. Útil para el painter
  /// que dibuja sectores proporcionales.
  int slotsForCategory(FoodCategory category) => _items
      .where((f) => f.category == category)
      .fold(0, (sum, f) => sum + f.category.slots);

  /// Slots de alimentos Tipo A en una categoría. Útil para colorear el
  /// sector: si una categoría tiene 4 slots y 3 son A, el painter
  /// pinta el sector mayormente verde con un toque ámbar.
  int qualityASlotsForCategory(FoodCategory category) => _items
      .where((f) => f.category == category && f.quality == FoodQuality.typeA)
      .fold(0, (sum, f) => sum + f.category.slots);

  // ── calidad del plato ──────────────────────────────────────────────

  /// Slots totales de alimentos Tipo A.
  int get aSlots => _items
      .where((f) => f.quality == FoodQuality.typeA)
      .fold(0, (sum, f) => sum + f.category.slots);

  /// Slots totales de alimentos Tipo E.
  int get eSlots => totalSlots - aSlots;

  /// Fracción del plato que es Tipo A (0.0 – 1.0). 0.0 si plato vacío.
  double get qualityFraction =>
      totalSlots == 0 ? 0.0 : (aSlots / totalSlots).clamp(0.0, 1.0);

  /// Nivel cualitativo visible al usuario.
  ///
  /// [cheatDayActive] fuerza [PlateQuality.cheatDay] independientemente
  /// de la composición — refleja la decisión consciente del usuario.
  PlateQuality quality({bool cheatDayActive = false}) {
    if (cheatDayActive) return PlateQuality.cheatDay;
    if (totalSlots == 0) return PlateQuality.cheatDay;
    final f = qualityFraction;
    if (f >= 0.85) return PlateQuality.excellent;
    if (f >= 0.60) return PlateQuality.good;
    if (f >= 0.35) return PlateQuality.needsWork;
    return PlateQuality.cheatDay;
  }

  // ── tip accionable ─────────────────────────────────────────────────

  /// Sugerencia textual de mejora. Null si el plato ya está en el
  /// nivel máximo o si está vacío.
  ///
  /// Como el catálogo NO contiene verduras (decisión consciente de
  /// Carlos en la tabla del 22-may-2026), los tips NO sugieren
  /// sustituciones específicas item-por-item. En cambio, sugieren
  /// reequilibrar la composición global del plato basándose en qué
  /// macro está sobre/sub-representado:
  ///
  /// 1. Si hay carbohidratos pero faltan proteínas → "Agregá proteína
  ///    (pollo, huevo, lentejas) para equilibrar el plato."
  /// 2. Si hay carbohidratos pero faltan grasas → "Agregá una grasa
  ///    saludable (aguacate, almendras) para equilibrar."
  /// 3. Si hay carbos y suficiente proteína/grasa → "Reducí los
  ///    carbohidratos (ej. menos arroz o pan) para subir a [nextLevel]."
  /// 4. Si el plato es solo carbos → "Tu plato es solo carbohidratos.
  ///    Agregá una proteína o grasa para mejorarlo."
  String? tip({bool cheatDayActive = false}) {
    if (cheatDayActive || isEmpty) return null;
    final currentLevel = quality(cheatDayActive: false);
    if (currentLevel == PlateQuality.excellent) return null;
    final nextLevel = currentLevel.nextLevelUp;
    if (nextLevel == null) return null;

    final hasProtein = slotsForCategory(FoodCategory.protein) > 0;
    final hasFat = slotsForCategory(FoodCategory.fat) > 0;
    final hasCarbs = slotsForCategory(FoodCategory.carb) > 0;

    // Caso extremo: solo carbos.
    if (hasCarbs && !hasProtein && !hasFat) {
      return 'Tu plato es solo carbohidratos. Agregá una proteína '
          '(pollo, huevo, lentejas) o una grasa (aguacate, almendras) '
          'para mejorarlo.';
    }

    // Caso: hay carbos pero faltan proteína Y grasa.
    if (hasCarbs && !hasProtein && !hasFat) {
      return 'Agregá proteína y grasa para equilibrar tu plato.';
    }

    // Caso: hay carbos pero falta proteína.
    if (hasCarbs && !hasProtein) {
      return 'Agregá proteína (pollo, huevo, lentejas) para equilibrar '
          'tu plato.';
    }

    // Caso: hay carbos pero falta grasa.
    if (hasCarbs && !hasFat) {
      return 'Agregá una grasa saludable (aguacate, almendras) para '
          'equilibrar.';
    }

    // Caso típico: hay de todo, demasiados carbos para el nivel actual.
    if (hasCarbs) {
      final firstCarb = _items.firstWhere(
        (f) => f.category == FoodCategory.carb,
        orElse: () => _items.first,
      );
      return 'Reducí los carbohidratos (ej. menos '
          '${firstCarb.name.toLowerCase()}) para subir a '
          '${nextLevel.label}.';
    }

    // Caso raro: no hay carbos pero la calidad sigue bajo Excelente
    // (no debería ocurrir con esta tabla, todos los E son carbos).
    return 'Tu plato puede mejorar. Probá distintas combinaciones para '
        'subir a ${nextLevel.label}.';
  }

  // ── persistencia: derivar MealRatio ────────────────────────────────

  /// Mapea la composición actual al [MealRatio] que persiste el
  /// `NutritionLog`. Es el puente entre la UX visual y el cálculo del
  /// Cociente A (que sigue siendo la métrica del IMR).
  ///
  /// Independiente del PlateQuality — los thresholds aquí están
  /// alineados con la unidad atómica `MealRatio` del dominio (5
  /// posiciones), no con los 4 niveles del badge visual.
  ///
  /// Si el plato está vacío, devuelve [MealRatio.a2e1] (default sensible).
  MealRatio get derivedMealRatio {
    if (totalSlots == 0) return MealRatio.a2e1;
    final f = qualityFraction;
    if (f >= 0.99) return MealRatio.allA;
    if (f >= 0.70) return MealRatio.a3e1;
    if (f >= 0.55) return MealRatio.a2e1;
    if (f >= 0.35) return MealRatio.a1e1;
    return MealRatio.allE;
  }
}
