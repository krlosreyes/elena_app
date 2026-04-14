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
    
    // --- Biometría ---
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
    @Default(3) int mealsPerDay,
    @Default('Ninguno') String fastingProtocol,
    @Default(['Ninguna']) List<String> pathologies,
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
    DateTime? firstMealGoal,
    DateTime? lastMealGoal,
  }) = _CircadianProfile;

  factory CircadianProfile.fromJson(Map<String, dynamic> json) => _$CircadianProfileFromJson(json);
}

// --- NUEVO MODELO PARA EL HISTORIAL (COORDENADAS TEMPORALES) ---
@freezed
class FastingInterval with _$FastingInterval {
  const factory FastingInterval({
    required String id,
    required String userId,
    required DateTime startTime, // La "coordenada" de inicio en el círculo
    DateTime? endTime,           // Si es null, el ayuno sigue activo
    @Default(true) bool isFasting, // true = Ayuno, false = Ventana de comida
    String? note,
  }) = _FastingInterval;

  factory FastingInterval.fromJson(Map<String, dynamic> json) => _$FastingIntervalFromJson(json);
}