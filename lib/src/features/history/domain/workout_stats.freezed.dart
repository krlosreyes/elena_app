// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_stats.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkoutStats {
  DateTime get date;
  double get totalVolume;
  int get durationMinutes;
  int get caloriesBurned;
  String get workoutType;
  int get totalSets;

  /// Create a copy of WorkoutStats
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WorkoutStatsCopyWith<WorkoutStats> get copyWith =>
      _$WorkoutStatsCopyWithImpl<WorkoutStats>(
          this as WorkoutStats, _$identity);

  /// Serializes this WorkoutStats to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WorkoutStats &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.totalVolume, totalVolume) ||
                other.totalVolume == totalVolume) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.caloriesBurned, caloriesBurned) ||
                other.caloriesBurned == caloriesBurned) &&
            (identical(other.workoutType, workoutType) ||
                other.workoutType == workoutType) &&
            (identical(other.totalSets, totalSets) ||
                other.totalSets == totalSets));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, date, totalVolume,
      durationMinutes, caloriesBurned, workoutType, totalSets);

  @override
  String toString() {
    return 'WorkoutStats(date: $date, totalVolume: $totalVolume, durationMinutes: $durationMinutes, caloriesBurned: $caloriesBurned, workoutType: $workoutType, totalSets: $totalSets)';
  }
}

/// @nodoc
abstract mixin class $WorkoutStatsCopyWith<$Res> {
  factory $WorkoutStatsCopyWith(
          WorkoutStats value, $Res Function(WorkoutStats) _then) =
      _$WorkoutStatsCopyWithImpl;
  @useResult
  $Res call(
      {DateTime date,
      double totalVolume,
      int durationMinutes,
      int caloriesBurned,
      String workoutType,
      int totalSets});
}

/// @nodoc
class _$WorkoutStatsCopyWithImpl<$Res> implements $WorkoutStatsCopyWith<$Res> {
  _$WorkoutStatsCopyWithImpl(this._self, this._then);

  final WorkoutStats _self;
  final $Res Function(WorkoutStats) _then;

  /// Create a copy of WorkoutStats
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? totalVolume = null,
    Object? durationMinutes = null,
    Object? caloriesBurned = null,
    Object? workoutType = null,
    Object? totalSets = null,
  }) {
    return _then(_self.copyWith(
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalVolume: null == totalVolume
          ? _self.totalVolume
          : totalVolume // ignore: cast_nullable_to_non_nullable
              as double,
      durationMinutes: null == durationMinutes
          ? _self.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      caloriesBurned: null == caloriesBurned
          ? _self.caloriesBurned
          : caloriesBurned // ignore: cast_nullable_to_non_nullable
              as int,
      workoutType: null == workoutType
          ? _self.workoutType
          : workoutType // ignore: cast_nullable_to_non_nullable
              as String,
      totalSets: null == totalSets
          ? _self.totalSets
          : totalSets // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [WorkoutStats].
extension WorkoutStatsPatterns on WorkoutStats {
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
    TResult Function(_WorkoutStats value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WorkoutStats() when $default != null:
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
    TResult Function(_WorkoutStats value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutStats():
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
    TResult? Function(_WorkoutStats value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutStats() when $default != null:
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
    TResult Function(DateTime date, double totalVolume, int durationMinutes,
            int caloriesBurned, String workoutType, int totalSets)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WorkoutStats() when $default != null:
        return $default(_that.date, _that.totalVolume, _that.durationMinutes,
            _that.caloriesBurned, _that.workoutType, _that.totalSets);
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
    TResult Function(DateTime date, double totalVolume, int durationMinutes,
            int caloriesBurned, String workoutType, int totalSets)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutStats():
        return $default(_that.date, _that.totalVolume, _that.durationMinutes,
            _that.caloriesBurned, _that.workoutType, _that.totalSets);
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
    TResult? Function(DateTime date, double totalVolume, int durationMinutes,
            int caloriesBurned, String workoutType, int totalSets)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutStats() when $default != null:
        return $default(_that.date, _that.totalVolume, _that.durationMinutes,
            _that.caloriesBurned, _that.workoutType, _that.totalSets);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WorkoutStats extends WorkoutStats {
  const _WorkoutStats(
      {required this.date,
      required this.totalVolume,
      required this.durationMinutes,
      required this.caloriesBurned,
      required this.workoutType,
      required this.totalSets})
      : super._();
  factory _WorkoutStats.fromJson(Map<String, dynamic> json) =>
      _$WorkoutStatsFromJson(json);

  @override
  final DateTime date;
  @override
  final double totalVolume;
  @override
  final int durationMinutes;
  @override
  final int caloriesBurned;
  @override
  final String workoutType;
  @override
  final int totalSets;

  /// Create a copy of WorkoutStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WorkoutStatsCopyWith<_WorkoutStats> get copyWith =>
      __$WorkoutStatsCopyWithImpl<_WorkoutStats>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WorkoutStatsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WorkoutStats &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.totalVolume, totalVolume) ||
                other.totalVolume == totalVolume) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.caloriesBurned, caloriesBurned) ||
                other.caloriesBurned == caloriesBurned) &&
            (identical(other.workoutType, workoutType) ||
                other.workoutType == workoutType) &&
            (identical(other.totalSets, totalSets) ||
                other.totalSets == totalSets));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, date, totalVolume,
      durationMinutes, caloriesBurned, workoutType, totalSets);

  @override
  String toString() {
    return 'WorkoutStats(date: $date, totalVolume: $totalVolume, durationMinutes: $durationMinutes, caloriesBurned: $caloriesBurned, workoutType: $workoutType, totalSets: $totalSets)';
  }
}

/// @nodoc
abstract mixin class _$WorkoutStatsCopyWith<$Res>
    implements $WorkoutStatsCopyWith<$Res> {
  factory _$WorkoutStatsCopyWith(
          _WorkoutStats value, $Res Function(_WorkoutStats) _then) =
      __$WorkoutStatsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DateTime date,
      double totalVolume,
      int durationMinutes,
      int caloriesBurned,
      String workoutType,
      int totalSets});
}

/// @nodoc
class __$WorkoutStatsCopyWithImpl<$Res>
    implements _$WorkoutStatsCopyWith<$Res> {
  __$WorkoutStatsCopyWithImpl(this._self, this._then);

  final _WorkoutStats _self;
  final $Res Function(_WorkoutStats) _then;

  /// Create a copy of WorkoutStats
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? date = null,
    Object? totalVolume = null,
    Object? durationMinutes = null,
    Object? caloriesBurned = null,
    Object? workoutType = null,
    Object? totalSets = null,
  }) {
    return _then(_WorkoutStats(
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalVolume: null == totalVolume
          ? _self.totalVolume
          : totalVolume // ignore: cast_nullable_to_non_nullable
              as double,
      durationMinutes: null == durationMinutes
          ? _self.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      caloriesBurned: null == caloriesBurned
          ? _self.caloriesBurned
          : caloriesBurned // ignore: cast_nullable_to_non_nullable
              as int,
      workoutType: null == workoutType
          ? _self.workoutType
          : workoutType // ignore: cast_nullable_to_non_nullable
              as String,
      totalSets: null == totalSets
          ? _self.totalSets
          : totalSets // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
