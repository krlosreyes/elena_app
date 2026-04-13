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
      'profile': instance.profile.toJson(),
    };

_$CircadianProfileImpl _$$CircadianProfileImplFromJson(
        Map<String, dynamic> json) =>
    _$CircadianProfileImpl(
      wakeUpTime: DateTime.parse(json['wakeUpTime'] as String),
      sleepTime: DateTime.parse(json['sleepTime'] as String),
      firstMealGoal: json['firstMealGoal'] == null
          ? null
          : DateTime.parse(json['firstMealGoal'] as String),
      lastMealGoal: json['lastMealGoal'] == null
          ? null
          : DateTime.parse(json['lastMealGoal'] as String),
    );

Map<String, dynamic> _$$CircadianProfileImplToJson(
        _$CircadianProfileImpl instance) =>
    <String, dynamic>{
      'wakeUpTime': instance.wakeUpTime.toIso8601String(),
      'sleepTime': instance.sleepTime.toIso8601String(),
      'firstMealGoal': instance.firstMealGoal?.toIso8601String(),
      'lastMealGoal': instance.lastMealGoal?.toIso8601String(),
    };
