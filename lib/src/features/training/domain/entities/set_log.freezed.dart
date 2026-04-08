// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'set_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SetLog {
  String get id;
  String get exerciseId;
  int get dayIndex;
  int get setNumber;
  int get reps;
  double get weightKg;
  int get rpe;
  @TimestampConverter()
  DateTime get loggedAt;

  /// Create a copy of SetLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SetLogCopyWith<SetLog> get copyWith =>
      _$SetLogCopyWithImpl<SetLog>(this as SetLog, _$identity);

  /// Serializes this SetLog to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SetLog &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.dayIndex, dayIndex) ||
                other.dayIndex == dayIndex) &&
            (identical(other.setNumber, setNumber) ||
                other.setNumber == setNumber) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.rpe, rpe) || other.rpe == rpe) &&
            (identical(other.loggedAt, loggedAt) ||
                other.loggedAt == loggedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, exerciseId, dayIndex,
      setNumber, reps, weightKg, rpe, loggedAt);

  @override
  String toString() {
    return 'SetLog(id: $id, exerciseId: $exerciseId, dayIndex: $dayIndex, setNumber: $setNumber, reps: $reps, weightKg: $weightKg, rpe: $rpe, loggedAt: $loggedAt)';
  }
}

/// @nodoc
abstract mixin class $SetLogCopyWith<$Res> {
  factory $SetLogCopyWith(SetLog value, $Res Function(SetLog) _then) =
      _$SetLogCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String exerciseId,
      int dayIndex,
      int setNumber,
      int reps,
      double weightKg,
      int rpe,
      @TimestampConverter() DateTime loggedAt});
}

/// @nodoc
class _$SetLogCopyWithImpl<$Res> implements $SetLogCopyWith<$Res> {
  _$SetLogCopyWithImpl(this._self, this._then);

  final SetLog _self;
  final $Res Function(SetLog) _then;

  /// Create a copy of SetLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? exerciseId = null,
    Object? dayIndex = null,
    Object? setNumber = null,
    Object? reps = null,
    Object? weightKg = null,
    Object? rpe = null,
    Object? loggedAt = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseId: null == exerciseId
          ? _self.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      dayIndex: null == dayIndex
          ? _self.dayIndex
          : dayIndex // ignore: cast_nullable_to_non_nullable
              as int,
      setNumber: null == setNumber
          ? _self.setNumber
          : setNumber // ignore: cast_nullable_to_non_nullable
              as int,
      reps: null == reps
          ? _self.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int,
      weightKg: null == weightKg
          ? _self.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double,
      rpe: null == rpe
          ? _self.rpe
          : rpe // ignore: cast_nullable_to_non_nullable
              as int,
      loggedAt: null == loggedAt
          ? _self.loggedAt
          : loggedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [SetLog].
extension SetLogPatterns on SetLog {
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
    TResult Function(_SetLog value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SetLog() when $default != null:
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
    TResult Function(_SetLog value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SetLog():
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
    TResult? Function(_SetLog value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SetLog() when $default != null:
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
            String exerciseId,
            int dayIndex,
            int setNumber,
            int reps,
            double weightKg,
            int rpe,
            @TimestampConverter() DateTime loggedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SetLog() when $default != null:
        return $default(
            _that.id,
            _that.exerciseId,
            _that.dayIndex,
            _that.setNumber,
            _that.reps,
            _that.weightKg,
            _that.rpe,
            _that.loggedAt);
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
            String exerciseId,
            int dayIndex,
            int setNumber,
            int reps,
            double weightKg,
            int rpe,
            @TimestampConverter() DateTime loggedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SetLog():
        return $default(
            _that.id,
            _that.exerciseId,
            _that.dayIndex,
            _that.setNumber,
            _that.reps,
            _that.weightKg,
            _that.rpe,
            _that.loggedAt);
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
            String exerciseId,
            int dayIndex,
            int setNumber,
            int reps,
            double weightKg,
            int rpe,
            @TimestampConverter() DateTime loggedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SetLog() when $default != null:
        return $default(
            _that.id,
            _that.exerciseId,
            _that.dayIndex,
            _that.setNumber,
            _that.reps,
            _that.weightKg,
            _that.rpe,
            _that.loggedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SetLog implements SetLog {
  const _SetLog(
      {this.id = '',
      required this.exerciseId,
      required this.dayIndex,
      required this.setNumber,
      required this.reps,
      this.weightKg = 0.0,
      this.rpe = 5,
      @TimestampConverter() required this.loggedAt});
  factory _SetLog.fromJson(Map<String, dynamic> json) => _$SetLogFromJson(json);

  @override
  @JsonKey()
  final String id;
  @override
  final String exerciseId;
  @override
  final int dayIndex;
  @override
  final int setNumber;
  @override
  final int reps;
  @override
  @JsonKey()
  final double weightKg;
  @override
  @JsonKey()
  final int rpe;
  @override
  @TimestampConverter()
  final DateTime loggedAt;

  /// Create a copy of SetLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SetLogCopyWith<_SetLog> get copyWith =>
      __$SetLogCopyWithImpl<_SetLog>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SetLogToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SetLog &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.dayIndex, dayIndex) ||
                other.dayIndex == dayIndex) &&
            (identical(other.setNumber, setNumber) ||
                other.setNumber == setNumber) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.rpe, rpe) || other.rpe == rpe) &&
            (identical(other.loggedAt, loggedAt) ||
                other.loggedAt == loggedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, exerciseId, dayIndex,
      setNumber, reps, weightKg, rpe, loggedAt);

  @override
  String toString() {
    return 'SetLog(id: $id, exerciseId: $exerciseId, dayIndex: $dayIndex, setNumber: $setNumber, reps: $reps, weightKg: $weightKg, rpe: $rpe, loggedAt: $loggedAt)';
  }
}

/// @nodoc
abstract mixin class _$SetLogCopyWith<$Res> implements $SetLogCopyWith<$Res> {
  factory _$SetLogCopyWith(_SetLog value, $Res Function(_SetLog) _then) =
      __$SetLogCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String exerciseId,
      int dayIndex,
      int setNumber,
      int reps,
      double weightKg,
      int rpe,
      @TimestampConverter() DateTime loggedAt});
}

/// @nodoc
class __$SetLogCopyWithImpl<$Res> implements _$SetLogCopyWith<$Res> {
  __$SetLogCopyWithImpl(this._self, this._then);

  final _SetLog _self;
  final $Res Function(_SetLog) _then;

  /// Create a copy of SetLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? exerciseId = null,
    Object? dayIndex = null,
    Object? setNumber = null,
    Object? reps = null,
    Object? weightKg = null,
    Object? rpe = null,
    Object? loggedAt = null,
  }) {
    return _then(_SetLog(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseId: null == exerciseId
          ? _self.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      dayIndex: null == dayIndex
          ? _self.dayIndex
          : dayIndex // ignore: cast_nullable_to_non_nullable
              as int,
      setNumber: null == setNumber
          ? _self.setNumber
          : setNumber // ignore: cast_nullable_to_non_nullable
              as int,
      reps: null == reps
          ? _self.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int,
      weightKg: null == weightKg
          ? _self.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double,
      rpe: null == rpe
          ? _self.rpe
          : rpe // ignore: cast_nullable_to_non_nullable
              as int,
      loggedAt: null == loggedAt
          ? _self.loggedAt
          : loggedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
