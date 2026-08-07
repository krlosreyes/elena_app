// SPEC-270 — Onboarding del Pilar de Alimentación: evaluación dietética.
//
// `NutritionIntake` es el "retrato dietético" del usuario: qué come hoy,
// en qué cantidades, qué pica, qué bebe, qué NO come y en qué contexto.
// Es la materia prima con la que el motor de la Minuta (SPEC-272)
// construye el plan diario por reemplazo suave.
//
// Se persiste como UN documento por usuario en
// `users/{uid}/nutritionProfile/intake` (ver
// nutrition_intake_repository_impl.dart). NO reemplaza ni toca el
// onboarding de alta: la biometría (height/gender/age/activityLevel) y la
// ventana (firstMealGoal/lastMealGoal) se LEEN del UserModel existente y
// solo se cachean en `derived` (ver ProteinTargetService).
//
// No usa Freezed (evita build_runner) — mismo criterio que MealPreset,
// StreakEntry y EarnedBadge. Parsing PERMISIVO en cada `fromJson`: un
// campo corrupto cae a un default sensato en vez de tumbar todo el
// documento (mismo criterio que MealPreset.fromJson). Un intake es un
// dato de baja criticidad — se re-encuesta cada 4 semanas (SPEC-275).
//
// Referencia de método: El Milagro Metabólico (Jaramillo, 2019) cap. 9-10
// y docs/NUTRITION_BIBLIOGRAPHY.md. Ver specs/SPEC-270-*.md.

// ─── Enums de captura ──────────────────────────────────────────────────────

/// Momento de la comida. `other` cubre meriendas formales / cuarta comida.
enum MealSlot {
  breakfast,
  lunch,
  dinner,
  other;

  String get wire => switch (this) {
        MealSlot.breakfast => 'breakfast',
        MealSlot.lunch => 'lunch',
        MealSlot.dinner => 'dinner',
        MealSlot.other => 'other',
      };

  static MealSlot fromWire(String? w) => switch (w) {
        'breakfast' => MealSlot.breakfast,
        'lunch' => MealSlot.lunch,
        'dinner' => MealSlot.dinner,
        _ => MealSlot.other,
      };
}

/// Cantidad "al ojímetro" — nunca gramos (NUTRITION_BIBLIOGRAPHY.md §1.2).
enum PortionQty {
  little,
  normal,
  plenty;

  String get wire => switch (this) {
        PortionQty.little => 'little',
        PortionQty.normal => 'normal',
        PortionQty.plenty => 'plenty',
      };

  static PortionQty fromWire(String? w) => switch (w) {
        'little' => PortionQty.little,
        'plenty' => PortionQty.plenty,
        _ => PortionQty.normal, // default seguro
      };
}

/// Frecuencia de consumo de snacks / bebidas.
enum ConsumptionFrequency {
  never,
  sometimes,
  daily,
  multipleDaily;

  String get wire => switch (this) {
        ConsumptionFrequency.never => 'never',
        ConsumptionFrequency.sometimes => 'sometimes',
        ConsumptionFrequency.daily => 'daily',
        ConsumptionFrequency.multipleDaily => 'multiple_daily',
      };

  static ConsumptionFrequency fromWire(String? w) => switch (w) {
        'never' => ConsumptionFrequency.never,
        'daily' => ConsumptionFrequency.daily,
        'multiple_daily' => ConsumptionFrequency.multipleDaily,
        _ => ConsumptionFrequency.sometimes, // default seguro
      };
}

/// Régimen alimentario declarado. Restringe el catálogo del motor.
enum DietType {
  omnivore,
  pescatarian,
  vegetarian,
  vegan,
  other;

  String get wire => switch (this) {
        DietType.omnivore => 'omnivore',
        DietType.pescatarian => 'pescatarian',
        DietType.vegetarian => 'vegetarian',
        DietType.vegan => 'vegan',
        DietType.other => 'other',
      };

  static DietType fromWire(String? w) => switch (w) {
        'pescatarian' => DietType.pescatarian,
        'vegetarian' => DietType.vegetarian,
        'vegan' => DietType.vegan,
        'other' => DietType.other,
        _ => DietType.omnivore, // default seguro
      };
}

/// Nivel low/mid/high para tiempo de cocina y presupuesto (contexto).
enum LevelLowMidHigh {
  low,
  mid,
  high;

  String get wire => switch (this) {
        LevelLowMidHigh.low => 'low',
        LevelLowMidHigh.mid => 'mid',
        LevelLowMidHigh.high => 'high',
      };

  static LevelLowMidHigh fromWire(String? w) => switch (w) {
        'low' => LevelLowMidHigh.low,
        'high' => LevelLowMidHigh.high,
        _ => LevelLowMidHigh.mid, // default seguro
      };
}

// ─── Tipos anidados ────────────────────────────────────────────────────────

/// Un alimento del plato habitual. `foodId` referencia `FoodCatalog.all`;
/// `freeText` cubre lo que no está en el catálogo (Bloque 2).
class IntakeItem {
  final String? foodId;
  final PortionQty qty;
  final String? freeText;

  const IntakeItem({this.foodId, this.qty = PortionQty.normal, this.freeText});

  /// True si el item aporta algo identificable (id o texto libre).
  bool get isMeaningful =>
      (foodId != null && foodId!.isNotEmpty) ||
      (freeText != null && freeText!.trim().isNotEmpty);

  Map<String, dynamic> toJson() => {
        if (foodId != null) 'foodId': foodId,
        'qty': qty.wire,
        if (freeText != null && freeText!.trim().isNotEmpty)
          'freeText': freeText!.trim(),
      };

  factory IntakeItem.fromJson(Map<String, dynamic> j) => IntakeItem(
        foodId: (j['foodId'] as String?)?.trim(),
        qty: PortionQty.fromWire(j['qty'] as String?),
        freeText: (j['freeText'] as String?)?.trim(),
      );

  @override
  bool operator ==(Object other) =>
      other is IntakeItem &&
      other.foodId == foodId &&
      other.qty == qty &&
      other.freeText == freeText;

  @override
  int get hashCode => Object.hash(foodId, qty, freeText);
}

/// Una comida habitual (Bloque 1-3): slot, hora aproximada y sus items.
class IntakeMeal {
  final MealSlot slot;

  /// Hora aproximada en formato "HH:mm" (24h). Puede venir del prellenado
  /// con firstMealGoal/lastMealGoal. Cadena vacía = sin especificar.
  final String timeApprox;

  final List<IntakeItem> items;

  const IntakeMeal({
    required this.slot,
    this.timeApprox = '',
    this.items = const [],
  });

  Map<String, dynamic> toJson() => {
        'slot': slot.wire,
        'timeApprox': timeApprox,
        'items': items.map((i) => i.toJson()).toList(growable: false),
      };

  factory IntakeMeal.fromJson(Map<String, dynamic> j) => IntakeMeal(
        slot: MealSlot.fromWire(j['slot'] as String?),
        timeApprox: (j['timeApprox'] as String?)?.trim() ?? '',
        items: _parseList(j['items'], IntakeItem.fromJson),
      );
}

/// Un snack / "galguería" entre comidas (Bloque 4).
class IntakeSnack {
  final String? foodId;
  final String? freeText;
  final ConsumptionFrequency frequency;

  const IntakeSnack({
    this.foodId,
    this.freeText,
    this.frequency = ConsumptionFrequency.sometimes,
  });

  Map<String, dynamic> toJson() => {
        if (foodId != null) 'foodId': foodId,
        if (freeText != null && freeText!.trim().isNotEmpty)
          'freeText': freeText!.trim(),
        'frequency': frequency.wire,
      };

  factory IntakeSnack.fromJson(Map<String, dynamic> j) => IntakeSnack(
        foodId: (j['foodId'] as String?)?.trim(),
        freeText: (j['freeText'] as String?)?.trim(),
        frequency: ConsumptionFrequency.fromWire(j['frequency'] as String?),
      );
}

/// Perfil de bebidas (Bloque 5). El alcohol se enlaza por referencia al
/// Protocolo de Consumo Consciente (SPEC-261), no se re-captura aquí.
class DrinksProfile {
  final ConsumptionFrequency sugary;
  final bool coffeeSweetened;

  /// Referencia lógica al módulo de alcohol (SPEC-261). `null` si el
  /// usuario no reporta consumo. No se guarda el detalle acá.
  final String? alcoholRef;

  const DrinksProfile({
    this.sugary = ConsumptionFrequency.sometimes,
    this.coffeeSweetened = false,
    this.alcoholRef,
  });

  Map<String, dynamic> toJson() => {
        'sugary': sugary.wire,
        'coffeeSweetened': coffeeSweetened,
        if (alcoholRef != null) 'alcoholRef': alcoholRef,
      };

  factory DrinksProfile.fromJson(Map<String, dynamic> j) => DrinksProfile(
        sugary: ConsumptionFrequency.fromWire(j['sugary'] as String?),
        coffeeSweetened: j['coffeeSweetened'] as bool? ?? false,
        alcoholRef: (j['alcoholRef'] as String?)?.trim(),
      );
}

/// Preferencias y restricciones (Bloque 6). Restringe el catálogo del motor.
class IntakeRestrictions {
  final DietType diet;

  /// Alimentos que el usuario NO come por elección/aversión (foodIds o
  /// texto). El motor nunca los propone.
  final List<String> excludes;

  /// Alergias/intolerancias. Se tratan como exclusión dura (nunca se
  /// proponen), separadas de `excludes` por semántica de seguridad.
  final List<String> allergies;

  const IntakeRestrictions({
    this.diet = DietType.omnivore,
    this.excludes = const [],
    this.allergies = const [],
  });

  /// Unión de exclusiones + alergias — lo que el motor debe evitar.
  List<String> get allBanned =>
      <String>{...excludes, ...allergies}.toList(growable: false);

  Map<String, dynamic> toJson() => {
        'diet': diet.wire,
        'excludes': excludes,
        'allergies': allergies,
      };

  factory IntakeRestrictions.fromJson(Map<String, dynamic> j) =>
      IntakeRestrictions(
        diet: DietType.fromWire(j['diet'] as String?),
        excludes: (j['excludes'] as List<dynamic>?)?.cast<String>() ??
            const <String>[],
        allergies: (j['allergies'] as List<dynamic>?)?.cast<String>() ??
            const <String>[],
      );
}

/// Contexto de adherencia (Bloque 6): define qué tan ambiciosa puede ser
/// la minuta (tiempo/dinero/quién cocina).
class IntakeContext {
  final LevelLowMidHigh cookTime;
  final LevelLowMidHigh budget;
  final bool cooksAtHome;

  const IntakeContext({
    this.cookTime = LevelLowMidHigh.mid,
    this.budget = LevelLowMidHigh.mid,
    this.cooksAtHome = true,
  });

  Map<String, dynamic> toJson() => {
        'cookTime': cookTime.wire,
        'budget': budget.wire,
        'cooksAtHome': cooksAtHome,
      };

  factory IntakeContext.fromJson(Map<String, dynamic> j) => IntakeContext(
        cookTime: LevelLowMidHigh.fromWire(j['cookTime'] as String?),
        budget: LevelLowMidHigh.fromWire(j['budget'] as String?),
        cooksAtHome: j['cooksAtHome'] as bool? ?? true,
      );
}

/// Objetivos DERIVADOS (caché). NO son fuente de verdad: se calculan desde
/// UserModel (biometría) + CircadianProfile (ventana) por
/// `ProteinTargetService`. Se persisten solo para no recalcular en cada
/// apertura. `windowFirst`/`windowLast` en "HH:mm"; vacío = sin ventana.
class DerivedTargets {
  final double idealWeightKg;
  final double targetProteinG;
  final String windowFirst;
  final String windowLast;

  const DerivedTargets({
    this.idealWeightKg = 0,
    this.targetProteinG = 0,
    this.windowFirst = '',
    this.windowLast = '',
  });

  Map<String, dynamic> toJson() => {
        'idealWeightKg': idealWeightKg,
        'targetProteinG': targetProteinG,
        'windowFirst': windowFirst,
        'windowLast': windowLast,
      };

  factory DerivedTargets.fromJson(Map<String, dynamic> j) => DerivedTargets(
        idealWeightKg: (j['idealWeightKg'] as num?)?.toDouble() ?? 0,
        targetProteinG: (j['targetProteinG'] as num?)?.toDouble() ?? 0,
        windowFirst: (j['windowFirst'] as String?)?.trim() ?? '',
        windowLast: (j['windowLast'] as String?)?.trim() ?? '',
      );

  @override
  bool operator ==(Object other) =>
      other is DerivedTargets &&
      other.idealWeightKg == idealWeightKg &&
      other.targetProteinG == targetProteinG &&
      other.windowFirst == windowFirst &&
      other.windowLast == windowLast;

  @override
  int get hashCode =>
      Object.hash(idealWeightKg, targetProteinG, windowFirst, windowLast);
}

// ─── Agregado raíz ─────────────────────────────────────────────────────────

/// Versión del esquema del intake. Se incrementa cuando el modelo cambia
/// de forma incompatible; también lo bumpea la re-encuesta (SPEC-275).
const int kNutritionIntakeSchemaVersion = 1;

class NutritionIntake {
  final int version;
  final DateTime updatedAt;

  /// Comidas/día declaradas (Bloque 1). Informativo: el target operativo
  /// de comidas se infiere del protocolo de ayuno (MealTargetService), no
  /// de este campo. Se guarda igual como parte del retrato.
  final int mealsPerDay;

  final List<IntakeMeal> meals; // Bloque 1-3
  final List<IntakeSnack> snacks; // Bloque 4
  final DrinksProfile drinks; // Bloque 5
  final IntakeRestrictions restrictions; // Bloque 6
  final IntakeContext context; // Bloque 6
  final DerivedTargets derived; // caché (desde UserModel + circadiano)

  const NutritionIntake({
    this.version = kNutritionIntakeSchemaVersion,
    required this.updatedAt,
    this.mealsPerDay = 3,
    this.meals = const [],
    this.snacks = const [],
    this.drinks = const DrinksProfile(),
    this.restrictions = const IntakeRestrictions(),
    this.context = const IntakeContext(),
    this.derived = const DerivedTargets(),
  });

  /// True si el retrato tiene contenido mínimo para generar una minuta:
  /// al menos una comida con al menos un item con sentido.
  bool get isComplete => meals.any((m) => m.items.any((i) => i.isMeaningful));

  NutritionIntake copyWith({
    int? version,
    DateTime? updatedAt,
    int? mealsPerDay,
    List<IntakeMeal>? meals,
    List<IntakeSnack>? snacks,
    DrinksProfile? drinks,
    IntakeRestrictions? restrictions,
    IntakeContext? context,
    DerivedTargets? derived,
  }) {
    return NutritionIntake(
      version: version ?? this.version,
      updatedAt: updatedAt ?? this.updatedAt,
      mealsPerDay: mealsPerDay ?? this.mealsPerDay,
      meals: meals ?? this.meals,
      snacks: snacks ?? this.snacks,
      drinks: drinks ?? this.drinks,
      restrictions: restrictions ?? this.restrictions,
      context: context ?? this.context,
      derived: derived ?? this.derived,
    );
  }

  Map<String, dynamic> toJson() => {
        'version': version,
        'updatedAt': updatedAt.toIso8601String(),
        'mealsPerDay': mealsPerDay,
        'meals': meals.map((m) => m.toJson()).toList(growable: false),
        'snacks': snacks.map((s) => s.toJson()).toList(growable: false),
        'drinks': drinks.toJson(),
        'restrictions': restrictions.toJson(),
        'context': context.toJson(),
        'derived': derived.toJson(),
      };

  factory NutritionIntake.fromJson(Map<String, dynamic> j) => NutritionIntake(
        version:
            (j['version'] as num?)?.toInt() ?? kNutritionIntakeSchemaVersion,
        updatedAt:
            DateTime.tryParse(j['updatedAt'] as String? ?? '') ?? _epoch(),
        mealsPerDay: (j['mealsPerDay'] as num?)?.toInt() ?? 3,
        meals: _parseList(j['meals'], IntakeMeal.fromJson),
        snacks: _parseList(j['snacks'], IntakeSnack.fromJson),
        drinks: _parseMap(
            j['drinks'], DrinksProfile.fromJson, const DrinksProfile()),
        restrictions: _parseMap(j['restrictions'], IntakeRestrictions.fromJson,
            const IntakeRestrictions()),
        context: _parseMap(
            j['context'], IntakeContext.fromJson, const IntakeContext()),
        derived: _parseMap(
            j['derived'], DerivedTargets.fromJson, const DerivedTargets()),
      );

  static DateTime _epoch() =>
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}

// ─── Helpers de parsing permisivo ───────────────────────────────────────────

List<T> _parseList<T>(
  Object? raw,
  T Function(Map<String, dynamic>) fromJson,
) {
  if (raw is! List) return const [];
  final out = <T>[];
  for (final e in raw) {
    if (e is Map) {
      try {
        out.add(fromJson(Map<String, dynamic>.from(e)));
      } catch (_) {
        // Elemento corrupto: se salta (mismo criterio que MealPreset).
      }
    }
  }
  return List.unmodifiable(out);
}

T _parseMap<T>(
  Object? raw,
  T Function(Map<String, dynamic>) fromJson,
  T fallback,
) {
  if (raw is Map) {
    try {
      return fromJson(Map<String, dynamic>.from(raw));
    } catch (_) {
      return fallback;
    }
  }
  return fallback;
}
