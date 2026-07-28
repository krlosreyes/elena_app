// "Mis platos frecuentes" (25-jul-2026, diferenciador de mercado — ver
// diagnóstico "Pilar Nutrición: dos métricas paralelas" §3.5).
//
// Un MealPreset es un plato que el usuario ya armó una vez y guardó
// para reutilizar sin tener que buscar/elegir cantidad de nuevo cada
// vez que come lo mismo — la brecha de fricción más grande identificada
// en la investigación de mercado (ninguna app de referencia analizada
// tenía este mecanismo para un sistema de calidad-de-plato como el de
// Elena).
//
// `foodIds` es una lista de ids de `FoodCatalog`, CON REPETICIÓN — igual
// que `PlateBuilder._items`: si el plato original tenía "2 huevos", la
// lista trae el id 'huevo' dos veces. Esto preserva la cantidad exacta
// sin necesitar un modelo separado de "cantidad por alimento"; aplicar
// el preset es simplemente `for (id in foodIds) builder.add(byId(id))`.
//
// No usa Freezed (evita build_runner) — mismo criterio que StreakEntry
// y EarnedBadge. Validación permisiva en `fromJson` (mismo criterio que
// EarnedBadge, no el más estricto de NutritionLog): un preset corrupto
// se descarta en el repositorio en vez de tumbar toda la lista.

class MealPreset {
  /// ID determinístico (UUID v4), también el ID del documento en
  /// Firestore.
  final String id;

  /// Nombre elegido por el usuario (ej. "Mi desayuno de siempre").
  /// Nunca vacío — el notifier aplica un default antes de guardar.
  final String name;

  /// Ids de `FoodCatalog`, con repetición (ver comentario de archivo).
  final List<String> foodIds;

  /// Momento en que se guardó por primera vez. No cambia después.
  final DateTime createdAt;

  /// Última vez que se aplicó este preset a un plato. Se actualiza cada
  /// vez que el usuario lo usa — permite ordenar "más reciente primero"
  /// sin necesitar un índice compuesto (orderBy de un solo campo).
  final DateTime lastUsedAt;

  /// Cuántas veces se aplicó. Informativo — no afecta ningún score.
  final int useCount;

  const MealPreset({
    required this.id,
    required this.name,
    required this.foodIds,
    required this.createdAt,
    required this.lastUsedAt,
    this.useCount = 1,
  });

  MealPreset copyWith({
    String? id,
    String? name,
    List<String>? foodIds,
    DateTime? createdAt,
    DateTime? lastUsedAt,
    int? useCount,
  }) {
    return MealPreset(
      id: id ?? this.id,
      name: name ?? this.name,
      foodIds: foodIds ?? this.foodIds,
      createdAt: createdAt ?? this.createdAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
      useCount: useCount ?? this.useCount,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'foodIds': foodIds,
        'createdAt': createdAt.toIso8601String(),
        'lastUsedAt': lastUsedAt.toIso8601String(),
        'useCount': useCount,
      };

  factory MealPreset.fromJson(Map<String, dynamic> json) {
    final rawName = (json['name'] as String?)?.trim() ?? '';
    return MealPreset(
      id: json['id'] as String? ?? '',
      name: rawName.isNotEmpty ? rawName : 'Mi plato',
      foodIds: (json['foodIds'] as List<dynamic>?)?.cast<String>() ??
          const <String>[],
      createdAt:
          DateTime.tryParse(json['createdAt'] as String? ?? '') ?? _epoch(),
      lastUsedAt:
          DateTime.tryParse(json['lastUsedAt'] as String? ?? '') ?? _epoch(),
      useCount: (json['useCount'] as num?)?.toInt() ?? 1,
    );
  }

  /// True si el preset tiene al menos un alimento — un preset vacío no
  /// tiene sentido y no debería haberse podido guardar, pero el
  /// notifier/UI lo usan como guardia defensiva antes de aplicar/mostrar.
  bool get isNotEmpty => foodIds.isNotEmpty;

  static DateTime _epoch() =>
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is MealPreset && id == other.id);

  @override
  int get hashCode => id.hashCode;
}
