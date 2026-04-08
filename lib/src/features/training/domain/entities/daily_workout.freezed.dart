// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_workout.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailyWorkout {
  int get dayIndex; // 1 to 7 (Monday to Sunday)
  WorkoutType get type;
  int get durationMinutes;
  String get description;
  String get details; // E.g., "Zona 2" or "FullBody A"
  List<RoutineExercise> get exercises;

  /// Create a copy of DailyWorkout
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DailyWorkoutCopyWith<DailyWorkout> get copyWith =>
      _$DailyWorkoutCopyWithImpl<DailyWorkout>(
          this as DailyWorkout, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DailyWorkout &&
            (identical(other.dayIndex, dayIndex) ||
                other.dayIndex == dayIndex) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.details, details) || other.details == details) &&
            const DeepCollectionEquality().equals(other.exercises, exercises));
  }

  @override
  int get hashCode => Object.hash(runtimeType, dayIndex, type, durationMinutes,
      description, details, const DeepCollectionEquality().hash(exercises));

  @override
  String toString() {
    return 'DailyWorkout(dayIndex: $dayIndex, type: $type, durationMinutes: $durationMinutes, description: $description, details: $details, exercises: $exercises)';
  }
}

/// @nodoc
abstract mixin class $DailyWorkoutCopyWith<$Res> {
  factory $DailyWorkoutCopyWith(
          DailyWorkout value, $Res Function(DailyWorkout) _then) =
      _$DailyWorkoutCopyWithImpl;
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
class _$DailyWorkoutCopyWithImpl<$Res> implements $DailyWorkoutCopyWith<$Res> {
  _$DailyWorkoutCopyWithImpl(this._self, this._then);

  final DailyWorkout _self;
  final $Res Function(DailyWorkout) _then;

  /// Create a copy of DailyWorkout
  /// with the given fields replaced by the non-null parameter values.
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
    return _then(_self.copyWith(
      dayIndex: null == dayIndex
          ? _self.dayIndex
          : dayIndex // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as WorkoutType,
      durationMinutes: null == durationMinutes
          ? _self.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      details: null == details
          ? _self.details
          : details // ignore: cast_nullable_to_non_nullable
              as String,
      exercises: null == exercises
          ? _self.exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<RoutineExercise>,
    ));
  }
}

/// Adds pattern-matching-related methods to [DailyWorkout].
extension DailyWorkoutPatterns on DailyWorkout {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_DailyWorkout value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DailyWorkout() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_DailyWorkout value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyWorkout():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_DailyWorkout value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyWorkout() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            int dayIndex,
            WorkoutType type,
            int durationMinutes,
            String description,
            String details,
            List<RoutineExercise> exercises)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DailyWorkout() when $default != null:
        return $default(_that.dayIndex, _that.type, _that.durationMinutes,
            _that.description, _that.details, _that.exercises);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(int dayIndex, WorkoutType type, int durationMinutes,
            String description, String details, List<RoutineExercise> exercises)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyWorkout():
        return $default(_that.dayIndex, _that.type, _that.durationMinutes,
            _that.description, _that.details, _that.exercises);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            int dayIndex,
            WorkoutType type,
            int durationMinutes,
            String description,
            String details,
            List<RoutineExercise> exercises)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyWorkout() when $default != null:
        return $default(_that.dayIndex, _that.type, _that.durationMinutes,
            _that.description, _that.details, _that.exercises);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _DailyWorkout implements DailyWorkout {
  const _DailyWorkout(
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

  /// Create a copy of DailyWorkout
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DailyWorkoutCopyWith<_DailyWorkout> get copyWith =>
      __$DailyWorkoutCopyWithImpl<_DailyWorkout>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DailyWorkout &&
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

  @override
  String toString() {
    return 'DailyWorkout(dayIndex: $dayIndex, type: $type, durationMinutes: $durationMinutes, description: $description, details: $details, exercises: $exercises)';
  }
}

/// @nodoc
abstract mixin class _$DailyWorkoutCopyWith<$Res>
    implements $DailyWorkoutCopyWith<$Res> {
  factory _$DailyWorkoutCopyWith(
          _DailyWorkout value, $Res Function(_DailyWorkout) _then) =
      __$DailyWorkoutCopyWithImpl;
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
class __$DailyWorkoutCopyWithImpl<$Res>
    implements _$DailyWorkoutCopyWith<$Res> {
  __$DailyWorkoutCopyWithImpl(this._self, this._then);

  final _DailyWorkout _self;
  final $Res Function(_DailyWorkout) _then;

  /// Create a copy of DailyWorkout
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? dayIndex = null,
    Object? type = null,
    Object? durationMinutes = null,
    Object? description = null,
    Object? details = null,
    Object? exercises = null,
  }) {
    return _then(_DailyWorkout(
      dayIndex: null == dayIndex
          ? _self.dayIndex
          : dayIndex // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as WorkoutType,
      durationMinutes: null == durationMinutes
          ? _self.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      details: null == details
          ? _self.details
          : details // ignore: cast_nullable_to_non_nullable
              as String,
      exercises: null == exercises
          ? _self._exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<RoutineExercise>,
    ));
  }
}

// dart format on
