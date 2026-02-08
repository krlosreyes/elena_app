// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      gender: $enumDecode(_$GenderEnumMap, json['gender']),
      birthDate: DateTime.parse(json['birthDate'] as String),
      heightCm: (json['heightCm'] as num).toDouble(),
      currentWeightKg: (json['currentWeightKg'] as num).toDouble(),
      waistCircumferenceCm: (json['waistCircumferenceCm'] as num).toDouble(),
      neckCircumferenceCm: (json['neckCircumferenceCm'] as num).toDouble(),
      hipCircumferenceCm: (json['hipCircumferenceCm'] as num?)?.toDouble(),
      pathologies: (json['pathologies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      activityLevel: $enumDecode(_$ActivityLevelEnumMap, json['activityLevel']),
      physicalLimitations: (json['physicalLimitations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      snackingHabit: $enumDecode(_$SnackingHabitEnumMap, json['snackingHabit']),
      dietaryPreference:
          $enumDecode(_$DietaryPreferenceEnumMap, json['dietaryPreference']),
      wakeUpTime: json['wakeUpTime'] as String,
      bedTime: json['bedTime'] as String,
      usualFirstMealTime: json['usualFirstMealTime'] as String,
      usualLastMealTime: json['usualLastMealTime'] as String,
      fastingExperience: $enumDecodeNullable(
              _$FastingExperienceEnumMap, json['fastingExperience']) ??
          FastingExperience.beginner,
      recommendedProtocol: json['recommendedProtocol'] as String?,
      healthGoal: $enumDecodeNullable(_$HealthGoalEnumMap, json['healthGoal']),
      checkInDay: (json['checkInDay'] as num?)?.toInt(),
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'displayName': instance.displayName,
      'photoUrl': instance.photoUrl,
      'gender': _$GenderEnumMap[instance.gender]!,
      'birthDate': instance.birthDate.toIso8601String(),
      'heightCm': instance.heightCm,
      'currentWeightKg': instance.currentWeightKg,
      'waistCircumferenceCm': instance.waistCircumferenceCm,
      'neckCircumferenceCm': instance.neckCircumferenceCm,
      'hipCircumferenceCm': instance.hipCircumferenceCm,
      'pathologies': instance.pathologies,
      'activityLevel': _$ActivityLevelEnumMap[instance.activityLevel]!,
      'physicalLimitations': instance.physicalLimitations,
      'snackingHabit': _$SnackingHabitEnumMap[instance.snackingHabit]!,
      'dietaryPreference':
          _$DietaryPreferenceEnumMap[instance.dietaryPreference]!,
      'wakeUpTime': instance.wakeUpTime,
      'bedTime': instance.bedTime,
      'usualFirstMealTime': instance.usualFirstMealTime,
      'usualLastMealTime': instance.usualLastMealTime,
      'fastingExperience':
          _$FastingExperienceEnumMap[instance.fastingExperience]!,
      'recommendedProtocol': instance.recommendedProtocol,
      'healthGoal': _$HealthGoalEnumMap[instance.healthGoal],
      'checkInDay': instance.checkInDay,
      'onboardingCompleted': instance.onboardingCompleted,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };

const _$GenderEnumMap = {
  Gender.male: 'male',
  Gender.female: 'female',
};

const _$ActivityLevelEnumMap = {
  ActivityLevel.sedentary: 'sedentary',
  ActivityLevel.light: 'light',
  ActivityLevel.moderate: 'moderate',
  ActivityLevel.heavy: 'heavy',
};

const _$SnackingHabitEnumMap = {
  SnackingHabit.never: 'never',
  SnackingHabit.sometimes: 'sometimes',
  SnackingHabit.frequent: 'frequent',
};

const _$DietaryPreferenceEnumMap = {
  DietaryPreference.omnivore: 'omnivore',
  DietaryPreference.keto: 'keto',
  DietaryPreference.vegan: 'vegan',
  DietaryPreference.low_carb: 'low_carb',
};

const _$FastingExperienceEnumMap = {
  FastingExperience.beginner: 'beginner',
  FastingExperience.intermediate: 'intermediate',
  FastingExperience.advanced: 'advanced',
};

const _$HealthGoalEnumMap = {
  HealthGoal.fat_loss: 'fat_loss',
  HealthGoal.muscle_gain: 'muscle_gain',
  HealthGoal.metabolic_health: 'metabolic_health',
};
