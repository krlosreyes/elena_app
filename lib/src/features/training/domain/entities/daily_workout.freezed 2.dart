// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_workout.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DailyWorkout {
  int get dayIndex =>
      throw _privateConstructorUsedError; // 1 to 7 (Monday to Sunday)
  WorkoutType get type => throw _privateConstructorUsedError;
  int get durationMinutes => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String get details =>
      throw _privateConstructorUsedError; // E.g., "Zona 2" or "FullBody A"
  List<RoutineExercise> get exercises => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DailyWorkoutCopyWith<DailyWorkout> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyWorkoutCopyWith<$Res> {
  factory $DailyWorkoutCopyWith(
          DailyWorkout value, $Res Function(DailyWorkout) then) =
      _$DailyWorkoutCopyWithImpl<$Res, DailyWorkout>;
  @useResult
  $Res call(
      {int dayIndex,
      WorkoutType type,
      int durationMinutes,
      String description,
      String details,
      List<RoutineExercise> exercises});
}

/// @nodoc
class _$DailyWorkoutCopyWithImpl<$Res, $Val extends DailyWorkout>
    implements $DailyWorkoutCopyWith<$Res> {
  _$DailyWorkoutCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayIndex = null,
    Object? type = null,
    Object? durationMinutes = null,
    Object? description = null,
    Object? details = null,
    Object? exercises = null,
  }) {
    return _then(_value.copyWith(
      dayIndex: null == dayIndex
          ? _value.dayIndex
          : dayIndex // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as WorkoutType,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      details: null == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as String,
      exercises: null == exercises
          ? _value.exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<RoutineExercise>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DailyWorkoutImplCopyWith<$Res>
    implements $DailyWorkoutCopyWith<$Res> {
  factory _$$DailyWorkoutImplCopyWith(
          _$DailyWorkoutImpl value, $Res Function(_$DailyWorkoutImpl) then) =
      __$$DailyWorkoutImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int dayIndex,
      WorkoutType type,
      int durationMinutes,
      String description,
      String details,
      List<RoutineExercise> exercises});
}

/// @nodoc
class __$$DailyWorkoutImplCopyWithImpl<$Res>
    extends _$DailyWorkoutCopyWithImpl<$Res, _$DailyWorkoutImpl>
    implements _$$DailyWorkoutImplCopyWith<$Res> {
  __$$DailyWorkoutImplCopyWithImpl(
      _$DailyWorkoutImpl _value, $Res Function(_$DailyWorkoutImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayIndex = null,
    Object? type = null,
    Object? durationMinutes = null,
    Object? description = null,
    Object? details = null,
    Object? exercises = null,
  }) {
    return _then(_$DailyWorkoutImpl(
      dayIndex: null == dayIndex
          ? _value.dayIndex
          : dayIndex // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _value.type
          : type // ignore: cast_nullable_to_non_nullable
              as WorkoutType,
      durationMinutes: null == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      details: null == details
          ? _value.details
          : details // ignore: cast_nullable_to_non_nullable
              as String,
      exercises: null == exercises
          ? _value._exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<RoutineExercise>,
    ));
  }
}

/// @nodoc

class _$DailyWorkoutImpl implements _DailyWorkout {
  const _$DailyWorkoutImpl(
      {required this.dayIndex,
      required this.type,
      required this.durationMinutes,
      required this.description,
      required this.details,
      final List<RoutineExercise> exercises = const []})
      : _exercises = exercises;

  @override
  final int dayIndex;
// 1 to 7 (Monday to Sunday)
  @override
  final WorkoutType type;
  @override
  final int durationMinutes;
  @override
  final String description;
  @override
  final String details;
// E.g., "Zona 2" or "FullBody A"
  final List<RoutineExercise> _exercises;
// E.g., "Zona 2" or "FullBody A"
  @override
  @JsonKey()
  List<RoutineExercise> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  @override
  String toString() {
    return 'DailyWorkout(dayIndex: $dayIndex, type: $type, durationMinutes: $durationMinutes, description: $description, details: $details, exercises: $exercises)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyWorkoutImpl &&
            (identical(other.dayIndex, dayIndex) ||
                other.dayIndex == dayIndex) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.details, details) || other.details == details) &&
            const DeepCollectionEquality()
                .equals(other._exercises, _exercises));
  }

  @override
  int get hashCode => Object.hash(runtimeType, dayIndex, type, durationMinutes,
      description, details, const DeepCollectionEquality().hash(_exercises));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyWorkoutImplCopyWith<_$DailyWorkoutImpl> get copyWith =>
      __$$DailyWorkoutImplCopyWithImpl<_$DailyWorkoutImpl>(this, _$identity);
}

abstract class _DailyWorkout implements DailyWorkout {
  const factory _DailyWorkout(
      {required final int dayIndex,
      required final WorkoutType type,
      required final int durationMinutes,
      required final String description,
      required final String details,
      final List<RoutineExercise> exercises}) = _$DailyWorkoutImpl;

  @override
  int get dayIndex;
  @override // 1 to 7 (Monday to Sunday)
  WorkoutType get type;
  @override
  int get durationMinutes;
  @override
  String get description;
  @override
  String get details;
  @override // E.g., "Zona 2" or "FullBody A"
  List<RoutineExercise> get exercises;
  @override
  @JsonKey(ignore: true)
  _$$DailyWorkoutImplCopyWith<_$DailyWorkoutImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
