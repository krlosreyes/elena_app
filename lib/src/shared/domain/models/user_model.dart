import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:elena_app/src/core/converters/timestamp_converter.dart';

part 'user_model.freezed.dart';
part 'user_model.g.dart';

@freezed
class UserModel with _$UserModel {
  // SPEC-73 NOTA: UserModel mantiene su shape estricto.
  //
  // Para usuarios provenientes del ecosistema metamorfosisreal.com cuyo
  // documento en Firestore tiene shape distinto, el AuthRepository NO
  // intenta deserializar a UserModel. En su lugar, devuelve un
  // `AppAccount` con `rawProfile: Map<String, dynamic>` y
  // `profileStatus: PARTIAL_PROFILE`. La deserialización a UserModel
  // ocurre sólo cuando el OnboardingController completa los campos
  // mínimos requeridos.
  //
  // El invariante de "perfil completo" vive en:
  //   lib/src/shared/domain/validators/user_profile_validator.dart
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

    // SPEC-92: `bodyFatPercentage` ahora es nullable. Antes tenía
    // `@Default(20.0)` que era una trampa silenciosa — cualquier ruta
    // de creación que omitiera el campo contaminaba el bloque
    // Estructura del IMR con un 20% poblacional. Hoy el caller debe
    // calcularlo explícitamente (`BodyFatCalculator` desde el
    // onboarding o `BiometryRecalc` desde la edición de Profile). Si
    // no hay datos para calcular, queda null y el ScoreEngine usa
    // fallback marcando `confidenceLevel: 'BAJA'`.
    double? bodyFatPercentage,

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
    @Default(0.85) double weeklyAdherence,
    @Default(20) int exerciseGoalMinutes,

    // --- SPEC-70.8: aceptación del disclaimer clínico ---
    //
    // El usuario debe aceptar explícitamente las contraindicaciones del IMR
    // documentadas en IMR_BIBLIOGRAPHY.md §11 (T1D, TCA, insuficiencia
    // renal, embarazo/lactancia, sarcopenia >75) durante el onboarding.
    // Sin esta aceptación, el flujo no avanza a /dashboard.
    //
    // El timestamp permite auditar cuándo se mostró y aceptó el disclaimer
    // — útil si en el futuro se actualizan los criterios y queremos
    // re-prompt a usuarios que aceptaron una versión vieja.
    @Default(false) bool healthDisclaimerAccepted,
    @OptionalTimestampConverter() DateTime? healthDisclaimerAcceptedAt,

    // SPEC-76: versión del disclaimer aceptado. Si cambia
    // `kHealthDisclaimerVersion`, los usuarios con versión menor
    // vuelven a ver el paso 0 del onboarding. Default 0 = nunca
    // aceptado (compatible con usuarios pre-SPEC-76 que se
    // re-promptean automáticamente al abrir la app).
    @Default(0) int healthDisclaimerVersion,

    // --- SPEC-137: Sistema nervioso (Frank Suárez) ---
    //
    // Captura en onboarding Paso 3.A con 5 preguntas (§RF-137-08.A).
    // Modula la sugerencia de proporción A:E del plato (§RF-137-09)
    // y la sugerencia inicial de protocolo de ayuno (§RF-137-08.C).
    //
    // Campos planos (no anidados) para minimizar el ruido del freezed
    // y mantener la deserialización trivial. La reconstrucción del
    // objeto `NervousSystemScore` se hace on-demand desde el caller
    // via `NervousSystemScore.fromMap`.
    //
    // Default 'unknown' (no 'passive') para que usuarios pre-SPEC-137
    // disparen el banner de "responder después" en el dashboard hasta
    // que completen el sub-step (§RF-137-08.E).

    /// 'passive' | 'excited' | 'unknown'. Default 'unknown' = aún no
    /// se ha clasificado al usuario.
    @Default('unknown') String nervousSystem,

    /// True si el usuario respondió ≥ 3 de las 5 preguntas del
    /// onboarding 3.A. Default false = no responde, dispara banner
    /// recordatorio cada 7 días.
    @Default(false) bool nervousSystemDeclared,

    /// Score crudo de las 5 preguntas para recalibración futura
    /// (§RF-137-08.F). Shape: { 'passive': N, 'excited': N, 'unknown': N }
    /// donde la suma ≤ 5 (5 si respondió todas, menos si saltó).
    /// Default {} = nunca declaró.
    @Default(<String, int>{}) Map<String, int> nervousSystemScore,

    /// Flag de aceptación del dialog de incongruencia protocolo×SN
    /// (§RF-137-08.D). Ej. "20:4-on-excited" significa "el usuario
    /// excitado eligió 20:4 a pesar de la advertencia". Null si nunca
    /// disparó el dialog.
    String? protocolWarningAccepted,
    required CircadianProfile profile,
  }) = _UserModel;

  factory UserModel.fromJson(Map<String, dynamic> json) =>
      _$UserModelFromJson(json);
}

@freezed
class CircadianProfile with _$CircadianProfile {
  const factory CircadianProfile({
    @TimestampConverter() required DateTime wakeUpTime,
    @TimestampConverter() required DateTime sleepTime,
    @OptionalTimestampConverter() DateTime? firstMealGoal,
    @OptionalTimestampConverter() DateTime? lastMealGoal,
  }) = _CircadianProfile;

  factory CircadianProfile.fromJson(Map<String, dynamic> json) =>
      _$CircadianProfileFromJson(json);
}

// --- NUEVO MODELO PARA EL HISTORIAL (COORDENADAS TEMPORALES) ---
//
// SPEC-72.5: campos DateTime aplican TimestampConverter para tolerar
// `Timestamp` de Firestore en `fromJson`. Antes el .g.dart asumía String
// ISO 8601, lo que disparaba "TypeError: Timestamp is not a subtype of
// String" cada vez que el provider leía el último intervalo.
@freezed
class FastingInterval with _$FastingInterval {
  const factory FastingInterval({
    required String id,
    required String userId,
    @TimestampConverter() required DateTime startTime,
    @OptionalTimestampConverter() DateTime? endTime,
    @Default(true) bool isFasting, // true = Ayuno, false = Ventana de comida
    String? note,
  }) = _FastingInterval;

  factory FastingInterval.fromJson(Map<String, dynamic> json) =>
      _$FastingIntervalFromJson(json);
}
