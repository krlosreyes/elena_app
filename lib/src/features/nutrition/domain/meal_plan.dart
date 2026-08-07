// SPEC-271 — Modelo de la Minuta Diaria (mealPlan).
//
// Un `MealPlan` es el plan de comidas que el motor (SPEC-272) genera para
// un día, por reemplazo suave sobre el intake del usuario. Se materializa
// por día en `users/{uid}/mealPlans/{yyyy-MM-dd}` (ver
// meal_plan_repository_impl.dart) para poder marcar adherencia y auditar.
//
// SPEC-271 solo define el MODELO y su persistencia; el algoritmo que lo
// llena vive en SPEC-272 y la UI/ciclo diario en SPEC-273.
//
// No usa Freezed (mismo criterio que NutritionIntake / MealPreset). Parsing
// PERMISIVO: un campo corrupto cae a un default en vez de tumbar el doc.
// Reutiliza `MealSlot` de nutrition_intake.dart para no duplicar el enum.

import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart'
    show MealSlot;

// ─── Enums ──────────────────────────────────────────────────────────────────

/// Estado del plan en su ciclo de vida.
enum PlanStatus {
  /// Generado, aún sin interacción del usuario.
  proposed,

  /// El usuario lo vio/aceptó como su plan del día.
  accepted,

  /// Al menos una comida marcada (adherencia registrada).
  logged;

  String get wire => switch (this) {
        PlanStatus.proposed => 'proposed',
        PlanStatus.accepted => 'accepted',
        PlanStatus.logged => 'logged',
      };

  static PlanStatus fromWire(String? w) => switch (w) {
        'accepted' => PlanStatus.accepted,
        'logged' => PlanStatus.logged,
        _ => PlanStatus.proposed,
      };
}

/// Marca de adherencia por comida (el "tap" del ciclo diario, SPEC-273).
enum AdherenceMark {
  /// "Comí esto" — cumplió el plan.
  ate,

  /// "Lo cambié" — comió algo distinto (equivalente del catálogo).
  changed,

  /// "Me lo salté".
  skipped;

  String get wire => switch (this) {
        AdherenceMark.ate => 'ate',
        AdherenceMark.changed => 'changed',
        AdherenceMark.skipped => 'skipped',
      };

  static AdherenceMark? fromWire(String? w) => switch (w) {
        'ate' => AdherenceMark.ate,
        'changed' => AdherenceMark.changed,
        'skipped' => AdherenceMark.skipped,
        _ => null, // null = sin marcar todavía
      };

  /// True si la marca cuenta como cumplimiento del plan (para el score de
  /// SPEC-274). "Cambié" cuenta como cumplido (el usuario comió algo sano
  /// equivalente); "Me salté" no.
  bool get isAdherent =>
      this == AdherenceMark.ate || this == AdherenceMark.changed;
}

/// Rol del alimento dentro del plato (para pintar y para las reglas del
/// método: proteína / vegetales / grasa).
enum PlanItemRole {
  protein,
  veg,
  fat,
  other;

  String get wire => switch (this) {
        PlanItemRole.protein => 'protein',
        PlanItemRole.veg => 'veg',
        PlanItemRole.fat => 'fat',
        PlanItemRole.other => 'other',
      };

  static PlanItemRole fromWire(String? w) => switch (w) {
        'protein' => PlanItemRole.protein,
        'veg' => PlanItemRole.veg,
        'fat' => PlanItemRole.fat,
        _ => PlanItemRole.other,
      };
}

/// Porción "al ojímetro" con referencia de mano (El Milagro Metabólico:
/// nada de gramos). palma≈proteína, puño≈vegetales, pulgar≈grasa.
enum HandPortion {
  palm,
  fist,
  thumb,
  cupped,
  tablespoon;

  String get wire => switch (this) {
        HandPortion.palm => 'palm',
        HandPortion.fist => 'fist',
        HandPortion.thumb => 'thumb',
        HandPortion.cupped => 'cupped',
        HandPortion.tablespoon => 'tablespoon',
      };

  static HandPortion fromWire(String? w) => switch (w) {
        'palm' => HandPortion.palm,
        'thumb' => HandPortion.thumb,
        'cupped' => HandPortion.cupped,
        'tablespoon' => HandPortion.tablespoon,
        _ => HandPortion.fist,
      };
}

// ─── Item del plan ──────────────────────────────────────────────────────────

/// Un alimento propuesto en un plato de la minuta. `foodId` referencia
/// `FoodCatalog.all`.
class PlanItem {
  final String foodId;
  final PlanItemRole role;
  final HandPortion portion;

  const PlanItem({
    required this.foodId,
    this.role = PlanItemRole.other,
    this.portion = HandPortion.fist,
  });

  Map<String, dynamic> toJson() => {
        'foodId': foodId,
        'role': role.wire,
        'portion': portion.wire,
      };

  factory PlanItem.fromJson(Map<String, dynamic> j) => PlanItem(
        foodId: (j['foodId'] as String?)?.trim() ?? '',
        role: PlanItemRole.fromWire(j['role'] as String?),
        portion: HandPortion.fromWire(j['portion'] as String?),
      );

  @override
  bool operator ==(Object other) =>
      other is PlanItem &&
      other.foodId == foodId &&
      other.role == role &&
      other.portion == portion;

  @override
  int get hashCode => Object.hash(foodId, role, portion);
}

// ─── Comida del plan ────────────────────────────────────────────────────────

class MealPlanEntry {
  final MealSlot slot;

  /// Proteína objetivo de ESTA comida (parte del targetProteinG del día).
  final double targetProteinG;

  final List<PlanItem> items;

  /// foodIds del intake que el motor reemplazó para armar esta comida
  /// (trazabilidad del "reemplazo suave").
  final List<String> swappedFrom;

  /// Explicación humana del cambio ("cambiamos el jugo por fruta entera…").
  final String rationale;

  /// Marca de adherencia del usuario. `null` = aún sin responder.
  final AdherenceMark? adherence;

  const MealPlanEntry({
    required this.slot,
    this.targetProteinG = 0,
    this.items = const [],
    this.swappedFrom = const [],
    this.rationale = '',
    this.adherence,
  });

  MealPlanEntry copyWith({AdherenceMark? adherence, bool clearAdherence = false}) {
    return MealPlanEntry(
      slot: slot,
      targetProteinG: targetProteinG,
      items: items,
      swappedFrom: swappedFrom,
      rationale: rationale,
      adherence: clearAdherence ? null : (adherence ?? this.adherence),
    );
  }

  Map<String, dynamic> toJson() => {
        'slot': slot.wire,
        'targetProteinG': targetProteinG,
        'items': items.map((i) => i.toJson()).toList(growable: false),
        'swappedFrom': swappedFrom,
        'rationale': rationale,
        if (adherence != null) 'adherence': adherence!.wire,
      };

  factory MealPlanEntry.fromJson(Map<String, dynamic> j) => MealPlanEntry(
        slot: MealSlot.fromWire(j['slot'] as String?),
        targetProteinG: (j['targetProteinG'] as num?)?.toDouble() ?? 0,
        items: _parseList(j['items'], PlanItem.fromJson),
        swappedFrom:
            (j['swappedFrom'] as List<dynamic>?)?.cast<String>() ?? const [],
        rationale: (j['rationale'] as String?) ?? '',
        adherence: AdherenceMark.fromWire(j['adherence'] as String?),
      );
}

// ─── Plan del día ─────────────────────────────────────────────────────────

/// Versión del esquema del mealPlan.
const int kMealPlanSchemaVersion = 1;

class MealPlan {
  /// Fecha del plan en formato 'yyyy-MM-dd' (también el id del documento).
  final String date;

  final int version;

  /// Versión del intake con que se generó (para regenerar si cambia).
  final int intakeVersion;

  /// Fase de transición del reemplazo suave (1-4, ver SPEC-272 §7.1).
  final int phase;

  /// Ventana de alimentación ('HH:mm'). El plan no propone fuera de aquí.
  final String windowFirst;
  final String windowLast;

  final List<MealPlanEntry> meals;
  final PlanStatus status;
  final DateTime? generatedAt;

  const MealPlan({
    required this.date,
    this.version = kMealPlanSchemaVersion,
    this.intakeVersion = 1,
    this.phase = 1,
    this.windowFirst = '',
    this.windowLast = '',
    this.meals = const [],
    this.status = PlanStatus.proposed,
    this.generatedAt,
  });

  /// Comidas cumplidas / con marca de adherencia (para el score SPEC-274).
  int get adherentCount =>
      meals.where((m) => m.adherence?.isAdherent ?? false).length;

  int get markedCount => meals.where((m) => m.adherence != null).length;

  /// Marca la adherencia de una comida y devuelve un nuevo MealPlan
  /// (inmutable). Si no existe esa comida, retorna el mismo plan.
  MealPlan markAdherence(MealSlot slot, AdherenceMark mark) {
    var found = false;
    final updated = meals.map((m) {
      if (m.slot == slot) {
        found = true;
        return m.copyWith(adherence: mark);
      }
      return m;
    }).toList(growable: false);
    if (!found) return this;
    return copyWith(
      meals: updated,
      status: PlanStatus.logged,
    );
  }

  MealPlan copyWith({
    String? date,
    int? version,
    int? intakeVersion,
    int? phase,
    String? windowFirst,
    String? windowLast,
    List<MealPlanEntry>? meals,
    PlanStatus? status,
    DateTime? generatedAt,
  }) {
    return MealPlan(
      date: date ?? this.date,
      version: version ?? this.version,
      intakeVersion: intakeVersion ?? this.intakeVersion,
      phase: phase ?? this.phase,
      windowFirst: windowFirst ?? this.windowFirst,
      windowLast: windowLast ?? this.windowLast,
      meals: meals ?? this.meals,
      status: status ?? this.status,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'version': version,
        'generatedFrom': {'intakeVersion': intakeVersion, 'phase': phase},
        'window': {'first': windowFirst, 'last': windowLast},
        'meals': meals.map((m) => m.toJson()).toList(growable: false),
        'status': status.wire,
        if (generatedAt != null) 'generatedAt': generatedAt!.toIso8601String(),
      };

  factory MealPlan.fromJson(Map<String, dynamic> j) {
    final gf = (j['generatedFrom'] is Map)
        ? Map<String, dynamic>.from(j['generatedFrom'] as Map)
        : const <String, dynamic>{};
    final win = (j['window'] is Map)
        ? Map<String, dynamic>.from(j['window'] as Map)
        : const <String, dynamic>{};
    return MealPlan(
      date: (j['date'] as String?)?.trim() ?? '',
      version: (j['version'] as num?)?.toInt() ?? kMealPlanSchemaVersion,
      intakeVersion: (gf['intakeVersion'] as num?)?.toInt() ?? 1,
      phase: (gf['phase'] as num?)?.toInt() ?? 1,
      windowFirst: (win['first'] as String?)?.trim() ?? '',
      windowLast: (win['last'] as String?)?.trim() ?? '',
      meals: _parseList(j['meals'], MealPlanEntry.fromJson),
      status: PlanStatus.fromWire(j['status'] as String?),
      generatedAt: DateTime.tryParse(j['generatedAt'] as String? ?? ''),
    );
  }

  /// Formatea un DateTime a el id de documento 'yyyy-MM-dd' (fecha local).
  static String dateId(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

// ─── Helper de parsing permisivo ─────────────────────────────────────────────

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
        // Elemento corrupto: se salta.
      }
    }
  }
  return List.unmodifiable(out);
}
