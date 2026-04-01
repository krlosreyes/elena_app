import '../../../core/converters/timestamp_converter.dart';

enum MealType { breakfast, lunch, dinner, snack, other }

/// ✅ MEAL LOG (Manual Data Transfer Object)
///
/// Evitamos depender de generators por problemas de permisos en el entorno SDK,
/// definiendo el modelo manualmente para un flujo de desarrollo ágil.
class MealLog {
  final String id;
  final String userId;
  final String name;
  final MealType type;
  final int calories;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final DateTime timestamp;

  MealLog({
    required this.id,
    required this.userId,
    required this.name,
    required this.type,
    required this.calories,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.timestamp,
  });

  factory MealLog.fromJson(Map<String, dynamic> json) {
    return MealLog(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      type: _parseMealType(json['type'] as String?),
      calories: json['calories'] as int? ?? 0,
      proteinGrams: json['proteinGrams'] as int? ?? 0,
      carbsGrams: json['carbsGrams'] as int? ?? 0,
      fatGrams: json['fatGrams'] as int? ?? 0,
      timestamp: json['timestamp'] != null
          ? const TimestampConverter().fromJson(json['timestamp'])
          : DateTime.now(),
    );
  }

  static MealType _parseMealType(String? type) {
    if (type == null) return MealType.other;
    return MealType.values.firstWhere(
      (e) => e.name == type.toLowerCase(),
      orElse: () => MealType.other,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'name': name,
      'type': type.name,
      'calories': calories,
      'proteinGrams': proteinGrams,
      'carbsGrams': carbsGrams,
      'fatGrams': fatGrams,
      'timestamp': const TimestampConverter().toJson(timestamp),
    };
  }
}
