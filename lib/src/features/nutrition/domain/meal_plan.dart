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

/// De dónde salió el alimento del plato (SPEC-276). Sirve para marcar en
/// la UI qué es tuyo, qué es una mejora sugerida y qué es un rol que te
/// faltaba. Por defecto `fromUser` (retro-compatible con planes viejos).
enum PlanItemOrigin {
  /// El usuario ya lo come (venía de su intake).
  fromUser,

  /// Mejora suave: cambiamos un alimento tuyo por una versión más sana.
  upgrade,

  /// Rol que te faltaba por completo: sugerencia nueva para probar.
  newSuggestion;

  String get wire => switch (this) {
        PlanItemOrigin.fromUser => 'from_user',
        PlanItemOrigin.upgrade => 'upgrade',
        PlanItemOrigin.newSuggestion => 'new',
      };

  static PlanItemOrigin fromWire(String? w) => switch (w) {
        'upgrade' => PlanItemOrigin.upgrade,
        'new' => PlanItemOrigin.newSuggestion,
        _ => PlanItemOrigin.fromUser, // default seguro
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

  /// SPEC-276: de dónde salió (tuyo / mejora / sugerencia nueva).
  final PlanItemOrigin origin;

  /// SPEC-293: cuántas porciones de referencia comió/comerá el usuario
  /// (p. ej. huevo ×3). Default 1. `portionLabel` es UNA porción; esto la
  /// multiplica.
  final int quantity;

  const PlanItem({
    required this.foodId,
    this.role = PlanItemRole.other,
    this.portion = HandPortion.fist,
    this.origin = PlanItemOrigin.fromUser,
    this.quantity = 1,
  });

  PlanItem copyWith({int? quantity}) => PlanItem(
        foodId: foodId,
        role: role,
        portion: portion,
        origin: origin,
        quantity: quantity ?? this.quantity,
      );

  Map<String, dynamic> toJson() => {
        'foodId': foodId,
        'role': role.wire,
        'portion': portion.wire,
        // Se omite cuando es lo normal (tuyo) para no ensuciar el doc.
        if (origin != PlanItemOrigin.fromUser) 'origin': origin.wire,
        if (quantity != 1) 'quantity': quantity,
      };

  factory PlanItem.fromJson(Map<String, dynamic> j) => PlanItem(
        foodId: (j['foodId'] as String?)?.trim() ?? '',
        role: PlanItemRole.fromWire(j['role'] as String?),
        portion: HandPortion.fromWire(j['portion'] as String?),
        origin: PlanItemOrigin.fromWire(j['origin'] as String?),
        quantity: (j['quantity'] as num?)?.toInt() ?? 1,
      );

  @override
  bool operator ==(Object other) =>
      other is PlanItem &&
      other.foodId == foodId &&
      other.role == role &&
      other.portion == portion &&
      other.origin == origin &&
      other.quantity == quantity;

  @override
  int get hashCode => Object.hash(foodId, role, portion, origin, quantity);
}

// ─── Comida del plan ────────────────────────────────────────────────────────

class MealPlanEntry {
  final MealSlot slot;

  /// Proteína objetivo de ESTA comida (parte del targetProteinG del día).
  final double targetProteinG;

  /// SPEC-284: la comida ES una receta del recetario (`RecipeCatalog`). Guarda
  /// su id para mostrar nombre + ingredientes + preparación. `null` solo en el
  /// fallback (ninguna receta encajó) o en planes viejos.
  final String? recipeId;

  final List<PlanItem> items;

  /// foodIds del intake que el motor reemplazó para armar esta comida
  /// (trazabilidad del "reemplazo suave").
  final List<String> swappedFrom;

  /// Explicación humana del cambio ("cambiamos el jugo por fruta entera…").
  final String rationale;

  /// Marca de adherencia del usuario. `null` = aún sin responder.
  final AdherenceMark? adherence;

  /// SPEC-298: hora REAL en que el usuario consumió esta comida (se sella al
  /// marcar "Comí"/"Cambié"; editable). `null` si aún no la marca o si se la
  /// saltó. Es la fuente que ancla la ventana de alimentación (pilar) y
  /// habilita la recomendación de timing circadiano.
  final DateTime? consumedAt;

  const MealPlanEntry({
    required this.slot,
    this.targetProteinG = 0,
    this.recipeId,
    this.items = const [],
    this.swappedFrom = const [],
    this.rationale = '',
    this.adherence,
    this.consumedAt,
  });

  MealPlanEntry copyWith({
    AdherenceMark? adherence,
    bool clearAdherence = false,
    DateTime? consumedAt,
    bool clearConsumedAt = false,
  }) {
    return MealPlanEntry(
      slot: slot,
      targetProteinG: targetProteinG,
      recipeId: recipeId,
      items: items,
      swappedFrom: swappedFrom,
      rationale: rationale,
      adherence: clearAdherence ? null : (adherence ?? this.adherence),
      consumedAt: clearConsumedAt ? null : (consumedAt ?? this.consumedAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'slot': slot.wire,
        'targetProteinG': targetProteinG,
        if (recipeId != null) 'recipeId': recipeId,
        'items': items.map((i) => i.toJson()).toList(growable: false),
        'swappedFrom': swappedFrom,
        'rationale': rationale,
        if (adherence != null) 'adherence': adherence!.wire,
        if (consumedAt != null) 'consumedAt': consumedAt!.toIso8601String(),
      };

  factory MealPlanEntry.fromJson(Map<String, dynamic> j) => MealPlanEntry(
        slot: MealSlot.fromWire(j['slot'] as String?),
        targetProteinG: (j['targetProteinG'] as num?)?.toDouble() ?? 0,
        recipeId: (j['recipeId'] as String?)?.trim(),
        items: _parseList(j['items'], PlanItem.fromJson),
        swappedFrom:
            (j['swappedFrom'] as List<dynamic>?)?.cast<String>() ?? const [],
        rationale: (j['rationale'] as String?) ?? '',
        adherence: AdherenceMark.fromWire(j['adherence'] as String?),
        consumedAt: DateTime.tryParse(j['consumedAt'] as String? ?? ''),
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

  /// SPEC-295: marca de tiempo (ms) del intake con el que se generó este plan.
  /// Si el intake actual es más nuevo (el usuario editó sus preferencias), el
  /// plan está OBSOLETO y hay que recalcularlo. 0 = desconocido (planes viejos).
  final int intakeStampMs;

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
    this.intakeStampMs = 0,
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
  MealPlan markAdherence(MealSlot slot, AdherenceMark mark, {DateTime? at}) {
    var found = false;
    final updated = meals.map((m) {
      if (m.slot != slot) return m;
      found = true;
      // SPEC-298: al comer/cambiar se sella la hora real (o la que pase el
      // caller); al saltarse, se limpia.
      if (mark.isAdherent) {
        return m.copyWith(
          adherence: mark,
          consumedAt: at ?? m.consumedAt ?? DateTime.now(),
        );
      }
      return m.copyWith(adherence: mark, clearConsumedAt: true);
    }).toList(growable: false);
    if (!found) return this;
    return copyWith(
      meals: updated,
      status: PlanStatus.logged,
    );
  }

  /// SPEC-298: corrige la hora de consumo de una comida (el lápiz de la UI).
  /// Inmutable; no-op si no existe la comida.
  MealPlan setConsumedAt(MealSlot slot, DateTime when) {
    var found = false;
    final updated = meals.map((m) {
      if (m.slot != slot) return m;
      found = true;
      return m.copyWith(consumedAt: when);
    }).toList(growable: false);
    if (!found) return this;
    return copyWith(meals: updated);
  }

  /// SPEC-298: primera comida REALMENTE consumida hoy (la más temprana con
  /// `consumedAt`). Es el ancla de la ventana de alimentación. `null` si aún
  /// no se ha marcado ninguna.
  DateTime? get firstConsumedAt {
    DateTime? earliest;
    for (final m in meals) {
      final t = m.consumedAt;
      if (t == null) continue;
      if (earliest == null || t.isBefore(earliest)) earliest = t;
    }
    return earliest;
  }

  /// SPEC-298: última comida consumida hoy (para el aviso de cierre circadiano).
  DateTime? get lastConsumedAt {
    DateTime? latest;
    for (final m in meals) {
      final t = m.consumedAt;
      if (t == null) continue;
      if (latest == null || t.isAfter(latest)) latest = t;
    }
    return latest;
  }

  /// SPEC-280: reemplaza un alimento del plato por otro que elige el usuario
  /// (en la misma comida). Inmutable; si no encuentra el alimento, devuelve
  /// el mismo plan.
  MealPlan replaceItem(MealSlot slot, String oldFoodId, PlanItem newItem) {
    var changed = false;
    final updated = meals.map((m) {
      if (m.slot != slot) return m;
      final items = m.items.map((it) {
        if (it.foodId == oldFoodId) {
          changed = true;
          return newItem;
        }
        return it;
      }).toList(growable: false);
      return MealPlanEntry(
        slot: m.slot,
        targetProteinG: m.targetProteinG,
        recipeId: m.recipeId,
        items: items,
        swappedFrom: m.swappedFrom,
        rationale: m.rationale,
        adherence: m.adherence,
        consumedAt: m.consumedAt,
      );
    }).toList(growable: false);
    if (!changed) return this;
    return copyWith(meals: updated);
  }

  /// SPEC-284: cambia el PLATO completo de una comida por otra receta que el
  /// usuario elige. Reemplaza `recipeId` + `items` y limpia la adherencia
  /// (es un plato distinto). Inmutable; si no existe la comida, mismo plan.
  MealPlan setMealRecipe(
    MealSlot slot,
    String recipeId,
    List<PlanItem> items, {
    String rationale = '',
  }) {
    var found = false;
    final updated = meals.map((m) {
      if (m.slot != slot) return m;
      found = true;
      return MealPlanEntry(
        slot: m.slot,
        targetProteinG: m.targetProteinG,
        recipeId: recipeId,
        items: items,
        swappedFrom: m.swappedFrom,
        rationale: rationale.isEmpty ? m.rationale : rationale,
        adherence: null,
      );
    }).toList(growable: false);
    if (!found) return this;
    return copyWith(meals: updated);
  }

  /// SPEC-293: fija la cantidad (porciones) de un alimento de una comida
  /// (ej. huevo ×3). Se acota a >= 1. Inmutable; no-op si no cambia.
  MealPlan setItemQuantity(MealSlot slot, String foodId, int quantity) {
    final q = quantity < 1 ? 1 : quantity;
    var changed = false;
    final updated = meals.map((m) {
      if (m.slot != slot) return m;
      final items = m.items.map((it) {
        if (it.foodId != foodId || it.quantity == q) return it;
        changed = true;
        return it.copyWith(quantity: q);
      }).toList(growable: false);
      return MealPlanEntry(
        slot: m.slot,
        targetProteinG: m.targetProteinG,
        recipeId: m.recipeId,
        items: items,
        swappedFrom: m.swappedFrom,
        rationale: m.rationale,
        adherence: m.adherence,
        consumedAt: m.consumedAt,
      );
    }).toList(growable: false);
    if (!changed) return this;
    return copyWith(meals: updated);
  }

  /// SPEC-292: quita un alimento de una comida (Delete del CRUD por
  /// ingrediente). Inmutable; si no existe la comida o el alimento, devuelve
  /// el mismo plan.
  MealPlan removeItem(MealSlot slot, String foodId) {
    var changed = false;
    final updated = meals.map((m) {
      if (m.slot != slot) return m;
      final items =
          m.items.where((it) => it.foodId != foodId).toList(growable: false);
      if (items.length == m.items.length) return m;
      changed = true;
      return MealPlanEntry(
        slot: m.slot,
        targetProteinG: m.targetProteinG,
        recipeId: m.recipeId,
        items: items,
        swappedFrom: m.swappedFrom,
        rationale: m.rationale,
        adherence: m.adherence,
        consumedAt: m.consumedAt,
      );
    }).toList(growable: false);
    if (!changed) return this;
    return copyWith(meals: updated);
  }

  /// SPEC-287: agrega un alimento que no estaba en la comida (extra del
  /// usuario). Inmutable; evita duplicar por foodId. Si no existe la comida
  /// o el alimento ya está, devuelve el mismo plan.
  MealPlan addItem(MealSlot slot, PlanItem item) {
    var changed = false;
    final updated = meals.map((m) {
      if (m.slot != slot) return m;
      if (m.items.any((it) => it.foodId == item.foodId)) return m;
      changed = true;
      return MealPlanEntry(
        slot: m.slot,
        targetProteinG: m.targetProteinG,
        recipeId: m.recipeId,
        items: [...m.items, item],
        swappedFrom: m.swappedFrom,
        rationale: m.rationale,
        adherence: m.adherence,
        consumedAt: m.consumedAt,
      );
    }).toList(growable: false);
    if (!changed) return this;
    return copyWith(meals: updated);
  }

  MealPlan copyWith({
    String? date,
    int? version,
    int? intakeVersion,
    int? intakeStampMs,
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
      intakeStampMs: intakeStampMs ?? this.intakeStampMs,
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
        'generatedFrom': {
          'intakeVersion': intakeVersion,
          'intakeStampMs': intakeStampMs,
          'phase': phase,
        },
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
      intakeStampMs: (gf['intakeStampMs'] as num?)?.toInt() ?? 0,
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
