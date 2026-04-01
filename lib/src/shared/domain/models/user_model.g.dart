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
      name: _readName(json, 'name') as String? ?? '',
      photoUrl: json['photoUrl'] as String?,
      gender:
          $enumDecodeNullable(_$GenderEnumMap, json['gender']) ?? Gender.female,
      birthDate: const OptionalTimestampConverter().fromJson(json['birthDate']),
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 165.0,
      currentWeightKg: (json['currentWeightKg'] as num?)?.toDouble() ?? 65.0,
      waistCircumferenceCm: (json['waistCircumferenceCm'] as num?)?.toDouble(),
      neckCircumferenceCm: (json['neckCircumferenceCm'] as num?)?.toDouble(),
      hipCircumferenceCm: (json['hipCircumferenceCm'] as num?)?.toDouble(),
      pathologies: (json['pathologies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      activityLevel: $enumDecodeNullable(_$ActivityLevelEnumMap,
              _readActivityLevel(json, 'activityLevel')) ??
          ActivityLevel.sedentary,
      physicalLimitations: (json['physicalLimitations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      snackingHabit:
          $enumDecodeNullable(_$SnackingHabitEnumMap, json['snackingHabit']) ??
              SnackingHabit.sometimes,
      dietaryPreference: $enumDecodeNullable(
              _$DietaryPreferenceEnumMap, json['dietaryPreference']) ??
          DietaryPreference.omnivore,
      hasDumbbells: json['hasDumbbells'] as bool? ?? false,
      workoutDays: (json['workoutDays'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [1, 3, 5],
      lastHighIntensityWorkoutAt: const OptionalTimestampConverter()
          .fromJson(json['lastHighIntensityWorkoutAt']),
      wakeUpTime: json['wakeUpTime'] as String?,
      bedTime: json['bedTime'] as String?,
      usualFirstMealTime: json['usualFirstMealTime'] as String?,
      usualLastMealTime: json['usualLastMealTime'] as String?,
      fastingExperience: $enumDecodeNullable(
              _$FastingExperienceEnumMap, json['fastingExperience']) ??
          FastingExperience.beginner,
      recommendedProtocol: json['recommendedProtocol'] as String?,
      healthGoal: $enumDecodeNullable(_$HealthGoalEnumMap, json['healthGoal']),
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      startWeightKg: (json['startWeightKg'] as num?)?.toDouble(),
      targetFatPercentage: (json['targetFatPercentage'] as num?)?.toDouble(),
      targetLBM: (json['targetLBM'] as num?)?.toDouble(),
      checkInDay: (json['checkInDay'] as num?)?.toInt(),
      averageSleepHours: (json['averageSleepHours'] as num?)?.toDouble(),
      energyLevel1To10: (json['energyLevel1To10'] as num?)?.toInt(),
      metaICA: (json['metaICA'] as num?)?.toDouble(),
      metaICC: (json['metaICC'] as num?)?.toDouble(),
      numberOfMeals: (json['numberOfMeals'] as num?)?.toInt() ?? 2,
      onboardingCompleted: json['onboardingCompleted'] as bool? ?? false,
      hasCompletedTour: json['hasCompletedTour'] as bool? ?? false,
      createdAt: const OptionalTimestampConverter().fromJson(json['createdAt']),
      updatedAt: const OptionalTimestampConverter().fromJson(json['updatedAt']),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'uid': instance.uid,
      'email': instance.email,
      'displayName': instance.displayName,
      'name': instance.name,
      'photoUrl': instance.photoUrl,
      'gender': _$GenderEnumMap[instance.gender]!,
      'birthDate':
          const OptionalTimestampConverter().toJson(instance.birthDate),
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
      'hasDumbbells': instance.hasDumbbells,
      'workoutDays': instance.workoutDays,
      'lastHighIntensityWorkoutAt': const OptionalTimestampConverter()
          .toJson(instance.lastHighIntensityWorkoutAt),
      'wakeUpTime': instance.wakeUpTime,
      'bedTime': instance.bedTime,
      'usualFirstMealTime': instance.usualFirstMealTime,
      'usualLastMealTime': instance.usualLastMealTime,
      'fastingExperience':
          _$FastingExperienceEnumMap[instance.fastingExperience]!,
      'recommendedProtocol': instance.recommendedProtocol,
      'healthGoal': _$HealthGoalEnumMap[instance.healthGoal],
      'targetWeightKg': instance.targetWeightKg,
      'startWeightKg': instance.startWeightKg,
      'targetFatPercentage': instance.targetFatPercentage,
      'targetLBM': instance.targetLBM,
      'checkInDay': instance.checkInDay,
      'averageSleepHours': instance.averageSleepHours,
      'energyLevel1To10': instance.energyLevel1To10,
      'metaICA': instance.metaICA,
      'metaICC': instance.metaICC,
      'numberOfMeals': instance.numberOfMeals,
      'onboardingCompleted': instance.onboardingCompleted,
      'hasCompletedTour': instance.hasCompletedTour,
      'createdAt':
          const OptionalTimestampConverter().toJson(instance.createdAt),
      'updatedAt':
          const OptionalTimestampConverter().toJson(instance.updatedAt),
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
  DietaryPreference.lowCarb: 'lowCarb',
};

const _$FastingExperienceEnumMap = {
  FastingExperience.beginner: 'beginner',
  FastingExperience.intermediate: 'intermediate',
  FastingExperience.advanced: 'advanced',
};

const _$HealthGoalEnumMap = {
  HealthGoal.fatLoss: 'fatLoss',
  HealthGoal.muscleGain: 'muscleGain',
  HealthGoal.metabolicHealth: 'metabolicHealth',
};
