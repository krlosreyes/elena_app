import 'dart:math' as math;
import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/converters/timestamp_converter.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

enum Gender { male, female }

enum ActivityLevel { sedentary, light, moderate, heavy }

enum SnackingHabit { never, sometimes, frequent }

enum DietaryPreference { omnivore, keto, vegan, lowCarb }

enum FastingExperience { beginner, intermediate, advanced }

enum HealthGoal { fatLoss, muscleGain, metabolicHealth }

enum TypographyStyle { technical, human }

@freezed
class UserModel with _$UserModel {
  const UserModel._();

  @Assert('heightCm >= 50 && heightCm <= 250',
      'La altura debe estar entre 50 y 250cm.')
  @Assert('currentWeightKg >= 20 && currentWeightKg <= 350',
      'El peso actual debe estar entre 20kg y 350kg.')
  @Assert(
      'waistCircumferenceCm == null || (waistCircumferenceCm >= 30 && waistCircumferenceCm <= 250)',
      'La circunferencia de cintura es ilógica.')
  const factory UserModel({
    // 1. Identificación
    required String uid,
    required String email,
    required String displayName,
    @Default('') @JsonKey(readValue: _readName) String name,
    String? photoUrl,
    @Default(Gender.female) Gender gender,
    @OptionalTimestampConverter() DateTime? birthDate,

    // 2. Antropometría
    @Default(165.0) double heightCm,
    @Default(65.0) double currentWeightKg,
    double? waistCircumferenceCm,
    double? neckCircumferenceCm,
    double? hipCircumferenceCm,

    // 3. Perfil Clínico & Hábitos
    @Default([]) List<String> pathologies,
    @Default(ActivityLevel.sedentary)
    @JsonKey(readValue: _readActivityLevel)
    ActivityLevel activityLevel,
    @Default([]) List<String> physicalLimitations,
    @Default(SnackingHabit.sometimes) SnackingHabit snackingHabit,
    @Default(DietaryPreference.omnivore) DietaryPreference dietaryPreference,
    @Default(false) bool hasDumbbells,
    @Default([1, 3, 5]) List<int> workoutDays,
    @OptionalTimestampConverter() DateTime? lastHighIntensityWorkoutAt,

    // 4. Cronobiología
    String? wakeUpTime, // target_wake_time
    String? bedTime, // target_sleep_time
    String? usualFirstMealTime,
    String? usualLastMealTime,

    // 5. Estado & Objetivos
    @Default(FastingExperience.beginner) FastingExperience fastingExperience,
    String? recommendedProtocol,
    HealthGoal? healthGoal,

    // Goals & Progress
    double? targetWeightKg,
    double? startWeightKg,
    double? targetFatPercentage,
    double? targetLBM,

    // Configuración
    int? checkInDay,

    // IMX Specific Overrides
    double? averageSleepHours,
    int? energyLevel1To10,

    // Legacy / Calculated (Can be stored or calculated)
    double? metaICA,
    double? metaICC,

    @Default(2) int numberOfMeals,

    // Metadata
    @Default(false) bool onboardingCompleted,
    @Default(false) bool hasCompletedTour,
    @OptionalTimestampConverter() DateTime? createdAt,
    @OptionalTimestampConverter() DateTime? updatedAt,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);

  // Helper getter for age
  int get age {
    final date = birthDate;
    if (date == null) return 30; // Default age if missing
    final now = DateTime.now();
    int age = now.year - date.year;
    if (now.month < date.month ||
        (now.month == date.month && now.day < date.day)) {
      age--;
    }
    return age;
  }

  static UserModel empty() {
    return UserModel(
      uid: '',
      email: '',
      displayName: '',
      gender: Gender.female,
      birthDate: DateTime(1990, 1, 1),
      heightCm: 165.0,
      currentWeightKg: 65.0,
      waistCircumferenceCm: 80.0,
      hipCircumferenceCm: 100.0,
      activityLevel: ActivityLevel.sedentary,
      snackingHabit: SnackingHabit.sometimes,
      dietaryPreference: DietaryPreference.omnivore,
      wakeUpTime: '07:00',
      bedTime: '23:00',
      usualFirstMealTime: '08:00',
      usualLastMealTime: '20:00',
    );
  }
}

// Custom reader for the name field
Object? _readName(Map<dynamic, dynamic> json, String key) {
  String? name = json['name'] as String? ??
      json['fullName'] as String? ??
      json['nombre'] as String?;

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

// Custom reader for ActivityLevel (supports Spanish values)
Object? _readActivityLevel(Map<dynamic, dynamic> json, String key) {
  final value = json[key]?.toString().toLowerCase();
  if (value == null) return null;

  if (value == 'sedentario' || value == 'sedentary') return 'sedentary';
  if (value == 'ligero' || value == 'light') return 'light';
  if (value == 'moderado' || value == 'moderate') return 'moderate';
  if (value == 'pesado' || value == 'heavy') return 'heavy';

  return value;
}

extension UserModelX on UserModel {
  bool get shouldTrackGlucose {
    if (pathologies.isEmpty) return false;
    final keywords = ['diabet', 'gluc', 'azucar', 'insulin', 'pre-diabet'];
    return pathologies.any((condition) {
      final c = condition.toLowerCase();
      return keywords.any((k) => c.contains(k));
    });
  }

  TypographyStyle get typographyStyle => TypographyStyle.technical;

  /// Estimated body fat % using the US Navy formula.
  /// Falls back to a BMI-based estimate when circumference data is absent.
  double? get currentFatPercentage {
    final waist = waistCircumferenceCm;
    final neck = neckCircumferenceCm;
    final height = heightCm;

    if (waist != null && neck != null && height > 0) {
      if (gender == Gender.female) {
        final hip = hipCircumferenceCm;
        if (hip != null) {
          // Female: 163.205 × log10(waist + hip − neck) − 97.684 × log10(height) − 78.387
          final val = 163.205 * math.log(waist + hip - neck) / math.ln10
              - 97.684 * math.log(height) / math.ln10
              - 78.387;
          return val.clamp(5.0, 50.0);
        }
      } else {
        // Male: 86.010 × log10(waist − neck) − 70.041 × log10(height) + 36.76
        if (waist > neck) {
          final val = 86.010 * math.log(waist - neck) / math.ln10
              - 70.041 * math.log(height) / math.ln10
              + 36.76;
          return val.clamp(5.0, 50.0);
        }
      }
    }

    // BMI-based fallback (Deurenberg equation)
    if (height > 0) {
      final bmi = currentWeightKg / math.pow(height / 100.0, 2);
      final ageYears = age.toDouble();
      final sexFactor = gender == Gender.male ? 1.0 : 0.0;
      // BF% = (1.20 × BMI) + (0.23 × age) − (10.8 × sex) − 5.4
      final val = (1.20 * bmi) + (0.23 * ageYears) - (10.8 * sexFactor) - 5.4;
      return val.clamp(5.0, 50.0);
    }

    return null;
  }
}
