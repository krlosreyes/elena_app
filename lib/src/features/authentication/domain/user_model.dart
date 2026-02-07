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

  factory AppUser.fromJson(Map<String, dynamic> json) => _$AppUserFromJson(json);
}

/// Medical and physiological profile of the user.
///
/// Contains critical metrics for the metabolic engine.
@freezed
class MedicalProfile with _$MedicalProfile {
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

  factory MedicalProfile.fromJson(Map<String, dynamic> json) => _$MedicalProfileFromJson(json);
}
