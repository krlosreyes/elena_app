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
  /// Estrategia:
  /// 1. Busca el primer Food Tipo E del plato con [Food.substituteHint]
  ///    no-null.
  /// 2. Sugiere reemplazarlo: "Cambiá el arroz por brócoli o espinaca y
  ///    subís a Excelente plato".
  /// 3. Si no hay reemplazo natural en el catálogo (leche, yogur con
  ///    azúcar, chocolate), sugiere reducir: "Reducí el yogur con azúcar
  ///    para mejorar tu plato".
  /// 4. Si el plato no tiene ningún Tipo E (todo A), no hay tip.
  String? tip({bool cheatDayActive = false}) {
    if (cheatDayActive || isEmpty) return null;
    final currentLevel = quality(cheatDayActive: false);
    if (currentLevel == PlateQuality.excellent) return null;
    final nextLevel = currentLevel.nextLevelUp;
    if (nextLevel == null) return null;

    final firstWithHint = _items.firstWhere(
      (f) => f.quality == FoodQuality.typeE && f.substituteHint != null,
      orElse: () => _items.firstWhere(
        (f) => f.quality == FoodQuality.typeE,
        orElse: () => _items.first,
      ),
    );

    if (firstWithHint.quality != FoodQuality.typeE) {
      return null;
    }

    if (firstWithHint.substituteHint != null) {
      return 'Cambiá ${_articleFor(firstWithHint.name)} '
          '${firstWithHint.name.toLowerCase()} por '
          '${firstWithHint.substituteHint} y subís a '
          '${nextLevel.label}.';
    } else {
      return 'Reducí ${_articleFor(firstWithHint.name)} '
          '${firstWithHint.name.toLowerCase()} para llegar a '
          '${nextLevel.label}.';
    }
  }

  /// Artículo gramatical aproximado para el copy ("el" / "la").
  /// Heurística simple: nombres que terminan en 'a' o 'e' (excepto
  /// "pescado"/"queso") → "la", el resto → "el". No es perfecto pero
  /// cubre el catálogo curado.
  static String _articleFor(String name) {
    final lower = name.toLowerCase();
    // Casos especiales del catálogo (todos los pongo aquí para evitar
    // que la heurística falle silenciosamente).
    const feminine = {
      'manzana',
      'fresa',
      'pasta',
      'papa',
      'banana',
      'leche',
      'espinaca',
      'lechuga',
      'mantequilla',
      'carne',
      'coliflor',
    };
    if (feminine.contains(lower)) return 'la';
    return 'el';
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
