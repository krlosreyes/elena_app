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
mixin _$DailyExercise {
  Exercise get exercise => throw _privateConstructorUsedError;
  RoutineExercise get routineDetails => throw _privateConstructorUsedError;
  double? get recommendedWeight => throw _privateConstructorUsedError;
  int? get lastRir => throw _privateConstructorUsedError;

  @JsonKey(ignore: true)
  $DailyExerciseCopyWith<DailyExercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DailyExerciseCopyWith<$Res> {
  factory $DailyExerciseCopyWith(
          DailyExercise value, $Res Function(DailyExercise) then) =
      _$DailyExerciseCopyWithImpl<$Res, DailyExercise>;
  @useResult
  $Res call(
      {Exercise exercise,
      RoutineExercise routineDetails,
      double? recommendedWeight,
      int? lastRir});

  $ExerciseCopyWith<$Res> get exercise;
  $RoutineExerciseCopyWith<$Res> get routineDetails;
}

/// @nodoc
class _$DailyExerciseCopyWithImpl<$Res, $Val extends DailyExercise>
    implements $DailyExerciseCopyWith<$Res> {
  _$DailyExerciseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exercise = null,
    Object? routineDetails = null,
    Object? recommendedWeight = freezed,
    Object? lastRir = freezed,
  }) {
    return _then(_value.copyWith(
      exercise: null == exercise
          ? _value.exercise
          : exercise // ignore: cast_nullable_to_non_nullable
              as Exercise,
      routineDetails: null == routineDetails
          ? _value.routineDetails
          : routineDetails // ignore: cast_nullable_to_non_nullable
              as RoutineExercise,
      recommendedWeight: freezed == recommendedWeight
          ? _value.recommendedWeight
          : recommendedWeight // ignore: cast_nullable_to_non_nullable
              as double?,
      lastRir: freezed == lastRir
          ? _value.lastRir
          : lastRir // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $ExerciseCopyWith<$Res> get exercise {
    return $ExerciseCopyWith<$Res>(_value.exercise, (value) {
      return _then(_value.copyWith(exercise: value) as $Val);
    });
  }

  @override
  @pragma('vm:prefer-inline')
  $RoutineExerciseCopyWith<$Res> get routineDetails {
    return $RoutineExerciseCopyWith<$Res>(_value.routineDetails, (value) {
      return _then(_value.copyWith(routineDetails: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$DailyExerciseImplCopyWith<$Res>
    implements $DailyExerciseCopyWith<$Res> {
  factory _$$DailyExerciseImplCopyWith(
          _$DailyExerciseImpl value, $Res Function(_$DailyExerciseImpl) then) =
      __$$DailyExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {Exercise exercise,
      RoutineExercise routineDetails,
      double? recommendedWeight,
      int? lastRir});

  @override
  $ExerciseCopyWith<$Res> get exercise;
  @override
  $RoutineExerciseCopyWith<$Res> get routineDetails;
}

/// @nodoc
class __$$DailyExerciseImplCopyWithImpl<$Res>
    extends _$DailyExerciseCopyWithImpl<$Res, _$DailyExerciseImpl>
    implements _$$DailyExerciseImplCopyWith<$Res> {
  __$$DailyExerciseImplCopyWithImpl(
      _$DailyExerciseImpl _value, $Res Function(_$DailyExerciseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exercise = null,
    Object? routineDetails = null,
    Object? recommendedWeight = freezed,
    Object? lastRir = freezed,
  }) {
    return _then(_$DailyExerciseImpl(
      exercise: null == exercise
          ? _value.exercise
          : exercise // ignore: cast_nullable_to_non_nullable
              as Exercise,
      routineDetails: null == routineDetails
          ? _value.routineDetails
          : routineDetails // ignore: cast_nullable_to_non_nullable
              as RoutineExercise,
      recommendedWeight: freezed == recommendedWeight
          ? _value.recommendedWeight
          : recommendedWeight // ignore: cast_nullable_to_non_nullable
              as double?,
      lastRir: freezed == lastRir
          ? _value.lastRir
          : lastRir // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _$DailyExerciseImpl implements _DailyExercise {
  const _$DailyExerciseImpl(
      {required this.exercise,
      required this.routineDetails,
      this.recommendedWeight,
      this.lastRir});

  @override
  final Exercise exercise;
  @override
  final RoutineExercise routineDetails;
  @override
  final double? recommendedWeight;
  @override
  final int? lastRir;

  @override
  String toString() {
    return 'DailyExercise(exercise: $exercise, routineDetails: $routineDetails, recommendedWeight: $recommendedWeight, lastRir: $lastRir)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DailyExerciseImpl &&
            (identical(other.exercise, exercise) ||
                other.exercise == exercise) &&
            (identical(other.routineDetails, routineDetails) ||
                other.routineDetails == routineDetails) &&
            (identical(other.recommendedWeight, recommendedWeight) ||
                other.recommendedWeight == recommendedWeight) &&
            (identical(other.lastRir, lastRir) || other.lastRir == lastRir));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, exercise, routineDetails, recommendedWeight, lastRir);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$DailyExerciseImplCopyWith<_$DailyExerciseImpl> get copyWith =>
      __$$DailyExerciseImplCopyWithImpl<_$DailyExerciseImpl>(this, _$identity);
}

abstract class _DailyExercise implements DailyExercise {
  const factory _DailyExercise(
      {required final Exercise exercise,
      required final RoutineExercise routineDetails,
      final double? recommendedWeight,
      final int? lastRir}) = _$DailyExerciseImpl;

  @override
  Exercise get exercise;
  @override
  RoutineExercise get routineDetails;
  @override
  double? get recommendedWeight;
  @override
  int? get lastRir;
  @override
  @JsonKey(ignore: true)
  _$$DailyExerciseImplCopyWith<_$DailyExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$DailyWorkoutState {
  RoutineTemplate? get routine => throw _privateConstructorUsedError;
  List<DailyExercise> get exercises => throw _privateConstructorUsedError;

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
  $Res call({RoutineTemplate? routine, List<DailyExercise> exercises});

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
              as List<DailyExercise>,
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
  $Res call({RoutineTemplate? routine, List<DailyExercise> exercises});

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
              as List<DailyExercise>,
    ));
  }
}

/// @nodoc

class _$DailyWorkoutStateImpl implements _DailyWorkoutState {
  const _$DailyWorkoutStateImpl(
      {required this.routine, required final List<DailyExercise> exercises})
      : _exercises = exercises;

  @override
  final RoutineTemplate? routine;
  final List<DailyExercise> _exercises;
  @override
  List<DailyExercise> get exercises {
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
      required final List<DailyExercise> exercises}) = _$DailyWorkoutStateImpl;

  @override
  RoutineTemplate? get routine;
  @override
  List<DailyExercise> get exercises;
  @override
  @JsonKey(ignore: true)
  _$$DailyWorkoutStateImplCopyWith<_$DailyWorkoutStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
