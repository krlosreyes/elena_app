// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'interactive_routine.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InteractiveExercise {
  String get id;
  String get name;
  String get targetRir; // e.g. "2-3"
  List<InteractiveSet> get sets;
  bool get requiresWeight;

  /// Create a copy of InteractiveExercise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $InteractiveExerciseCopyWith<InteractiveExercise> get copyWith =>
      _$InteractiveExerciseCopyWithImpl<InteractiveExercise>(
          this as InteractiveExercise, _$identity);

  /// Serializes this InteractiveExercise to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is InteractiveExercise &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.targetRir, targetRir) ||
                other.targetRir == targetRir) &&
            const DeepCollectionEquality().equals(other.sets, sets) &&
            (identical(other.requiresWeight, requiresWeight) ||
                other.requiresWeight == requiresWeight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, targetRir,
      const DeepCollectionEquality().hash(sets), requiresWeight);

  @override
  String toString() {
    return 'InteractiveExercise(id: $id, name: $name, targetRir: $targetRir, sets: $sets, requiresWeight: $requiresWeight)';
  }
}

/// @nodoc
abstract mixin class $InteractiveExerciseCopyWith<$Res> {
  factory $InteractiveExerciseCopyWith(
          InteractiveExercise value, $Res Function(InteractiveExercise) _then) =
      _$InteractiveExerciseCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String targetRir,
      List<InteractiveSet> sets,
      bool requiresWeight});
}

/// @nodoc
class _$InteractiveExerciseCopyWithImpl<$Res>
    implements $InteractiveExerciseCopyWith<$Res> {
  _$InteractiveExerciseCopyWithImpl(this._self, this._then);

  final InteractiveExercise _self;
  final $Res Function(InteractiveExercise) _then;

  /// Create a copy of InteractiveExercise
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? targetRir = null,
    Object? sets = null,
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
      targetRir: null == targetRir
          ? _self.targetRir
          : targetRir // ignore: cast_nullable_to_non_nullable
              as String,
      sets: null == sets
          ? _self.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as List<InteractiveSet>,
      requiresWeight: null == requiresWeight
          ? _self.requiresWeight
          : requiresWeight // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [InteractiveExercise].
extension InteractiveExercisePatterns on InteractiveExercise {
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
    TResult Function(_InteractiveExercise value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _InteractiveExercise() when $default != null:
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
    TResult Function(_InteractiveExercise value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InteractiveExercise():
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
    TResult? Function(_InteractiveExercise value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InteractiveExercise() when $default != null:
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
    TResult Function(String id, String name, String targetRir,
            List<InteractiveSet> sets, bool requiresWeight)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _InteractiveExercise() when $default != null:
        return $default(_that.id, _that.name, _that.targetRir, _that.sets,
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
    TResult Function(String id, String name, String targetRir,
            List<InteractiveSet> sets, bool requiresWeight)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InteractiveExercise():
        return $default(_that.id, _that.name, _that.targetRir, _that.sets,
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
    TResult? Function(String id, String name, String targetRir,
            List<InteractiveSet> sets, bool requiresWeight)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InteractiveExercise() when $default != null:
        return $default(_that.id, _that.name, _that.targetRir, _that.sets,
            _that.requiresWeight);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _InteractiveExercise implements InteractiveExercise {
  const _InteractiveExercise(
      {required this.id,
      required this.name,
      required this.targetRir,
      final List<InteractiveSet> sets = const [],
      this.requiresWeight = true})
      : _sets = sets;
  factory _InteractiveExercise.fromJson(Map<String, dynamic> json) =>
      _$InteractiveExerciseFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String targetRir;
// e.g. "2-3"
  final List<InteractiveSet> _sets;
// e.g. "2-3"
  @override
  @JsonKey()
  List<InteractiveSet> get sets {
    if (_sets is EqualUnmodifiableListView) return _sets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sets);
  }

  @override
  @JsonKey()
  final bool requiresWeight;

  /// Create a copy of InteractiveExercise
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$InteractiveExerciseCopyWith<_InteractiveExercise> get copyWith =>
      __$InteractiveExerciseCopyWithImpl<_InteractiveExercise>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$InteractiveExerciseToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _InteractiveExercise &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.targetRir, targetRir) ||
                other.targetRir == targetRir) &&
            const DeepCollectionEquality().equals(other._sets, _sets) &&
            (identical(other.requiresWeight, requiresWeight) ||
                other.requiresWeight == requiresWeight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, targetRir,
      const DeepCollectionEquality().hash(_sets), requiresWeight);

  @override
  String toString() {
    return 'InteractiveExercise(id: $id, name: $name, targetRir: $targetRir, sets: $sets, requiresWeight: $requiresWeight)';
  }
}

/// @nodoc
abstract mixin class _$InteractiveExerciseCopyWith<$Res>
    implements $InteractiveExerciseCopyWith<$Res> {
  factory _$InteractiveExerciseCopyWith(_InteractiveExercise value,
          $Res Function(_InteractiveExercise) _then) =
      __$InteractiveExerciseCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String targetRir,
      List<InteractiveSet> sets,
      bool requiresWeight});
}

/// @nodoc
class __$InteractiveExerciseCopyWithImpl<$Res>
    implements _$InteractiveExerciseCopyWith<$Res> {
  __$InteractiveExerciseCopyWithImpl(this._self, this._then);

  final _InteractiveExercise _self;
  final $Res Function(_InteractiveExercise) _then;

  /// Create a copy of InteractiveExercise
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? targetRir = null,
    Object? sets = null,
    Object? requiresWeight = null,
  }) {
    return _then(_InteractiveExercise(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      targetRir: null == targetRir
          ? _self.targetRir
          : targetRir // ignore: cast_nullable_to_non_nullable
              as String,
      sets: null == sets
          ? _self._sets
          : sets // ignore: cast_nullable_to_non_nullable
              as List<InteractiveSet>,
      requiresWeight: null == requiresWeight
          ? _self.requiresWeight
          : requiresWeight // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
mixin _$InteractiveSet {
  int get setIndex;
  String get targetReps;
  double get weight;
  int? get reps;
  bool get isDone;
  bool get isBonus;

  /// Create a copy of InteractiveSet
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $InteractiveSetCopyWith<InteractiveSet> get copyWith =>
      _$InteractiveSetCopyWithImpl<InteractiveSet>(
          this as InteractiveSet, _$identity);

  /// Serializes this InteractiveSet to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is InteractiveSet &&
            (identical(other.setIndex, setIndex) ||
                other.setIndex == setIndex) &&
            (identical(other.targetReps, targetReps) ||
                other.targetReps == targetReps) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.isDone, isDone) || other.isDone == isDone) &&
            (identical(other.isBonus, isBonus) || other.isBonus == isBonus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, setIndex, targetReps, weight, reps, isDone, isBonus);

  @override
  String toString() {
    return 'InteractiveSet(setIndex: $setIndex, targetReps: $targetReps, weight: $weight, reps: $reps, isDone: $isDone, isBonus: $isBonus)';
  }
}

/// @nodoc
abstract mixin class $InteractiveSetCopyWith<$Res> {
  factory $InteractiveSetCopyWith(
          InteractiveSet value, $Res Function(InteractiveSet) _then) =
      _$InteractiveSetCopyWithImpl;
  @useResult
  $Res call(
      {int setIndex,
      String targetReps,
      double weight,
      int? reps,
      bool isDone,
      bool isBonus});
}

/// @nodoc
class _$InteractiveSetCopyWithImpl<$Res>
    implements $InteractiveSetCopyWith<$Res> {
  _$InteractiveSetCopyWithImpl(this._self, this._then);

  final InteractiveSet _self;
  final $Res Function(InteractiveSet) _then;

  /// Create a copy of InteractiveSet
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? setIndex = null,
    Object? targetReps = null,
    Object? weight = null,
    Object? reps = freezed,
    Object? isDone = null,
    Object? isBonus = null,
  }) {
    return _then(_self.copyWith(
      setIndex: null == setIndex
          ? _self.setIndex
          : setIndex // ignore: cast_nullable_to_non_nullable
              as int,
      targetReps: null == targetReps
          ? _self.targetReps
          : targetReps // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _self.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
      reps: freezed == reps
          ? _self.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int?,
      isDone: null == isDone
          ? _self.isDone
          : isDone // ignore: cast_nullable_to_non_nullable
              as bool,
      isBonus: null == isBonus
          ? _self.isBonus
          : isBonus // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [InteractiveSet].
extension InteractiveSetPatterns on InteractiveSet {
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
    TResult Function(_InteractiveSet value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _InteractiveSet() when $default != null:
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
    TResult Function(_InteractiveSet value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InteractiveSet():
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
    TResult? Function(_InteractiveSet value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InteractiveSet() when $default != null:
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
    TResult Function(int setIndex, String targetReps, double weight, int? reps,
            bool isDone, bool isBonus)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _InteractiveSet() when $default != null:
        return $default(_that.setIndex, _that.targetReps, _that.weight,
            _that.reps, _that.isDone, _that.isBonus);
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
    TResult Function(int setIndex, String targetReps, double weight, int? reps,
            bool isDone, bool isBonus)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InteractiveSet():
        return $default(_that.setIndex, _that.targetReps, _that.weight,
            _that.reps, _that.isDone, _that.isBonus);
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
    TResult? Function(int setIndex, String targetReps, double weight, int? reps,
            bool isDone, bool isBonus)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _InteractiveSet() when $default != null:
        return $default(_that.setIndex, _that.targetReps, _that.weight,
            _that.reps, _that.isDone, _that.isBonus);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _InteractiveSet implements InteractiveSet {
  const _InteractiveSet(
      {required this.setIndex,
      this.targetReps = '8-12',
      this.weight = 5.0,
      this.reps,
      this.isDone = false,
      this.isBonus = false});
  factory _InteractiveSet.fromJson(Map<String, dynamic> json) =>
      _$InteractiveSetFromJson(json);

  @override
  final int setIndex;
  @override
  @JsonKey()
  final String targetReps;
  @override
  @JsonKey()
  final double weight;
  @override
  final int? reps;
  @override
  @JsonKey()
  final bool isDone;
  @override
  @JsonKey()
  final bool isBonus;

  /// Create a copy of InteractiveSet
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$InteractiveSetCopyWith<_InteractiveSet> get copyWith =>
      __$InteractiveSetCopyWithImpl<_InteractiveSet>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$InteractiveSetToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _InteractiveSet &&
            (identical(other.setIndex, setIndex) ||
                other.setIndex == setIndex) &&
            (identical(other.targetReps, targetReps) ||
                other.targetReps == targetReps) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.isDone, isDone) || other.isDone == isDone) &&
            (identical(other.isBonus, isBonus) || other.isBonus == isBonus));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, setIndex, targetReps, weight, reps, isDone, isBonus);

  @override
  String toString() {
    return 'InteractiveSet(setIndex: $setIndex, targetReps: $targetReps, weight: $weight, reps: $reps, isDone: $isDone, isBonus: $isBonus)';
  }
}

/// @nodoc
abstract mixin class _$InteractiveSetCopyWith<$Res>
    implements $InteractiveSetCopyWith<$Res> {
  factory _$InteractiveSetCopyWith(
          _InteractiveSet value, $Res Function(_InteractiveSet) _then) =
      __$InteractiveSetCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int setIndex,
      String targetReps,
      double weight,
      int? reps,
      bool isDone,
      bool isBonus});
}

/// @nodoc
class __$InteractiveSetCopyWithImpl<$Res>
    implements _$InteractiveSetCopyWith<$Res> {
  __$InteractiveSetCopyWithImpl(this._self, this._then);

  final _InteractiveSet _self;
  final $Res Function(_InteractiveSet) _then;

  /// Create a copy of InteractiveSet
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? setIndex = null,
    Object? targetReps = null,
    Object? weight = null,
    Object? reps = freezed,
    Object? isDone = null,
    Object? isBonus = null,
  }) {
    return _then(_InteractiveSet(
      setIndex: null == setIndex
          ? _self.setIndex
          : setIndex // ignore: cast_nullable_to_non_nullable
              as int,
      targetReps: null == targetReps
          ? _self.targetReps
          : targetReps // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _self.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
      reps: freezed == reps
          ? _self.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int?,
      isDone: null == isDone
          ? _self.isDone
          : isDone // ignore: cast_nullable_to_non_nullable
              as bool,
      isBonus: null == isBonus
          ? _self.isBonus
          : isBonus // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
