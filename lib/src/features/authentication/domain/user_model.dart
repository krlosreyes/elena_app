import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

/// Represents the metabolic stage of the user.
enum MetabolicStage {
  recovery,
  recomposition,
  longevity,
}

/// Represents the user's physical activity level.
enum ActivityLevel {
  sedentary,
  active,
  athlete,
}

/// Represents biological sex for physiological calculations.
enum Gender {
  male,
  female,
}

/// Core user entity for the application.
@freezed
class AppUser with _$AppUser {
  const factory AppUser({
    required String uid,
    required String email,
    required String displayName,
    @Default(false) bool onboardingCompleted,
  }) = _AppUser;

  factory AppUser.fromJson(Map<String, dynamic> json) =>
      _$AppUserFromJson(json);
}

/// Medical and physiological profile of the user.
///
/// Contains critical metrics for the metabolic engine.
@freezed
class MedicalProfile with _$MedicalProfile {
  // ✅ Validación de Dominio: Evita inconsistencias matemáticas y físicas
  // antes de que entren al Motor IMX y base de datos.
  @Assert('heightCm >= 50 && heightCm <= 250', 'La altura debe estar entre 50 y 250cm.')
  @Assert('startWeightKg >= 20 && startWeightKg <= 350', 'El peso inicial debe estar entre 20kg y 350kg.')
  @Assert('currentWeightKg >= 20 && currentWeightKg <= 350', 'El peso actual debe estar entre 20kg y 350kg.')
  @Assert('waistCircumferenceCm >= 30 && waistCircumferenceCm <= 250', 'La circunferencia es ilógica (<30cm o >250cm).')
  const factory MedicalProfile({
    required DateTime birthDate,
    required double heightCm,
    required double startWeightKg,
    required double currentWeightKg,

    /// Critical metric for cardiovascular risk assessment.
    required double waistCircumferenceCm,
    @Default(false) bool hasPrediabetes,
    double? targetWeightKg,
    @Default(MetabolicStage.recovery) MetabolicStage metabolicStage,
    @Default(ActivityLevel.sedentary) ActivityLevel activityLevel,
    @Default(Gender.female) Gender gender,
  }) = _MedicalProfile;

  factory MedicalProfile.fromJson(Map<String, dynamic> json) =>
      _$MedicalProfileFromJson(json);
}
