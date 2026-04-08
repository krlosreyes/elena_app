// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weekly_routine.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExerciseTemplate {
  String get exerciseId;
  String get name;
  String get muscleGroup;
  int get targetSets;
  int get targetReps;
  int get targetMinutes;
  bool get requiresDumbbells;
  int get completedSets;

  /// Create a copy of ExerciseTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExerciseTemplateCopyWith<ExerciseTemplate> get copyWith =>
      _$ExerciseTemplateCopyWithImpl<ExerciseTemplate>(
          this as ExerciseTemplate, _$identity);

  /// Serializes this ExerciseTemplate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExerciseTemplate &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.muscleGroup, muscleGroup) ||
                other.muscleGroup == muscleGroup) &&
            (identical(other.targetSets, targetSets) ||
                other.targetSets == targetSets) &&
            (identical(other.targetReps, targetReps) ||
                other.targetReps == targetReps) &&
            (identical(other.targetMinutes, targetMinutes) ||
                other.targetMinutes == targetMinutes) &&
            (identical(other.requiresDumbbells, requiresDumbbells) ||
                other.requiresDumbbells == requiresDumbbells) &&
            (identical(other.completedSets, completedSets) ||
                other.completedSets == completedSets));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, exerciseId, name, muscleGroup,
      targetSets, targetReps, targetMinutes, requiresDumbbells, completedSets);

  @override
  String toString() {
    return 'ExerciseTemplate(exerciseId: $exerciseId, name: $name, muscleGroup: $muscleGroup, targetSets: $targetSets, targetReps: $targetReps, targetMinutes: $targetMinutes, requiresDumbbells: $requiresDumbbells, completedSets: $completedSets)';
  }
}

/// @nodoc
abstract mixin class $ExerciseTemplateCopyWith<$Res> {
  factory $ExerciseTemplateCopyWith(
          ExerciseTemplate value, $Res Function(ExerciseTemplate) _then) =
      _$ExerciseTemplateCopyWithImpl;
  @useResult
  $Res call(
      {String exerciseId,
      String name,
      String muscleGroup,
      int targetSets,
      int targetReps,
      int targetMinutes,
      bool requiresDumbbells,
      int completedSets});
}

/// @nodoc
class _$ExerciseTemplateCopyWithImpl<$Res>
    implements $ExerciseTemplateCopyWith<$Res> {
  _$ExerciseTemplateCopyWithImpl(this._self, this._then);

  final ExerciseTemplate _self;
  final $Res Function(ExerciseTemplate) _then;

  /// Create a copy of ExerciseTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? name = null,
    Object? muscleGroup = null,
    Object? targetSets = null,
    Object? targetReps = null,
    Object? targetMinutes = null,
    Object? requiresDumbbells = null,
    Object? completedSets = null,
  }) {
    return _then(_self.copyWith(
      exerciseId: null == exerciseId
          ? _self.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      muscleGroup: null == muscleGroup
          ? _self.muscleGroup
          : muscleGroup // ignore: cast_nullable_to_non_nullable
              as String,
      targetSets: null == targetSets
          ? _self.targetSets
          : targetSets // ignore: cast_nullable_to_non_nullable
              as int,
      targetReps: null == targetReps
          ? _self.targetReps
          : targetReps // ignore: cast_nullable_to_non_nullable
              as int,
      targetMinutes: null == targetMinutes
          ? _self.targetMinutes
          : targetMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      requiresDumbbells: null == requiresDumbbells
          ? _self.requiresDumbbells
          : requiresDumbbells // ignore: cast_nullable_to_non_nullable
              as bool,
      completedSets: null == completedSets
          ? _self.completedSets
          : completedSets // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [ExerciseTemplate].
extension ExerciseTemplatePatterns on ExerciseTemplate {
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
    TResult Function(_ExerciseTemplate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ExerciseTemplate() when $default != null:
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
    TResult Function(_ExerciseTemplate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExerciseTemplate():
        return $default(_that);
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
    TResult? Function(_ExerciseTemplate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExerciseTemplate() when $default != null:
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
            String exerciseId,
            String name,
            String muscleGroup,
            int targetSets,
            int targetReps,
            int targetMinutes,
            bool requiresDumbbells,
            int completedSets)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ExerciseTemplate() when $default != null:
        return $default(
            _that.exerciseId,
            _that.name,
            _that.muscleGroup,
            _that.targetSets,
            _that.targetReps,
            _that.targetMinutes,
            _that.requiresDumbbells,
            _that.completedSets);
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
    TResult Function(
            String exerciseId,
            String name,
            String muscleGroup,
            int targetSets,
            int targetReps,
            int targetMinutes,
            bool requiresDumbbells,
            int completedSets)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExerciseTemplate():
        return $default(
            _that.exerciseId,
            _that.name,
            _that.muscleGroup,
            _that.targetSets,
            _that.targetReps,
            _that.targetMinutes,
            _that.requiresDumbbells,
            _that.completedSets);
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
            String exerciseId,
            String name,
            String muscleGroup,
            int targetSets,
            int targetReps,
            int targetMinutes,
            bool requiresDumbbells,
            int completedSets)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExerciseTemplate() when $default != null:
        return $default(
            _that.exerciseId,
            _that.name,
            _that.muscleGroup,
            _that.targetSets,
            _that.targetReps,
            _that.targetMinutes,
            _that.requiresDumbbells,
            _that.completedSets);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ExerciseTemplate implements ExerciseTemplate {
  const _ExerciseTemplate(
      {required this.exerciseId,
      required this.name,
      required this.muscleGroup,
      this.targetSets = 3,
      this.targetReps = 10,
      this.targetMinutes = 0,
      this.requiresDumbbells = false,
      this.completedSets = 0});
  factory _ExerciseTemplate.fromJson(Map<String, dynamic> json) =>
      _$ExerciseTemplateFromJson(json);

  @override
  final String exerciseId;
  @override
  final String name;
  @override
  final String muscleGroup;
  @override
  @JsonKey()
  final int targetSets;
  @override
  @JsonKey()
  final int targetReps;
  @override
  @JsonKey()
  final int targetMinutes;
  @override
  @JsonKey()
  final bool requiresDumbbells;
  @override
  @JsonKey()
  final int completedSets;

  /// Create a copy of ExerciseTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ExerciseTemplateCopyWith<_ExerciseTemplate> get copyWith =>
      __$ExerciseTemplateCopyWithImpl<_ExerciseTemplate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ExerciseTemplateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ExerciseTemplate &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.muscleGroup, muscleGroup) ||
                other.muscleGroup == muscleGroup) &&
            (identical(other.targetSets, targetSets) ||
                other.targetSets == targetSets) &&
            (identical(other.targetReps, targetReps) ||
                other.targetReps == targetReps) &&
            (identical(other.targetMinutes, targetMinutes) ||
                other.targetMinutes == targetMinutes) &&
            (identical(other.requiresDumbbells, requiresDumbbells) ||
                other.requiresDumbbells == requiresDumbbells) &&
            (identical(other.completedSets, completedSets) ||
                other.completedSets == completedSets));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, exerciseId, name, muscleGroup,
      targetSets, targetReps, targetMinutes, requiresDumbbells, completedSets);

  @override
  String toString() {
    return 'ExerciseTemplate(exerciseId: $exerciseId, name: $name, muscleGroup: $muscleGroup, targetSets: $targetSets, targetReps: $targetReps, targetMinutes: $targetMinutes, requiresDumbbells: $requiresDumbbells, completedSets: $completedSets)';
  }
}

/// @nodoc
abstract mixin class _$ExerciseTemplateCopyWith<$Res>
    implements $ExerciseTemplateCopyWith<$Res> {
  factory _$ExerciseTemplateCopyWith(
          _ExerciseTemplate value, $Res Function(_ExerciseTemplate) _then) =
      __$ExerciseTemplateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String exerciseId,
      String name,
      String muscleGroup,
      int targetSets,
      int targetReps,
      int targetMinutes,
      bool requiresDumbbells,
      int completedSets});
}

/// @nodoc
class __$ExerciseTemplateCopyWithImpl<$Res>
    implements _$ExerciseTemplateCopyWith<$Res> {
  __$ExerciseTemplateCopyWithImpl(this._self, this._then);

  final _ExerciseTemplate _self;
  final $Res Function(_ExerciseTemplate) _then;

  /// Create a copy of ExerciseTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? exerciseId = null,
    Object? name = null,
    Object? muscleGroup = null,
    Object? targetSets = null,
    Object? targetReps = null,
    Object? targetMinutes = null,
    Object? requiresDumbbells = null,
    Object? completedSets = null,
  }) {
    return _then(_ExerciseTemplate(
      exerciseId: null == exerciseId
          ? _self.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      muscleGroup: null == muscleGroup
          ? _self.muscleGroup
          : muscleGroup // ignore: cast_nullable_to_non_nullable
              as String,
      targetSets: null == targetSets
          ? _self.targetSets
          : targetSets // ignore: cast_nullable_to_non_nullable
              as int,
      targetReps: null == targetReps
          ? _self.targetReps
          : targetReps // ignore: cast_nullable_to_non_nullable
              as int,
      targetMinutes: null == targetMinutes
          ? _self.targetMinutes
          : targetMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      requiresDumbbells: null == requiresDumbbells
          ? _self.requiresDumbbells
          : requiresDumbbells // ignore: cast_nullable_to_non_nullable
              as bool,
      completedSets: null == completedSets
          ? _self.completedSets
          : completedSets // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
mixin _$WorkoutDay {
  int get dayIndex;
  WorkoutDayType get type;
  bool get completed;
  @OptionalTimestampConverter()
  DateTime? get completedAt;
  List<ExerciseTemplate> get exercises;

  /// Create a copy of WorkoutDay
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WorkoutDayCopyWith<WorkoutDay> get copyWith =>
      _$WorkoutDayCopyWithImpl<WorkoutDay>(this as WorkoutDay, _$identity);

  /// Serializes this WorkoutDay to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WorkoutDay &&
            (identical(other.dayIndex, dayIndex) ||
                other.dayIndex == dayIndex) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            const DeepCollectionEquality().equals(other.exercises, exercises));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, dayIndex, type, completed,
      completedAt, const DeepCollectionEquality().hash(exercises));

  @override
  String toString() {
    return 'WorkoutDay(dayIndex: $dayIndex, type: $type, completed: $completed, completedAt: $completedAt, exercises: $exercises)';
  }
}

/// @nodoc
abstract mixin class $WorkoutDayCopyWith<$Res> {
  factory $WorkoutDayCopyWith(
          WorkoutDay value, $Res Function(WorkoutDay) _then) =
      _$WorkoutDayCopyWithImpl;
  @useResult
  $Res call(
      {int dayIndex,
      WorkoutDayType type,
      bool completed,
      @OptionalTimestampConverter() DateTime? completedAt,
      List<ExerciseTemplate> exercises});
}

/// @nodoc
class _$WorkoutDayCopyWithImpl<$Res> implements $WorkoutDayCopyWith<$Res> {
  _$WorkoutDayCopyWithImpl(this._self, this._then);

  final WorkoutDay _self;
  final $Res Function(WorkoutDay) _then;

  /// Create a copy of WorkoutDay
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayIndex = null,
    Object? type = null,
    Object? completed = null,
    Object? completedAt = freezed,
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
              as WorkoutDayType,
      completed: null == completed
          ? _self.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as bool,
      completedAt: freezed == completedAt
          ? _self.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      exercises: null == exercises
          ? _self.exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<ExerciseTemplate>,
    ));
  }
}

/// Adds pattern-matching-related methods to [WorkoutDay].
extension WorkoutDayPatterns on WorkoutDay {
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
    TResult Function(_WorkoutDay value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WorkoutDay() when $default != null:
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
    TResult Function(_WorkoutDay value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutDay():
        return $default(_that);
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
    TResult? Function(_WorkoutDay value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutDay() when $default != null:
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
            WorkoutDayType type,
            bool completed,
            @OptionalTimestampConverter() DateTime? completedAt,
            List<ExerciseTemplate> exercises)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WorkoutDay() when $default != null:
        return $default(_that.dayIndex, _that.type, _that.completed,
            _that.completedAt, _that.exercises);
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
    TResult Function(
            int dayIndex,
            WorkoutDayType type,
            bool completed,
            @OptionalTimestampConverter() DateTime? completedAt,
            List<ExerciseTemplate> exercises)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutDay():
        return $default(_that.dayIndex, _that.type, _that.completed,
            _that.completedAt, _that.exercises);
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
            WorkoutDayType type,
            bool completed,
            @OptionalTimestampConverter() DateTime? completedAt,
            List<ExerciseTemplate> exercises)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutDay() when $default != null:
        return $default(_that.dayIndex, _that.type, _that.completed,
            _that.completedAt, _that.exercises);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WorkoutDay implements WorkoutDay {
  const _WorkoutDay(
      {required this.dayIndex,
      required this.type,
      this.completed = false,
      @OptionalTimestampConverter() this.completedAt,
      final List<ExerciseTemplate> exercises = const []})
      : _exercises = exercises;
  factory _WorkoutDay.fromJson(Map<String, dynamic> json) =>
      _$WorkoutDayFromJson(json);

  @override
  final int dayIndex;
  @override
  final WorkoutDayType type;
  @override
  @JsonKey()
  final bool completed;
  @override
  @OptionalTimestampConverter()
  final DateTime? completedAt;
  final List<ExerciseTemplate> _exercises;
  @override
  @JsonKey()
  List<ExerciseTemplate> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  /// Create a copy of WorkoutDay
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WorkoutDayCopyWith<_WorkoutDay> get copyWith =>
      __$WorkoutDayCopyWithImpl<_WorkoutDay>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WorkoutDayToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WorkoutDay &&
            (identical(other.dayIndex, dayIndex) ||
                other.dayIndex == dayIndex) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            const DeepCollectionEquality()
                .equals(other._exercises, _exercises));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, dayIndex, type, completed,
      completedAt, const DeepCollectionEquality().hash(_exercises));

  @override
  String toString() {
    return 'WorkoutDay(dayIndex: $dayIndex, type: $type, completed: $completed, completedAt: $completedAt, exercises: $exercises)';
  }
}

/// @nodoc
abstract mixin class _$WorkoutDayCopyWith<$Res>
    implements $WorkoutDayCopyWith<$Res> {
  factory _$WorkoutDayCopyWith(
          _WorkoutDay value, $Res Function(_WorkoutDay) _then) =
      __$WorkoutDayCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int dayIndex,
      WorkoutDayType type,
      bool completed,
      @OptionalTimestampConverter() DateTime? completedAt,
      List<ExerciseTemplate> exercises});
}

/// @nodoc
class __$WorkoutDayCopyWithImpl<$Res> implements _$WorkoutDayCopyWith<$Res> {
  __$WorkoutDayCopyWithImpl(this._self, this._then);

  final _WorkoutDay _self;
  final $Res Function(_WorkoutDay) _then;

  /// Create a copy of WorkoutDay
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? dayIndex = null,
    Object? type = null,
    Object? completed = null,
    Object? completedAt = freezed,
    Object? exercises = null,
  }) {
    return _then(_WorkoutDay(
      dayIndex: null == dayIndex
          ? _self.dayIndex
          : dayIndex // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as WorkoutDayType,
      completed: null == completed
          ? _self.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as bool,
      completedAt: freezed == completedAt
          ? _self.completedAt
          : completedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      exercises: null == exercises
          ? _self._exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<ExerciseTemplate>,
    ));
  }
}

/// @nodoc
mixin _$WeeklyRoutine {
  String get weekId;
  @TimestampConverter()
  DateTime get generatedAt;
  String get activityLevelSnapshot;
  String get healthGoalSnapshot;
  bool get completed;
  List<WorkoutDay> get days;

  /// Create a copy of WeeklyRoutine
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WeeklyRoutineCopyWith<WeeklyRoutine> get copyWith =>
      _$WeeklyRoutineCopyWithImpl<WeeklyRoutine>(
          this as WeeklyRoutine, _$identity);

  /// Serializes this WeeklyRoutine to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WeeklyRoutine &&
            (identical(other.weekId, weekId) || other.weekId == weekId) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt) &&
            (identical(other.activityLevelSnapshot, activityLevelSnapshot) ||
                other.activityLevelSnapshot == activityLevelSnapshot) &&
            (identical(other.healthGoalSnapshot, healthGoalSnapshot) ||
                other.healthGoalSnapshot == healthGoalSnapshot) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            const DeepCollectionEquality().equals(other.days, days));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      weekId,
      generatedAt,
      activityLevelSnapshot,
      healthGoalSnapshot,
      completed,
      const DeepCollectionEquality().hash(days));

  @override
  String toString() {
    return 'WeeklyRoutine(weekId: $weekId, generatedAt: $generatedAt, activityLevelSnapshot: $activityLevelSnapshot, healthGoalSnapshot: $healthGoalSnapshot, completed: $completed, days: $days)';
  }
}

/// @nodoc
abstract mixin class $WeeklyRoutineCopyWith<$Res> {
  factory $WeeklyRoutineCopyWith(
          WeeklyRoutine value, $Res Function(WeeklyRoutine) _then) =
      _$WeeklyRoutineCopyWithImpl;
  @useResult
  $Res call(
      {String weekId,
      @TimestampConverter() DateTime generatedAt,
      String activityLevelSnapshot,
      String healthGoalSnapshot,
      bool completed,
      List<WorkoutDay> days});
}

/// @nodoc
class _$WeeklyRoutineCopyWithImpl<$Res>
    implements $WeeklyRoutineCopyWith<$Res> {
  _$WeeklyRoutineCopyWithImpl(this._self, this._then);

  final WeeklyRoutine _self;
  final $Res Function(WeeklyRoutine) _then;

  /// Create a copy of WeeklyRoutine
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weekId = null,
    Object? generatedAt = null,
    Object? activityLevelSnapshot = null,
    Object? healthGoalSnapshot = null,
    Object? completed = null,
    Object? days = null,
  }) {
    return _then(_self.copyWith(
      weekId: null == weekId
          ? _self.weekId
          : weekId // ignore: cast_nullable_to_non_nullable
              as String,
      generatedAt: null == generatedAt
          ? _self.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      activityLevelSnapshot: null == activityLevelSnapshot
          ? _self.activityLevelSnapshot
          : activityLevelSnapshot // ignore: cast_nullable_to_non_nullable
              as String,
      healthGoalSnapshot: null == healthGoalSnapshot
          ? _self.healthGoalSnapshot
          : healthGoalSnapshot // ignore: cast_nullable_to_non_nullable
              as String,
      completed: null == completed
          ? _self.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as bool,
      days: null == days
          ? _self.days
          : days // ignore: cast_nullable_to_non_nullable
              as List<WorkoutDay>,
    ));
  }
}

/// Adds pattern-matching-related methods to [WeeklyRoutine].
extension WeeklyRoutinePatterns on WeeklyRoutine {
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
    TResult Function(_WeeklyRoutine value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WeeklyRoutine() when $default != null:
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
    TResult Function(_WeeklyRoutine value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WeeklyRoutine():
        return $default(_that);
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
    TResult? Function(_WeeklyRoutine value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WeeklyRoutine() when $default != null:
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
            String weekId,
            @TimestampConverter() DateTime generatedAt,
            String activityLevelSnapshot,
            String healthGoalSnapshot,
            bool completed,
            List<WorkoutDay> days)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WeeklyRoutine() when $default != null:
        return $default(
            _that.weekId,
            _that.generatedAt,
            _that.activityLevelSnapshot,
            _that.healthGoalSnapshot,
            _that.completed,
            _that.days);
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
    TResult Function(
            String weekId,
            @TimestampConverter() DateTime generatedAt,
            String activityLevelSnapshot,
            String healthGoalSnapshot,
            bool completed,
            List<WorkoutDay> days)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WeeklyRoutine():
        return $default(
            _that.weekId,
            _that.generatedAt,
            _that.activityLevelSnapshot,
            _that.healthGoalSnapshot,
            _that.completed,
            _that.days);
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
            String weekId,
            @TimestampConverter() DateTime generatedAt,
            String activityLevelSnapshot,
            String healthGoalSnapshot,
            bool completed,
            List<WorkoutDay> days)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WeeklyRoutine() when $default != null:
        return $default(
            _that.weekId,
            _that.generatedAt,
            _that.activityLevelSnapshot,
            _that.healthGoalSnapshot,
            _that.completed,
            _that.days);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WeeklyRoutine extends WeeklyRoutine {
  const _WeeklyRoutine(
      {required this.weekId,
      @TimestampConverter() required this.generatedAt,
      required this.activityLevelSnapshot,
      required this.healthGoalSnapshot,
      this.completed = false,
      final List<WorkoutDay> days = const []})
      : _days = days,
        super._();
  factory _WeeklyRoutine.fromJson(Map<String, dynamic> json) =>
      _$WeeklyRoutineFromJson(json);

  @override
  final String weekId;
  @override
  @TimestampConverter()
  final DateTime generatedAt;
  @override
  final String activityLevelSnapshot;
  @override
  final String healthGoalSnapshot;
  @override
  @JsonKey()
  final bool completed;
  final List<WorkoutDay> _days;
  @override
  @JsonKey()
  List<WorkoutDay> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  /// Create a copy of WeeklyRoutine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WeeklyRoutineCopyWith<_WeeklyRoutine> get copyWith =>
      __$WeeklyRoutineCopyWithImpl<_WeeklyRoutine>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WeeklyRoutineToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WeeklyRoutine &&
            (identical(other.weekId, weekId) || other.weekId == weekId) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt) &&
            (identical(other.activityLevelSnapshot, activityLevelSnapshot) ||
                other.activityLevelSnapshot == activityLevelSnapshot) &&
            (identical(other.healthGoalSnapshot, healthGoalSnapshot) ||
                other.healthGoalSnapshot == healthGoalSnapshot) &&
            (identical(other.completed, completed) ||
                other.completed == completed) &&
            const DeepCollectionEquality().equals(other._days, _days));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      weekId,
      generatedAt,
      activityLevelSnapshot,
      healthGoalSnapshot,
      completed,
      const DeepCollectionEquality().hash(_days));

  @override
  String toString() {
    return 'WeeklyRoutine(weekId: $weekId, generatedAt: $generatedAt, activityLevelSnapshot: $activityLevelSnapshot, healthGoalSnapshot: $healthGoalSnapshot, completed: $completed, days: $days)';
  }
}

/// @nodoc
abstract mixin class _$WeeklyRoutineCopyWith<$Res>
    implements $WeeklyRoutineCopyWith<$Res> {
  factory _$WeeklyRoutineCopyWith(
          _WeeklyRoutine value, $Res Function(_WeeklyRoutine) _then) =
      __$WeeklyRoutineCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String weekId,
      @TimestampConverter() DateTime generatedAt,
      String activityLevelSnapshot,
      String healthGoalSnapshot,
      bool completed,
      List<WorkoutDay> days});
}

/// @nodoc
class __$WeeklyRoutineCopyWithImpl<$Res>
    implements _$WeeklyRoutineCopyWith<$Res> {
  __$WeeklyRoutineCopyWithImpl(this._self, this._then);

  final _WeeklyRoutine _self;
  final $Res Function(_WeeklyRoutine) _then;

  /// Create a copy of WeeklyRoutine
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? weekId = null,
    Object? generatedAt = null,
    Object? activityLevelSnapshot = null,
    Object? healthGoalSnapshot = null,
    Object? completed = null,
    Object? days = null,
  }) {
    return _then(_WeeklyRoutine(
      weekId: null == weekId
          ? _self.weekId
          : weekId // ignore: cast_nullable_to_non_nullable
              as String,
      generatedAt: null == generatedAt
          ? _self.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      activityLevelSnapshot: null == activityLevelSnapshot
          ? _self.activityLevelSnapshot
          : activityLevelSnapshot // ignore: cast_nullable_to_non_nullable
              as String,
      healthGoalSnapshot: null == healthGoalSnapshot
          ? _self.healthGoalSnapshot
          : healthGoalSnapshot // ignore: cast_nullable_to_non_nullable
              as String,
      completed: null == completed
          ? _self.completed
          : completed // ignore: cast_nullable_to_non_nullable
              as bool,
      days: null == days
          ? _self._days
          : days // ignore: cast_nullable_to_non_nullable
              as List<WorkoutDay>,
    ));
  }
}

// dart format on
