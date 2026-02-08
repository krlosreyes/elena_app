// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

HealthPlan _$HealthPlanFromJson(Map<String, dynamic> json) {
  return _HealthPlan.fromJson(json);
}

/// @nodoc
mixin _$HealthPlan {
// 1. Métricas Base
  String get protocol => throw _privateConstructorUsedError; // e.g. "16:8"
  int get hydrationGoal => throw _privateConstructorUsedError; // Vasil of 250ml
  int get maxHeartRate => throw _privateConstructorUsedError; // MAF 180
// 2. Estrategias Prescriptivas
  String get exerciseStrategy =>
      throw _privateConstructorUsedError; // e.g. "Caminata Rápida en Zona 2"
  String get exerciseFrequency =>
      throw _privateConstructorUsedError; // e.g. "45 min diarios"
  String get nutritionStrategy =>
      throw _privateConstructorUsedError; // e.g. "Dieta 3x1"
  String get breakingFastTip =>
      throw _privateConstructorUsedError; // e.g. "Romper con caldo"
// 3. Clínico
  String? get glucoseStrategy =>
      throw _privateConstructorUsedError; // e.g. "Meta < 140 mg/dL"
  String get whyThisPlan =>
      throw _privateConstructorUsedError; // Explicación personalizada
// Metadata
  DateTime get generatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HealthPlanCopyWith<HealthPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HealthPlanCopyWith<$Res> {
  factory $HealthPlanCopyWith(
          HealthPlan value, $Res Function(HealthPlan) then) =
      _$HealthPlanCopyWithImpl<$Res, HealthPlan>;
  @useResult
  $Res call(
      {String protocol,
      int hydrationGoal,
      int maxHeartRate,
      String exerciseStrategy,
      String exerciseFrequency,
      String nutritionStrategy,
      String breakingFastTip,
      String? glucoseStrategy,
      String whyThisPlan,
      DateTime generatedAt});
}

/// @nodoc
class _$HealthPlanCopyWithImpl<$Res, $Val extends HealthPlan>
    implements $HealthPlanCopyWith<$Res> {
  _$HealthPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? protocol = null,
    Object? hydrationGoal = null,
    Object? maxHeartRate = null,
    Object? exerciseStrategy = null,
    Object? exerciseFrequency = null,
    Object? nutritionStrategy = null,
    Object? breakingFastTip = null,
    Object? glucoseStrategy = freezed,
    Object? whyThisPlan = null,
    Object? generatedAt = null,
  }) {
    return _then(_value.copyWith(
      protocol: null == protocol
          ? _value.protocol
          : protocol // ignore: cast_nullable_to_non_nullable
              as String,
      hydrationGoal: null == hydrationGoal
          ? _value.hydrationGoal
          : hydrationGoal // ignore: cast_nullable_to_non_nullable
              as int,
      maxHeartRate: null == maxHeartRate
          ? _value.maxHeartRate
          : maxHeartRate // ignore: cast_nullable_to_non_nullable
              as int,
      exerciseStrategy: null == exerciseStrategy
          ? _value.exerciseStrategy
          : exerciseStrategy // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseFrequency: null == exerciseFrequency
          ? _value.exerciseFrequency
          : exerciseFrequency // ignore: cast_nullable_to_non_nullable
              as String,
      nutritionStrategy: null == nutritionStrategy
          ? _value.nutritionStrategy
          : nutritionStrategy // ignore: cast_nullable_to_non_nullable
              as String,
      breakingFastTip: null == breakingFastTip
          ? _value.breakingFastTip
          : breakingFastTip // ignore: cast_nullable_to_non_nullable
              as String,
      glucoseStrategy: freezed == glucoseStrategy
          ? _value.glucoseStrategy
          : glucoseStrategy // ignore: cast_nullable_to_non_nullable
              as String?,
      whyThisPlan: null == whyThisPlan
          ? _value.whyThisPlan
          : whyThisPlan // ignore: cast_nullable_to_non_nullable
              as String,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HealthPlanImplCopyWith<$Res>
    implements $HealthPlanCopyWith<$Res> {
  factory _$$HealthPlanImplCopyWith(
          _$HealthPlanImpl value, $Res Function(_$HealthPlanImpl) then) =
      __$$HealthPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String protocol,
      int hydrationGoal,
      int maxHeartRate,
      String exerciseStrategy,
      String exerciseFrequency,
      String nutritionStrategy,
      String breakingFastTip,
      String? glucoseStrategy,
      String whyThisPlan,
      DateTime generatedAt});
}

/// @nodoc
class __$$HealthPlanImplCopyWithImpl<$Res>
    extends _$HealthPlanCopyWithImpl<$Res, _$HealthPlanImpl>
    implements _$$HealthPlanImplCopyWith<$Res> {
  __$$HealthPlanImplCopyWithImpl(
      _$HealthPlanImpl _value, $Res Function(_$HealthPlanImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? protocol = null,
    Object? hydrationGoal = null,
    Object? maxHeartRate = null,
    Object? exerciseStrategy = null,
    Object? exerciseFrequency = null,
    Object? nutritionStrategy = null,
    Object? breakingFastTip = null,
    Object? glucoseStrategy = freezed,
    Object? whyThisPlan = null,
    Object? generatedAt = null,
  }) {
    return _then(_$HealthPlanImpl(
      protocol: null == protocol
          ? _value.protocol
          : protocol // ignore: cast_nullable_to_non_nullable
              as String,
      hydrationGoal: null == hydrationGoal
          ? _value.hydrationGoal
          : hydrationGoal // ignore: cast_nullable_to_non_nullable
              as int,
      maxHeartRate: null == maxHeartRate
          ? _value.maxHeartRate
          : maxHeartRate // ignore: cast_nullable_to_non_nullable
              as int,
      exerciseStrategy: null == exerciseStrategy
          ? _value.exerciseStrategy
          : exerciseStrategy // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseFrequency: null == exerciseFrequency
          ? _value.exerciseFrequency
          : exerciseFrequency // ignore: cast_nullable_to_non_nullable
              as String,
      nutritionStrategy: null == nutritionStrategy
          ? _value.nutritionStrategy
          : nutritionStrategy // ignore: cast_nullable_to_non_nullable
              as String,
      breakingFastTip: null == breakingFastTip
          ? _value.breakingFastTip
          : breakingFastTip // ignore: cast_nullable_to_non_nullable
              as String,
      glucoseStrategy: freezed == glucoseStrategy
          ? _value.glucoseStrategy
          : glucoseStrategy // ignore: cast_nullable_to_non_nullable
              as String?,
      whyThisPlan: null == whyThisPlan
          ? _value.whyThisPlan
          : whyThisPlan // ignore: cast_nullable_to_non_nullable
              as String,
      generatedAt: null == generatedAt
          ? _value.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HealthPlanImpl implements _HealthPlan {
  const _$HealthPlanImpl(
      {required this.protocol,
      required this.hydrationGoal,
      required this.maxHeartRate,
      required this.exerciseStrategy,
      required this.exerciseFrequency,
      required this.nutritionStrategy,
      required this.breakingFastTip,
      this.glucoseStrategy,
      required this.whyThisPlan,
      required this.generatedAt});

  factory _$HealthPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$HealthPlanImplFromJson(json);

// 1. Métricas Base
  @override
  final String protocol;
// e.g. "16:8"
  @override
  final int hydrationGoal;
// Vasil of 250ml
  @override
  final int maxHeartRate;
// MAF 180
// 2. Estrategias Prescriptivas
  @override
  final String exerciseStrategy;
// e.g. "Caminata Rápida en Zona 2"
  @override
  final String exerciseFrequency;
// e.g. "45 min diarios"
  @override
  final String nutritionStrategy;
// e.g. "Dieta 3x1"
  @override
  final String breakingFastTip;
// e.g. "Romper con caldo"
// 3. Clínico
  @override
  final String? glucoseStrategy;
// e.g. "Meta < 140 mg/dL"
  @override
  final String whyThisPlan;
// Explicación personalizada
// Metadata
  @override
  final DateTime generatedAt;

  @override
  String toString() {
    return 'HealthPlan(protocol: $protocol, hydrationGoal: $hydrationGoal, maxHeartRate: $maxHeartRate, exerciseStrategy: $exerciseStrategy, exerciseFrequency: $exerciseFrequency, nutritionStrategy: $nutritionStrategy, breakingFastTip: $breakingFastTip, glucoseStrategy: $glucoseStrategy, whyThisPlan: $whyThisPlan, generatedAt: $generatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HealthPlanImpl &&
            (identical(other.protocol, protocol) ||
                other.protocol == protocol) &&
            (identical(other.hydrationGoal, hydrationGoal) ||
                other.hydrationGoal == hydrationGoal) &&
            (identical(other.maxHeartRate, maxHeartRate) ||
                other.maxHeartRate == maxHeartRate) &&
            (identical(other.exerciseStrategy, exerciseStrategy) ||
                other.exerciseStrategy == exerciseStrategy) &&
            (identical(other.exerciseFrequency, exerciseFrequency) ||
                other.exerciseFrequency == exerciseFrequency) &&
            (identical(other.nutritionStrategy, nutritionStrategy) ||
                other.nutritionStrategy == nutritionStrategy) &&
            (identical(other.breakingFastTip, breakingFastTip) ||
                other.breakingFastTip == breakingFastTip) &&
            (identical(other.glucoseStrategy, glucoseStrategy) ||
                other.glucoseStrategy == glucoseStrategy) &&
            (identical(other.whyThisPlan, whyThisPlan) ||
                other.whyThisPlan == whyThisPlan) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      protocol,
      hydrationGoal,
      maxHeartRate,
      exerciseStrategy,
      exerciseFrequency,
      nutritionStrategy,
      breakingFastTip,
      glucoseStrategy,
      whyThisPlan,
      generatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HealthPlanImplCopyWith<_$HealthPlanImpl> get copyWith =>
      __$$HealthPlanImplCopyWithImpl<_$HealthPlanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HealthPlanImplToJson(
      this,
    );
  }
}

abstract class _HealthPlan implements HealthPlan {
  const factory _HealthPlan(
      {required final String protocol,
      required final int hydrationGoal,
      required final int maxHeartRate,
      required final String exerciseStrategy,
      required final String exerciseFrequency,
      required final String nutritionStrategy,
      required final String breakingFastTip,
      final String? glucoseStrategy,
      required final String whyThisPlan,
      required final DateTime generatedAt}) = _$HealthPlanImpl;

  factory _HealthPlan.fromJson(Map<String, dynamic> json) =
      _$HealthPlanImpl.fromJson;

  @override // 1. Métricas Base
  String get protocol;
  @override // e.g. "16:8"
  int get hydrationGoal;
  @override // Vasil of 250ml
  int get maxHeartRate;
  @override // MAF 180
// 2. Estrategias Prescriptivas
  String get exerciseStrategy;
  @override // e.g. "Caminata Rápida en Zona 2"
  String get exerciseFrequency;
  @override // e.g. "45 min diarios"
  String get nutritionStrategy;
  @override // e.g. "Dieta 3x1"
  String get breakingFastTip;
  @override // e.g. "Romper con caldo"
// 3. Clínico
  String? get glucoseStrategy;
  @override // e.g. "Meta < 140 mg/dL"
  String get whyThisPlan;
  @override // Explicación personalizada
// Metadata
  DateTime get generatedAt;
  @override
  @JsonKey(ignore: true)
  _$$HealthPlanImplCopyWith<_$HealthPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
