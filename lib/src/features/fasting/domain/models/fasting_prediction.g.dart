// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fasting_prediction.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$FastingPredictionImpl _$$FastingPredictionImplFromJson(
        Map<String, dynamic> json) =>
    _$FastingPredictionImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      generatedAt: DateTime.parse(json['generatedAt'] as String),
      fastedHours: (json['fastedHours'] as num).toInt(),
      estimatedGlycogen: (json['estimatedGlycogen'] as num).toDouble(),
      currentFastingPhase: json['currentFastingPhase'] as String,
      currentCircadianPhase: json['currentCircadianPhase'] as String,
      optimalBreakTime: DateTime.parse(json['optimalBreakTime'] as String),
      suggestedMacroProfile: json['suggestedMacroProfile'] as String,
      glucemicResponse: json['glucemicResponse'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      minutesUntilOptimal: (json['minutesUntilOptimal'] as num).toInt(),
      macroOptions: (json['macroOptions'] as List<dynamic>)
          .map((e) => MacroOption.fromJson(e as Map<String, dynamic>))
          .toList(),
      hasBeenBroken: json['hasBeenBroken'] as bool? ?? false,
      actualBreakTime: json['actualBreakTime'] == null
          ? null
          : DateTime.parse(json['actualBreakTime'] as String),
      actualMacroChoice: json['actualMacroChoice'] as String?,
      userEnergyLevel: (json['userEnergyLevel'] as num?)?.toInt(),
      userNotes: json['userNotes'] as String?,
    );

Map<String, dynamic> _$$FastingPredictionImplToJson(
        _$FastingPredictionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'generatedAt': instance.generatedAt.toIso8601String(),
      'fastedHours': instance.fastedHours,
      'estimatedGlycogen': instance.estimatedGlycogen,
      'currentFastingPhase': instance.currentFastingPhase,
      'currentCircadianPhase': instance.currentCircadianPhase,
      'optimalBreakTime': instance.optimalBreakTime.toIso8601String(),
      'suggestedMacroProfile': instance.suggestedMacroProfile,
      'glucemicResponse': instance.glucemicResponse,
      'confidence': instance.confidence,
      'minutesUntilOptimal': instance.minutesUntilOptimal,
      'macroOptions': instance.macroOptions.map((e) => e.toJson()).toList(),
      'hasBeenBroken': instance.hasBeenBroken,
      'actualBreakTime': instance.actualBreakTime?.toIso8601String(),
      'actualMacroChoice': instance.actualMacroChoice,
      'userEnergyLevel': instance.userEnergyLevel,
      'userNotes': instance.userNotes,
    };

_$MacroOptionImpl _$$MacroOptionImplFromJson(Map<String, dynamic> json) =>
    _$MacroOptionImpl(
      profile: json['profile'] as String,
      suggestedCarbs: (json['suggestedCarbs'] as num).toDouble(),
      suggestedProtein: (json['suggestedProtein'] as num).toDouble(),
      suggestedFat: (json['suggestedFat'] as num).toDouble(),
      estimatedCalories: (json['estimatedCalories'] as num).toInt(),
      glucemicResponse: json['glucemicResponse'] as String,
      description: json['description'] as String,
      foodExamples: (json['foodExamples'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.8,
    );

Map<String, dynamic> _$$MacroOptionImplToJson(_$MacroOptionImpl instance) =>
    <String, dynamic>{
      'profile': instance.profile,
      'suggestedCarbs': instance.suggestedCarbs,
      'suggestedProtein': instance.suggestedProtein,
      'suggestedFat': instance.suggestedFat,
      'estimatedCalories': instance.estimatedCalories,
      'glucemicResponse': instance.glucemicResponse,
      'description': instance.description,
      'foodExamples': instance.foodExamples,
      'confidence': instance.confidence,
    };
