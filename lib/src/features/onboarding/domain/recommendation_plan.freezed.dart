// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recommendation_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RecommendationPlan _$RecommendationPlanFromJson(Map<String, dynamic> json) {
  return _RecommendationPlan.fromJson(json);
}

/// @nodoc
mixin _$RecommendationPlan {
// 1. Hidratación
  double get dailyWaterIntakeLitres =>
      throw _privateConstructorUsedError; // 2. Ayuno
  String get recommendedFastingProtocol =>
      throw _privateConstructorUsedError; // e.g., '14:10'
  String get fastingWindowDescription =>
      throw _privateConstructorUsedError; // e.g., 'Cena antes de las 8pm'
// 3. Ejercicio (Zona 2 / MAF)
  int get exerciseZoneHeartRate =>
      throw _privateConstructorUsedError; // MAF 180 Formula
  String get exerciseFrequency =>
      throw _privateConstructorUsedError; // e.g., 'Caminata 45min diarios'
  String get exerciseDescription =>
      throw _privateConstructorUsedError; // Explicación de Zona 2
// 4. Monitoreo de Glucosa
  bool get requiresGlucometer => throw _privateConstructorUsedError;
  String? get glucoseTargetFasting =>
      throw _privateConstructorUsedError; // e.g., '< 100 mg/dL'
  String? get glucoseTargetPostMeal =>
      throw _privateConstructorUsedError; // e.g., '< 140 mg/dL'
  String? get monitoringFocusMessage =>
      throw _privateConstructorUsedError; // Mensaje educativo
// Metadata
  DateTime get generatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RecommendationPlanCopyWith<RecommendationPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecommendationPlanCopyWith<$Res> {
  factory $RecommendationPlanCopyWith(
          RecommendationPlan value, $Res Function(RecommendationPlan) then) =
      _$RecommendationPlanCopyWithImpl<$Res, RecommendationPlan>;
  @useResult
  $Res call(
      {double dailyWaterIntakeLitres,
      String recommendedFastingProtocol,
      String fastingWindowDescription,
      int exerciseZoneHeartRate,
      String exerciseFrequency,
      String exerciseDescription,
      bool requiresGlucometer,
      String? glucoseTargetFasting,
      String? glucoseTargetPostMeal,
      String? monitoringFocusMessage,
      DateTime generatedAt});
}

/// @nodoc
class _$RecommendationPlanCopyWithImpl<$Res, $Val extends RecommendationPlan>
    implements $RecommendationPlanCopyWith<$Res> {
  _$RecommendationPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dailyWaterIntakeLitres = null,
    Object? recommendedFastingProtocol = null,
    Object? fastingWindowDescription = null,
    Object? exerciseZoneHeartRate = null,
    Object? exerciseFrequency = null,
    Object? exerciseDescription = null,
    Object? requiresGlucometer = null,
    Object? glucoseTargetFasting = freezed,
    Object? glucoseTargetPostMeal = freezed,
    Object? monitoringFocusMessage = freezed,
    Object? generatedAt = null,
  }) {
    return _then(_value.copyWith(
      dailyWaterIntakeLitres: null == dailyWaterIntakeLitres
          ? _value.dailyWaterIntakeLitres
          : dailyWaterIntakeLitres // ignore: cast_nullable_to_non_nullable
              as double,
      recommendedFastingProtocol: null == recommendedFastingProtocol
          ? _value.recommendedFastingProtocol
          : recommendedFastingProtocol // ignore: cast_nullable_to_non_nullable
              as String,
      fastingWindowDescription: null == fastingWindowDescription
          ? _value.fastingWindowDescription
          : fastingWindowDescription // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseZoneHeartRate: null == exerciseZoneHeartRate
          ? _value.exerciseZoneHeartRate
          : exerciseZoneHeartRate // ignore: cast_nullable_to_non_nullable
              as int,
      exerciseFrequency: null == exerciseFrequency
          ? _value.exerciseFrequency
          : exerciseFrequency // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseDescription: null == exerciseDescription
          ? _value.exerciseDescription
          : exerciseDescription // ignore: cast_nullable_to_non_nullable
              as String,
      requiresGlucometer: null == requiresGlucometer
          ? _value.requiresGlucometer
          : requiresGlucometer // ignore: cast_nullable_to_non_nullable
              as bool,
      glucoseTargetFasting: freezed == glucoseTargetFasting
          ? _value.glucoseTargetFasting
          : glucoseTargetFasting // ignore: cast_nullable_to_non_nullable
              as String?,
      glucoseTargetPostMeal: freezed == glucoseTargetPostMeal
          ? _value.glucoseTargetPostMeal
          : glucoseTargetPostMeal // ignore: cast_nullable_to_non_nullable
              as String?,
      monitoringFocusMessage: freezed == monitoringFocusMessage
          ? _value.monitoringFocusMessage
          : monitoringFocusMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecommendationPlanImplCopyWith<$Res>
    implements $RecommendationPlanCopyWith<$Res> {
  factory _$$RecommendationPlanImplCopyWith(_$RecommendationPlanImpl value,
          $Res Function(_$RecommendationPlanImpl) then) =
      __$$RecommendationPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double dailyWaterIntakeLitres,
      String recommendedFastingProtocol,
      String fastingWindowDescription,
      int exerciseZoneHeartRate,
      String exerciseFrequency,
      String exerciseDescription,
      bool requiresGlucometer,
      String? glucoseTargetFasting,
      String? glucoseTargetPostMeal,
      String? monitoringFocusMessage,
      DateTime generatedAt});
}

/// @nodoc
class __$$RecommendationPlanImplCopyWithImpl<$Res>
    extends _$RecommendationPlanCopyWithImpl<$Res, _$RecommendationPlanImpl>
    implements _$$RecommendationPlanImplCopyWith<$Res> {
  __$$RecommendationPlanImplCopyWithImpl(_$RecommendationPlanImpl _value,
      $Res Function(_$RecommendationPlanImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dailyWaterIntakeLitres = null,
    Object? recommendedFastingProtocol = null,
    Object? fastingWindowDescription = null,
    Object? exerciseZoneHeartRate = null,
    Object? exerciseFrequency = null,
    Object? exerciseDescription = null,
    Object? requiresGlucometer = null,
    Object? glucoseTargetFasting = freezed,
    Object? glucoseTargetPostMeal = freezed,
    Object? monitoringFocusMessage = freezed,
    Object? generatedAt = null,
  }) {
    return _then(_$RecommendationPlanImpl(
      dailyWaterIntakeLitres: null == dailyWaterIntakeLitres
          ? _value.dailyWaterIntakeLitres
          : dailyWaterIntakeLitres // ignore: cast_nullable_to_non_nullable
              as double,
      recommendedFastingProtocol: null == recommendedFastingProtocol
          ? _value.recommendedFastingProtocol
          : recommendedFastingProtocol // ignore: cast_nullable_to_non_nullable
              as String,
      fastingWindowDescription: null == fastingWindowDescription
          ? _value.fastingWindowDescription
          : fastingWindowDescription // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseZoneHeartRate: null == exerciseZoneHeartRate
          ? _value.exerciseZoneHeartRate
          : exerciseZoneHeartRate // ignore: cast_nullable_to_non_nullable
              as int,
      exerciseFrequency: null == exerciseFrequency
          ? _value.exerciseFrequency
          : exerciseFrequency // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseDescription: null == exerciseDescription
          ? _value.exerciseDescription
          : exerciseDescription // ignore: cast_nullable_to_non_nullable
              as String,
      requiresGlucometer: null == requiresGlucometer
          ? _value.requiresGlucometer
          : requiresGlucometer // ignore: cast_nullable_to_non_nullable
              as bool,
      glucoseTargetFasting: freezed == glucoseTargetFasting
          ? _value.glucoseTargetFasting
          : glucoseTargetFasting // ignore: cast_nullable_to_non_nullable
              as String?,
      glucoseTargetPostMeal: freezed == glucoseTargetPostMeal
          ? _value.glucoseTargetPostMeal
          : glucoseTargetPostMeal // ignore: cast_nullable_to_non_nullable
              as String?,
      monitoringFocusMessage: freezed == monitoringFocusMessage
          ? _value.monitoringFocusMessage
          : monitoringFocusMessage // ignore: cast_nullable_to_non_nullable
              as String?,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecommendationPlanImpl implements _RecommendationPlan {
  const _$RecommendationPlanImpl(
      {required this.dailyWaterIntakeLitres,
      required this.recommendedFastingProtocol,
      required this.fastingWindowDescription,
      required this.exerciseZoneHeartRate,
      required this.exerciseFrequency,
      required this.exerciseDescription,
      required this.requiresGlucometer,
      this.glucoseTargetFasting,
      this.glucoseTargetPostMeal,
      this.monitoringFocusMessage,
      required this.generatedAt});

  factory _$RecommendationPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecommendationPlanImplFromJson(json);

// 1. Hidratación
  @override
  final double dailyWaterIntakeLitres;
// 2. Ayuno
  @override
  final String recommendedFastingProtocol;
// e.g., '14:10'
  @override
  final String fastingWindowDescription;
// e.g., 'Cena antes de las 8pm'
// 3. Ejercicio (Zona 2 / MAF)
  @override
  final int exerciseZoneHeartRate;
// MAF 180 Formula
  @override
  final String exerciseFrequency;
// e.g., 'Caminata 45min diarios'
  @override
  final String exerciseDescription;
// Explicación de Zona 2
// 4. Monitoreo de Glucosa
  @override
  final bool requiresGlucometer;
  @override
  final String? glucoseTargetFasting;
// e.g., '< 100 mg/dL'
  @override
  final String? glucoseTargetPostMeal;
// e.g., '< 140 mg/dL'
  @override
  final String? monitoringFocusMessage;
// Mensaje educativo
// Metadata
  @override
  final DateTime generatedAt;

  @override
  String toString() {
    return 'RecommendationPlan(dailyWaterIntakeLitres: $dailyWaterIntakeLitres, recommendedFastingProtocol: $recommendedFastingProtocol, fastingWindowDescription: $fastingWindowDescription, exerciseZoneHeartRate: $exerciseZoneHeartRate, exerciseFrequency: $exerciseFrequency, exerciseDescription: $exerciseDescription, requiresGlucometer: $requiresGlucometer, glucoseTargetFasting: $glucoseTargetFasting, glucoseTargetPostMeal: $glucoseTargetPostMeal, monitoringFocusMessage: $monitoringFocusMessage, generatedAt: $generatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecommendationPlanImpl &&
            (identical(other.dailyWaterIntakeLitres, dailyWaterIntakeLitres) ||
                other.dailyWaterIntakeLitres == dailyWaterIntakeLitres) &&
            (identical(other.recommendedFastingProtocol,
                    recommendedFastingProtocol) ||
                other.recommendedFastingProtocol ==
                    recommendedFastingProtocol) &&
            (identical(
                    other.fastingWindowDescription, fastingWindowDescription) ||
                other.fastingWindowDescription == fastingWindowDescription) &&
            (identical(other.exerciseZoneHeartRate, exerciseZoneHeartRate) ||
                other.exerciseZoneHeartRate == exerciseZoneHeartRate) &&
            (identical(other.exerciseFrequency, exerciseFrequency) ||
                other.exerciseFrequency == exerciseFrequency) &&
            (identical(other.exerciseDescription, exerciseDescription) ||
                other.exerciseDescription == exerciseDescription) &&
            (identical(other.requiresGlucometer, requiresGlucometer) ||
                other.requiresGlucometer == requiresGlucometer) &&
            (identical(other.glucoseTargetFasting, glucoseTargetFasting) ||
                other.glucoseTargetFasting == glucoseTargetFasting) &&
            (identical(other.glucoseTargetPostMeal, glucoseTargetPostMeal) ||
                other.glucoseTargetPostMeal == glucoseTargetPostMeal) &&
            (identical(other.monitoringFocusMessage, monitoringFocusMessage) ||
                other.monitoringFocusMessage == monitoringFocusMessage) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      dailyWaterIntakeLitres,
      recommendedFastingProtocol,
      fastingWindowDescription,
      exerciseZoneHeartRate,
      exerciseFrequency,
      exerciseDescription,
      requiresGlucometer,
      glucoseTargetFasting,
      glucoseTargetPostMeal,
      monitoringFocusMessage,
      generatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RecommendationPlanImplCopyWith<_$RecommendationPlanImpl> get copyWith =>
      __$$RecommendationPlanImplCopyWithImpl<_$RecommendationPlanImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecommendationPlanImplToJson(
      this,
    );
  }
}

abstract class _RecommendationPlan implements RecommendationPlan {
  const factory _RecommendationPlan(
      {required final double dailyWaterIntakeLitres,
      required final String recommendedFastingProtocol,
      required final String fastingWindowDescription,
      required final int exerciseZoneHeartRate,
      required final String exerciseFrequency,
      required final String exerciseDescription,
      required final bool requiresGlucometer,
      final String? glucoseTargetFasting,
      final String? glucoseTargetPostMeal,
      final String? monitoringFocusMessage,
      required final DateTime generatedAt}) = _$RecommendationPlanImpl;

  factory _RecommendationPlan.fromJson(Map<String, dynamic> json) =
      _$RecommendationPlanImpl.fromJson;

  @override // 1. Hidratación
  double get dailyWaterIntakeLitres;
  @override // 2. Ayuno
  String get recommendedFastingProtocol;
  @override // e.g., '14:10'
  String get fastingWindowDescription;
  @override // e.g., 'Cena antes de las 8pm'
// 3. Ejercicio (Zona 2 / MAF)
  int get exerciseZoneHeartRate;
  @override // MAF 180 Formula
  String get exerciseFrequency;
  @override // e.g., 'Caminata 45min diarios'
  String get exerciseDescription;
  @override // Explicación de Zona 2
// 4. Monitoreo de Glucosa
  bool get requiresGlucometer;
  @override
  String? get glucoseTargetFasting;
  @override // e.g., '< 100 mg/dL'
  String? get glucoseTargetPostMeal;
  @override // e.g., '< 140 mg/dL'
  String? get monitoringFocusMessage;
  @override // Mensaje educativo
// Metadata
  DateTime get generatedAt;
  @override
  @JsonKey(ignore: true)
  _$$RecommendationPlanImplCopyWith<_$RecommendationPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
