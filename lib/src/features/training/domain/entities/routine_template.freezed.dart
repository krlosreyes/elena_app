// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'routine_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoutineExercise {
  String get exerciseId;
  int get order;
  int get sets;
  String get repsRange;
  int get targetRir;
  int get restSeconds;

  /// Create a copy of RoutineExercise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RoutineExerciseCopyWith<RoutineExercise> get copyWith =>
      _$RoutineExerciseCopyWithImpl<RoutineExercise>(
          this as RoutineExercise, _$identity);

  /// Serializes this RoutineExercise to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RoutineExercise &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.sets, sets) || other.sets == sets) &&
            (identical(other.repsRange, repsRange) ||
                other.repsRange == repsRange) &&
            (identical(other.targetRir, targetRir) ||
                other.targetRir == targetRir) &&
            (identical(other.restSeconds, restSeconds) ||
                other.restSeconds == restSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, exerciseId, order, sets, repsRange, targetRir, restSeconds);

  @override
  String toString() {
    return 'RoutineExercise(exerciseId: $exerciseId, order: $order, sets: $sets, repsRange: $repsRange, targetRir: $targetRir, restSeconds: $restSeconds)';
  }
}

/// @nodoc
abstract mixin class $RoutineExerciseCopyWith<$Res> {
  factory $RoutineExerciseCopyWith(
          RoutineExercise value, $Res Function(RoutineExercise) _then) =
      _$RoutineExerciseCopyWithImpl;
  @useResult
  $Res call(
      {String exerciseId,
      int order,
      int sets,
      String repsRange,
      int targetRir,
      int restSeconds});
}

/// @nodoc
class _$RoutineExerciseCopyWithImpl<$Res>
    implements $RoutineExerciseCopyWith<$Res> {
  _$RoutineExerciseCopyWithImpl(this._self, this._then);

  final RoutineExercise _self;
  final $Res Function(RoutineExercise) _then;

  /// Create a copy of RoutineExercise
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? order = null,
    Object? sets = null,
    Object? repsRange = null,
    Object? targetRir = null,
    Object? restSeconds = null,
  }) {
    return _then(_self.copyWith(
      exerciseId: null == exerciseId
          ? _self.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      order: null == order
          ? _self.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      sets: null == sets
          ? _self.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as int,
      repsRange: null == repsRange
          ? _self.repsRange
          : repsRange // ignore: cast_nullable_to_non_nullable
              as String,
      targetRir: null == targetRir
          ? _self.targetRir
          : targetRir // ignore: cast_nullable_to_non_nullable
              as int,
      restSeconds: null == restSeconds
          ? _self.restSeconds
          : restSeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [RoutineExercise].
extension RoutineExercisePatterns on RoutineExercise {
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
    TResult Function(_RoutineExercise value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RoutineExercise() when $default != null:
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
    TResult Function(_RoutineExercise value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineExercise():
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
    TResult? Function(_RoutineExercise value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineExercise() when $default != null:
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
    TResult Function(String exerciseId, int order, int sets, String repsRange,
            int targetRir, int restSeconds)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RoutineExercise() when $default != null:
        return $default(_that.exerciseId, _that.order, _that.sets,
            _that.repsRange, _that.targetRir, _that.restSeconds);
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
    TResult Function(String exerciseId, int order, int sets, String repsRange,
            int targetRir, int restSeconds)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineExercise():
        return $default(_that.exerciseId, _that.order, _that.sets,
            _that.repsRange, _that.targetRir, _that.restSeconds);
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
    TResult? Function(String exerciseId, int order, int sets, String repsRange,
            int targetRir, int restSeconds)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineExercise() when $default != null:
        return $default(_that.exerciseId, _that.order, _that.sets,
            _that.repsRange, _that.targetRir, _that.restSeconds);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RoutineExercise implements RoutineExercise {
  const _RoutineExercise(
      {required this.exerciseId,
      required this.order,
      required this.sets,
      required this.repsRange,
      required this.targetRir,
      required this.restSeconds});
  factory _RoutineExercise.fromJson(Map<String, dynamic> json) =>
      _$RoutineExerciseFromJson(json);

  @override
  final String exerciseId;
  @override
  final int order;
  @override
  final int sets;
  @override
  final String repsRange;
  @override
  final int targetRir;
  @override
  final int restSeconds;

  /// Create a copy of RoutineExercise
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RoutineExerciseCopyWith<_RoutineExercise> get copyWith =>
      __$RoutineExerciseCopyWithImpl<_RoutineExercise>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RoutineExerciseToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RoutineExercise &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.sets, sets) || other.sets == sets) &&
            (identical(other.repsRange, repsRange) ||
                other.repsRange == repsRange) &&
            (identical(other.targetRir, targetRir) ||
                other.targetRir == targetRir) &&
            (identical(other.restSeconds, restSeconds) ||
                other.restSeconds == restSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, exerciseId, order, sets, repsRange, targetRir, restSeconds);

  @override
  String toString() {
    return 'RoutineExercise(exerciseId: $exerciseId, order: $order, sets: $sets, repsRange: $repsRange, targetRir: $targetRir, restSeconds: $restSeconds)';
  }
}

/// @nodoc
abstract mixin class _$RoutineExerciseCopyWith<$Res>
    implements $RoutineExerciseCopyWith<$Res> {
  factory _$RoutineExerciseCopyWith(
          _RoutineExercise value, $Res Function(_RoutineExercise) _then) =
      __$RoutineExerciseCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String exerciseId,
      int order,
      int sets,
      String repsRange,
      int targetRir,
      int restSeconds});
}

/// @nodoc
class __$RoutineExerciseCopyWithImpl<$Res>
    implements _$RoutineExerciseCopyWith<$Res> {
  __$RoutineExerciseCopyWithImpl(this._self, this._then);

  final _RoutineExercise _self;
  final $Res Function(_RoutineExercise) _then;

  /// Create a copy of RoutineExercise
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? exerciseId = null,
    Object? order = null,
    Object? sets = null,
    Object? repsRange = null,
    Object? targetRir = null,
    Object? restSeconds = null,
  }) {
    return _then(_RoutineExercise(
      exerciseId: null == exerciseId
          ? _self.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      order: null == order
          ? _self.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      sets: null == sets
          ? _self.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as int,
      repsRange: null == repsRange
          ? _self.repsRange
          : repsRange // ignore: cast_nullable_to_non_nullable
              as String,
      targetRir: null == targetRir
          ? _self.targetRir
          : targetRir // ignore: cast_nullable_to_non_nullable
              as int,
      restSeconds: null == restSeconds
          ? _self.restSeconds
          : restSeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
mixin _$RoutineTemplate {
  String get id;
  String get goal;
  String get level;
  String get target; // e.g., "Full Body", "Upper"
  int get estimatedMinutes;
  List<RoutineExercise> get exercises;

  /// Create a copy of RoutineTemplate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RoutineTemplateCopyWith<RoutineTemplate> get copyWith =>
      _$RoutineTemplateCopyWithImpl<RoutineTemplate>(
          this as RoutineTemplate, _$identity);

  /// Serializes this RoutineTemplate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RoutineTemplate &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.goal, goal) || other.goal == goal) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.estimatedMinutes, estimatedMinutes) ||
                other.estimatedMinutes == estimatedMinutes) &&
            const DeepCollectionEquality().equals(other.exercises, exercises));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, goal, level, target,
      estimatedMinutes, const DeepCollectionEquality().hash(exercises));

  @override
  String toString() {
    return 'RoutineTemplate(id: $id, goal: $goal, level: $level, target: $target, estimatedMinutes: $estimatedMinutes, exercises: $exercises)';
  }
}

/// @nodoc
abstract mixin class $RoutineTemplateCopyWith<$Res> {
  factory $RoutineTemplateCopyWith(
          RoutineTemplate value, $Res Function(RoutineTemplate) _then) =
      _$RoutineTemplateCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String goal,
      String level,
      String target,
      int estimatedMinutes,
      List<RoutineExercise> exercises});
}

/// @nodoc
class _$RoutineTemplateCopyWithImpl<$Res>
    implements $RoutineTemplateCopyWith<$Res> {
  _$RoutineTemplateCopyWithImpl(this._self, this._then);

  final RoutineTemplate _self;
  final $Res Function(RoutineTemplate) _then;

  /// Create a copy of RoutineTemplate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? goal = null,
    Object? level = null,
    Object? target = null,
    Object? estimatedMinutes = null,
    Object? exercises = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      goal: null == goal
          ? _self.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _self.level
          : level // ignore: cast_nullable_to_non_nullable
              as String,
      target: null == target
          ? _self.target
          : target // ignore: cast_nullable_to_non_nullable
              as String,
      estimatedMinutes: null == estimatedMinutes
          ? _self.estimatedMinutes
          : estimatedMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      exercises: null == exercises
          ? _self.exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<RoutineExercise>,
    ));
  }
}

/// Adds pattern-matching-related methods to [RoutineTemplate].
extension RoutineTemplatePatterns on RoutineTemplate {
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
    TResult Function(_RoutineTemplate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RoutineTemplate() when $default != null:
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
    TResult Function(_RoutineTemplate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineTemplate():
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
    TResult? Function(_RoutineTemplate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineTemplate() when $default != null:
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
    TResult Function(String id, String goal, String level, String target,
            int estimatedMinutes, List<RoutineExercise> exercises)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RoutineTemplate() when $default != null:
        return $default(_that.id, _that.goal, _that.level, _that.target,
            _that.estimatedMinutes, _that.exercises);
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
    TResult Function(String id, String goal, String level, String target,
            int estimatedMinutes, List<RoutineExercise> exercises)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineTemplate():
        return $default(_that.id, _that.goal, _that.level, _that.target,
            _that.estimatedMinutes, _that.exercises);
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
    TResult? Function(String id, String goal, String level, String target,
            int estimatedMinutes, List<RoutineExercise> exercises)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineTemplate() when $default != null:
        return $default(_that.id, _that.goal, _that.level, _that.target,
            _that.estimatedMinutes, _that.exercises);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RoutineTemplate implements RoutineTemplate {
  const _RoutineTemplate(
      {required this.id,
      required this.goal,
      required this.level,
      required this.target,
      required this.estimatedMinutes,
      required final List<RoutineExercise> exercises})
      : _exercises = exercises;
  factory _RoutineTemplate.fromJson(Map<String, dynamic> json) =>
      _$RoutineTemplateFromJson(json);

  @override
  final String id;
  @override
  final String goal;
  @override
  final String level;
  @override
  final String target;
// e.g., "Full Body", "Upper"
  @override
  final int estimatedMinutes;
  final List<RoutineExercise> _exercises;
  @override
  List<RoutineExercise> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  /// Create a copy of RoutineTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RoutineTemplateCopyWith<_RoutineTemplate> get copyWith =>
      __$RoutineTemplateCopyWithImpl<_RoutineTemplate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RoutineTemplateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RoutineTemplate &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.goal, goal) || other.goal == goal) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.estimatedMinutes, estimatedMinutes) ||
                other.estimatedMinutes == estimatedMinutes) &&
            const DeepCollectionEquality()
                .equals(other._exercises, _exercises));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, goal, level, target,
      estimatedMinutes, const DeepCollectionEquality().hash(_exercises));

  @override
  String toString() {
    return 'RoutineTemplate(id: $id, goal: $goal, level: $level, target: $target, estimatedMinutes: $estimatedMinutes, exercises: $exercises)';
  }
}

/// @nodoc
abstract mixin class _$RoutineTemplateCopyWith<$Res>
    implements $RoutineTemplateCopyWith<$Res> {
  factory _$RoutineTemplateCopyWith(
          _RoutineTemplate value, $Res Function(_RoutineTemplate) _then) =
      __$RoutineTemplateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String goal,
      String level,
      String target,
      int estimatedMinutes,
      List<RoutineExercise> exercises});
}

/// @nodoc
class __$RoutineTemplateCopyWithImpl<$Res>
    implements _$RoutineTemplateCopyWith<$Res> {
  __$RoutineTemplateCopyWithImpl(this._self, this._then);

  final _RoutineTemplate _self;
  final $Res Function(_RoutineTemplate) _then;

  /// Create a copy of RoutineTemplate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? goal = null,
    Object? level = null,
    Object? target = null,
    Object? estimatedMinutes = null,
    Object? exercises = null,
  }) {
    return _then(_RoutineTemplate(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      goal: null == goal
          ? _self.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _self.level
          : level // ignore: cast_nullable_to_non_nullable
              as String,
      target: null == target
          ? _self.target
          : target // ignore: cast_nullable_to_non_nullable
              as String,
      estimatedMinutes: null == estimatedMinutes
          ? _self.estimatedMinutes
          : estimatedMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      exercises: null == exercises
          ? _self._exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<RoutineExercise>,
    ));
  }
}

// dart format on
