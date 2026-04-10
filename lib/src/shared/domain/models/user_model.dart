import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  const factory UserModel({
    @Default('') String id,
    @Default('Usuario') String name,
    required int age,
    required String gender, 
    required double weight, 
    required double height, 
    
    // --- Biometría (cm) ---
    double? waistCircumference, 
    double? neckCircumference,  
    @Default(20.0) double bodyFatPercentage, 
    
    // --- Inferencia ---
    @Default(30) int pantSize,      
    @Default('M') String shirtSize, 
    @Default(true) bool isMeasurementEstimated, 
    @Default(0.0) double imrStdDev,
    @Default('BAJA') String confidenceLevel,
    
    // --- Hábitos ---
    @Default(1.2) double activityLevel, 
    required CircadianProfile profile,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);
}

@freezed
class CircadianProfile with _$CircadianProfile {
  const factory CircadianProfile({
    required DateTime wakeUpTime,
    required DateTime sleepTime,
    required DateTime firstMealGoal,
    required DateTime lastMealGoal,
  }) = _CircadianProfile;

  factory CircadianProfile.fromJson(Map<String, dynamic> json) => _$CircadianProfileFromJson(json);
}