// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fasting_prediction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

FastingPrediction _$FastingPredictionFromJson(Map<String, dynamic> json) {
  return _FastingPrediction.fromJson(json);
}

/// @nodoc
mixin _$FastingPrediction {
  /// ID único de la predicción
  String get id => throw _privateConstructorUsedError;

  /// ID del usuario
  String get userId => throw _privateConstructorUsedError;

  /// Cuándo se generó esta predicción
  DateTime get generatedAt => throw _privateConstructorUsedError;

  /// Duración actual del ayuno en horas
  int get fastedHours => throw _privateConstructorUsedError;

  /// Glucógeno estimado en gramos (0-500)
  double get estimatedGlycogen => throw _privateConstructorUsedError;

  /// Fase de ayuno actual (ALERTA, GLUCONEOGÉNESIS, CETOSIS, AUTOFAGIA)
  String get currentFastingPhase => throw _privateConstructorUsedError;

  /// Fase circadiana actual (ALERTA, ENERGÍA, CREPÚSCULO, SUEÑO, LIMPIEZA)
  String get currentCircadianPhase => throw _privateConstructorUsedError;

  /// Momento recomendado para romper el ayuno
  DateTime get optimalBreakTime => throw _privateConstructorUsedError;

  /// Opción macro sugerida: 'A' (low-carb), 'B' (balanced), 'C' (high-carb)
  String get suggestedMacroProfile => throw _privateConstructorUsedError;

  /// Respuesta glucémica estimada: BAJA, MEDIA, ALTA
  String get glucemicResponse => throw _privateConstructorUsedError;

  /// Confianza del predictor basada en historial (0.0-1.0)
  double get confidence => throw _privateConstructorUsedError;

  /// Minutos hasta el momento óptimo
  int get minutesUntilOptimal => throw _privateConstructorUsedError;

  /// Detalles de las 3 opciones macro
  List<MacroOption> get macroOptions => throw _privateConstructorUsedError;

  /// Si el usuario ya rompió el ayuno (feedback)
  bool get hasBeenBroken => throw _privateConstructorUsedError;

  /// Cuándo se rompió realmente (si hasBeenBroken = true)
  DateTime? get actualBreakTime => throw _privateConstructorUsedError;

  /// Opción macro elegida por usuario (A, B, C)
  String? get actualMacroChoice => throw _privateConstructorUsedError;

  /// Cómo se sintió el usuario post-ruptura (1-10)
  int? get userEnergyLevel => throw _privateConstructorUsedError;

  /// Notas del usuario sobre la ruptura
  String? get userNotes => throw _privateConstructorUsedError;

  /// Serializes this FastingPrediction to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of FastingPrediction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FastingPredictionCopyWith<FastingPrediction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FastingPredictionCopyWith<$Res> {
  factory $FastingPredictionCopyWith(
          FastingPrediction value, $Res Function(FastingPrediction) then) =
      _$FastingPredictionCopyWithImpl<$Res, FastingPrediction>;
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime generatedAt,
      int fastedHours,
      double estimatedGlycogen,
      String currentFastingPhase,
      String currentCircadianPhase,
      DateTime optimalBreakTime,
      String suggestedMacroProfile,
      String glucemicResponse,
      double confidence,
      int minutesUntilOptimal,
      List<MacroOption> macroOptions,
      bool hasBeenBroken,
      DateTime? actualBreakTime,
      String? actualMacroChoice,
      int? userEnergyLevel,
      String? userNotes});
}

/// @nodoc
class _$FastingPredictionCopyWithImpl<$Res, $Val extends FastingPrediction>
    implements $FastingPredictionCopyWith<$Res> {
  _$FastingPredictionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of FastingPrediction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? generatedAt = null,
    Object? fastedHours = null,
    Object? estimatedGlycogen = null,
    Object? currentFastingPhase = null,
    Object? currentCircadianPhase = null,
    Object? optimalBreakTime = null,
    Object? suggestedMacroProfile = null,
    Object? glucemicResponse = null,
    Object? confidence = null,
    Object? minutesUntilOptimal = null,
    Object? macroOptions = null,
    Object? hasBeenBroken = null,
    Object? actualBreakTime = freezed,
    Object? actualMacroChoice = freezed,
    Object? userEnergyLevel = freezed,
    Object? userNotes = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      fastedHours: null == fastedHours
          ? _value.fastedHours
          : fastedHours // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedGlycogen: null == estimatedGlycogen
          ? _value.estimatedGlycogen
          : estimatedGlycogen // ignore: cast_nullable_to_non_nullable
              as double,
      currentFastingPhase: null == currentFastingPhase
          ? _value.currentFastingPhase
          : currentFastingPhase // ignore: cast_nullable_to_non_nullable
              as String,
      currentCircadianPhase: null == currentCircadianPhase
          ? _value.currentCircadianPhase
          : currentCircadianPhase // ignore: cast_nullable_to_non_nullable
              as String,
      optimalBreakTime: null == optimalBreakTime
          ? _value.optimalBreakTime
          : optimalBreakTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      suggestedMacroProfile: null == suggestedMacroProfile
          ? _value.suggestedMacroProfile
          : suggestedMacroProfile // ignore: cast_nullable_to_non_nullable
              as String,
      glucemicResponse: null == glucemicResponse
          ? _value.glucemicResponse
          : glucemicResponse // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      minutesUntilOptimal: null == minutesUntilOptimal
          ? _value.minutesUntilOptimal
          : minutesUntilOptimal // ignore: cast_nullable_to_non_nullable
              as int,
      macroOptions: null == macroOptions
          ? _value.macroOptions
          : macroOptions // ignore: cast_nullable_to_non_nullable
              as List<MacroOption>,
      hasBeenBroken: null == hasBeenBroken
          ? _value.hasBeenBroken
          : hasBeenBroken // ignore: cast_nullable_to_non_nullable
              as bool,
      actualBreakTime: freezed == actualBreakTime
          ? _value.actualBreakTime
          : actualBreakTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      actualMacroChoice: freezed == actualMacroChoice
          ? _value.actualMacroChoice
          : actualMacroChoice // ignore: cast_nullable_to_non_nullable
              as String?,
      userEnergyLevel: freezed == userEnergyLevel
          ? _value.userEnergyLevel
          : userEnergyLevel // ignore: cast_nullable_to_non_nullable
              as int?,
      userNotes: freezed == userNotes
          ? _value.userNotes
          : userNotes // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FastingPredictionImplCopyWith<$Res>
    implements $FastingPredictionCopyWith<$Res> {
  factory _$$FastingPredictionImplCopyWith(_$FastingPredictionImpl value,
          $Res Function(_$FastingPredictionImpl) then) =
      __$$FastingPredictionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      DateTime generatedAt,
      int fastedHours,
      double estimatedGlycogen,
      String currentFastingPhase,
      String currentCircadianPhase,
      DateTime optimalBreakTime,
      String suggestedMacroProfile,
      String glucemicResponse,
      double confidence,
      int minutesUntilOptimal,
      List<MacroOption> macroOptions,
      bool hasBeenBroken,
      DateTime? actualBreakTime,
      String? actualMacroChoice,
      int? userEnergyLevel,
      String? userNotes});
}

/// @nodoc
class __$$FastingPredictionImplCopyWithImpl<$Res>
    extends _$FastingPredictionCopyWithImpl<$Res, _$FastingPredictionImpl>
    implements _$$FastingPredictionImplCopyWith<$Res> {
  __$$FastingPredictionImplCopyWithImpl(_$FastingPredictionImpl _value,
      $Res Function(_$FastingPredictionImpl) _then)
      : super(_value, _then);

  /// Create a copy of FastingPrediction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? generatedAt = null,
    Object? fastedHours = null,
    Object? estimatedGlycogen = null,
    Object? currentFastingPhase = null,
    Object? currentCircadianPhase = null,
    Object? optimalBreakTime = null,
    Object? suggestedMacroProfile = null,
    Object? glucemicResponse = null,
    Object? confidence = null,
    Object? minutesUntilOptimal = null,
    Object? macroOptions = null,
    Object? hasBeenBroken = null,
    Object? actualBreakTime = freezed,
    Object? actualMacroChoice = freezed,
    Object? userEnergyLevel = freezed,
    Object? userNotes = freezed,
  }) {
    return _then(_$FastingPredictionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      fastedHours: null == fastedHours
          ? _value.fastedHours
          : fastedHours // ignore: cast_nullable_to_non_nullable
              as int,
      estimatedGlycogen: null == estimatedGlycogen
          ? _value.estimatedGlycogen
          : estimatedGlycogen // ignore: cast_nullable_to_non_nullable
              as double,
      currentFastingPhase: null == currentFastingPhase
          ? _value.currentFastingPhase
          : currentFastingPhase // ignore: cast_nullable_to_non_nullable
              as String,
      currentCircadianPhase: null == currentCircadianPhase
          ? _value.currentCircadianPhase
          : currentCircadianPhase // ignore: cast_nullable_to_non_nullable
              as String,
      optimalBreakTime: null == optimalBreakTime
          ? _value.optimalBreakTime
          : optimalBreakTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      suggestedMacroProfile: null == suggestedMacroProfile
          ? _value.suggestedMacroProfile
          : suggestedMacroProfile // ignore: cast_nullable_to_non_nullable
              as String,
      glucemicResponse: null == glucemicResponse
          ? _value.glucemicResponse
          : glucemicResponse // ignore: cast_nullable_to_non_nullable
              as String,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
      minutesUntilOptimal: null == minutesUntilOptimal
          ? _value.minutesUntilOptimal
          : minutesUntilOptimal // ignore: cast_nullable_to_non_nullable
              as int,
      macroOptions: null == macroOptions
          ? _value._macroOptions
          : macroOptions // ignore: cast_nullable_to_non_nullable
              as List<MacroOption>,
      hasBeenBroken: null == hasBeenBroken
          ? _value.hasBeenBroken
          : hasBeenBroken // ignore: cast_nullable_to_non_nullable
              as bool,
      actualBreakTime: freezed == actualBreakTime
          ? _value.actualBreakTime
          : actualBreakTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      actualMacroChoice: freezed == actualMacroChoice
          ? _value.actualMacroChoice
          : actualMacroChoice // ignore: cast_nullable_to_non_nullable
              as String?,
      userEnergyLevel: freezed == userEnergyLevel
          ? _value.userEnergyLevel
          : userEnergyLevel // ignore: cast_nullable_to_non_nullable
              as int?,
      userNotes: freezed == userNotes
          ? _value.userNotes
          : userNotes // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FastingPredictionImpl implements _FastingPrediction {
  const _$FastingPredictionImpl(
      {required this.id,
      required this.userId,
      required this.generatedAt,
      required this.fastedHours,
      required this.estimatedGlycogen,
      required this.currentFastingPhase,
      required this.currentCircadianPhase,
      required this.optimalBreakTime,
      required this.suggestedMacroProfile,
      required this.glucemicResponse,
      required this.confidence,
      required this.minutesUntilOptimal,
      required final List<MacroOption> macroOptions,
      this.hasBeenBroken = false,
      this.actualBreakTime,
      this.actualMacroChoice,
      this.userEnergyLevel,
      this.userNotes})
      : _macroOptions = macroOptions;

  factory _$FastingPredictionImpl.fromJson(Map<String, dynamic> json) =>
      _$$FastingPredictionImplFromJson(json);

  /// ID único de la predicción
  @override
  final String id;

  /// ID del usuario
  @override
  final String userId;

  /// Cuándo se generó esta predicción
  @override
  final DateTime generatedAt;

  /// Duración actual del ayuno en horas
  @override
  final int fastedHours;

  /// Glucógeno estimado en gramos (0-500)
  @override
  final double estimatedGlycogen;

  /// Fase de ayuno actual (ALERTA, GLUCONEOGÉNESIS, CETOSIS, AUTOFAGIA)
  @override
  final String currentFastingPhase;

  /// Fase circadiana actual (ALERTA, ENERGÍA, CREPÚSCULO, SUEÑO, LIMPIEZA)
  @override
  final String currentCircadianPhase;

  /// Momento recomendado para romper el ayuno
  @override
  final DateTime optimalBreakTime;

  /// Opción macro sugerida: 'A' (low-carb), 'B' (balanced), 'C' (high-carb)
  @override
  final String suggestedMacroProfile;

  /// Respuesta glucémica estimada: BAJA, MEDIA, ALTA
  @override
  final String glucemicResponse;

  /// Confianza del predictor basada en historial (0.0-1.0)
  @override
  final double confidence;

  /// Minutos hasta el momento óptimo
  @override
  final int minutesUntilOptimal;

  /// Detalles de las 3 opciones macro
  final List<MacroOption> _macroOptions;

  /// Detalles de las 3 opciones macro
  @override
  List<MacroOption> get macroOptions {
    if (_macroOptions is EqualUnmodifiableListView) return _macroOptions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_macroOptions);
  }

  /// Si el usuario ya rompió el ayuno (feedback)
  @override
  @JsonKey()
  final bool hasBeenBroken;

  /// Cuándo se rompió realmente (si hasBeenBroken = true)
  @override
  final DateTime? actualBreakTime;

  /// Opción macro elegida por usuario (A, B, C)
  @override
  final String? actualMacroChoice;

  /// Cómo se sintió el usuario post-ruptura (1-10)
  @override
  final int? userEnergyLevel;

  /// Notas del usuario sobre la ruptura
  @override
  final String? userNotes;

  @override
  String toString() {
    return 'FastingPrediction(id: $id, userId: $userId, generatedAt: $generatedAt, fastedHours: $fastedHours, estimatedGlycogen: $estimatedGlycogen, currentFastingPhase: $currentFastingPhase, currentCircadianPhase: $currentCircadianPhase, optimalBreakTime: $optimalBreakTime, suggestedMacroProfile: $suggestedMacroProfile, glucemicResponse: $glucemicResponse, confidence: $confidence, minutesUntilOptimal: $minutesUntilOptimal, macroOptions: $macroOptions, hasBeenBroken: $hasBeenBroken, actualBreakTime: $actualBreakTime, actualMacroChoice: $actualMacroChoice, userEnergyLevel: $userEnergyLevel, userNotes: $userNotes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FastingPredictionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt) &&
            (identical(other.fastedHours, fastedHours) ||
                other.fastedHours == fastedHours) &&
            (identical(other.estimatedGlycogen, estimatedGlycogen) ||
                other.estimatedGlycogen == estimatedGlycogen) &&
            (identical(other.currentFastingPhase, currentFastingPhase) ||
                other.currentFastingPhase == currentFastingPhase) &&
            (identical(other.currentCircadianPhase, currentCircadianPhase) ||
                other.currentCircadianPhase == currentCircadianPhase) &&
            (identical(other.optimalBreakTime, optimalBreakTime) ||
                other.optimalBreakTime == optimalBreakTime) &&
            (identical(other.suggestedMacroProfile, suggestedMacroProfile) ||
                other.suggestedMacroProfile == suggestedMacroProfile) &&
            (identical(other.glucemicResponse, glucemicResponse) ||
                other.glucemicResponse == glucemicResponse) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.minutesUntilOptimal, minutesUntilOptimal) ||
                other.minutesUntilOptimal == minutesUntilOptimal) &&
            const DeepCollectionEquality()
                .equals(other._macroOptions, _macroOptions) &&
            (identical(other.hasBeenBroken, hasBeenBroken) ||
                other.hasBeenBroken == hasBeenBroken) &&
            (identical(other.actualBreakTime, actualBreakTime) ||
                other.actualBreakTime == actualBreakTime) &&
            (identical(other.actualMacroChoice, actualMacroChoice) ||
                other.actualMacroChoice == actualMacroChoice) &&
            (identical(other.userEnergyLevel, userEnergyLevel) ||
                other.userEnergyLevel == userEnergyLevel) &&
            (identical(other.userNotes, userNotes) ||
                other.userNotes == userNotes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      generatedAt,
      fastedHours,
      estimatedGlycogen,
      currentFastingPhase,
      currentCircadianPhase,
      optimalBreakTime,
      suggestedMacroProfile,
      glucemicResponse,
      confidence,
      minutesUntilOptimal,
      const DeepCollectionEquality().hash(_macroOptions),
      hasBeenBroken,
      actualBreakTime,
      actualMacroChoice,
      userEnergyLevel,
      userNotes);

  /// Create a copy of FastingPrediction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FastingPredictionImplCopyWith<_$FastingPredictionImpl> get copyWith =>
      __$$FastingPredictionImplCopyWithImpl<_$FastingPredictionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FastingPredictionImplToJson(
      this,
    );
  }
}

abstract class _FastingPrediction implements FastingPrediction {
  const factory _FastingPrediction(
      {required final String id,
      required final String userId,
      required final DateTime generatedAt,
      required final int fastedHours,
      required final double estimatedGlycogen,
      required final String currentFastingPhase,
      required final String currentCircadianPhase,
      required final DateTime optimalBreakTime,
      required final String suggestedMacroProfile,
      required final String glucemicResponse,
      required final double confidence,
      required final int minutesUntilOptimal,
      required final List<MacroOption> macroOptions,
      final bool hasBeenBroken,
      final DateTime? actualBreakTime,
      final String? actualMacroChoice,
      final int? userEnergyLevel,
      final String? userNotes}) = _$FastingPredictionImpl;

  factory _FastingPrediction.fromJson(Map<String, dynamic> json) =
      _$FastingPredictionImpl.fromJson;

  /// ID único de la predicción
  @override
  String get id;

  /// ID del usuario
  @override
  String get userId;

  /// Cuándo se generó esta predicción
  @override
  DateTime get generatedAt;

  /// Duración actual del ayuno en horas
  @override
  int get fastedHours;

  /// Glucógeno estimado en gramos (0-500)
  @override
  double get estimatedGlycogen;

  /// Fase de ayuno actual (ALERTA, GLUCONEOGÉNESIS, CETOSIS, AUTOFAGIA)
  @override
  String get currentFastingPhase;

  /// Fase circadiana actual (ALERTA, ENERGÍA, CREPÚSCULO, SUEÑO, LIMPIEZA)
  @override
  String get currentCircadianPhase;

  /// Momento recomendado para romper el ayuno
  @override
  DateTime get optimalBreakTime;

  /// Opción macro sugerida: 'A' (low-carb), 'B' (balanced), 'C' (high-carb)
  @override
  String get suggestedMacroProfile;

  /// Respuesta glucémica estimada: BAJA, MEDIA, ALTA
  @override
  String get glucemicResponse;

  /// Confianza del predictor basada en historial (0.0-1.0)
  @override
  double get confidence;

  /// Minutos hasta el momento óptimo
  @override
  int get minutesUntilOptimal;

  /// Detalles de las 3 opciones macro
  @override
  List<MacroOption> get macroOptions;

  /// Si el usuario ya rompió el ayuno (feedback)
  @override
  bool get hasBeenBroken;

  /// Cuándo se rompió realmente (si hasBeenBroken = true)
  @override
  DateTime? get actualBreakTime;

  /// Opción macro elegida por usuario (A, B, C)
  @override
  String? get actualMacroChoice;

  /// Cómo se sintió el usuario post-ruptura (1-10)
  @override
  int? get userEnergyLevel;

  /// Notas del usuario sobre la ruptura
  @override
  String? get userNotes;

  /// Create a copy of FastingPrediction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FastingPredictionImplCopyWith<_$FastingPredictionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MacroOption _$MacroOptionFromJson(Map<String, dynamic> json) {
  return _MacroOption.fromJson(json);
}

/// @nodoc
mixin _$MacroOption {
  /// A = low-carb, B = balanced, C = high-carb
  String get profile => throw _privateConstructorUsedError;

  /// Carbohidratos sugeridos en gramos
  double get suggestedCarbs => throw _privateConstructorUsedError;

  /// Proteína sugerida en gramos
  double get suggestedProtein => throw _privateConstructorUsedError;

  /// Grasas sugeridas en gramos
  double get suggestedFat => throw _privateConstructorUsedError;

  /// Calorías totales estimadas
  int get estimatedCalories => throw _privateConstructorUsedError;

  /// Respuesta glucémica: BAJA, MEDIA, ALTA
  String get glucemicResponse => throw _privateConstructorUsedError;

  /// Descripción legible para usuario
  String get description => throw _privateConstructorUsedError;

  /// Ejemplos de alimentos para esta opción
  List<String> get foodExamples => throw _privateConstructorUsedError;

  /// Confianza en esta recomendación (0.0-1.0)
  double get confidence => throw _privateConstructorUsedError;

  /// Serializes this MacroOption to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of MacroOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $MacroOptionCopyWith<MacroOption> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MacroOptionCopyWith<$Res> {
  factory $MacroOptionCopyWith(
          MacroOption value, $Res Function(MacroOption) then) =
      _$MacroOptionCopyWithImpl<$Res, MacroOption>;
  @useResult
  $Res call(
      {String profile,
      double suggestedCarbs,
      double suggestedProtein,
      double suggestedFat,
      int estimatedCalories,
      String glucemicResponse,
      String description,
      List<String> foodExamples,
      double confidence});
}

/// @nodoc
class _$MacroOptionCopyWithImpl<$Res, $Val extends MacroOption>
    implements $MacroOptionCopyWith<$Res> {
  _$MacroOptionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of MacroOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profile = null,
    Object? suggestedCarbs = null,
    Object? suggestedProtein = null,
    Object? suggestedFat = null,
    Object? estimatedCalories = null,
    Object? glucemicResponse = null,
    Object? description = null,
    Object? foodExamples = null,
    Object? confidence = null,
  }) {
    return _then(_value.copyWith(
      profile: null == profile
          ? _value.profile
          : profile // ignore: cast_nullable_to_non_nullable
              as String,
      suggestedCarbs: null == suggestedCarbs
          ? _value.suggestedCarbs
          : suggestedCarbs // ignore: cast_nullable_to_non_nullable
              as double,
      suggestedProtein: null == suggestedProtein
          ? _value.suggestedProtein
          : suggestedProtein // ignore: cast_nullable_to_non_nullable
              as double,
      suggestedFat: null == suggestedFat
          ? _value.suggestedFat
          : suggestedFat // ignore: cast_nullable_to_non_nullable
              as double,
      estimatedCalories: null == estimatedCalories
          ? _value.estimatedCalories
          : estimatedCalories // ignore: cast_nullable_to_non_nullable
              as int,
      glucemicResponse: null == glucemicResponse
          ? _value.glucemicResponse
          : glucemicResponse // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      foodExamples: null == foodExamples
          ? _value.foodExamples
          : foodExamples // ignore: cast_nullable_to_non_nullable
              as List<String>,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MacroOptionImplCopyWith<$Res>
    implements $MacroOptionCopyWith<$Res> {
  factory _$$MacroOptionImplCopyWith(
          _$MacroOptionImpl value, $Res Function(_$MacroOptionImpl) then) =
      __$$MacroOptionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String profile,
      double suggestedCarbs,
      double suggestedProtein,
      double suggestedFat,
      int estimatedCalories,
      String glucemicResponse,
      String description,
      List<String> foodExamples,
      double confidence});
}

/// @nodoc
class __$$MacroOptionImplCopyWithImpl<$Res>
    extends _$MacroOptionCopyWithImpl<$Res, _$MacroOptionImpl>
    implements _$$MacroOptionImplCopyWith<$Res> {
  __$$MacroOptionImplCopyWithImpl(
      _$MacroOptionImpl _value, $Res Function(_$MacroOptionImpl) _then)
      : super(_value, _then);

  /// Create a copy of MacroOption
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? profile = null,
    Object? suggestedCarbs = null,
    Object? suggestedProtein = null,
    Object? suggestedFat = null,
    Object? estimatedCalories = null,
    Object? glucemicResponse = null,
    Object? description = null,
    Object? foodExamples = null,
    Object? confidence = null,
  }) {
    return _then(_$MacroOptionImpl(
      profile: null == profile
          ? _value.profile
          : profile // ignore: cast_nullable_to_non_nullable
              as String,
      suggestedCarbs: null == suggestedCarbs
          ? _value.suggestedCarbs
          : suggestedCarbs // ignore: cast_nullable_to_non_nullable
              as double,
      suggestedProtein: null == suggestedProtein
          ? _value.suggestedProtein
          : suggestedProtein // ignore: cast_nullable_to_non_nullable
              as double,
      suggestedFat: null == suggestedFat
          ? _value.suggestedFat
          : suggestedFat // ignore: cast_nullable_to_non_nullable
              as double,
      estimatedCalories: null == estimatedCalories
          ? _value.estimatedCalories
          : estimatedCalories // ignore: cast_nullable_to_non_nullable
              as int,
      glucemicResponse: null == glucemicResponse
          ? _value.glucemicResponse
          : glucemicResponse // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      foodExamples: null == foodExamples
          ? _value._foodExamples
          : foodExamples // ignore: cast_nullable_to_non_nullable
              as List<String>,
      confidence: null == confidence
          ? _value.confidence
          : confidence // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MacroOptionImpl implements _MacroOption {
  const _$MacroOptionImpl(
      {required this.profile,
      required this.suggestedCarbs,
      required this.suggestedProtein,
      required this.suggestedFat,
      required this.estimatedCalories,
      required this.glucemicResponse,
      required this.description,
      final List<String> foodExamples = const [],
      this.confidence = 0.8})
      : _foodExamples = foodExamples;

  factory _$MacroOptionImpl.fromJson(Map<String, dynamic> json) =>
      _$$MacroOptionImplFromJson(json);

  /// A = low-carb, B = balanced, C = high-carb
  @override
  final String profile;

  /// Carbohidratos sugeridos en gramos
  @override
  final double suggestedCarbs;

  /// Proteína sugerida en gramos
  @override
  final double suggestedProtein;

  /// Grasas sugeridas en gramos
  @override
  final double suggestedFat;

  /// Calorías totales estimadas
  @override
  final int estimatedCalories;

  /// Respuesta glucémica: BAJA, MEDIA, ALTA
  @override
  final String glucemicResponse;

  /// Descripción legible para usuario
  @override
  final String description;

  /// Ejemplos de alimentos para esta opción
  final List<String> _foodExamples;

  /// Ejemplos de alimentos para esta opción
  @override
  @JsonKey()
  List<String> get foodExamples {
    if (_foodExamples is EqualUnmodifiableListView) return _foodExamples;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_foodExamples);
  }

  /// Confianza en esta recomendación (0.0-1.0)
  @override
  @JsonKey()
  final double confidence;

  @override
  String toString() {
    return 'MacroOption(profile: $profile, suggestedCarbs: $suggestedCarbs, suggestedProtein: $suggestedProtein, suggestedFat: $suggestedFat, estimatedCalories: $estimatedCalories, glucemicResponse: $glucemicResponse, description: $description, foodExamples: $foodExamples, confidence: $confidence)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MacroOptionImpl &&
            (identical(other.profile, profile) || other.profile == profile) &&
            (identical(other.suggestedCarbs, suggestedCarbs) ||
                other.suggestedCarbs == suggestedCarbs) &&
            (identical(other.suggestedProtein, suggestedProtein) ||
                other.suggestedProtein == suggestedProtein) &&
            (identical(other.suggestedFat, suggestedFat) ||
                other.suggestedFat == suggestedFat) &&
            (identical(other.estimatedCalories, estimatedCalories) ||
                other.estimatedCalories == estimatedCalories) &&
            (identical(other.glucemicResponse, glucemicResponse) ||
                other.glucemicResponse == glucemicResponse) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._foodExamples, _foodExamples) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      profile,
      suggestedCarbs,
      suggestedProtein,
      suggestedFat,
      estimatedCalories,
      glucemicResponse,
      description,
      const DeepCollectionEquality().hash(_foodExamples),
      confidence);

  /// Create a copy of MacroOption
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$MacroOptionImplCopyWith<_$MacroOptionImpl> get copyWith =>
      __$$MacroOptionImplCopyWithImpl<_$MacroOptionImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MacroOptionImplToJson(
      this,
    );
  }
}

abstract class _MacroOption implements MacroOption {
  const factory _MacroOption(
      {required final String profile,
      required final double suggestedCarbs,
      required final double suggestedProtein,
      required final double suggestedFat,
      required final int estimatedCalories,
      required final String glucemicResponse,
      required final String description,
      final List<String> foodExamples,
      final double confidence}) = _$MacroOptionImpl;

  factory _MacroOption.fromJson(Map<String, dynamic> json) =
      _$MacroOptionImpl.fromJson;

  /// A = low-carb, B = balanced, C = high-carb
  @override
  String get profile;

  /// Carbohidratos sugeridos en gramos
  @override
  double get suggestedCarbs;

  /// Proteína sugerida en gramos
  @override
  double get suggestedProtein;

  /// Grasas sugeridas en gramos
  @override
  double get suggestedFat;

  /// Calorías totales estimadas
  @override
  int get estimatedCalories;

  /// Respuesta glucémica: BAJA, MEDIA, ALTA
  @override
  String get glucemicResponse;

  /// Descripción legible para usuario
  @override
  String get description;

  /// Ejemplos de alimentos para esta opción
  @override
  List<String> get foodExamples;

  /// Confianza en esta recomendación (0.0-1.0)
  @override
  double get confidence;

  /// Create a copy of MacroOption
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$MacroOptionImplCopyWith<_$MacroOptionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
