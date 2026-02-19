// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WorkoutStats _$WorkoutStatsFromJson(Map<String, dynamic> json) {
  return _WorkoutStats.fromJson(json);
}

/// @nodoc
mixin _$WorkoutStats {
  DateTime get date => throw _privateConstructorUsedError;
  double get totalVolume => throw _privateConstructorUsedError; // kg moved
  int get durationMinutes => throw _privateConstructorUsedError;
  int get caloriesBurned => throw _privateConstructorUsedError;
  String get workoutType => throw _privateConstructorUsedError;
  int get totalSets => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutStatsCopyWith<WorkoutStats> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutStatsCopyWith<$Res> {
  factory $WorkoutStatsCopyWith(
          WorkoutStats value, $Res Function(WorkoutStats) then) =
      _$WorkoutStatsCopyWithImpl<$Res, WorkoutStats>;
  @useResult
  $Res call(
      {DateTime date,
      double totalVolume,
      int durationMinutes,
      int caloriesBurned,
      String workoutType,
      int totalSets});
}

/// @nodoc
class _$WorkoutStatsCopyWithImpl<$Res, $Val extends WorkoutStats>
    implements $WorkoutStatsCopyWith<$Res> {
  _$WorkoutStatsCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? totalVolume = null,
    Object? durationMinutes = null,
    Object? caloriesBurned = null,
    Object? workoutType = null,
    Object? totalSets = null,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalVolume: null == totalVolume
          ? _value.totalVolume
          : totalVolume // ignore: cast_nullable_to_non_nullable
              as double,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      caloriesBurned: null == caloriesBurned
          ? _value.caloriesBurned
          : caloriesBurned // ignore: cast_nullable_to_non_nullable
              as int,
      workoutType: null == workoutType
          ? _value.workoutType
          : workoutType // ignore: cast_nullable_to_non_nullable
              as String,
      totalSets: null == totalSets
          ? _value.totalSets
          : totalSets // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkoutStatsImplCopyWith<$Res>
    implements $WorkoutStatsCopyWith<$Res> {
  factory _$$WorkoutStatsImplCopyWith(
          _$WorkoutStatsImpl value, $Res Function(_$WorkoutStatsImpl) then) =
      __$$WorkoutStatsImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime date,
      double totalVolume,
      int durationMinutes,
      int caloriesBurned,
      String workoutType,
      int totalSets});
}

/// @nodoc
class __$$WorkoutStatsImplCopyWithImpl<$Res>
    extends _$WorkoutStatsCopyWithImpl<$Res, _$WorkoutStatsImpl>
    implements _$$WorkoutStatsImplCopyWith<$Res> {
  __$$WorkoutStatsImplCopyWithImpl(
      _$WorkoutStatsImpl _value, $Res Function(_$WorkoutStatsImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? totalVolume = null,
    Object? durationMinutes = null,
    Object? caloriesBurned = null,
    Object? workoutType = null,
    Object? totalSets = null,
  }) {
    return _then(_$WorkoutStatsImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalVolume: null == totalVolume
          ? _value.totalVolume
          : totalVolume // ignore: cast_nullable_to_non_nullable
              as double,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      caloriesBurned: null == caloriesBurned
          ? _value.caloriesBurned
          : caloriesBurned // ignore: cast_nullable_to_non_nullable
              as int,
      workoutType: null == workoutType
          ? _value.workoutType
          : workoutType // ignore: cast_nullable_to_non_nullable
              as String,
      totalSets: null == totalSets
          ? _value.totalSets
          : totalSets // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutStatsImpl extends _WorkoutStats {
  const _$WorkoutStatsImpl(
      {required this.date,
      required this.totalVolume,
      required this.durationMinutes,
      required this.caloriesBurned,
      required this.workoutType,
      required this.totalSets})
      : super._();

  factory _$WorkoutStatsImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutStatsImplFromJson(json);

  @override
  final DateTime date;
  @override
  final double totalVolume;
// kg moved
  @override
  final int durationMinutes;
  @override
  final int caloriesBurned;
  @override
  final String workoutType;
  @override
  final int totalSets;

  @override
  String toString() {
    return 'WorkoutStats(date: $date, totalVolume: $totalVolume, durationMinutes: $durationMinutes, caloriesBurned: $caloriesBurned, workoutType: $workoutType, totalSets: $totalSets)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutStatsImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.totalVolume, totalVolume) ||
                other.totalVolume == totalVolume) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.caloriesBurned, caloriesBurned) ||
                other.caloriesBurned == caloriesBurned) &&
            (identical(other.workoutType, workoutType) ||
                other.workoutType == workoutType) &&
            (identical(other.totalSets, totalSets) ||
                other.totalSets == totalSets));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, date, totalVolume,
      durationMinutes, caloriesBurned, workoutType, totalSets);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutStatsImplCopyWith<_$WorkoutStatsImpl> get copyWith =>
      __$$WorkoutStatsImplCopyWithImpl<_$WorkoutStatsImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutStatsImplToJson(
      this,
    );
  }
}

abstract class _WorkoutStats extends WorkoutStats {
  const factory _WorkoutStats(
      {required final DateTime date,
      required final double totalVolume,
      required final int durationMinutes,
      required final int caloriesBurned,
      required final String workoutType,
      required final int totalSets}) = _$WorkoutStatsImpl;
  const _WorkoutStats._() : super._();

  factory _WorkoutStats.fromJson(Map<String, dynamic> json) =
      _$WorkoutStatsImpl.fromJson;

  @override
  DateTime get date;
  @override
  double get totalVolume;
  @override // kg moved
  int get durationMinutes;
  @override
  int get caloriesBurned;
  @override
  String get workoutType;
  @override
  int get totalSets;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutStatsImplCopyWith<_$WorkoutStatsImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
