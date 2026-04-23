// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'orchestrator_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

OrchestratorState _$OrchestratorStateFromJson(Map<String, dynamic> json) {
  return _OrchestratorState.fromJson(json);
}

/// @nodoc
mixin _$OrchestratorState {
  /// Última actualización del estado
  DateTime get lastUpdated => throw _privateConstructorUsedError;

  /// Fase actual de ayuno (ALERTA, GLUCONEOGÉNESIS, CETOSIS, AUTOFAGIA)
  String get currentFastingPhase => throw _privateConstructorUsedError;

  /// Fase circadiana actual (ALERTA, ENERGÍA, CREPÚSCULO, SUEÑO, LIMPIEZA)
  String get currentCircadianPhase => throw _privateConstructorUsedError;

  /// Horas de ayuno actual
  double get fastedHours => throw _privateConstructorUsedError;

  /// Es seguro hacer ejercicio ahora
  bool get canExerciseNow => throw _privateConstructorUsedError;

  /// Es seguro comer ahora (dentro de ventana circadiana)
  bool get canEatNow => throw _privateConstructorUsedError;

  /// Tipo de ejercicio recomendado (LISS, STRENGTH, HIIT o null)
  String? get exerciseRecommendedType => throw _privateConstructorUsedError;

  /// Intensidad recomendada (0-100 percent)
  int get exerciseRecommendedIntensity => throw _privateConstructorUsedError;

  /// Es óptimo continuar en ayuno
  bool get isOptimalForFasting => throw _privateConstructorUsedError;

  /// Score de sincronización metabólica (0-1)
  double get metabolicCoherence => throw _privateConstructorUsedError;

  /// Violaciones activas (lista de strings descriptivos)
  List<String> get activeSyncViolations => throw _privateConstructorUsedError;

  /// Sugerencia de acción principal para ahora
  String? get primaryActionSuggestion => throw _privateConstructorUsedError;

  /// Cache de scores por pilar
  Map<String, double> get syncMetrics => throw _privateConstructorUsedError;

  /// Penalización de ejercicio por estado de ayuno (0-1, donde 1 = sin penalización)
  double get exerciseSafetyMultiplier => throw _privateConstructorUsedError;

  /// Penalización de nutrición por fase circadiana (0-1)
  double get nutritionPhaseMultiplier => throw _privateConstructorUsedError;

  /// Horas desde última comida
  double get hoursSinceLastMeal => throw _privateConstructorUsedError;

  /// Minutos hasta cierre de ventana de comida
  int? get minutesToWindowClose => throw _privateConstructorUsedError;

  /// Recovery status del sueño (0-1)
  double get sleepRecoveryScore => throw _privateConstructorUsedError;

  /// Serializes this OrchestratorState to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of OrchestratorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrchestratorStateCopyWith<OrchestratorState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrchestratorStateCopyWith<$Res> {
  factory $OrchestratorStateCopyWith(
          OrchestratorState value, $Res Function(OrchestratorState) then) =
      _$OrchestratorStateCopyWithImpl<$Res, OrchestratorState>;
  @useResult
  $Res call(
      {DateTime lastUpdated,
      String currentFastingPhase,
      String currentCircadianPhase,
      double fastedHours,
      bool canExerciseNow,
      bool canEatNow,
      String? exerciseRecommendedType,
      int exerciseRecommendedIntensity,
      bool isOptimalForFasting,
      double metabolicCoherence,
      List<String> activeSyncViolations,
      String? primaryActionSuggestion,
      Map<String, double> syncMetrics,
      double exerciseSafetyMultiplier,
      double nutritionPhaseMultiplier,
      double hoursSinceLastMeal,
      int? minutesToWindowClose,
      double sleepRecoveryScore});
}

/// @nodoc
class _$OrchestratorStateCopyWithImpl<$Res, $Val extends OrchestratorState>
    implements $OrchestratorStateCopyWith<$Res> {
  _$OrchestratorStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrchestratorState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lastUpdated = null,
    Object? currentFastingPhase = null,
    Object? currentCircadianPhase = null,
    Object? fastedHours = null,
    Object? canExerciseNow = null,
    Object? canEatNow = null,
    Object? exerciseRecommendedType = freezed,
    Object? exerciseRecommendedIntensity = null,
    Object? isOptimalForFasting = null,
    Object? metabolicCoherence = null,
    Object? activeSyncViolations = null,
    Object? primaryActionSuggestion = freezed,
    Object? syncMetrics = null,
    Object? exerciseSafetyMultiplier = null,
    Object? nutritionPhaseMultiplier = null,
    Object? hoursSinceLastMeal = null,
    Object? minutesToWindowClose = freezed,
    Object? sleepRecoveryScore = null,
  }) {
    return _then(_value.copyWith(
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
      currentFastingPhase: null == currentFastingPhase
          ? _value.currentFastingPhase
          : currentFastingPhase // ignore: cast_nullable_to_non_nullable
              as String,
      currentCircadianPhase: null == currentCircadianPhase
          ? _value.currentCircadianPhase
          : currentCircadianPhase // ignore: cast_nullable_to_non_nullable
              as String,
      fastedHours: null == fastedHours
          ? _value.fastedHours
          : fastedHours // ignore: cast_nullable_to_non_nullable
              as double,
      canExerciseNow: null == canExerciseNow
          ? _value.canExerciseNow
          : canExerciseNow // ignore: cast_nullable_to_non_nullable
              as bool,
      canEatNow: null == canEatNow
          ? _value.canEatNow
          : canEatNow // ignore: cast_nullable_to_non_nullable
              as bool,
      exerciseRecommendedType: freezed == exerciseRecommendedType
          ? _value.exerciseRecommendedType
          : exerciseRecommendedType // ignore: cast_nullable_to_non_nullable
              as String?,
      exerciseRecommendedIntensity: null == exerciseRecommendedIntensity
          ? _value.exerciseRecommendedIntensity
          : exerciseRecommendedIntensity // ignore: cast_nullable_to_non_nullable
              as int,
      isOptimalForFasting: null == isOptimalForFasting
          ? _value.isOptimalForFasting
          : isOptimalForFasting // ignore: cast_nullable_to_non_nullable
              as bool,
      metabolicCoherence: null == metabolicCoherence
          ? _value.metabolicCoherence
          : metabolicCoherence // ignore: cast_nullable_to_non_nullable
              as double,
      activeSyncViolations: null == activeSyncViolations
          ? _value.activeSyncViolations
          : activeSyncViolations // ignore: cast_nullable_to_non_nullable
              as List<String>,
      primaryActionSuggestion: freezed == primaryActionSuggestion
          ? _value.primaryActionSuggestion
          : primaryActionSuggestion // ignore: cast_nullable_to_non_nullable
              as String?,
      syncMetrics: null == syncMetrics
          ? _value.syncMetrics
          : syncMetrics // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      exerciseSafetyMultiplier: null == exerciseSafetyMultiplier
          ? _value.exerciseSafetyMultiplier
          : exerciseSafetyMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      nutritionPhaseMultiplier: null == nutritionPhaseMultiplier
          ? _value.nutritionPhaseMultiplier
          : nutritionPhaseMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      hoursSinceLastMeal: null == hoursSinceLastMeal
          ? _value.hoursSinceLastMeal
          : hoursSinceLastMeal // ignore: cast_nullable_to_non_nullable
              as double,
      minutesToWindowClose: freezed == minutesToWindowClose
          ? _value.minutesToWindowClose
          : minutesToWindowClose // ignore: cast_nullable_to_non_nullable
              as int?,
      sleepRecoveryScore: null == sleepRecoveryScore
          ? _value.sleepRecoveryScore
          : sleepRecoveryScore // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrchestratorStateImplCopyWith<$Res>
    implements $OrchestratorStateCopyWith<$Res> {
  factory _$$OrchestratorStateImplCopyWith(_$OrchestratorStateImpl value,
          $Res Function(_$OrchestratorStateImpl) then) =
      __$$OrchestratorStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime lastUpdated,
      String currentFastingPhase,
      String currentCircadianPhase,
      double fastedHours,
      bool canExerciseNow,
      bool canEatNow,
      String? exerciseRecommendedType,
      int exerciseRecommendedIntensity,
      bool isOptimalForFasting,
      double metabolicCoherence,
      List<String> activeSyncViolations,
      String? primaryActionSuggestion,
      Map<String, double> syncMetrics,
      double exerciseSafetyMultiplier,
      double nutritionPhaseMultiplier,
      double hoursSinceLastMeal,
      int? minutesToWindowClose,
      double sleepRecoveryScore});
}

/// @nodoc
class __$$OrchestratorStateImplCopyWithImpl<$Res>
    extends _$OrchestratorStateCopyWithImpl<$Res, _$OrchestratorStateImpl>
    implements _$$OrchestratorStateImplCopyWith<$Res> {
  __$$OrchestratorStateImplCopyWithImpl(_$OrchestratorStateImpl _value,
      $Res Function(_$OrchestratorStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of OrchestratorState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? lastUpdated = null,
    Object? currentFastingPhase = null,
    Object? currentCircadianPhase = null,
    Object? fastedHours = null,
    Object? canExerciseNow = null,
    Object? canEatNow = null,
    Object? exerciseRecommendedType = freezed,
    Object? exerciseRecommendedIntensity = null,
    Object? isOptimalForFasting = null,
    Object? metabolicCoherence = null,
    Object? activeSyncViolations = null,
    Object? primaryActionSuggestion = freezed,
    Object? syncMetrics = null,
    Object? exerciseSafetyMultiplier = null,
    Object? nutritionPhaseMultiplier = null,
    Object? hoursSinceLastMeal = null,
    Object? minutesToWindowClose = freezed,
    Object? sleepRecoveryScore = null,
  }) {
    return _then(_$OrchestratorStateImpl(
      lastUpdated: null == lastUpdated
          ? _value.lastUpdated
          : lastUpdated // ignore: cast_nullable_to_non_nullable
              as DateTime,
      currentFastingPhase: null == currentFastingPhase
          ? _value.currentFastingPhase
          : currentFastingPhase // ignore: cast_nullable_to_non_nullable
              as String,
      currentCircadianPhase: null == currentCircadianPhase
          ? _value.currentCircadianPhase
          : currentCircadianPhase // ignore: cast_nullable_to_non_nullable
              as String,
      fastedHours: null == fastedHours
          ? _value.fastedHours
          : fastedHours // ignore: cast_nullable_to_non_nullable
              as double,
      canExerciseNow: null == canExerciseNow
          ? _value.canExerciseNow
          : canExerciseNow // ignore: cast_nullable_to_non_nullable
              as bool,
      canEatNow: null == canEatNow
          ? _value.canEatNow
          : canEatNow // ignore: cast_nullable_to_non_nullable
              as bool,
      exerciseRecommendedType: freezed == exerciseRecommendedType
          ? _value.exerciseRecommendedType
          : exerciseRecommendedType // ignore: cast_nullable_to_non_nullable
              as String?,
      exerciseRecommendedIntensity: null == exerciseRecommendedIntensity
          ? _value.exerciseRecommendedIntensity
          : exerciseRecommendedIntensity // ignore: cast_nullable_to_non_nullable
              as int,
      isOptimalForFasting: null == isOptimalForFasting
          ? _value.isOptimalForFasting
          : isOptimalForFasting // ignore: cast_nullable_to_non_nullable
              as bool,
      metabolicCoherence: null == metabolicCoherence
          ? _value.metabolicCoherence
          : metabolicCoherence // ignore: cast_nullable_to_non_nullable
              as double,
      activeSyncViolations: null == activeSyncViolations
          ? _value._activeSyncViolations
          : activeSyncViolations // ignore: cast_nullable_to_non_nullable
              as List<String>,
      primaryActionSuggestion: freezed == primaryActionSuggestion
          ? _value.primaryActionSuggestion
          : primaryActionSuggestion // ignore: cast_nullable_to_non_nullable
              as String?,
      syncMetrics: null == syncMetrics
          ? _value._syncMetrics
          : syncMetrics // ignore: cast_nullable_to_non_nullable
              as Map<String, double>,
      exerciseSafetyMultiplier: null == exerciseSafetyMultiplier
          ? _value.exerciseSafetyMultiplier
          : exerciseSafetyMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      nutritionPhaseMultiplier: null == nutritionPhaseMultiplier
          ? _value.nutritionPhaseMultiplier
          : nutritionPhaseMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      hoursSinceLastMeal: null == hoursSinceLastMeal
          ? _value.hoursSinceLastMeal
          : hoursSinceLastMeal // ignore: cast_nullable_to_non_nullable
              as double,
      minutesToWindowClose: freezed == minutesToWindowClose
          ? _value.minutesToWindowClose
          : minutesToWindowClose // ignore: cast_nullable_to_non_nullable
              as int?,
      sleepRecoveryScore: null == sleepRecoveryScore
          ? _value.sleepRecoveryScore
          : sleepRecoveryScore // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$OrchestratorStateImpl extends _OrchestratorState {
  const _$OrchestratorStateImpl(
      {required this.lastUpdated,
      required this.currentFastingPhase,
      required this.currentCircadianPhase,
      required this.fastedHours,
      required this.canExerciseNow,
      required this.canEatNow,
      this.exerciseRecommendedType,
      this.exerciseRecommendedIntensity = 0,
      required this.isOptimalForFasting,
      required this.metabolicCoherence,
      final List<String> activeSyncViolations = const [],
      this.primaryActionSuggestion,
      final Map<String, double> syncMetrics = const {},
      this.exerciseSafetyMultiplier = 1.0,
      this.nutritionPhaseMultiplier = 1.0,
      required this.hoursSinceLastMeal,
      this.minutesToWindowClose,
      this.sleepRecoveryScore = 0.5})
      : _activeSyncViolations = activeSyncViolations,
        _syncMetrics = syncMetrics,
        super._();

  factory _$OrchestratorStateImpl.fromJson(Map<String, dynamic> json) =>
      _$$OrchestratorStateImplFromJson(json);

  /// Última actualización del estado
  @override
  final DateTime lastUpdated;

  /// Fase actual de ayuno (ALERTA, GLUCONEOGÉNESIS, CETOSIS, AUTOFAGIA)
  @override
  final String currentFastingPhase;

  /// Fase circadiana actual (ALERTA, ENERGÍA, CREPÚSCULO, SUEÑO, LIMPIEZA)
  @override
  final String currentCircadianPhase;

  /// Horas de ayuno actual
  @override
  final double fastedHours;

  /// Es seguro hacer ejercicio ahora
  @override
  final bool canExerciseNow;

  /// Es seguro comer ahora (dentro de ventana circadiana)
  @override
  final bool canEatNow;

  /// Tipo de ejercicio recomendado (LISS, STRENGTH, HIIT o null)
  @override
  final String? exerciseRecommendedType;

  /// Intensidad recomendada (0-100 percent)
  @override
  @JsonKey()
  final int exerciseRecommendedIntensity;

  /// Es óptimo continuar en ayuno
  @override
  final bool isOptimalForFasting;

  /// Score de sincronización metabólica (0-1)
  @override
  final double metabolicCoherence;

  /// Violaciones activas (lista de strings descriptivos)
  final List<String> _activeSyncViolations;

  /// Violaciones activas (lista de strings descriptivos)
  @override
  @JsonKey()
  List<String> get activeSyncViolations {
    if (_activeSyncViolations is EqualUnmodifiableListView)
      return _activeSyncViolations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activeSyncViolations);
  }

  /// Sugerencia de acción principal para ahora
  @override
  final String? primaryActionSuggestion;

  /// Cache de scores por pilar
  final Map<String, double> _syncMetrics;

  /// Cache de scores por pilar
  @override
  @JsonKey()
  Map<String, double> get syncMetrics {
    if (_syncMetrics is EqualUnmodifiableMapView) return _syncMetrics;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_syncMetrics);
  }

  /// Penalización de ejercicio por estado de ayuno (0-1, donde 1 = sin penalización)
  @override
  @JsonKey()
  final double exerciseSafetyMultiplier;

  /// Penalización de nutrición por fase circadiana (0-1)
  @override
  @JsonKey()
  final double nutritionPhaseMultiplier;

  /// Horas desde última comida
  @override
  final double hoursSinceLastMeal;

  /// Minutos hasta cierre de ventana de comida
  @override
  final int? minutesToWindowClose;

  /// Recovery status del sueño (0-1)
  @override
  @JsonKey()
  final double sleepRecoveryScore;

  @override
  String toString() {
    return 'OrchestratorState(lastUpdated: $lastUpdated, currentFastingPhase: $currentFastingPhase, currentCircadianPhase: $currentCircadianPhase, fastedHours: $fastedHours, canExerciseNow: $canExerciseNow, canEatNow: $canEatNow, exerciseRecommendedType: $exerciseRecommendedType, exerciseRecommendedIntensity: $exerciseRecommendedIntensity, isOptimalForFasting: $isOptimalForFasting, metabolicCoherence: $metabolicCoherence, activeSyncViolations: $activeSyncViolations, primaryActionSuggestion: $primaryActionSuggestion, syncMetrics: $syncMetrics, exerciseSafetyMultiplier: $exerciseSafetyMultiplier, nutritionPhaseMultiplier: $nutritionPhaseMultiplier, hoursSinceLastMeal: $hoursSinceLastMeal, minutesToWindowClose: $minutesToWindowClose, sleepRecoveryScore: $sleepRecoveryScore)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrchestratorStateImpl &&
            (identical(other.lastUpdated, lastUpdated) ||
                other.lastUpdated == lastUpdated) &&
            (identical(other.currentFastingPhase, currentFastingPhase) ||
                other.currentFastingPhase == currentFastingPhase) &&
            (identical(other.currentCircadianPhase, currentCircadianPhase) ||
                other.currentCircadianPhase == currentCircadianPhase) &&
            (identical(other.fastedHours, fastedHours) ||
                other.fastedHours == fastedHours) &&
            (identical(other.canExerciseNow, canExerciseNow) ||
                other.canExerciseNow == canExerciseNow) &&
            (identical(other.canEatNow, canEatNow) ||
                other.canEatNow == canEatNow) &&
            (identical(other.exerciseRecommendedType, exerciseRecommendedType) ||
                other.exerciseRecommendedType == exerciseRecommendedType) &&
            (identical(other.exerciseRecommendedIntensity,
                    exerciseRecommendedIntensity) ||
                other.exerciseRecommendedIntensity ==
                    exerciseRecommendedIntensity) &&
            (identical(other.isOptimalForFasting, isOptimalForFasting) ||
                other.isOptimalForFasting == isOptimalForFasting) &&
            (identical(other.metabolicCoherence, metabolicCoherence) ||
                other.metabolicCoherence == metabolicCoherence) &&
            const DeepCollectionEquality()
                .equals(other._activeSyncViolations, _activeSyncViolations) &&
            (identical(
                    other.primaryActionSuggestion, primaryActionSuggestion) ||
                other.primaryActionSuggestion == primaryActionSuggestion) &&
            const DeepCollectionEquality()
                .equals(other._syncMetrics, _syncMetrics) &&
            (identical(
                    other.exerciseSafetyMultiplier, exerciseSafetyMultiplier) ||
                other.exerciseSafetyMultiplier == exerciseSafetyMultiplier) &&
            (identical(
                    other.nutritionPhaseMultiplier, nutritionPhaseMultiplier) ||
                other.nutritionPhaseMultiplier == nutritionPhaseMultiplier) &&
            (identical(other.hoursSinceLastMeal, hoursSinceLastMeal) ||
                other.hoursSinceLastMeal == hoursSinceLastMeal) &&
            (identical(other.minutesToWindowClose, minutesToWindowClose) ||
                other.minutesToWindowClose == minutesToWindowClose) &&
            (identical(other.sleepRecoveryScore, sleepRecoveryScore) ||
                other.sleepRecoveryScore == sleepRecoveryScore));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      lastUpdated,
      currentFastingPhase,
      currentCircadianPhase,
      fastedHours,
      canExerciseNow,
      canEatNow,
      exerciseRecommendedType,
      exerciseRecommendedIntensity,
      isOptimalForFasting,
      metabolicCoherence,
      const DeepCollectionEquality().hash(_activeSyncViolations),
      primaryActionSuggestion,
      const DeepCollectionEquality().hash(_syncMetrics),
      exerciseSafetyMultiplier,
      nutritionPhaseMultiplier,
      hoursSinceLastMeal,
      minutesToWindowClose,
      sleepRecoveryScore);

  /// Create a copy of OrchestratorState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrchestratorStateImplCopyWith<_$OrchestratorStateImpl> get copyWith =>
      __$$OrchestratorStateImplCopyWithImpl<_$OrchestratorStateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$OrchestratorStateImplToJson(
      this,
    );
  }
}

abstract class _OrchestratorState extends OrchestratorState {
  const factory _OrchestratorState(
      {required final DateTime lastUpdated,
      required final String currentFastingPhase,
      required final String currentCircadianPhase,
      required final double fastedHours,
      required final bool canExerciseNow,
      required final bool canEatNow,
      final String? exerciseRecommendedType,
      final int exerciseRecommendedIntensity,
      required final bool isOptimalForFasting,
      required final double metabolicCoherence,
      final List<String> activeSyncViolations,
      final String? primaryActionSuggestion,
      final Map<String, double> syncMetrics,
      final double exerciseSafetyMultiplier,
      final double nutritionPhaseMultiplier,
      required final double hoursSinceLastMeal,
      final int? minutesToWindowClose,
      final double sleepRecoveryScore}) = _$OrchestratorStateImpl;
  const _OrchestratorState._() : super._();

  factory _OrchestratorState.fromJson(Map<String, dynamic> json) =
      _$OrchestratorStateImpl.fromJson;

  /// Última actualización del estado
  @override
  DateTime get lastUpdated;

  /// Fase actual de ayuno (ALERTA, GLUCONEOGÉNESIS, CETOSIS, AUTOFAGIA)
  @override
  String get currentFastingPhase;

  /// Fase circadiana actual (ALERTA, ENERGÍA, CREPÚSCULO, SUEÑO, LIMPIEZA)
  @override
  String get currentCircadianPhase;

  /// Horas de ayuno actual
  @override
  double get fastedHours;

  /// Es seguro hacer ejercicio ahora
  @override
  bool get canExerciseNow;

  /// Es seguro comer ahora (dentro de ventana circadiana)
  @override
  bool get canEatNow;

  /// Tipo de ejercicio recomendado (LISS, STRENGTH, HIIT o null)
  @override
  String? get exerciseRecommendedType;

  /// Intensidad recomendada (0-100 percent)
  @override
  int get exerciseRecommendedIntensity;

  /// Es óptimo continuar en ayuno
  @override
  bool get isOptimalForFasting;

  /// Score de sincronización metabólica (0-1)
  @override
  double get metabolicCoherence;

  /// Violaciones activas (lista de strings descriptivos)
  @override
  List<String> get activeSyncViolations;

  /// Sugerencia de acción principal para ahora
  @override
  String? get primaryActionSuggestion;

  /// Cache de scores por pilar
  @override
  Map<String, double> get syncMetrics;

  /// Penalización de ejercicio por estado de ayuno (0-1, donde 1 = sin penalización)
  @override
  double get exerciseSafetyMultiplier;

  /// Penalización de nutrición por fase circadiana (0-1)
  @override
  double get nutritionPhaseMultiplier;

  /// Horas desde última comida
  @override
  double get hoursSinceLastMeal;

  /// Minutos hasta cierre de ventana de comida
  @override
  int? get minutesToWindowClose;

  /// Recovery status del sueño (0-1)
  @override
  double get sleepRecoveryScore;

  /// Create a copy of OrchestratorState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrchestratorStateImplCopyWith<_$OrchestratorStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
