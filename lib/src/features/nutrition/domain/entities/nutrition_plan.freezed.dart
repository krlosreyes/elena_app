// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nutrition_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

NutritionPlan _$NutritionPlanFromJson(Map<String, dynamic> json) {
  return _NutritionPlan.fromJson(json);
}

/// @nodoc
mixin _$NutritionPlan {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get algorithmVersion => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get calculatedAt => throw _privateConstructorUsedError;
  BaseMetrics get baseMetrics => throw _privateConstructorUsedError;
  MacroTargets get macroTargets => throw _privateConstructorUsedError;
  VisualPlate get visualPlate => throw _privateConstructorUsedError;
  WeeklyAdjustment get weeklyAdjustment => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NutritionPlanCopyWith<NutritionPlan> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NutritionPlanCopyWith<$Res> {
  factory $NutritionPlanCopyWith(
          NutritionPlan value, $Res Function(NutritionPlan) then) =
      _$NutritionPlanCopyWithImpl<$Res, NutritionPlan>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String algorithmVersion,
      @TimestampConverter() DateTime calculatedAt,
      BaseMetrics baseMetrics,
      MacroTargets macroTargets,
      VisualPlate visualPlate,
      WeeklyAdjustment weeklyAdjustment});

  $BaseMetricsCopyWith<$Res> get baseMetrics;
  $MacroTargetsCopyWith<$Res> get macroTargets;
  $VisualPlateCopyWith<$Res> get visualPlate;
  $WeeklyAdjustmentCopyWith<$Res> get weeklyAdjustment;
}

/// @nodoc
class _$NutritionPlanCopyWithImpl<$Res, $Val extends NutritionPlan>
    implements $NutritionPlanCopyWith<$Res> {
  _$NutritionPlanCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? algorithmVersion = null,
    Object? calculatedAt = null,
    Object? baseMetrics = null,
    Object? macroTargets = null,
    Object? visualPlate = null,
    Object? weeklyAdjustment = null,
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
      algorithmVersion: null == algorithmVersion
          ? _value.algorithmVersion
          : algorithmVersion // ignore: cast_nullable_to_non_nullable
              as String,
      calculatedAt: null == calculatedAt
          ? _value.calculatedAt
          : calculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      baseMetrics: null == baseMetrics
          ? _value.baseMetrics
          : baseMetrics // ignore: cast_nullable_to_non_nullable
              as BaseMetrics,
      macroTargets: null == macroTargets
          ? _value.macroTargets
          : macroTargets // ignore: cast_nullable_to_non_nullable
              as MacroTargets,
      visualPlate: null == visualPlate
          ? _value.visualPlate
          : visualPlate // ignore: cast_nullable_to_non_nullable
              as VisualPlate,
      weeklyAdjustment: null == weeklyAdjustment
          ? _value.weeklyAdjustment
          : weeklyAdjustment // ignore: cast_nullable_to_non_nullable
              as WeeklyAdjustment,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $BaseMetricsCopyWith<$Res> get baseMetrics {
    return $BaseMetricsCopyWith<$Res>(_value.baseMetrics, (value) {
      return _then(_value.copyWith(baseMetrics: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $MacroTargetsCopyWith<$Res> get macroTargets {
    return $MacroTargetsCopyWith<$Res>(_value.macroTargets, (value) {
      return _then(_value.copyWith(macroTargets: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $VisualPlateCopyWith<$Res> get visualPlate {
    return $VisualPlateCopyWith<$Res>(_value.visualPlate, (value) {
      return _then(_value.copyWith(visualPlate: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $WeeklyAdjustmentCopyWith<$Res> get weeklyAdjustment {
    return $WeeklyAdjustmentCopyWith<$Res>(_value.weeklyAdjustment, (value) {
      return _then(_value.copyWith(weeklyAdjustment: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NutritionPlanImplCopyWith<$Res>
    implements $NutritionPlanCopyWith<$Res> {
  factory _$$NutritionPlanImplCopyWith(
          _$NutritionPlanImpl value, $Res Function(_$NutritionPlanImpl) then) =
      __$$NutritionPlanImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String algorithmVersion,
      @TimestampConverter() DateTime calculatedAt,
      BaseMetrics baseMetrics,
      MacroTargets macroTargets,
      VisualPlate visualPlate,
      WeeklyAdjustment weeklyAdjustment});

  @override
  $BaseMetricsCopyWith<$Res> get baseMetrics;
  @override
  $MacroTargetsCopyWith<$Res> get macroTargets;
  @override
  $VisualPlateCopyWith<$Res> get visualPlate;
  @override
  $WeeklyAdjustmentCopyWith<$Res> get weeklyAdjustment;
}

/// @nodoc
class __$$NutritionPlanImplCopyWithImpl<$Res>
    extends _$NutritionPlanCopyWithImpl<$Res, _$NutritionPlanImpl>
    implements _$$NutritionPlanImplCopyWith<$Res> {
  __$$NutritionPlanImplCopyWithImpl(
      _$NutritionPlanImpl _value, $Res Function(_$NutritionPlanImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? algorithmVersion = null,
    Object? calculatedAt = null,
    Object? baseMetrics = null,
    Object? macroTargets = null,
    Object? visualPlate = null,
    Object? weeklyAdjustment = null,
  }) {
    return _then(_$NutritionPlanImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      algorithmVersion: null == algorithmVersion
          ? _value.algorithmVersion
          : algorithmVersion // ignore: cast_nullable_to_non_nullable
              as String,
      calculatedAt: null == calculatedAt
          ? _value.calculatedAt
          : calculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      baseMetrics: null == baseMetrics
          ? _value.baseMetrics
          : baseMetrics // ignore: cast_nullable_to_non_nullable
              as BaseMetrics,
      macroTargets: null == macroTargets
          ? _value.macroTargets
          : macroTargets // ignore: cast_nullable_to_non_nullable
              as MacroTargets,
      visualPlate: null == visualPlate
          ? _value.visualPlate
          : visualPlate // ignore: cast_nullable_to_non_nullable
              as VisualPlate,
      weeklyAdjustment: null == weeklyAdjustment
          ? _value.weeklyAdjustment
          : weeklyAdjustment // ignore: cast_nullable_to_non_nullable
              as WeeklyAdjustment,
    ));
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _$NutritionPlanImpl implements _NutritionPlan {
  const _$NutritionPlanImpl(
      {required this.id,
      required this.userId,
      this.algorithmVersion = '1.0.0',
      @TimestampConverter() required this.calculatedAt,
      required this.baseMetrics,
      required this.macroTargets,
      required this.visualPlate,
      required this.weeklyAdjustment});

  factory _$NutritionPlanImpl.fromJson(Map<String, dynamic> json) =>
      _$$NutritionPlanImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  @JsonKey()
  final String algorithmVersion;
  @override
  @TimestampConverter()
  final DateTime calculatedAt;
  @override
  final BaseMetrics baseMetrics;
  @override
  final MacroTargets macroTargets;
  @override
  final VisualPlate visualPlate;
  @override
  final WeeklyAdjustment weeklyAdjustment;

  @override
  String toString() {
    return 'NutritionPlan(id: $id, userId: $userId, algorithmVersion: $algorithmVersion, calculatedAt: $calculatedAt, baseMetrics: $baseMetrics, macroTargets: $macroTargets, visualPlate: $visualPlate, weeklyAdjustment: $weeklyAdjustment)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NutritionPlanImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.algorithmVersion, algorithmVersion) ||
                other.algorithmVersion == algorithmVersion) &&
            (identical(other.calculatedAt, calculatedAt) ||
                other.calculatedAt == calculatedAt) &&
            (identical(other.baseMetrics, baseMetrics) ||
                other.baseMetrics == baseMetrics) &&
            (identical(other.macroTargets, macroTargets) ||
                other.macroTargets == macroTargets) &&
            (identical(other.visualPlate, visualPlate) ||
                other.visualPlate == visualPlate) &&
            (identical(other.weeklyAdjustment, weeklyAdjustment) ||
                other.weeklyAdjustment == weeklyAdjustment));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, algorithmVersion,
      calculatedAt, baseMetrics, macroTargets, visualPlate, weeklyAdjustment);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NutritionPlanImplCopyWith<_$NutritionPlanImpl> get copyWith =>
      __$$NutritionPlanImplCopyWithImpl<_$NutritionPlanImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NutritionPlanImplToJson(
      this,
    );
  }
}

abstract class _NutritionPlan implements NutritionPlan {
  const factory _NutritionPlan(
      {required final String id,
      required final String userId,
      final String algorithmVersion,
      @TimestampConverter() required final DateTime calculatedAt,
      required final BaseMetrics baseMetrics,
      required final MacroTargets macroTargets,
      required final VisualPlate visualPlate,
      required final WeeklyAdjustment weeklyAdjustment}) = _$NutritionPlanImpl;

  factory _NutritionPlan.fromJson(Map<String, dynamic> json) =
      _$NutritionPlanImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get algorithmVersion;
  @override
  @TimestampConverter()
  DateTime get calculatedAt;
  @override
  BaseMetrics get baseMetrics;
  @override
  MacroTargets get macroTargets;
  @override
  VisualPlate get visualPlate;
  @override
  WeeklyAdjustment get weeklyAdjustment;
  @override
  @JsonKey(ignore: true)
  _$$NutritionPlanImplCopyWith<_$NutritionPlanImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

BaseMetrics _$BaseMetricsFromJson(Map<String, dynamic> json) {
  return _BaseMetrics.fromJson(json);
}

/// @nodoc
mixin _$BaseMetrics {
  double get weightKg => throw _privateConstructorUsedError;
  double get bodyFatPercentage => throw _privateConstructorUsedError;
  double get fatFreeMassKg => throw _privateConstructorUsedError;
  double get bmr => throw _privateConstructorUsedError;
  double get tdee => throw _privateConstructorUsedError;
  double get activityMultiplier => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $BaseMetricsCopyWith<BaseMetrics> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $BaseMetricsCopyWith<$Res> {
  factory $BaseMetricsCopyWith(
          BaseMetrics value, $Res Function(BaseMetrics) then) =
      _$BaseMetricsCopyWithImpl<$Res, BaseMetrics>;
  @useResult
  $Res call(
      {double weightKg,
      double bodyFatPercentage,
      double fatFreeMassKg,
      double bmr,
      double tdee,
      double activityMultiplier});
}

/// @nodoc
class _$BaseMetricsCopyWithImpl<$Res, $Val extends BaseMetrics>
    implements $BaseMetricsCopyWith<$Res> {
  _$BaseMetricsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weightKg = null,
    Object? bodyFatPercentage = null,
    Object? fatFreeMassKg = null,
    Object? bmr = null,
    Object? tdee = null,
    Object? activityMultiplier = null,
  }) {
    return _then(_value.copyWith(
      weightKg: null == weightKg
          ? _value.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double,
      bodyFatPercentage: null == bodyFatPercentage
          ? _value.bodyFatPercentage
          : bodyFatPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      fatFreeMassKg: null == fatFreeMassKg
          ? _value.fatFreeMassKg
          : fatFreeMassKg // ignore: cast_nullable_to_non_nullable
              as double,
      bmr: null == bmr
          ? _value.bmr
          : bmr // ignore: cast_nullable_to_non_nullable
              as double,
      tdee: null == tdee
          ? _value.tdee
          : tdee // ignore: cast_nullable_to_non_nullable
              as double,
      activityMultiplier: null == activityMultiplier
          ? _value.activityMultiplier
          : activityMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$BaseMetricsImplCopyWith<$Res>
    implements $BaseMetricsCopyWith<$Res> {
  factory _$$BaseMetricsImplCopyWith(
          _$BaseMetricsImpl value, $Res Function(_$BaseMetricsImpl) then) =
      __$$BaseMetricsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double weightKg,
      double bodyFatPercentage,
      double fatFreeMassKg,
      double bmr,
      double tdee,
      double activityMultiplier});
}

/// @nodoc
class __$$BaseMetricsImplCopyWithImpl<$Res>
    extends _$BaseMetricsCopyWithImpl<$Res, _$BaseMetricsImpl>
    implements _$$BaseMetricsImplCopyWith<$Res> {
  __$$BaseMetricsImplCopyWithImpl(
      _$BaseMetricsImpl _value, $Res Function(_$BaseMetricsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weightKg = null,
    Object? bodyFatPercentage = null,
    Object? fatFreeMassKg = null,
    Object? bmr = null,
    Object? tdee = null,
    Object? activityMultiplier = null,
  }) {
    return _then(_$BaseMetricsImpl(
      weightKg: null == weightKg
          ? _value.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double,
      bodyFatPercentage: null == bodyFatPercentage
          ? _value.bodyFatPercentage
          : bodyFatPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      fatFreeMassKg: null == fatFreeMassKg
          ? _value.fatFreeMassKg
          : fatFreeMassKg // ignore: cast_nullable_to_non_nullable
              as double,
      bmr: null == bmr
          ? _value.bmr
          : bmr // ignore: cast_nullable_to_non_nullable
              as double,
      tdee: null == tdee
          ? _value.tdee
          : tdee // ignore: cast_nullable_to_non_nullable
              as double,
      activityMultiplier: null == activityMultiplier
          ? _value.activityMultiplier
          : activityMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$BaseMetricsImpl implements _BaseMetrics {
  const _$BaseMetricsImpl(
      {required this.weightKg,
      required this.bodyFatPercentage,
      required this.fatFreeMassKg,
      required this.bmr,
      required this.tdee,
      required this.activityMultiplier});

  factory _$BaseMetricsImpl.fromJson(Map<String, dynamic> json) =>
      _$$BaseMetricsImplFromJson(json);

  @override
  final double weightKg;
  @override
  final double bodyFatPercentage;
  @override
  final double fatFreeMassKg;
  @override
  final double bmr;
  @override
  final double tdee;
  @override
  final double activityMultiplier;

  @override
  String toString() {
    return 'BaseMetrics(weightKg: $weightKg, bodyFatPercentage: $bodyFatPercentage, fatFreeMassKg: $fatFreeMassKg, bmr: $bmr, tdee: $tdee, activityMultiplier: $activityMultiplier)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$BaseMetricsImpl &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.bodyFatPercentage, bodyFatPercentage) ||
                other.bodyFatPercentage == bodyFatPercentage) &&
            (identical(other.fatFreeMassKg, fatFreeMassKg) ||
                other.fatFreeMassKg == fatFreeMassKg) &&
            (identical(other.bmr, bmr) || other.bmr == bmr) &&
            (identical(other.tdee, tdee) || other.tdee == tdee) &&
            (identical(other.activityMultiplier, activityMultiplier) ||
                other.activityMultiplier == activityMultiplier));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, weightKg, bodyFatPercentage,
      fatFreeMassKg, bmr, tdee, activityMultiplier);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$BaseMetricsImplCopyWith<_$BaseMetricsImpl> get copyWith =>
      __$$BaseMetricsImplCopyWithImpl<_$BaseMetricsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$BaseMetricsImplToJson(
      this,
    );
  }
}

abstract class _BaseMetrics implements BaseMetrics {
  const factory _BaseMetrics(
      {required final double weightKg,
      required final double bodyFatPercentage,
      required final double fatFreeMassKg,
      required final double bmr,
      required final double tdee,
      required final double activityMultiplier}) = _$BaseMetricsImpl;

  factory _BaseMetrics.fromJson(Map<String, dynamic> json) =
      _$BaseMetricsImpl.fromJson;

  @override
  double get weightKg;
  @override
  double get bodyFatPercentage;
  @override
  double get fatFreeMassKg;
  @override
  double get bmr;
  @override
  double get tdee;
  @override
  double get activityMultiplier;
  @override
  @JsonKey(ignore: true)
  _$$BaseMetricsImplCopyWith<_$BaseMetricsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MacroTargets _$MacroTargetsFromJson(Map<String, dynamic> json) {
  return _MacroTargets.fromJson(json);
}

/// @nodoc
mixin _$MacroTargets {
  int get totalCalories => throw _privateConstructorUsedError;
  int get proteinGrams => throw _privateConstructorUsedError;
  int get fatGrams => throw _privateConstructorUsedError;
  int get carbsGrams => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MacroTargetsCopyWith<MacroTargets> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MacroTargetsCopyWith<$Res> {
  factory $MacroTargetsCopyWith(
          MacroTargets value, $Res Function(MacroTargets) then) =
      _$MacroTargetsCopyWithImpl<$Res, MacroTargets>;
  @useResult
  $Res call(
      {int totalCalories, int proteinGrams, int fatGrams, int carbsGrams});
}

/// @nodoc
class _$MacroTargetsCopyWithImpl<$Res, $Val extends MacroTargets>
    implements $MacroTargetsCopyWith<$Res> {
  _$MacroTargetsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalCalories = null,
    Object? proteinGrams = null,
    Object? fatGrams = null,
    Object? carbsGrams = null,
  }) {
    return _then(_value.copyWith(
      totalCalories: null == totalCalories
          ? _value.totalCalories
          : totalCalories // ignore: cast_nullable_to_non_nullable
              as int,
      proteinGrams: null == proteinGrams
          ? _value.proteinGrams
          : proteinGrams // ignore: cast_nullable_to_non_nullable
              as int,
      fatGrams: null == fatGrams
          ? _value.fatGrams
          : fatGrams // ignore: cast_nullable_to_non_nullable
              as int,
      carbsGrams: null == carbsGrams
          ? _value.carbsGrams
          : carbsGrams // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MacroTargetsImplCopyWith<$Res>
    implements $MacroTargetsCopyWith<$Res> {
  factory _$$MacroTargetsImplCopyWith(
          _$MacroTargetsImpl value, $Res Function(_$MacroTargetsImpl) then) =
      __$$MacroTargetsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int totalCalories, int proteinGrams, int fatGrams, int carbsGrams});
}

/// @nodoc
class __$$MacroTargetsImplCopyWithImpl<$Res>
    extends _$MacroTargetsCopyWithImpl<$Res, _$MacroTargetsImpl>
    implements _$$MacroTargetsImplCopyWith<$Res> {
  __$$MacroTargetsImplCopyWithImpl(
      _$MacroTargetsImpl _value, $Res Function(_$MacroTargetsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalCalories = null,
    Object? proteinGrams = null,
    Object? fatGrams = null,
    Object? carbsGrams = null,
  }) {
    return _then(_$MacroTargetsImpl(
      totalCalories: null == totalCalories
          ? _value.totalCalories
          : totalCalories // ignore: cast_nullable_to_non_nullable
              as int,
      proteinGrams: null == proteinGrams
          ? _value.proteinGrams
          : proteinGrams // ignore: cast_nullable_to_non_nullable
              as int,
      fatGrams: null == fatGrams
          ? _value.fatGrams
          : fatGrams // ignore: cast_nullable_to_non_nullable
              as int,
      carbsGrams: null == carbsGrams
          ? _value.carbsGrams
          : carbsGrams // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MacroTargetsImpl implements _MacroTargets {
  const _$MacroTargetsImpl(
      {required this.totalCalories,
      required this.proteinGrams,
      required this.fatGrams,
      required this.carbsGrams});

  factory _$MacroTargetsImpl.fromJson(Map<String, dynamic> json) =>
      _$$MacroTargetsImplFromJson(json);

  @override
  final int totalCalories;
  @override
  final int proteinGrams;
  @override
  final int fatGrams;
  @override
  final int carbsGrams;

  @override
  String toString() {
    return 'MacroTargets(totalCalories: $totalCalories, proteinGrams: $proteinGrams, fatGrams: $fatGrams, carbsGrams: $carbsGrams)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MacroTargetsImpl &&
            (identical(other.totalCalories, totalCalories) ||
                other.totalCalories == totalCalories) &&
            (identical(other.proteinGrams, proteinGrams) ||
                other.proteinGrams == proteinGrams) &&
            (identical(other.fatGrams, fatGrams) ||
                other.fatGrams == fatGrams) &&
            (identical(other.carbsGrams, carbsGrams) ||
                other.carbsGrams == carbsGrams));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, totalCalories, proteinGrams, fatGrams, carbsGrams);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MacroTargetsImplCopyWith<_$MacroTargetsImpl> get copyWith =>
      __$$MacroTargetsImplCopyWithImpl<_$MacroTargetsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MacroTargetsImplToJson(
      this,
    );
  }
}

abstract class _MacroTargets implements MacroTargets {
  const factory _MacroTargets(
      {required final int totalCalories,
      required final int proteinGrams,
      required final int fatGrams,
      required final int carbsGrams}) = _$MacroTargetsImpl;

  factory _MacroTargets.fromJson(Map<String, dynamic> json) =
      _$MacroTargetsImpl.fromJson;

  @override
  int get totalCalories;
  @override
  int get proteinGrams;
  @override
  int get fatGrams;
  @override
  int get carbsGrams;
  @override
  @JsonKey(ignore: true)
  _$$MacroTargetsImplCopyWith<_$MacroTargetsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VisualPlate _$VisualPlateFromJson(Map<String, dynamic> json) {
  return _VisualPlate.fromJson(json);
}

/// @nodoc
mixin _$VisualPlate {
  double get vegetablesPercent => throw _privateConstructorUsedError;
  double get proteinPercent => throw _privateConstructorUsedError;
  double get carbsPercent => throw _privateConstructorUsedError;
  String get carbsType => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $VisualPlateCopyWith<VisualPlate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VisualPlateCopyWith<$Res> {
  factory $VisualPlateCopyWith(
          VisualPlate value, $Res Function(VisualPlate) then) =
      _$VisualPlateCopyWithImpl<$Res, VisualPlate>;
  @useResult
  $Res call(
      {double vegetablesPercent,
      double proteinPercent,
      double carbsPercent,
      String carbsType});
}

/// @nodoc
class _$VisualPlateCopyWithImpl<$Res, $Val extends VisualPlate>
    implements $VisualPlateCopyWith<$Res> {
  _$VisualPlateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? vegetablesPercent = null,
    Object? proteinPercent = null,
    Object? carbsPercent = null,
    Object? carbsType = null,
  }) {
    return _then(_value.copyWith(
      vegetablesPercent: null == vegetablesPercent
          ? _value.vegetablesPercent
          : vegetablesPercent // ignore: cast_nullable_to_non_nullable
              as double,
      proteinPercent: null == proteinPercent
          ? _value.proteinPercent
          : proteinPercent // ignore: cast_nullable_to_non_nullable
              as double,
      carbsPercent: null == carbsPercent
          ? _value.carbsPercent
          : carbsPercent // ignore: cast_nullable_to_non_nullable
              as double,
      carbsType: null == carbsType
          ? _value.carbsType
          : carbsType // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VisualPlateImplCopyWith<$Res>
    implements $VisualPlateCopyWith<$Res> {
  factory _$$VisualPlateImplCopyWith(
          _$VisualPlateImpl value, $Res Function(_$VisualPlateImpl) then) =
      __$$VisualPlateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {double vegetablesPercent,
      double proteinPercent,
      double carbsPercent,
      String carbsType});
}

/// @nodoc
class __$$VisualPlateImplCopyWithImpl<$Res>
    extends _$VisualPlateCopyWithImpl<$Res, _$VisualPlateImpl>
    implements _$$VisualPlateImplCopyWith<$Res> {
  __$$VisualPlateImplCopyWithImpl(
      _$VisualPlateImpl _value, $Res Function(_$VisualPlateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? vegetablesPercent = null,
    Object? proteinPercent = null,
    Object? carbsPercent = null,
    Object? carbsType = null,
  }) {
    return _then(_$VisualPlateImpl(
      vegetablesPercent: null == vegetablesPercent
          ? _value.vegetablesPercent
          : vegetablesPercent // ignore: cast_nullable_to_non_nullable
              as double,
      proteinPercent: null == proteinPercent
          ? _value.proteinPercent
          : proteinPercent // ignore: cast_nullable_to_non_nullable
              as double,
      carbsPercent: null == carbsPercent
          ? _value.carbsPercent
          : carbsPercent // ignore: cast_nullable_to_non_nullable
              as double,
      carbsType: null == carbsType
          ? _value.carbsType
          : carbsType // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VisualPlateImpl implements _VisualPlate {
  const _$VisualPlateImpl(
      {required this.vegetablesPercent,
      required this.proteinPercent,
      required this.carbsPercent,
      required this.carbsType});

  factory _$VisualPlateImpl.fromJson(Map<String, dynamic> json) =>
      _$$VisualPlateImplFromJson(json);

  @override
  final double vegetablesPercent;
  @override
  final double proteinPercent;
  @override
  final double carbsPercent;
  @override
  final String carbsType;

  @override
  String toString() {
    return 'VisualPlate(vegetablesPercent: $vegetablesPercent, proteinPercent: $proteinPercent, carbsPercent: $carbsPercent, carbsType: $carbsType)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VisualPlateImpl &&
            (identical(other.vegetablesPercent, vegetablesPercent) ||
                other.vegetablesPercent == vegetablesPercent) &&
            (identical(other.proteinPercent, proteinPercent) ||
                other.proteinPercent == proteinPercent) &&
            (identical(other.carbsPercent, carbsPercent) ||
                other.carbsPercent == carbsPercent) &&
            (identical(other.carbsType, carbsType) ||
                other.carbsType == carbsType));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, vegetablesPercent, proteinPercent, carbsPercent, carbsType);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$VisualPlateImplCopyWith<_$VisualPlateImpl> get copyWith =>
      __$$VisualPlateImplCopyWithImpl<_$VisualPlateImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VisualPlateImplToJson(
      this,
    );
  }
}

abstract class _VisualPlate implements VisualPlate {
  const factory _VisualPlate(
      {required final double vegetablesPercent,
      required final double proteinPercent,
      required final double carbsPercent,
      required final String carbsType}) = _$VisualPlateImpl;

  factory _VisualPlate.fromJson(Map<String, dynamic> json) =
      _$VisualPlateImpl.fromJson;

  @override
  double get vegetablesPercent;
  @override
  double get proteinPercent;
  @override
  double get carbsPercent;
  @override
  String get carbsType;
  @override
  @JsonKey(ignore: true)
  _$$VisualPlateImplCopyWith<_$VisualPlateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

WeeklyAdjustment _$WeeklyAdjustmentFromJson(Map<String, dynamic> json) {
  return _WeeklyAdjustment.fromJson(json);
}

/// @nodoc
mixin _$WeeklyAdjustment {
  bool get isAdjusted => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime? get lastAdjustmentDate => throw _privateConstructorUsedError;
  String? get adjustmentReason => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WeeklyAdjustmentCopyWith<WeeklyAdjustment> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WeeklyAdjustmentCopyWith<$Res> {
  factory $WeeklyAdjustmentCopyWith(
          WeeklyAdjustment value, $Res Function(WeeklyAdjustment) then) =
      _$WeeklyAdjustmentCopyWithImpl<$Res, WeeklyAdjustment>;
  @useResult
  $Res call(
      {bool isAdjusted,
      @TimestampConverter() DateTime? lastAdjustmentDate,
      String? adjustmentReason});
}

/// @nodoc
class _$WeeklyAdjustmentCopyWithImpl<$Res, $Val extends WeeklyAdjustment>
    implements $WeeklyAdjustmentCopyWith<$Res> {
  _$WeeklyAdjustmentCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isAdjusted = null,
    Object? lastAdjustmentDate = freezed,
    Object? adjustmentReason = freezed,
  }) {
    return _then(_value.copyWith(
      isAdjusted: null == isAdjusted
          ? _value.isAdjusted
          : isAdjusted // ignore: cast_nullable_to_non_nullable
              as bool,
      lastAdjustmentDate: freezed == lastAdjustmentDate
          ? _value.lastAdjustmentDate
          : lastAdjustmentDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      adjustmentReason: freezed == adjustmentReason
          ? _value.adjustmentReason
          : adjustmentReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WeeklyAdjustmentImplCopyWith<$Res>
    implements $WeeklyAdjustmentCopyWith<$Res> {
  factory _$$WeeklyAdjustmentImplCopyWith(_$WeeklyAdjustmentImpl value,
          $Res Function(_$WeeklyAdjustmentImpl) then) =
      __$$WeeklyAdjustmentImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {bool isAdjusted,
      @TimestampConverter() DateTime? lastAdjustmentDate,
      String? adjustmentReason});
}

/// @nodoc
class __$$WeeklyAdjustmentImplCopyWithImpl<$Res>
    extends _$WeeklyAdjustmentCopyWithImpl<$Res, _$WeeklyAdjustmentImpl>
    implements _$$WeeklyAdjustmentImplCopyWith<$Res> {
  __$$WeeklyAdjustmentImplCopyWithImpl(_$WeeklyAdjustmentImpl _value,
      $Res Function(_$WeeklyAdjustmentImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isAdjusted = null,
    Object? lastAdjustmentDate = freezed,
    Object? adjustmentReason = freezed,
  }) {
    return _then(_$WeeklyAdjustmentImpl(
      isAdjusted: null == isAdjusted
          ? _value.isAdjusted
          : isAdjusted // ignore: cast_nullable_to_non_nullable
              as bool,
      lastAdjustmentDate: freezed == lastAdjustmentDate
          ? _value.lastAdjustmentDate
          : lastAdjustmentDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      adjustmentReason: freezed == adjustmentReason
          ? _value.adjustmentReason
          : adjustmentReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WeeklyAdjustmentImpl implements _WeeklyAdjustment {
  const _$WeeklyAdjustmentImpl(
      {this.isAdjusted = false,
      @TimestampConverter() this.lastAdjustmentDate,
      this.adjustmentReason});

  factory _$WeeklyAdjustmentImpl.fromJson(Map<String, dynamic> json) =>
      _$$WeeklyAdjustmentImplFromJson(json);

  @override
  @JsonKey()
  final bool isAdjusted;
  @override
  @TimestampConverter()
  final DateTime? lastAdjustmentDate;
  @override
  final String? adjustmentReason;

  @override
  String toString() {
    return 'WeeklyAdjustment(isAdjusted: $isAdjusted, lastAdjustmentDate: $lastAdjustmentDate, adjustmentReason: $adjustmentReason)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WeeklyAdjustmentImpl &&
            (identical(other.isAdjusted, isAdjusted) ||
                other.isAdjusted == isAdjusted) &&
            (identical(other.lastAdjustmentDate, lastAdjustmentDate) ||
                other.lastAdjustmentDate == lastAdjustmentDate) &&
            (identical(other.adjustmentReason, adjustmentReason) ||
                other.adjustmentReason == adjustmentReason));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, isAdjusted, lastAdjustmentDate, adjustmentReason);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WeeklyAdjustmentImplCopyWith<_$WeeklyAdjustmentImpl> get copyWith =>
      __$$WeeklyAdjustmentImplCopyWithImpl<_$WeeklyAdjustmentImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WeeklyAdjustmentImplToJson(
      this,
    );
  }
}

abstract class _WeeklyAdjustment implements WeeklyAdjustment {
  const factory _WeeklyAdjustment(
      {final bool isAdjusted,
      @TimestampConverter() final DateTime? lastAdjustmentDate,
      final String? adjustmentReason}) = _$WeeklyAdjustmentImpl;

  factory _WeeklyAdjustment.fromJson(Map<String, dynamic> json) =
      _$WeeklyAdjustmentImpl.fromJson;

  @override
  bool get isAdjusted;
  @override
  @TimestampConverter()
  DateTime? get lastAdjustmentDate;
  @override
  String? get adjustmentReason;
  @override
  @JsonKey(ignore: true)
  _$$WeeklyAdjustmentImplCopyWith<_$WeeklyAdjustmentImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
