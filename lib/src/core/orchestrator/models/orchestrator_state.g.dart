// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'orchestrator_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$OrchestratorStateImpl _$$OrchestratorStateImplFromJson(
        Map<String, dynamic> json) =>
    _$OrchestratorStateImpl(
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      currentFastingPhase: json['currentFastingPhase'] as String,
      currentCircadianPhase: json['currentCircadianPhase'] as String,
      fastedHours: (json['fastedHours'] as num).toDouble(),
      canExerciseNow: json['canExerciseNow'] as bool,
      canEatNow: json['canEatNow'] as bool,
      exerciseRecommendedType: json['exerciseRecommendedType'] as String?,
      exerciseRecommendedIntensity:
          (json['exerciseRecommendedIntensity'] as num?)?.toInt() ?? 0,
      isOptimalForFasting: json['isOptimalForFasting'] as bool,
      metabolicCoherence: (json['metabolicCoherence'] as num).toDouble(),
      activeSyncViolations: (json['activeSyncViolations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      primaryActionSuggestion: json['primaryActionSuggestion'] as String?,
      syncMetrics: (json['syncMetrics'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as num).toDouble()),
          ) ??
          const {},
      exerciseSafetyMultiplier:
          (json['exerciseSafetyMultiplier'] as num?)?.toDouble() ?? 1.0,
      nutritionPhaseMultiplier:
          (json['nutritionPhaseMultiplier'] as num?)?.toDouble() ?? 1.0,
      hoursSinceLastMeal: (json['hoursSinceLastMeal'] as num).toDouble(),
      minutesToWindowClose: (json['minutesToWindowClose'] as num?)?.toInt(),
      sleepRecoveryScore:
          (json['sleepRecoveryScore'] as num?)?.toDouble() ?? 0.5,
    );

Map<String, dynamic> _$$OrchestratorStateImplToJson(
        _$OrchestratorStateImpl instance) =>
    <String, dynamic>{
      'lastUpdated': instance.lastUpdated.toIso8601String(),
      'currentFastingPhase': instance.currentFastingPhase,
      'currentCircadianPhase': instance.currentCircadianPhase,
      'fastedHours': instance.fastedHours,
      'canExerciseNow': instance.canExerciseNow,
      'canEatNow': instance.canEatNow,
      'exerciseRecommendedType': instance.exerciseRecommendedType,
      'exerciseRecommendedIntensity': instance.exerciseRecommendedIntensity,
      'isOptimalForFasting': instance.isOptimalForFasting,
      'metabolicCoherence': instance.metabolicCoherence,
      'activeSyncViolations': instance.activeSyncViolations,
      'primaryActionSuggestion': instance.primaryActionSuggestion,
      'syncMetrics': instance.syncMetrics,
      'exerciseSafetyMultiplier': instance.exerciseSafetyMultiplier,
      'nutritionPhaseMultiplier': instance.nutritionPhaseMultiplier,
      'hoursSinceLastMeal': instance.hoursSinceLastMeal,
      'minutesToWindowClose': instance.minutesToWindowClose,
      'sleepRecoveryScore': instance.sleepRecoveryScore,
    };
