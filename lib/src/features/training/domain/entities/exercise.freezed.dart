// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exercise.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Exercise {
  String get id;
  String get name;
  String get targetMuscle;
  String get mechanics;
  String get description;
  String? get videoUrl;
  bool get requiresWeight;

  /// Create a copy of Exercise
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExerciseCopyWith<Exercise> get copyWith =>
      _$ExerciseCopyWithImpl<Exercise>(this as Exercise, _$identity);

  /// Serializes this Exercise to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Exercise &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.targetMuscle, targetMuscle) ||
                other.targetMuscle == targetMuscle) &&
            (identical(other.mechanics, mechanics) ||
                other.mechanics == mechanics) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.videoUrl, videoUrl) ||
                other.videoUrl == videoUrl) &&
            (identical(other.requiresWeight, requiresWeight) ||
                other.requiresWeight == requiresWeight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, targetMuscle,
      mechanics, description, videoUrl, requiresWeight);

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, targetMuscle: $targetMuscle, mechanics: $mechanics, description: $description, videoUrl: $videoUrl, requiresWeight: $requiresWeight)';
  }
}

/// @nodoc
abstract mixin class $ExerciseCopyWith<$Res> {
  factory $ExerciseCopyWith(Exercise value, $Res Function(Exercise) _then) =
      _$ExerciseCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String name,
      String targetMuscle,
      String mechanics,
      String description,
      String? videoUrl,
      bool requiresWeight});
}

/// @nodoc
class _$ExerciseCopyWithImpl<$Res> implements $ExerciseCopyWith<$Res> {
  _$ExerciseCopyWithImpl(this._self, this._then);

  final Exercise _self;
  final $Res Function(Exercise) _then;

  /// Create a copy of Exercise
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? targetMuscle = null,
    Object? mechanics = null,
    Object? description = null,
    Object? videoUrl = freezed,
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
      targetMuscle: null == targetMuscle
          ? _self.targetMuscle
          : targetMuscle // ignore: cast_nullable_to_non_nullable
              as String,
      mechanics: null == mechanics
          ? _self.mechanics
          : mechanics // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      videoUrl: freezed == videoUrl
          ? _self.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      requiresWeight: null == requiresWeight
          ? _self.requiresWeight
          : requiresWeight // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [Exercise].
extension ExercisePatterns on Exercise {
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
    TResult Function(_Exercise value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Exercise() when $default != null:
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
    TResult Function(_Exercise value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Exercise():
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
    TResult? Function(_Exercise value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Exercise() when $default != null:
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
            String name,
            String targetMuscle,
            String mechanics,
            String description,
            String? videoUrl,
            bool requiresWeight)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Exercise() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.targetMuscle,
            _that.mechanics,
            _that.description,
            _that.videoUrl,
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
    TResult Function(
            String id,
            String name,
            String targetMuscle,
            String mechanics,
            String description,
            String? videoUrl,
            bool requiresWeight)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Exercise():
        return $default(
            _that.id,
            _that.name,
            _that.targetMuscle,
            _that.mechanics,
            _that.description,
            _that.videoUrl,
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
    TResult? Function(
            String id,
            String name,
            String targetMuscle,
            String mechanics,
            String description,
            String? videoUrl,
            bool requiresWeight)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Exercise() when $default != null:
        return $default(
            _that.id,
            _that.name,
            _that.targetMuscle,
            _that.mechanics,
            _that.description,
            _that.videoUrl,
            _that.requiresWeight);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Exercise implements Exercise {
  const _Exercise(
      {required this.id,
      required this.name,
      required this.targetMuscle,
      required this.mechanics,
      required this.description,
      this.videoUrl,
      this.requiresWeight = true});
  factory _Exercise.fromJson(Map<String, dynamic> json) =>
      _$ExerciseFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String targetMuscle;
  @override
  final String mechanics;
  @override
  final String description;
  @override
  final String? videoUrl;
  @override
  @JsonKey()
  final bool requiresWeight;

  /// Create a copy of Exercise
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ExerciseCopyWith<_Exercise> get copyWith =>
      __$ExerciseCopyWithImpl<_Exercise>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ExerciseToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Exercise &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.targetMuscle, targetMuscle) ||
                other.targetMuscle == targetMuscle) &&
            (identical(other.mechanics, mechanics) ||
                other.mechanics == mechanics) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.videoUrl, videoUrl) ||
                other.videoUrl == videoUrl) &&
            (identical(other.requiresWeight, requiresWeight) ||
                other.requiresWeight == requiresWeight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, targetMuscle,
      mechanics, description, videoUrl, requiresWeight);

  @override
  String toString() {
    return 'Exercise(id: $id, name: $name, targetMuscle: $targetMuscle, mechanics: $mechanics, description: $description, videoUrl: $videoUrl, requiresWeight: $requiresWeight)';
  }
}

/// @nodoc
abstract mixin class _$ExerciseCopyWith<$Res>
    implements $ExerciseCopyWith<$Res> {
  factory _$ExerciseCopyWith(_Exercise value, $Res Function(_Exercise) _then) =
      __$ExerciseCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String targetMuscle,
      String mechanics,
      String description,
      String? videoUrl,
      bool requiresWeight});
}

/// @nodoc
class __$ExerciseCopyWithImpl<$Res> implements _$ExerciseCopyWith<$Res> {
  __$ExerciseCopyWithImpl(this._self, this._then);

  final _Exercise _self;
  final $Res Function(_Exercise) _then;

  /// Create a copy of Exercise
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? targetMuscle = null,
    Object? mechanics = null,
    Object? description = null,
    Object? videoUrl = freezed,
    Object? requiresWeight = null,
  }) {
    return _then(_Exercise(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      targetMuscle: null == targetMuscle
          ? _self.targetMuscle
          : targetMuscle // ignore: cast_nullable_to_non_nullable
              as String,
      mechanics: null == mechanics
          ? _self.mechanics
          : mechanics // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      videoUrl: freezed == videoUrl
          ? _self.videoUrl
          : videoUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      requiresWeight: null == requiresWeight
          ? _self.requiresWeight
          : requiresWeight // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
