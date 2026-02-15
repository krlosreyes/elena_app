// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_routine_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$DailyWorkoutState {
  RoutineTemplate? get routine => throw _privateConstructorUsedError;
  List<Exercise> get exercises => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DailyWorkoutStateCopyWith<DailyWorkoutState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyWorkoutStateCopyWith<$Res> {
  factory $DailyWorkoutStateCopyWith(
          DailyWorkoutState value, $Res Function(DailyWorkoutState) then) =
      _$DailyWorkoutStateCopyWithImpl<$Res, DailyWorkoutState>;
  @useResult
  $Res call({RoutineTemplate? routine, List<Exercise> exercises});

  $RoutineTemplateCopyWith<$Res>? get routine;
}

/// @nodoc
class _$DailyWorkoutStateCopyWithImpl<$Res, $Val extends DailyWorkoutState>
    implements $DailyWorkoutStateCopyWith<$Res> {
  _$DailyWorkoutStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? routine = freezed,
    Object? exercises = null,
  }) {
    return _then(_value.copyWith(
      routine: freezed == routine
          ? _value.routine
          : routine // ignore: cast_nullable_to_non_nullable
              as RoutineTemplate?,
      exercises: null == exercises
          ? _value.exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<Exercise>,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $RoutineTemplateCopyWith<$Res>? get routine {
    if (_value.routine == null) {
      return null;
    }

    return $RoutineTemplateCopyWith<$Res>(_value.routine!, (value) {
      return _then(_value.copyWith(routine: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DailyWorkoutStateImplCopyWith<$Res>
    implements $DailyWorkoutStateCopyWith<$Res> {
  factory _$$DailyWorkoutStateImplCopyWith(_$DailyWorkoutStateImpl value,
          $Res Function(_$DailyWorkoutStateImpl) then) =
      __$$DailyWorkoutStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({RoutineTemplate? routine, List<Exercise> exercises});

  @override
  $RoutineTemplateCopyWith<$Res>? get routine;
}

/// @nodoc
class __$$DailyWorkoutStateImplCopyWithImpl<$Res>
    extends _$DailyWorkoutStateCopyWithImpl<$Res, _$DailyWorkoutStateImpl>
    implements _$$DailyWorkoutStateImplCopyWith<$Res> {
  __$$DailyWorkoutStateImplCopyWithImpl(_$DailyWorkoutStateImpl _value,
      $Res Function(_$DailyWorkoutStateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? routine = freezed,
    Object? exercises = null,
  }) {
    return _then(_$DailyWorkoutStateImpl(
      routine: freezed == routine
          ? _value.routine
          : routine // ignore: cast_nullable_to_non_nullable
              as RoutineTemplate?,
      exercises: null == exercises
          ? _value._exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<Exercise>,
    ));
  }
}

/// @nodoc

class _$DailyWorkoutStateImpl implements _DailyWorkoutState {
  const _$DailyWorkoutStateImpl(
      {required this.routine, required final List<Exercise> exercises})
      : _exercises = exercises;

  @override
  final RoutineTemplate? routine;
  final List<Exercise> _exercises;
  @override
  List<Exercise> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  @override
  String toString() {
    return 'DailyWorkoutState(routine: $routine, exercises: $exercises)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyWorkoutStateImpl &&
            (identical(other.routine, routine) || other.routine == routine) &&
            const DeepCollectionEquality()
                .equals(other._exercises, _exercises));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, routine, const DeepCollectionEquality().hash(_exercises));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyWorkoutStateImplCopyWith<_$DailyWorkoutStateImpl> get copyWith =>
      __$$DailyWorkoutStateImplCopyWithImpl<_$DailyWorkoutStateImpl>(
          this, _$identity);
}

abstract class _DailyWorkoutState implements DailyWorkoutState {
  const factory _DailyWorkoutState(
      {required final RoutineTemplate? routine,
      required final List<Exercise> exercises}) = _$DailyWorkoutStateImpl;

  @override
  RoutineTemplate? get routine;
  @override
  List<Exercise> get exercises;
  @override
  @JsonKey(ignore: true)
  _$$DailyWorkoutStateImplCopyWith<_$DailyWorkoutStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
