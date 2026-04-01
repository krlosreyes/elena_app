/// ✅ USER FOOD PREFERENCES (Manual Data Object)
///
/// We avoid generators for environmental compatibility.
class UserFoodPreferences {
  final List<String> proteins;
  final List<String> fats;
  final List<String> carbs;
  final List<String> vegetables;

  const UserFoodPreferences({
    this.proteins = const [],
    this.fats = const [],
    this.carbs = const [],
    this.vegetables = const [],
  });

  factory UserFoodPreferences.fromJson(Map<String, dynamic> json) {
    return UserFoodPreferences(
      proteins: List<String>.from(json['proteins'] ?? []),
      fats: List<String>.from(json['fats'] ?? []),
      carbs: List<String>.from(json['carbs'] ?? []),
      vegetables: List<String>.from(json['vegetables'] ?? []),
    );
  }

  UserFoodPreferences copyWith({
    List<String>? proteins,
    List<String>? fats,
    List<String>? carbs,
    List<String>? vegetables,
  }) {
    return UserFoodPreferences(
      proteins: proteins ?? this.proteins,
      fats: fats ?? this.fats,
      carbs: carbs ?? this.carbs,
      vegetables: vegetables ?? this.vegetables,
    );
  }

  Map<String, dynamic> toJson() => {
        'proteins': proteins,
        'fats': fats,
        'carbs': carbs,
        'vegetables': vegetables,
      };

  List<String> get allSelectedIds =>
      [...proteins, ...fats, ...carbs, ...vegetables];

  factory UserFoodPreferences.empty() => const UserFoodPreferences();
}
