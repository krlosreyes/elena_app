// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_workout_orchestrator.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$SingleWorkoutState {
  DailyWorkout get plan => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  WorkoutLog? get log => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $SingleWorkoutStateCopyWith<SingleWorkoutState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SingleWorkoutStateCopyWith<$Res> {
  factory $SingleWorkoutStateCopyWith(
          SingleWorkoutState value, $Res Function(SingleWorkoutState) then) =
      _$SingleWorkoutStateCopyWithImpl<$Res, SingleWorkoutState>;
  @useResult
  $Res call(
      {DailyWorkout plan, DateTime date, bool isCompleted, WorkoutLog? log});

  $DailyWorkoutCopyWith<$Res> get plan;
  $WorkoutLogCopyWith<$Res>? get log;
}

/// @nodoc
class _$SingleWorkoutStateCopyWithImpl<$Res, $Val extends SingleWorkoutState>
    implements $SingleWorkoutStateCopyWith<$Res> {
  _$SingleWorkoutStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plan = null,
    Object? date = null,
    Object? isCompleted = null,
    Object? log = freezed,
  }) {
    return _then(_value.copyWith(
      plan: null == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as DailyWorkout,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      log: freezed == log
          ? _value.log
          : log // ignore: cast_nullable_to_non_nullable
              as WorkoutLog?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $DailyWorkoutCopyWith<$Res> get plan {
    return $DailyWorkoutCopyWith<$Res>(_value.plan, (value) {
      return _then(_value.copyWith(plan: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $WorkoutLogCopyWith<$Res>? get log {
    if (_value.log == null) {
      return null;
    }

    return $WorkoutLogCopyWith<$Res>(_value.log!, (value) {
      return _then(_value.copyWith(log: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$SingleWorkoutStateImplCopyWith<$Res>
    implements $SingleWorkoutStateCopyWith<$Res> {
  factory _$$SingleWorkoutStateImplCopyWith(_$SingleWorkoutStateImpl value,
          $Res Function(_$SingleWorkoutStateImpl) then) =
      __$$SingleWorkoutStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DailyWorkout plan, DateTime date, bool isCompleted, WorkoutLog? log});

  @override
  $DailyWorkoutCopyWith<$Res> get plan;
  @override
  $WorkoutLogCopyWith<$Res>? get log;
}

/// @nodoc
class __$$SingleWorkoutStateImplCopyWithImpl<$Res>
    extends _$SingleWorkoutStateCopyWithImpl<$Res, _$SingleWorkoutStateImpl>
    implements _$$SingleWorkoutStateImplCopyWith<$Res> {
  __$$SingleWorkoutStateImplCopyWithImpl(_$SingleWorkoutStateImpl _value,
      $Res Function(_$SingleWorkoutStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? plan = null,
    Object? date = null,
    Object? isCompleted = null,
    Object? log = freezed,
  }) {
    return _then(_$SingleWorkoutStateImpl(
      plan: null == plan
          ? _value.plan
          : plan // ignore: cast_nullable_to_non_nullable
              as DailyWorkout,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      log: freezed == log
          ? _value.log
          : log // ignore: cast_nullable_to_non_nullable
              as WorkoutLog?,
    ));
  }
}

/// @nodoc

class _$SingleWorkoutStateImpl implements _SingleWorkoutState {
  const _$SingleWorkoutStateImpl(
      {required this.plan,
      required this.date,
      required this.isCompleted,
      this.log});

  @override
  final DailyWorkout plan;
  @override
  final DateTime date;
  @override
  final bool isCompleted;
  @override
  final WorkoutLog? log;

  @override
  String toString() {
    return 'SingleWorkoutState(plan: $plan, date: $date, isCompleted: $isCompleted, log: $log)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SingleWorkoutStateImpl &&
            (identical(other.plan, plan) || other.plan == plan) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.log, log) || other.log == log));
  }

  @override
  int get hashCode => Object.hash(runtimeType, plan, date, isCompleted, log);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SingleWorkoutStateImplCopyWith<_$SingleWorkoutStateImpl> get copyWith =>
      __$$SingleWorkoutStateImplCopyWithImpl<_$SingleWorkoutStateImpl>(
          this, _$identity);
}

abstract class _SingleWorkoutState implements SingleWorkoutState {
  const factory _SingleWorkoutState(
      {required final DailyWorkout plan,
      required final DateTime date,
      required final bool isCompleted,
      final WorkoutLog? log}) = _$SingleWorkoutStateImpl;

  @override
  DailyWorkout get plan;
  @override
  DateTime get date;
  @override
  bool get isCompleted;
  @override
  WorkoutLog? get log;
  @override
  @JsonKey(ignore: true)
  _$$SingleWorkoutStateImplCopyWith<_$SingleWorkoutStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
