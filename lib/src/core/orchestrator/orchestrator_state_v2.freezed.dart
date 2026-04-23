// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'orchestrator_state_v2.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$OrchestratorStateV2 {
// ── Fases biológicas (tipadas) ──────────────────────────────────────
  FastingPhase get fastingPhase => throw _privateConstructorUsedError;
  CircadianPhase get circadianPhase =>
      throw _privateConstructorUsedError; // ── Decisiones booleanas ────────────────────────────────────────────
  bool get canExerciseNow => throw _privateConstructorUsedError;
  bool get canEatNow => throw _privateConstructorUsedError;
  bool get isOptimalForFasting => throw _privateConstructorUsedError;
  bool get isInNutritionWindow =>
      throw _privateConstructorUsedError; // ── Multiplicadores de seguridad (0.0–1.0) ─────────────────────────
  double get exerciseSafetyMultiplier => throw _privateConstructorUsedError;
  double get nutritionPhaseMultiplier =>
      throw _privateConstructorUsedError; // ── Recomendaciones tipadas ─────────────────────────────────────────
  List<Recommendation> get recommendations =>
      throw _privateConstructorUsedError; // ── Ejercicio ───────────────────────────────────────────────────────
  String? get exerciseRecommendedType => throw _privateConstructorUsedError;
  int get exerciseRecommendedIntensity =>
      throw _privateConstructorUsedError; // ── Coherencia y violaciones ────────────────────────────────────────
  double get metabolicCoherence => throw _privateConstructorUsedError;
  List<String> get activeSyncViolations =>
      throw _privateConstructorUsedError; // ── Datos temporales crudos ─────────────────────────────────────────
  double get fastedHours => throw _privateConstructorUsedError;
  double get hoursSinceLastMeal => throw _privateConstructorUsedError;
  int? get minutesToWindowClose =>
      throw _privateConstructorUsedError; // ── Timestamp de la fuente de datos ─────────────────────────────────
  DateTime get sourceTimestamp => throw _privateConstructorUsedError;

  /// Create a copy of OrchestratorStateV2
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $OrchestratorStateV2CopyWith<OrchestratorStateV2> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $OrchestratorStateV2CopyWith<$Res> {
  factory $OrchestratorStateV2CopyWith(
          OrchestratorStateV2 value, $Res Function(OrchestratorStateV2) then) =
      _$OrchestratorStateV2CopyWithImpl<$Res, OrchestratorStateV2>;
  @useResult
  $Res call(
      {FastingPhase fastingPhase,
      CircadianPhase circadianPhase,
      bool canExerciseNow,
      bool canEatNow,
      bool isOptimalForFasting,
      bool isInNutritionWindow,
      double exerciseSafetyMultiplier,
      double nutritionPhaseMultiplier,
      List<Recommendation> recommendations,
      String? exerciseRecommendedType,
      int exerciseRecommendedIntensity,
      double metabolicCoherence,
      List<String> activeSyncViolations,
      double fastedHours,
      double hoursSinceLastMeal,
      int? minutesToWindowClose,
      DateTime sourceTimestamp});
}

/// @nodoc
class _$OrchestratorStateV2CopyWithImpl<$Res, $Val extends OrchestratorStateV2>
    implements $OrchestratorStateV2CopyWith<$Res> {
  _$OrchestratorStateV2CopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of OrchestratorStateV2
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fastingPhase = null,
    Object? circadianPhase = null,
    Object? canExerciseNow = null,
    Object? canEatNow = null,
    Object? isOptimalForFasting = null,
    Object? isInNutritionWindow = null,
    Object? exerciseSafetyMultiplier = null,
    Object? nutritionPhaseMultiplier = null,
    Object? recommendations = null,
    Object? exerciseRecommendedType = freezed,
    Object? exerciseRecommendedIntensity = null,
    Object? metabolicCoherence = null,
    Object? activeSyncViolations = null,
    Object? fastedHours = null,
    Object? hoursSinceLastMeal = null,
    Object? minutesToWindowClose = freezed,
    Object? sourceTimestamp = null,
  }) {
    return _then(_value.copyWith(
      fastingPhase: null == fastingPhase
          ? _value.fastingPhase
          : fastingPhase // ignore: cast_nullable_to_non_nullable
              as FastingPhase,
      circadianPhase: null == circadianPhase
          ? _value.circadianPhase
          : circadianPhase // ignore: cast_nullable_to_non_nullable
              as CircadianPhase,
      canExerciseNow: null == canExerciseNow
          ? _value.canExerciseNow
          : canExerciseNow // ignore: cast_nullable_to_non_nullable
              as bool,
      canEatNow: null == canEatNow
          ? _value.canEatNow
          : canEatNow // ignore: cast_nullable_to_non_nullable
              as bool,
      isOptimalForFasting: null == isOptimalForFasting
          ? _value.isOptimalForFasting
          : isOptimalForFasting // ignore: cast_nullable_to_non_nullable
              as bool,
      isInNutritionWindow: null == isInNutritionWindow
          ? _value.isInNutritionWindow
          : isInNutritionWindow // ignore: cast_nullable_to_non_nullable
              as bool,
      exerciseSafetyMultiplier: null == exerciseSafetyMultiplier
          ? _value.exerciseSafetyMultiplier
          : exerciseSafetyMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      nutritionPhaseMultiplier: null == nutritionPhaseMultiplier
          ? _value.nutritionPhaseMultiplier
          : nutritionPhaseMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      recommendations: null == recommendations
          ? _value.recommendations
          : recommendations // ignore: cast_nullable_to_non_nullable
              as List<Recommendation>,
      exerciseRecommendedType: freezed == exerciseRecommendedType
          ? _value.exerciseRecommendedType
          : exerciseRecommendedType // ignore: cast_nullable_to_non_nullable
              as String?,
      exerciseRecommendedIntensity: null == exerciseRecommendedIntensity
          ? _value.exerciseRecommendedIntensity
          : exerciseRecommendedIntensity // ignore: cast_nullable_to_non_nullable
              as int,
      metabolicCoherence: null == metabolicCoherence
          ? _value.metabolicCoherence
          : metabolicCoherence // ignore: cast_nullable_to_non_nullable
              as double,
      activeSyncViolations: null == activeSyncViolations
          ? _value.activeSyncViolations
          : activeSyncViolations // ignore: cast_nullable_to_non_nullable
              as List<String>,
      fastedHours: null == fastedHours
          ? _value.fastedHours
          : fastedHours // ignore: cast_nullable_to_non_nullable
              as double,
      hoursSinceLastMeal: null == hoursSinceLastMeal
          ? _value.hoursSinceLastMeal
          : hoursSinceLastMeal // ignore: cast_nullable_to_non_nullable
              as double,
      minutesToWindowClose: freezed == minutesToWindowClose
          ? _value.minutesToWindowClose
          : minutesToWindowClose // ignore: cast_nullable_to_non_nullable
              as int?,
      sourceTimestamp: null == sourceTimestamp
          ? _value.sourceTimestamp
          : sourceTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$OrchestratorStateV2ImplCopyWith<$Res>
    implements $OrchestratorStateV2CopyWith<$Res> {
  factory _$$OrchestratorStateV2ImplCopyWith(_$OrchestratorStateV2Impl value,
          $Res Function(_$OrchestratorStateV2Impl) then) =
      __$$OrchestratorStateV2ImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {FastingPhase fastingPhase,
      CircadianPhase circadianPhase,
      bool canExerciseNow,
      bool canEatNow,
      bool isOptimalForFasting,
      bool isInNutritionWindow,
      double exerciseSafetyMultiplier,
      double nutritionPhaseMultiplier,
      List<Recommendation> recommendations,
      String? exerciseRecommendedType,
      int exerciseRecommendedIntensity,
      double metabolicCoherence,
      List<String> activeSyncViolations,
      double fastedHours,
      double hoursSinceLastMeal,
      int? minutesToWindowClose,
      DateTime sourceTimestamp});
}

/// @nodoc
class __$$OrchestratorStateV2ImplCopyWithImpl<$Res>
    extends _$OrchestratorStateV2CopyWithImpl<$Res, _$OrchestratorStateV2Impl>
    implements _$$OrchestratorStateV2ImplCopyWith<$Res> {
  __$$OrchestratorStateV2ImplCopyWithImpl(_$OrchestratorStateV2Impl _value,
      $Res Function(_$OrchestratorStateV2Impl) _then)
      : super(_value, _then);

  /// Create a copy of OrchestratorStateV2
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? fastingPhase = null,
    Object? circadianPhase = null,
    Object? canExerciseNow = null,
    Object? canEatNow = null,
    Object? isOptimalForFasting = null,
    Object? isInNutritionWindow = null,
    Object? exerciseSafetyMultiplier = null,
    Object? nutritionPhaseMultiplier = null,
    Object? recommendations = null,
    Object? exerciseRecommendedType = freezed,
    Object? exerciseRecommendedIntensity = null,
    Object? metabolicCoherence = null,
    Object? activeSyncViolations = null,
    Object? fastedHours = null,
    Object? hoursSinceLastMeal = null,
    Object? minutesToWindowClose = freezed,
    Object? sourceTimestamp = null,
  }) {
    return _then(_$OrchestratorStateV2Impl(
      fastingPhase: null == fastingPhase
          ? _value.fastingPhase
          : fastingPhase // ignore: cast_nullable_to_non_nullable
              as FastingPhase,
      circadianPhase: null == circadianPhase
          ? _value.circadianPhase
          : circadianPhase // ignore: cast_nullable_to_non_nullable
              as CircadianPhase,
      canExerciseNow: null == canExerciseNow
          ? _value.canExerciseNow
          : canExerciseNow // ignore: cast_nullable_to_non_nullable
              as bool,
      canEatNow: null == canEatNow
          ? _value.canEatNow
          : canEatNow // ignore: cast_nullable_to_non_nullable
              as bool,
      isOptimalForFasting: null == isOptimalForFasting
          ? _value.isOptimalForFasting
          : isOptimalForFasting // ignore: cast_nullable_to_non_nullable
              as bool,
      isInNutritionWindow: null == isInNutritionWindow
          ? _value.isInNutritionWindow
          : isInNutritionWindow // ignore: cast_nullable_to_non_nullable
              as bool,
      exerciseSafetyMultiplier: null == exerciseSafetyMultiplier
          ? _value.exerciseSafetyMultiplier
          : exerciseSafetyMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      nutritionPhaseMultiplier: null == nutritionPhaseMultiplier
          ? _value.nutritionPhaseMultiplier
          : nutritionPhaseMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
      recommendations: null == recommendations
          ? _value._recommendations
          : recommendations // ignore: cast_nullable_to_non_nullable
              as List<Recommendation>,
      exerciseRecommendedType: freezed == exerciseRecommendedType
          ? _value.exerciseRecommendedType
          : exerciseRecommendedType // ignore: cast_nullable_to_non_nullable
              as String?,
      exerciseRecommendedIntensity: null == exerciseRecommendedIntensity
          ? _value.exerciseRecommendedIntensity
          : exerciseRecommendedIntensity // ignore: cast_nullable_to_non_nullable
              as int,
      metabolicCoherence: null == metabolicCoherence
          ? _value.metabolicCoherence
          : metabolicCoherence // ignore: cast_nullable_to_non_nullable
              as double,
      activeSyncViolations: null == activeSyncViolations
          ? _value._activeSyncViolations
          : activeSyncViolations // ignore: cast_nullable_to_non_nullable
              as List<String>,
      fastedHours: null == fastedHours
          ? _value.fastedHours
          : fastedHours // ignore: cast_nullable_to_non_nullable
              as double,
      hoursSinceLastMeal: null == hoursSinceLastMeal
          ? _value.hoursSinceLastMeal
          : hoursSinceLastMeal // ignore: cast_nullable_to_non_nullable
              as double,
      minutesToWindowClose: freezed == minutesToWindowClose
          ? _value.minutesToWindowClose
          : minutesToWindowClose // ignore: cast_nullable_to_non_nullable
              as int?,
      sourceTimestamp: null == sourceTimestamp
          ? _value.sourceTimestamp
          : sourceTimestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc

class _$OrchestratorStateV2Impl extends _OrchestratorStateV2 {
  const _$OrchestratorStateV2Impl(
      {required this.fastingPhase,
      required this.circadianPhase,
      required this.canExerciseNow,
      required this.canEatNow,
      required this.isOptimalForFasting,
      required this.isInNutritionWindow,
      required this.exerciseSafetyMultiplier,
      required this.nutritionPhaseMultiplier,
      required final List<Recommendation> recommendations,
      this.exerciseRecommendedType,
      this.exerciseRecommendedIntensity = 0,
      required this.metabolicCoherence,
      final List<String> activeSyncViolations = const [],
      required this.fastedHours,
      required this.hoursSinceLastMeal,
      this.minutesToWindowClose,
      required this.sourceTimestamp})
      : _recommendations = recommendations,
        _activeSyncViolations = activeSyncViolations,
        super._();

// ── Fases biológicas (tipadas) ──────────────────────────────────────
  @override
  final FastingPhase fastingPhase;
  @override
  final CircadianPhase circadianPhase;
// ── Decisiones booleanas ────────────────────────────────────────────
  @override
  final bool canExerciseNow;
  @override
  final bool canEatNow;
  @override
  final bool isOptimalForFasting;
  @override
  final bool isInNutritionWindow;
// ── Multiplicadores de seguridad (0.0–1.0) ─────────────────────────
  @override
  final double exerciseSafetyMultiplier;
  @override
  final double nutritionPhaseMultiplier;
// ── Recomendaciones tipadas ─────────────────────────────────────────
  final List<Recommendation> _recommendations;
// ── Recomendaciones tipadas ─────────────────────────────────────────
  @override
  List<Recommendation> get recommendations {
    if (_recommendations is EqualUnmodifiableListView) return _recommendations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_recommendations);
  }

// ── Ejercicio ───────────────────────────────────────────────────────
  @override
  final String? exerciseRecommendedType;
  @override
  @JsonKey()
  final int exerciseRecommendedIntensity;
// ── Coherencia y violaciones ────────────────────────────────────────
  @override
  final double metabolicCoherence;
  final List<String> _activeSyncViolations;
  @override
  @JsonKey()
  List<String> get activeSyncViolations {
    if (_activeSyncViolations is EqualUnmodifiableListView)
      return _activeSyncViolations;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_activeSyncViolations);
  }

// ── Datos temporales crudos ─────────────────────────────────────────
  @override
  final double fastedHours;
  @override
  final double hoursSinceLastMeal;
  @override
  final int? minutesToWindowClose;
// ── Timestamp de la fuente de datos ─────────────────────────────────
  @override
  final DateTime sourceTimestamp;

  @override
  String toString() {
    return 'OrchestratorStateV2(fastingPhase: $fastingPhase, circadianPhase: $circadianPhase, canExerciseNow: $canExerciseNow, canEatNow: $canEatNow, isOptimalForFasting: $isOptimalForFasting, isInNutritionWindow: $isInNutritionWindow, exerciseSafetyMultiplier: $exerciseSafetyMultiplier, nutritionPhaseMultiplier: $nutritionPhaseMultiplier, recommendations: $recommendations, exerciseRecommendedType: $exerciseRecommendedType, exerciseRecommendedIntensity: $exerciseRecommendedIntensity, metabolicCoherence: $metabolicCoherence, activeSyncViolations: $activeSyncViolations, fastedHours: $fastedHours, hoursSinceLastMeal: $hoursSinceLastMeal, minutesToWindowClose: $minutesToWindowClose, sourceTimestamp: $sourceTimestamp)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$OrchestratorStateV2Impl &&
            (identical(other.fastingPhase, fastingPhase) ||
                other.fastingPhase == fastingPhase) &&
            (identical(other.circadianPhase, circadianPhase) ||
                other.circadianPhase == circadianPhase) &&
            (identical(other.canExerciseNow, canExerciseNow) ||
                other.canExerciseNow == canExerciseNow) &&
            (identical(other.canEatNow, canEatNow) ||
                other.canEatNow == canEatNow) &&
            (identical(other.isOptimalForFasting, isOptimalForFasting) ||
                other.isOptimalForFasting == isOptimalForFasting) &&
            (identical(other.isInNutritionWindow, isInNutritionWindow) ||
                other.isInNutritionWindow == isInNutritionWindow) &&
            (identical(
                    other.exerciseSafetyMultiplier, exerciseSafetyMultiplier) ||
                other.exerciseSafetyMultiplier == exerciseSafetyMultiplier) &&
            (identical(
                    other.nutritionPhaseMultiplier, nutritionPhaseMultiplier) ||
                other.nutritionPhaseMultiplier == nutritionPhaseMultiplier) &&
            const DeepCollectionEquality()
                .equals(other._recommendations, _recommendations) &&
            (identical(
                    other.exerciseRecommendedType, exerciseRecommendedType) ||
                other.exerciseRecommendedType == exerciseRecommendedType) &&
            (identical(other.exerciseRecommendedIntensity,
                    exerciseRecommendedIntensity) ||
                other.exerciseRecommendedIntensity ==
                    exerciseRecommendedIntensity) &&
            (identical(other.metabolicCoherence, metabolicCoherence) ||
                other.metabolicCoherence == metabolicCoherence) &&
            const DeepCollectionEquality()
                .equals(other._activeSyncViolations, _activeSyncViolations) &&
            (identical(other.fastedHours, fastedHours) ||
                other.fastedHours == fastedHours) &&
            (identical(other.hoursSinceLastMeal, hoursSinceLastMeal) ||
                other.hoursSinceLastMeal == hoursSinceLastMeal) &&
            (identical(other.minutesToWindowClose, minutesToWindowClose) ||
                other.minutesToWindowClose == minutesToWindowClose) &&
            (identical(other.sourceTimestamp, sourceTimestamp) ||
                other.sourceTimestamp == sourceTimestamp));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      fastingPhase,
      circadianPhase,
      canExerciseNow,
      canEatNow,
      isOptimalForFasting,
      isInNutritionWindow,
      exerciseSafetyMultiplier,
      nutritionPhaseMultiplier,
      const DeepCollectionEquality().hash(_recommendations),
      exerciseRecommendedType,
      exerciseRecommendedIntensity,
      metabolicCoherence,
      const DeepCollectionEquality().hash(_activeSyncViolations),
      fastedHours,
      hoursSinceLastMeal,
      minutesToWindowClose,
      sourceTimestamp);

  /// Create a copy of OrchestratorStateV2
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$OrchestratorStateV2ImplCopyWith<_$OrchestratorStateV2Impl> get copyWith =>
      __$$OrchestratorStateV2ImplCopyWithImpl<_$OrchestratorStateV2Impl>(
          this, _$identity);
}

abstract class _OrchestratorStateV2 extends OrchestratorStateV2 {
  const factory _OrchestratorStateV2(
      {required final FastingPhase fastingPhase,
      required final CircadianPhase circadianPhase,
      required final bool canExerciseNow,
      required final bool canEatNow,
      required final bool isOptimalForFasting,
      required final bool isInNutritionWindow,
      required final double exerciseSafetyMultiplier,
      required final double nutritionPhaseMultiplier,
      required final List<Recommendation> recommendations,
      final String? exerciseRecommendedType,
      final int exerciseRecommendedIntensity,
      required final double metabolicCoherence,
      final List<String> activeSyncViolations,
      required final double fastedHours,
      required final double hoursSinceLastMeal,
      final int? minutesToWindowClose,
      required final DateTime sourceTimestamp}) = _$OrchestratorStateV2Impl;
  const _OrchestratorStateV2._() : super._();

// ── Fases biológicas (tipadas) ──────────────────────────────────────
  @override
  FastingPhase get fastingPhase;
  @override
  CircadianPhase
      get circadianPhase; // ── Decisiones booleanas ────────────────────────────────────────────
  @override
  bool get canExerciseNow;
  @override
  bool get canEatNow;
  @override
  bool get isOptimalForFasting;
  @override
  bool
      get isInNutritionWindow; // ── Multiplicadores de seguridad (0.0–1.0) ─────────────────────────
  @override
  double get exerciseSafetyMultiplier;
  @override
  double
      get nutritionPhaseMultiplier; // ── Recomendaciones tipadas ─────────────────────────────────────────
  @override
  List<Recommendation>
      get recommendations; // ── Ejercicio ───────────────────────────────────────────────────────
  @override
  String? get exerciseRecommendedType;
  @override
  int get exerciseRecommendedIntensity; // ── Coherencia y violaciones ────────────────────────────────────────
  @override
  double get metabolicCoherence;
  @override
  List<String>
      get activeSyncViolations; // ── Datos temporales crudos ─────────────────────────────────────────
  @override
  double get fastedHours;
  @override
  double get hoursSinceLastMeal;
  @override
  int?
      get minutesToWindowClose; // ── Timestamp de la fuente de datos ─────────────────────────────────
  @override
  DateTime get sourceTimestamp;

  /// Create a copy of OrchestratorStateV2
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$OrchestratorStateV2ImplCopyWith<_$OrchestratorStateV2Impl> get copyWith =>
      throw _privateConstructorUsedError;
}
