// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UserModelImpl _$$UserModelImplFromJson(Map<String, dynamic> json) =>
    _$UserModelImpl(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Usuario',
      age: (json['age'] as num).toInt(),
      gender: json['gender'] as String,
      weight: (json['weight'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      waistCircumference: (json['waistCircumference'] as num?)?.toDouble(),
      neckCircumference: (json['neckCircumference'] as num?)?.toDouble(),
      bodyFatPercentage:
          (json['bodyFatPercentage'] as num?)?.toDouble() ?? 20.0,
      pantSize: (json['pantSize'] as num?)?.toInt() ?? 30,
      shirtSize: json['shirtSize'] as String? ?? 'M',
      isMeasurementEstimated: json['isMeasurementEstimated'] as bool? ?? true,
      imrStdDev: (json['imrStdDev'] as num?)?.toDouble() ?? 0.0,
      confidenceLevel: json['confidenceLevel'] as String? ?? 'BAJA',
      mealsPerDay: (json['mealsPerDay'] as num?)?.toInt() ?? 3,
      fastingProtocol: json['fastingProtocol'] as String? ?? 'Ninguno',
      pathologies: (json['pathologies'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const ['Ninguna'],
      activityLevel: (json['activityLevel'] as num?)?.toDouble() ?? 1.2,
      weeklyAdherence: (json['weeklyAdherence'] as num?)?.toDouble() ?? 0.85,
      exerciseGoalMinutes: (json['exerciseGoalMinutes'] as num?)?.toInt() ?? 20,
      healthDisclaimerAccepted:
          json['healthDisclaimerAccepted'] as bool? ?? false,
      healthDisclaimerAcceptedAt: const OptionalTimestampConverter()
          .fromJson(json['healthDisclaimerAcceptedAt']),
      healthDisclaimerVersion:
          (json['healthDisclaimerVersion'] as num?)?.toInt() ?? 0,
      profile:
          CircadianProfile.fromJson(json['profile'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$UserModelImplToJson(_$UserModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'age': instance.age,
      'gender': instance.gender,
      'weight': instance.weight,
      'height': instance.height,
      'waistCircumference': instance.waistCircumference,
      'neckCircumference': instance.neckCircumference,
      'bodyFatPercentage': instance.bodyFatPercentage,
      'pantSize': instance.pantSize,
      'shirtSize': instance.shirtSize,
      'isMeasurementEstimated': instance.isMeasurementEstimated,
      'imrStdDev': instance.imrStdDev,
      'confidenceLevel': instance.confidenceLevel,
      'mealsPerDay': instance.mealsPerDay,
      'fastingProtocol': instance.fastingProtocol,
      'pathologies': instance.pathologies,
      'activityLevel': instance.activityLevel,
      'weeklyAdherence': instance.weeklyAdherence,
      'exerciseGoalMinutes': instance.exerciseGoalMinutes,
      'healthDisclaimerAccepted': instance.healthDisclaimerAccepted,
      'healthDisclaimerAcceptedAt': const OptionalTimestampConverter()
          .toJson(instance.healthDisclaimerAcceptedAt),
      'healthDisclaimerVersion': instance.healthDisclaimerVersion,
      'profile': instance.profile.toJson(),
    };

_$CircadianProfileImpl _$$CircadianProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$CircadianProfileImpl(
      wakeUpTime: const TimestampConverter().fromJson(json['wakeUpTime']),
      sleepTime: const TimestampConverter().fromJson(json['sleepTime']),
      firstMealGoal:
          const OptionalTimestampConverter().fromJson(json['firstMealGoal']),
      lastMealGoal:
          const OptionalTimestampConverter().fromJson(json['lastMealGoal']),
    );

Map<String, dynamic> _$$CircadianProfileImplToJson(
        _$CircadianProfileImpl instance) =>
    <String, dynamic>{
      'wakeUpTime': const TimestampConverter().toJson(instance.wakeUpTime),
      'sleepTime': const TimestampConverter().toJson(instance.sleepTime),
      'firstMealGoal':
          const OptionalTimestampConverter().toJson(instance.firstMealGoal),
      'lastMealGoal':
          const OptionalTimestampConverter().toJson(instance.lastMealGoal),
    };

_$FastingIntervalImpl _$$FastingIntervalImplFromJson(
        Map<String, dynamic> json) =>
    _$FastingIntervalImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      startTime: const TimestampConverter().fromJson(json['startTime']),
      endTime: const OptionalTimestampConverter().fromJson(json['endTime']),
      isFasting: json['isFasting'] as bool? ?? true,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$FastingIntervalImplToJson(
        _$FastingIntervalImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'startTime': const TimestampConverter().toJson(instance.startTime),
      'endTime': const OptionalTimestampConverter().toJson(instance.endTime),
      'isFasting': instance.isFasting,
      'note': instance.note,
    };
