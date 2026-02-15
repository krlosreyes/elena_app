import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

enum Gender { male, female }

enum ActivityLevel { sedentary, light, moderate, heavy }

enum SnackingHabit { never, sometimes, frequent }

enum DietaryPreference { omnivore, keto, vegan, low_carb }

enum FastingExperience { beginner, intermediate, advanced }

enum HealthGoal { fat_loss, muscle_gain, metabolic_health }

@freezed
class UserModel with _$UserModel {
  const UserModel._();

  const factory UserModel({
    // 1. Identificación
    required String uid,
    required String email,
    required String displayName,
    @Default('') @JsonKey(readValue: _readName) String name, // <--- Added name field with custom reader
    String? photoUrl,
    required Gender gender,
    required DateTime birthDate,

    // 2. Antropometría
    required double heightCm,
    required double currentWeightKg,
    required double waistCircumferenceCm,
    required double neckCircumferenceCm,
    double? hipCircumferenceCm,

    // 3. Perfil Clínico & Hábitos
    @Default([]) List<String> pathologies,
    required ActivityLevel activityLevel,
    @Default([]) List<String> physicalLimitations,
    required SnackingHabit snackingHabit,
    required DietaryPreference dietaryPreference,

    // 4. Cronobiología (Guardado como String 'HH:mm')
    required String wakeUpTime,
    required String bedTime,
    required String usualFirstMealTime,
    required String usualLastMealTime,

    // 5. Estado del Ayuno (Calculado)
    @Default(FastingExperience.beginner) FastingExperience fastingExperience,
    String? recommendedProtocol,
    HealthGoal? healthGoal,
    
    // Goals & Progress
    double? targetWeightKg,
    double? startWeightKg,
    double? targetFatPercentage, // <--- New field
    double? targetLBM,           // <--- New field
    
    // Configuración
    int? checkInDay, // 1 = Lunes, 7 = Domingo

    // Metadata
    @Default(false) bool onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  // Helper getter for age
  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month || (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}

// Custom reader for the name field
Object? _readName(Map<dynamic, dynamic> json, String key) {
  String? name = json['name'] as String? ?? json['fullName'] as String? ?? json['nombre'] as String?;
  
  if (name != null && name.isNotEmpty) {
    return name;
  }

  final email = json['email'] as String?;
  if (email != null && email.contains('@')) {
     String extracted = email.split('@')[0];
     if (extracted.isNotEmpty) {
       return extracted[0].toUpperCase() + extracted.substring(1);
     }
  }
  
  return '';
}

extension UserModelX on UserModel {
  bool get shouldTrackGlucose {
    if (pathologies.isEmpty) return false;

    // Palabras clave que activan el módulo
    final keywords = ['diabet', 'gluc', 'azucar', 'insulin', 'pre-diabet'];

    return pathologies.any((condition) {
      final c = condition.toLowerCase();
      return keywords.any((k) => c.contains(k));
    });
  }
}
