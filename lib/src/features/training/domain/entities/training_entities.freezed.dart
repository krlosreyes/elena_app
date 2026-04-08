// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'training_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkoutSession {
  String get id;
  String get userId;
  @TimestampConverter()
  DateTime get startTime;
  @TimestampConverter()
  DateTime get endTime;
  int get intensityLevel;
  String get type;
  TargetMuscle? get targetMuscle;
  List<ExerciseSet> get sets;

  /// Create a copy of WorkoutSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WorkoutSessionCopyWith<WorkoutSession> get copyWith =>
      _$WorkoutSessionCopyWithImpl<WorkoutSession>(
          this as WorkoutSession, _$identity);

  /// Serializes this WorkoutSession to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WorkoutSession &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.intensityLevel, intensityLevel) ||
                other.intensityLevel == intensityLevel) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.targetMuscle, targetMuscle) ||
                other.targetMuscle == targetMuscle) &&
            const DeepCollectionEquality().equals(other.sets, sets));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      startTime,
      endTime,
      intensityLevel,
      type,
      targetMuscle,
      const DeepCollectionEquality().hash(sets));

  @override
  String toString() {
    return 'WorkoutSession(id: $id, userId: $userId, startTime: $startTime, endTime: $endTime, intensityLevel: $intensityLevel, type: $type, targetMuscle: $targetMuscle, sets: $sets)';
  }
}

/// @nodoc
abstract mixin class $WorkoutSessionCopyWith<$Res> {
  factory $WorkoutSessionCopyWith(
          WorkoutSession value, $Res Function(WorkoutSession) _then) =
      _$WorkoutSessionCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String userId,
      @TimestampConverter() DateTime startTime,
      @TimestampConverter() DateTime endTime,
      int intensityLevel,
      String type,
      TargetMuscle? targetMuscle,
      List<ExerciseSet> sets});
}

/// @nodoc
class _$WorkoutSessionCopyWithImpl<$Res>
    implements $WorkoutSessionCopyWith<$Res> {
  _$WorkoutSessionCopyWithImpl(this._self, this._then);

  final WorkoutSession _self;
  final $Res Function(WorkoutSession) _then;

  /// Create a copy of WorkoutSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? intensityLevel = null,
    Object? type = null,
    Object? targetMuscle = freezed,
    Object? sets = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      intensityLevel: null == intensityLevel
          ? _self.intensityLevel
          : intensityLevel // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      targetMuscle: freezed == targetMuscle
          ? _self.targetMuscle
          : targetMuscle // ignore: cast_nullable_to_non_nullable
              as TargetMuscle?,
      sets: null == sets
          ? _self.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as List<ExerciseSet>,
    ));
  }
}

/// Adds pattern-matching-related methods to [WorkoutSession].
extension WorkoutSessionPatterns on WorkoutSession {
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
    TResult Function(_WorkoutSession value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WorkoutSession() when $default != null:
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
    TResult Function(_WorkoutSession value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutSession():
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
    TResult? Function(_WorkoutSession value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutSession() when $default != null:
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
            String id,
            String userId,
            @TimestampConverter() DateTime startTime,
            @TimestampConverter() DateTime endTime,
            int intensityLevel,
            String type,
            TargetMuscle? targetMuscle,
            List<ExerciseSet> sets)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WorkoutSession() when $default != null:
        return $default(_that.id, _that.userId, _that.startTime, _that.endTime,
            _that.intensityLevel, _that.type, _that.targetMuscle, _that.sets);
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
            String id,
            String userId,
            @TimestampConverter() DateTime startTime,
            @TimestampConverter() DateTime endTime,
            int intensityLevel,
            String type,
            TargetMuscle? targetMuscle,
            List<ExerciseSet> sets)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutSession():
        return $default(_that.id, _that.userId, _that.startTime, _that.endTime,
            _that.intensityLevel, _that.type, _that.targetMuscle, _that.sets);
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
            String id,
            String userId,
            @TimestampConverter() DateTime startTime,
            @TimestampConverter() DateTime endTime,
            int intensityLevel,
            String type,
            TargetMuscle? targetMuscle,
            List<ExerciseSet> sets)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutSession() when $default != null:
        return $default(_that.id, _that.userId, _that.startTime, _that.endTime,
            _that.intensityLevel, _that.type, _that.targetMuscle, _that.sets);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WorkoutSession implements WorkoutSession {
  const _WorkoutSession(
      {required this.id,
      required this.userId,
      @TimestampConverter() required this.startTime,
      @TimestampConverter() required this.endTime,
      required this.intensityLevel,
      required this.type,
      this.targetMuscle,
      final List<ExerciseSet> sets = const []})
      : _sets = sets;
  factory _WorkoutSession.fromJson(Map<String, dynamic> json) =>
      _$WorkoutSessionFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  @TimestampConverter()
  final DateTime startTime;
  @override
  @TimestampConverter()
  final DateTime endTime;
  @override
  final int intensityLevel;
  @override
  final String type;
  @override
  final TargetMuscle? targetMuscle;
  final List<ExerciseSet> _sets;
  @override
  @JsonKey()
  List<ExerciseSet> get sets {
    if (_sets is EqualUnmodifiableListView) return _sets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sets);
  }

  /// Create a copy of WorkoutSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WorkoutSessionCopyWith<_WorkoutSession> get copyWith =>
      __$WorkoutSessionCopyWithImpl<_WorkoutSession>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WorkoutSessionToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WorkoutSession &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.intensityLevel, intensityLevel) ||
                other.intensityLevel == intensityLevel) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.targetMuscle, targetMuscle) ||
                other.targetMuscle == targetMuscle) &&
            const DeepCollectionEquality().equals(other._sets, _sets));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      startTime,
      endTime,
      intensityLevel,
      type,
      targetMuscle,
      const DeepCollectionEquality().hash(_sets));

  @override
  String toString() {
    return 'WorkoutSession(id: $id, userId: $userId, startTime: $startTime, endTime: $endTime, intensityLevel: $intensityLevel, type: $type, targetMuscle: $targetMuscle, sets: $sets)';
  }
}

/// @nodoc
abstract mixin class _$WorkoutSessionCopyWith<$Res>
    implements $WorkoutSessionCopyWith<$Res> {
  factory _$WorkoutSessionCopyWith(
          _WorkoutSession value, $Res Function(_WorkoutSession) _then) =
      __$WorkoutSessionCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      @TimestampConverter() DateTime startTime,
      @TimestampConverter() DateTime endTime,
      int intensityLevel,
      String type,
      TargetMuscle? targetMuscle,
      List<ExerciseSet> sets});
}

/// @nodoc
class __$WorkoutSessionCopyWithImpl<$Res>
    implements _$WorkoutSessionCopyWith<$Res> {
  __$WorkoutSessionCopyWithImpl(this._self, this._then);

  final _WorkoutSession _self;
  final $Res Function(_WorkoutSession) _then;

  /// Create a copy of WorkoutSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? intensityLevel = null,
    Object? type = null,
    Object? targetMuscle = freezed,
    Object? sets = null,
  }) {
    return _then(_WorkoutSession(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: null == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      intensityLevel: null == intensityLevel
          ? _self.intensityLevel
          : intensityLevel // ignore: cast_nullable_to_non_nullable
              as int,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      targetMuscle: freezed == targetMuscle
          ? _self.targetMuscle
          : targetMuscle // ignore: cast_nullable_to_non_nullable
              as TargetMuscle?,
      sets: null == sets
          ? _self._sets
          : sets // ignore: cast_nullable_to_non_nullable
              as List<ExerciseSet>,
    ));
  }
}

/// @nodoc
mixin _$ExerciseSet {
  int get setIndex;
  String get exerciseName;
  double get weight;
  int get repsCompleted;
  int get rir;
  bool get isDone;

  /// Create a copy of ExerciseSet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExerciseSetCopyWith<ExerciseSet> get copyWith =>
      _$ExerciseSetCopyWithImpl<ExerciseSet>(this as ExerciseSet, _$identity);

  /// Serializes this ExerciseSet to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExerciseSet &&
            (identical(other.setIndex, setIndex) ||
                other.setIndex == setIndex) &&
            (identical(other.exerciseName, exerciseName) ||
                other.exerciseName == exerciseName) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.repsCompleted, repsCompleted) ||
                other.repsCompleted == repsCompleted) &&
            (identical(other.rir, rir) || other.rir == rir) &&
            (identical(other.isDone, isDone) || other.isDone == isDone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, setIndex, exerciseName, weight, repsCompleted, rir, isDone);

  @override
  String toString() {
    return 'ExerciseSet(setIndex: $setIndex, exerciseName: $exerciseName, weight: $weight, repsCompleted: $repsCompleted, rir: $rir, isDone: $isDone)';
  }
}

/// @nodoc
abstract mixin class $ExerciseSetCopyWith<$Res> {
  factory $ExerciseSetCopyWith(
          ExerciseSet value, $Res Function(ExerciseSet) _then) =
      _$ExerciseSetCopyWithImpl;
  @useResult
  $Res call(
      {int setIndex,
      String exerciseName,
      double weight,
      int repsCompleted,
      int rir,
      bool isDone});
}

/// @nodoc
class _$ExerciseSetCopyWithImpl<$Res> implements $ExerciseSetCopyWith<$Res> {
  _$ExerciseSetCopyWithImpl(this._self, this._then);

  final ExerciseSet _self;
  final $Res Function(ExerciseSet) _then;

  /// Create a copy of ExerciseSet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? setIndex = null,
    Object? exerciseName = null,
    Object? weight = null,
    Object? repsCompleted = null,
    Object? rir = null,
    Object? isDone = null,
  }) {
    return _then(_self.copyWith(
      setIndex: null == setIndex
          ? _self.setIndex
          : setIndex // ignore: cast_nullable_to_non_nullable
              as int,
      exerciseName: null == exerciseName
          ? _self.exerciseName
          : exerciseName // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _self.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
      repsCompleted: null == repsCompleted
          ? _self.repsCompleted
          : repsCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      rir: null == rir
          ? _self.rir
          : rir // ignore: cast_nullable_to_non_nullable
              as int,
      isDone: null == isDone
          ? _self.isDone
          : isDone // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [ExerciseSet].
extension ExerciseSetPatterns on ExerciseSet {
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
    TResult Function(_ExerciseSet value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ExerciseSet() when $default != null:
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
    TResult Function(_ExerciseSet value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExerciseSet():
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
    TResult? Function(_ExerciseSet value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExerciseSet() when $default != null:
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
    TResult Function(int setIndex, String exerciseName, double weight,
            int repsCompleted, int rir, bool isDone)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ExerciseSet() when $default != null:
        return $default(_that.setIndex, _that.exerciseName, _that.weight,
            _that.repsCompleted, _that.rir, _that.isDone);
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
    TResult Function(int setIndex, String exerciseName, double weight,
            int repsCompleted, int rir, bool isDone)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExerciseSet():
        return $default(_that.setIndex, _that.exerciseName, _that.weight,
            _that.repsCompleted, _that.rir, _that.isDone);
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
    TResult? Function(int setIndex, String exerciseName, double weight,
            int repsCompleted, int rir, bool isDone)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExerciseSet() when $default != null:
        return $default(_that.setIndex, _that.exerciseName, _that.weight,
            _that.repsCompleted, _that.rir, _that.isDone);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ExerciseSet implements ExerciseSet {
  const _ExerciseSet(
      {required this.setIndex,
      required this.exerciseName,
      required this.weight,
      required this.repsCompleted,
      required this.rir,
      this.isDone = false});
  factory _ExerciseSet.fromJson(Map<String, dynamic> json) =>
      _$ExerciseSetFromJson(json);

  @override
  final int setIndex;
  @override
  final String exerciseName;
  @override
  final double weight;
  @override
  final int repsCompleted;
  @override
  final int rir;
  @override
  @JsonKey()
  final bool isDone;

  /// Create a copy of ExerciseSet
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ExerciseSetCopyWith<_ExerciseSet> get copyWith =>
      __$ExerciseSetCopyWithImpl<_ExerciseSet>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ExerciseSetToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ExerciseSet &&
            (identical(other.setIndex, setIndex) ||
                other.setIndex == setIndex) &&
            (identical(other.exerciseName, exerciseName) ||
                other.exerciseName == exerciseName) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.repsCompleted, repsCompleted) ||
                other.repsCompleted == repsCompleted) &&
            (identical(other.rir, rir) || other.rir == rir) &&
            (identical(other.isDone, isDone) || other.isDone == isDone));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, setIndex, exerciseName, weight, repsCompleted, rir, isDone);

  @override
  String toString() {
    return 'ExerciseSet(setIndex: $setIndex, exerciseName: $exerciseName, weight: $weight, repsCompleted: $repsCompleted, rir: $rir, isDone: $isDone)';
  }
}

/// @nodoc
abstract mixin class _$ExerciseSetCopyWith<$Res>
    implements $ExerciseSetCopyWith<$Res> {
  factory _$ExerciseSetCopyWith(
          _ExerciseSet value, $Res Function(_ExerciseSet) _then) =
      __$ExerciseSetCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int setIndex,
      String exerciseName,
      double weight,
      int repsCompleted,
      int rir,
      bool isDone});
}

/// @nodoc
class __$ExerciseSetCopyWithImpl<$Res> implements _$ExerciseSetCopyWith<$Res> {
  __$ExerciseSetCopyWithImpl(this._self, this._then);

  final _ExerciseSet _self;
  final $Res Function(_ExerciseSet) _then;

  /// Create a copy of ExerciseSet
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? setIndex = null,
    Object? exerciseName = null,
    Object? weight = null,
    Object? repsCompleted = null,
    Object? rir = null,
    Object? isDone = null,
  }) {
    return _then(_ExerciseSet(
      setIndex: null == setIndex
          ? _self.setIndex
          : setIndex // ignore: cast_nullable_to_non_nullable
              as int,
      exerciseName: null == exerciseName
          ? _self.exerciseName
          : exerciseName // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _self.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
      repsCompleted: null == repsCompleted
          ? _self.repsCompleted
          : repsCompleted // ignore: cast_nullable_to_non_nullable
              as int,
      rir: null == rir
          ? _self.rir
          : rir // ignore: cast_nullable_to_non_nullable
              as int,
      isDone: null == isDone
          ? _self.isDone
          : isDone // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$RoutineExercise {
  String get id;
  String get name;
  int get sets;
  String get targetReps;
  int get rir;
  int get restSeconds;
  String get targetMuscle;
  bool get requiresWeight;

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
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.sets, sets) || other.sets == sets) &&
            (identical(other.targetReps, targetReps) ||
                other.targetReps == targetReps) &&
            (identical(other.rir, rir) || other.rir == rir) &&
            (identical(other.restSeconds, restSeconds) ||
                other.restSeconds == restSeconds) &&
            (identical(other.targetMuscle, targetMuscle) ||
                other.targetMuscle == targetMuscle) &&
            (identical(other.requiresWeight, requiresWeight) ||
                other.requiresWeight == requiresWeight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, sets, targetReps, rir,
      restSeconds, targetMuscle, requiresWeight);

  @override
  String toString() {
    return 'RoutineExercise(id: $id, name: $name, sets: $sets, targetReps: $targetReps, rir: $rir, restSeconds: $restSeconds, targetMuscle: $targetMuscle, requiresWeight: $requiresWeight)';
  }
}

/// @nodoc
abstract mixin class $RoutineExerciseCopyWith<$Res> {
  factory $RoutineExerciseCopyWith(
          RoutineExercise value, $Res Function(RoutineExercise) _then) =
      _$RoutineExerciseCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      int sets,
      String targetReps,
      int rir,
      int restSeconds,
      String targetMuscle,
      bool requiresWeight});
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
    Object? id = null,
    Object? name = null,
    Object? sets = null,
    Object? targetReps = null,
    Object? rir = null,
    Object? restSeconds = null,
    Object? targetMuscle = null,
    Object? requiresWeight = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      sets: null == sets
          ? _self.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as int,
      targetReps: null == targetReps
          ? _self.targetReps
          : targetReps // ignore: cast_nullable_to_non_nullable
              as String,
      rir: null == rir
          ? _self.rir
          : rir // ignore: cast_nullable_to_non_nullable
              as int,
      restSeconds: null == restSeconds
          ? _self.restSeconds
          : restSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      targetMuscle: null == targetMuscle
          ? _self.targetMuscle
          : targetMuscle // ignore: cast_nullable_to_non_nullable
              as String,
      requiresWeight: null == requiresWeight
          ? _self.requiresWeight
          : requiresWeight // ignore: cast_nullable_to_non_nullable
              as bool,
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
    TResult Function(String id, String name, int sets, String targetReps,
            int rir, int restSeconds, String targetMuscle, bool requiresWeight)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RoutineExercise() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.sets,
            _that.targetReps,
            _that.rir,
            _that.restSeconds,
            _that.targetMuscle,
            _that.requiresWeight);
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
    TResult Function(String id, String name, int sets, String targetReps,
            int rir, int restSeconds, String targetMuscle, bool requiresWeight)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineExercise():
        return $default(
            _that.id,
            _that.name,
            _that.sets,
            _that.targetReps,
            _that.rir,
            _that.restSeconds,
            _that.targetMuscle,
            _that.requiresWeight);
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
    TResult? Function(String id, String name, int sets, String targetReps,
            int rir, int restSeconds, String targetMuscle, bool requiresWeight)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineExercise() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.sets,
            _that.targetReps,
            _that.rir,
            _that.restSeconds,
            _that.targetMuscle,
            _that.requiresWeight);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RoutineExercise implements RoutineExercise {
  const _RoutineExercise(
      {required this.id,
      required this.name,
      required this.sets,
      required this.targetReps,
      required this.rir,
      required this.restSeconds,
      this.targetMuscle = 'Unknown',
      this.requiresWeight = true});
  factory _RoutineExercise.fromJson(Map<String, dynamic> json) =>
      _$RoutineExerciseFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final int sets;
  @override
  final String targetReps;
  @override
  final int rir;
  @override
  final int restSeconds;
  @override
  @JsonKey()
  final String targetMuscle;
  @override
  @JsonKey()
  final bool requiresWeight;

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
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.sets, sets) || other.sets == sets) &&
            (identical(other.targetReps, targetReps) ||
                other.targetReps == targetReps) &&
            (identical(other.rir, rir) || other.rir == rir) &&
            (identical(other.restSeconds, restSeconds) ||
                other.restSeconds == restSeconds) &&
            (identical(other.targetMuscle, targetMuscle) ||
                other.targetMuscle == targetMuscle) &&
            (identical(other.requiresWeight, requiresWeight) ||
                other.requiresWeight == requiresWeight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, sets, targetReps, rir,
      restSeconds, targetMuscle, requiresWeight);

  @override
  String toString() {
    return 'RoutineExercise(id: $id, name: $name, sets: $sets, targetReps: $targetReps, rir: $rir, restSeconds: $restSeconds, targetMuscle: $targetMuscle, requiresWeight: $requiresWeight)';
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
      {String id,
      String name,
      int sets,
      String targetReps,
      int rir,
      int restSeconds,
      String targetMuscle,
      bool requiresWeight});
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
    Object? id = null,
    Object? name = null,
    Object? sets = null,
    Object? targetReps = null,
    Object? rir = null,
    Object? restSeconds = null,
    Object? targetMuscle = null,
    Object? requiresWeight = null,
  }) {
    return _then(_RoutineExercise(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      sets: null == sets
          ? _self.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as int,
      targetReps: null == targetReps
          ? _self.targetReps
          : targetReps // ignore: cast_nullable_to_non_nullable
              as String,
      rir: null == rir
          ? _self.rir
          : rir // ignore: cast_nullable_to_non_nullable
              as int,
      restSeconds: null == restSeconds
          ? _self.restSeconds
          : restSeconds // ignore: cast_nullable_to_non_nullable
              as int,
      targetMuscle: null == targetMuscle
          ? _self.targetMuscle
          : targetMuscle // ignore: cast_nullable_to_non_nullable
              as String,
      requiresWeight: null == requiresWeight
          ? _self.requiresWeight
          : requiresWeight // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$WeeklyTrainingStats {
  int get totalStrengthMins;
  int get totalHiitMins;
  int get zone2Mins;
  int get consecutiveWeeksTrained;

  /// Create a copy of WeeklyTrainingStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WeeklyTrainingStatsCopyWith<WeeklyTrainingStats> get copyWith =>
      _$WeeklyTrainingStatsCopyWithImpl<WeeklyTrainingStats>(
          this as WeeklyTrainingStats, _$identity);

  /// Serializes this WeeklyTrainingStats to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WeeklyTrainingStats &&
            (identical(other.totalStrengthMins, totalStrengthMins) ||
                other.totalStrengthMins == totalStrengthMins) &&
            (identical(other.totalHiitMins, totalHiitMins) ||
                other.totalHiitMins == totalHiitMins) &&
            (identical(other.zone2Mins, zone2Mins) ||
                other.zone2Mins == zone2Mins) &&
            (identical(
                    other.consecutiveWeeksTrained, consecutiveWeeksTrained) ||
                other.consecutiveWeeksTrained == consecutiveWeeksTrained));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, totalStrengthMins, totalHiitMins,
      zone2Mins, consecutiveWeeksTrained);

  @override
  String toString() {
    return 'WeeklyTrainingStats(totalStrengthMins: $totalStrengthMins, totalHiitMins: $totalHiitMins, zone2Mins: $zone2Mins, consecutiveWeeksTrained: $consecutiveWeeksTrained)';
  }
}

/// @nodoc
abstract mixin class $WeeklyTrainingStatsCopyWith<$Res> {
  factory $WeeklyTrainingStatsCopyWith(
          WeeklyTrainingStats value, $Res Function(WeeklyTrainingStats) _then) =
      _$WeeklyTrainingStatsCopyWithImpl;
  @useResult
  $Res call(
      {int totalStrengthMins,
      int totalHiitMins,
      int zone2Mins,
      int consecutiveWeeksTrained});
}

/// @nodoc
class _$WeeklyTrainingStatsCopyWithImpl<$Res>
    implements $WeeklyTrainingStatsCopyWith<$Res> {
  _$WeeklyTrainingStatsCopyWithImpl(this._self, this._then);

  final WeeklyTrainingStats _self;
  final $Res Function(WeeklyTrainingStats) _then;

  /// Create a copy of WeeklyTrainingStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalStrengthMins = null,
    Object? totalHiitMins = null,
    Object? zone2Mins = null,
    Object? consecutiveWeeksTrained = null,
  }) {
    return _then(_self.copyWith(
      totalStrengthMins: null == totalStrengthMins
          ? _self.totalStrengthMins
          : totalStrengthMins // ignore: cast_nullable_to_non_nullable
              as int,
      totalHiitMins: null == totalHiitMins
          ? _self.totalHiitMins
          : totalHiitMins // ignore: cast_nullable_to_non_nullable
              as int,
      zone2Mins: null == zone2Mins
          ? _self.zone2Mins
          : zone2Mins // ignore: cast_nullable_to_non_nullable
              as int,
      consecutiveWeeksTrained: null == consecutiveWeeksTrained
          ? _self.consecutiveWeeksTrained
          : consecutiveWeeksTrained // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [WeeklyTrainingStats].
extension WeeklyTrainingStatsPatterns on WeeklyTrainingStats {
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
    TResult Function(_WeeklyTrainingStats value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WeeklyTrainingStats() when $default != null:
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
    TResult Function(_WeeklyTrainingStats value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WeeklyTrainingStats():
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
    TResult? Function(_WeeklyTrainingStats value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WeeklyTrainingStats() when $default != null:
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
    TResult Function(int totalStrengthMins, int totalHiitMins, int zone2Mins,
            int consecutiveWeeksTrained)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WeeklyTrainingStats() when $default != null:
        return $default(_that.totalStrengthMins, _that.totalHiitMins,
            _that.zone2Mins, _that.consecutiveWeeksTrained);
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
    TResult Function(int totalStrengthMins, int totalHiitMins, int zone2Mins,
            int consecutiveWeeksTrained)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WeeklyTrainingStats():
        return $default(_that.totalStrengthMins, _that.totalHiitMins,
            _that.zone2Mins, _that.consecutiveWeeksTrained);
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
    TResult? Function(int totalStrengthMins, int totalHiitMins, int zone2Mins,
            int consecutiveWeeksTrained)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WeeklyTrainingStats() when $default != null:
        return $default(_that.totalStrengthMins, _that.totalHiitMins,
            _that.zone2Mins, _that.consecutiveWeeksTrained);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WeeklyTrainingStats implements WeeklyTrainingStats {
  const _WeeklyTrainingStats(
      {required this.totalStrengthMins,
      required this.totalHiitMins,
      required this.zone2Mins,
      required this.consecutiveWeeksTrained});
  factory _WeeklyTrainingStats.fromJson(Map<String, dynamic> json) =>
      _$WeeklyTrainingStatsFromJson(json);

  @override
  final int totalStrengthMins;
  @override
  final int totalHiitMins;
  @override
  final int zone2Mins;
  @override
  final int consecutiveWeeksTrained;

  /// Create a copy of WeeklyTrainingStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WeeklyTrainingStatsCopyWith<_WeeklyTrainingStats> get copyWith =>
      __$WeeklyTrainingStatsCopyWithImpl<_WeeklyTrainingStats>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WeeklyTrainingStatsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WeeklyTrainingStats &&
            (identical(other.totalStrengthMins, totalStrengthMins) ||
                other.totalStrengthMins == totalStrengthMins) &&
            (identical(other.totalHiitMins, totalHiitMins) ||
                other.totalHiitMins == totalHiitMins) &&
            (identical(other.zone2Mins, zone2Mins) ||
                other.zone2Mins == zone2Mins) &&
            (identical(
                    other.consecutiveWeeksTrained, consecutiveWeeksTrained) ||
                other.consecutiveWeeksTrained == consecutiveWeeksTrained));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, totalStrengthMins, totalHiitMins,
      zone2Mins, consecutiveWeeksTrained);

  @override
  String toString() {
    return 'WeeklyTrainingStats(totalStrengthMins: $totalStrengthMins, totalHiitMins: $totalHiitMins, zone2Mins: $zone2Mins, consecutiveWeeksTrained: $consecutiveWeeksTrained)';
  }
}

/// @nodoc
abstract mixin class _$WeeklyTrainingStatsCopyWith<$Res>
    implements $WeeklyTrainingStatsCopyWith<$Res> {
  factory _$WeeklyTrainingStatsCopyWith(_WeeklyTrainingStats value,
          $Res Function(_WeeklyTrainingStats) _then) =
      __$WeeklyTrainingStatsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int totalStrengthMins,
      int totalHiitMins,
      int zone2Mins,
      int consecutiveWeeksTrained});
}

/// @nodoc
class __$WeeklyTrainingStatsCopyWithImpl<$Res>
    implements _$WeeklyTrainingStatsCopyWith<$Res> {
  __$WeeklyTrainingStatsCopyWithImpl(this._self, this._then);

  final _WeeklyTrainingStats _self;
  final $Res Function(_WeeklyTrainingStats) _then;

  /// Create a copy of WeeklyTrainingStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? totalStrengthMins = null,
    Object? totalHiitMins = null,
    Object? zone2Mins = null,
    Object? consecutiveWeeksTrained = null,
  }) {
    return _then(_WeeklyTrainingStats(
      totalStrengthMins: null == totalStrengthMins
          ? _self.totalStrengthMins
          : totalStrengthMins // ignore: cast_nullable_to_non_nullable
              as int,
      totalHiitMins: null == totalHiitMins
          ? _self.totalHiitMins
          : totalHiitMins // ignore: cast_nullable_to_non_nullable
              as int,
      zone2Mins: null == zone2Mins
          ? _self.zone2Mins
          : zone2Mins // ignore: cast_nullable_to_non_nullable
              as int,
      consecutiveWeeksTrained: null == consecutiveWeeksTrained
          ? _self.consecutiveWeeksTrained
          : consecutiveWeeksTrained // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
mixin _$WorkoutRecommendation {
  String get type;
  TargetMuscle? get targetMuscle;
  int get durationMinutes;
  String get intensity;
  String get notes;

  /// Create a copy of WorkoutRecommendation
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WorkoutRecommendationCopyWith<WorkoutRecommendation> get copyWith =>
      _$WorkoutRecommendationCopyWithImpl<WorkoutRecommendation>(
          this as WorkoutRecommendation, _$identity);

  /// Serializes this WorkoutRecommendation to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WorkoutRecommendation &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.targetMuscle, targetMuscle) ||
                other.targetMuscle == targetMuscle) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.intensity, intensity) ||
                other.intensity == intensity) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, type, targetMuscle, durationMinutes, intensity, notes);

  @override
  String toString() {
    return 'WorkoutRecommendation(type: $type, targetMuscle: $targetMuscle, durationMinutes: $durationMinutes, intensity: $intensity, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class $WorkoutRecommendationCopyWith<$Res> {
  factory $WorkoutRecommendationCopyWith(WorkoutRecommendation value,
          $Res Function(WorkoutRecommendation) _then) =
      _$WorkoutRecommendationCopyWithImpl;
  @useResult
  $Res call(
      {String type,
      TargetMuscle? targetMuscle,
      int durationMinutes,
      String intensity,
      String notes});
}

/// @nodoc
class _$WorkoutRecommendationCopyWithImpl<$Res>
    implements $WorkoutRecommendationCopyWith<$Res> {
  _$WorkoutRecommendationCopyWithImpl(this._self, this._then);

  final WorkoutRecommendation _self;
  final $Res Function(WorkoutRecommendation) _then;

  /// Create a copy of WorkoutRecommendation
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? type = null,
    Object? targetMuscle = freezed,
    Object? durationMinutes = null,
    Object? intensity = null,
    Object? notes = null,
  }) {
    return _then(_self.copyWith(
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      targetMuscle: freezed == targetMuscle
          ? _self.targetMuscle
          : targetMuscle // ignore: cast_nullable_to_non_nullable
              as TargetMuscle?,
      durationMinutes: null == durationMinutes
          ? _self.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      intensity: null == intensity
          ? _self.intensity
          : intensity // ignore: cast_nullable_to_non_nullable
              as String,
      notes: null == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [WorkoutRecommendation].
extension WorkoutRecommendationPatterns on WorkoutRecommendation {
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
    TResult Function(_WorkoutRecommendation value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WorkoutRecommendation() when $default != null:
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
    TResult Function(_WorkoutRecommendation value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutRecommendation():
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
    TResult? Function(_WorkoutRecommendation value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutRecommendation() when $default != null:
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
    TResult Function(String type, TargetMuscle? targetMuscle,
            int durationMinutes, String intensity, String notes)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WorkoutRecommendation() when $default != null:
        return $default(_that.type, _that.targetMuscle, _that.durationMinutes,
            _that.intensity, _that.notes);
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
    TResult Function(String type, TargetMuscle? targetMuscle,
            int durationMinutes, String intensity, String notes)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutRecommendation():
        return $default(_that.type, _that.targetMuscle, _that.durationMinutes,
            _that.intensity, _that.notes);
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
    TResult? Function(String type, TargetMuscle? targetMuscle,
            int durationMinutes, String intensity, String notes)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutRecommendation() when $default != null:
        return $default(_that.type, _that.targetMuscle, _that.durationMinutes,
            _that.intensity, _that.notes);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WorkoutRecommendation implements WorkoutRecommendation {
  const _WorkoutRecommendation(
      {required this.type,
      this.targetMuscle,
      required this.durationMinutes,
      required this.intensity,
      required this.notes});
  factory _WorkoutRecommendation.fromJson(Map<String, dynamic> json) =>
      _$WorkoutRecommendationFromJson(json);

  @override
  final String type;
  @override
  final TargetMuscle? targetMuscle;
  @override
  final int durationMinutes;
  @override
  final String intensity;
  @override
  final String notes;

  /// Create a copy of WorkoutRecommendation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WorkoutRecommendationCopyWith<_WorkoutRecommendation> get copyWith =>
      __$WorkoutRecommendationCopyWithImpl<_WorkoutRecommendation>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WorkoutRecommendationToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WorkoutRecommendation &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.targetMuscle, targetMuscle) ||
                other.targetMuscle == targetMuscle) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.intensity, intensity) ||
                other.intensity == intensity) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, type, targetMuscle, durationMinutes, intensity, notes);

  @override
  String toString() {
    return 'WorkoutRecommendation(type: $type, targetMuscle: $targetMuscle, durationMinutes: $durationMinutes, intensity: $intensity, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class _$WorkoutRecommendationCopyWith<$Res>
    implements $WorkoutRecommendationCopyWith<$Res> {
  factory _$WorkoutRecommendationCopyWith(_WorkoutRecommendation value,
          $Res Function(_WorkoutRecommendation) _then) =
      __$WorkoutRecommendationCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String type,
      TargetMuscle? targetMuscle,
      int durationMinutes,
      String intensity,
      String notes});
}

/// @nodoc
class __$WorkoutRecommendationCopyWithImpl<$Res>
    implements _$WorkoutRecommendationCopyWith<$Res> {
  __$WorkoutRecommendationCopyWithImpl(this._self, this._then);

  final _WorkoutRecommendation _self;
  final $Res Function(_WorkoutRecommendation) _then;

  /// Create a copy of WorkoutRecommendation
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? type = null,
    Object? targetMuscle = freezed,
    Object? durationMinutes = null,
    Object? intensity = null,
    Object? notes = null,
  }) {
    return _then(_WorkoutRecommendation(
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      targetMuscle: freezed == targetMuscle
          ? _self.targetMuscle
          : targetMuscle // ignore: cast_nullable_to_non_nullable
              as TargetMuscle?,
      durationMinutes: null == durationMinutes
          ? _self.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      intensity: null == intensity
          ? _self.intensity
          : intensity // ignore: cast_nullable_to_non_nullable
              as String,
      notes: null == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$TrainingCycle {
  int get sessionCount;
  bool get isDeloadActive;
  int get cycleNumber;
  DateTime? get deloadStartDate;

  /// Create a copy of TrainingCycle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TrainingCycleCopyWith<TrainingCycle> get copyWith =>
      _$TrainingCycleCopyWithImpl<TrainingCycle>(
          this as TrainingCycle, _$identity);

  /// Serializes this TrainingCycle to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TrainingCycle &&
            (identical(other.sessionCount, sessionCount) ||
                other.sessionCount == sessionCount) &&
            (identical(other.isDeloadActive, isDeloadActive) ||
                other.isDeloadActive == isDeloadActive) &&
            (identical(other.cycleNumber, cycleNumber) ||
                other.cycleNumber == cycleNumber) &&
            (identical(other.deloadStartDate, deloadStartDate) ||
                other.deloadStartDate == deloadStartDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, sessionCount, isDeloadActive, cycleNumber, deloadStartDate);

  @override
  String toString() {
    return 'TrainingCycle(sessionCount: $sessionCount, isDeloadActive: $isDeloadActive, cycleNumber: $cycleNumber, deloadStartDate: $deloadStartDate)';
  }
}

/// @nodoc
abstract mixin class $TrainingCycleCopyWith<$Res> {
  factory $TrainingCycleCopyWith(
          TrainingCycle value, $Res Function(TrainingCycle) _then) =
      _$TrainingCycleCopyWithImpl;
  @useResult
  $Res call(
      {int sessionCount,
      bool isDeloadActive,
      int cycleNumber,
      DateTime? deloadStartDate});
}

/// @nodoc
class _$TrainingCycleCopyWithImpl<$Res>
    implements $TrainingCycleCopyWith<$Res> {
  _$TrainingCycleCopyWithImpl(this._self, this._then);

  final TrainingCycle _self;
  final $Res Function(TrainingCycle) _then;

  /// Create a copy of TrainingCycle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? sessionCount = null,
    Object? isDeloadActive = null,
    Object? cycleNumber = null,
    Object? deloadStartDate = freezed,
  }) {
    return _then(_self.copyWith(
      sessionCount: null == sessionCount
          ? _self.sessionCount
          : sessionCount // ignore: cast_nullable_to_non_nullable
              as int,
      isDeloadActive: null == isDeloadActive
          ? _self.isDeloadActive
          : isDeloadActive // ignore: cast_nullable_to_non_nullable
              as bool,
      cycleNumber: null == cycleNumber
          ? _self.cycleNumber
          : cycleNumber // ignore: cast_nullable_to_non_nullable
              as int,
      deloadStartDate: freezed == deloadStartDate
          ? _self.deloadStartDate
          : deloadStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// Adds pattern-matching-related methods to [TrainingCycle].
extension TrainingCyclePatterns on TrainingCycle {
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
    TResult Function(_TrainingCycle value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TrainingCycle() when $default != null:
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
    TResult Function(_TrainingCycle value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrainingCycle():
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
    TResult? Function(_TrainingCycle value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrainingCycle() when $default != null:
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
    TResult Function(int sessionCount, bool isDeloadActive, int cycleNumber,
            DateTime? deloadStartDate)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TrainingCycle() when $default != null:
        return $default(_that.sessionCount, _that.isDeloadActive,
            _that.cycleNumber, _that.deloadStartDate);
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
    TResult Function(int sessionCount, bool isDeloadActive, int cycleNumber,
            DateTime? deloadStartDate)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrainingCycle():
        return $default(_that.sessionCount, _that.isDeloadActive,
            _that.cycleNumber, _that.deloadStartDate);
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
    TResult? Function(int sessionCount, bool isDeloadActive, int cycleNumber,
            DateTime? deloadStartDate)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrainingCycle() when $default != null:
        return $default(_that.sessionCount, _that.isDeloadActive,
            _that.cycleNumber, _that.deloadStartDate);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _TrainingCycle implements TrainingCycle {
  const _TrainingCycle(
      {required this.sessionCount,
      required this.isDeloadActive,
      required this.cycleNumber,
      this.deloadStartDate});
  factory _TrainingCycle.fromJson(Map<String, dynamic> json) =>
      _$TrainingCycleFromJson(json);

  @override
  final int sessionCount;
  @override
  final bool isDeloadActive;
  @override
  final int cycleNumber;
  @override
  final DateTime? deloadStartDate;

  /// Create a copy of TrainingCycle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TrainingCycleCopyWith<_TrainingCycle> get copyWith =>
      __$TrainingCycleCopyWithImpl<_TrainingCycle>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TrainingCycleToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TrainingCycle &&
            (identical(other.sessionCount, sessionCount) ||
                other.sessionCount == sessionCount) &&
            (identical(other.isDeloadActive, isDeloadActive) ||
                other.isDeloadActive == isDeloadActive) &&
            (identical(other.cycleNumber, cycleNumber) ||
                other.cycleNumber == cycleNumber) &&
            (identical(other.deloadStartDate, deloadStartDate) ||
                other.deloadStartDate == deloadStartDate));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, sessionCount, isDeloadActive, cycleNumber, deloadStartDate);

  @override
  String toString() {
    return 'TrainingCycle(sessionCount: $sessionCount, isDeloadActive: $isDeloadActive, cycleNumber: $cycleNumber, deloadStartDate: $deloadStartDate)';
  }
}

/// @nodoc
abstract mixin class _$TrainingCycleCopyWith<$Res>
    implements $TrainingCycleCopyWith<$Res> {
  factory _$TrainingCycleCopyWith(
          _TrainingCycle value, $Res Function(_TrainingCycle) _then) =
      __$TrainingCycleCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int sessionCount,
      bool isDeloadActive,
      int cycleNumber,
      DateTime? deloadStartDate});
}

/// @nodoc
class __$TrainingCycleCopyWithImpl<$Res>
    implements _$TrainingCycleCopyWith<$Res> {
  __$TrainingCycleCopyWithImpl(this._self, this._then);

  final _TrainingCycle _self;
  final $Res Function(_TrainingCycle) _then;

  /// Create a copy of TrainingCycle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? sessionCount = null,
    Object? isDeloadActive = null,
    Object? cycleNumber = null,
    Object? deloadStartDate = freezed,
  }) {
    return _then(_TrainingCycle(
      sessionCount: null == sessionCount
          ? _self.sessionCount
          : sessionCount // ignore: cast_nullable_to_non_nullable
              as int,
      isDeloadActive: null == isDeloadActive
          ? _self.isDeloadActive
          : isDeloadActive // ignore: cast_nullable_to_non_nullable
              as bool,
      cycleNumber: null == cycleNumber
          ? _self.cycleNumber
          : cycleNumber // ignore: cast_nullable_to_non_nullable
              as int,
      deloadStartDate: freezed == deloadStartDate
          ? _self.deloadStartDate
          : deloadStartDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

// dart format on
