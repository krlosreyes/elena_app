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
  const factory UserModel({
    // 1. Identificación
    required String uid,
    required String email,
    required String displayName,
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
    
    // Configuración
    int? checkInDay, // 1 = Lunes, 7 = Domingo

    // Metadata
    @Default(false) bool onboardingCompleted,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}
