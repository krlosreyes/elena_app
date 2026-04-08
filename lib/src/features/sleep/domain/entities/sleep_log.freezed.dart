// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sleep_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SleepLog {
  String get id;
  String get userId;
  double get hours;
  @TimestampConverter()
  DateTime get timestamp;

  /// Create a copy of SleepLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SleepLogCopyWith<SleepLog> get copyWith =>
      _$SleepLogCopyWithImpl<SleepLog>(this as SleepLog, _$identity);

  /// Serializes this SleepLog to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SleepLog &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.hours, hours) || other.hours == hours) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, hours, timestamp);

  @override
  String toString() {
    return 'SleepLog(id: $id, userId: $userId, hours: $hours, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class $SleepLogCopyWith<$Res> {
  factory $SleepLogCopyWith(SleepLog value, $Res Function(SleepLog) _then) =
      _$SleepLogCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String userId,
      double hours,
      @TimestampConverter() DateTime timestamp});
}

/// @nodoc
class _$SleepLogCopyWithImpl<$Res> implements $SleepLogCopyWith<$Res> {
  _$SleepLogCopyWithImpl(this._self, this._then);

  final SleepLog _self;
  final $Res Function(SleepLog) _then;

  /// Create a copy of SleepLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? hours = null,
    Object? timestamp = null,
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
      hours: null == hours
          ? _self.hours
          : hours // ignore: cast_nullable_to_non_nullable
              as double,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [SleepLog].
extension SleepLogPatterns on SleepLog {
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
    TResult Function(_SleepLog value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SleepLog() when $default != null:
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
    TResult Function(_SleepLog value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SleepLog():
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
    TResult? Function(_SleepLog value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SleepLog() when $default != null:
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
    TResult Function(String id, String userId, double hours,
            @TimestampConverter() DateTime timestamp)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SleepLog() when $default != null:
        return $default(_that.id, _that.userId, _that.hours, _that.timestamp);
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
    TResult Function(String id, String userId, double hours,
            @TimestampConverter() DateTime timestamp)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SleepLog():
        return $default(_that.id, _that.userId, _that.hours, _that.timestamp);
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
    TResult? Function(String id, String userId, double hours,
            @TimestampConverter() DateTime timestamp)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SleepLog() when $default != null:
        return $default(_that.id, _that.userId, _that.hours, _that.timestamp);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SleepLog implements SleepLog {
  const _SleepLog(
      {required this.id,
      required this.userId,
      required this.hours,
      @TimestampConverter() required this.timestamp});
  factory _SleepLog.fromJson(Map<String, dynamic> json) =>
      _$SleepLogFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final double hours;
  @override
  @TimestampConverter()
  final DateTime timestamp;

  /// Create a copy of SleepLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SleepLogCopyWith<_SleepLog> get copyWith =>
      __$SleepLogCopyWithImpl<_SleepLog>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SleepLogToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SleepLog &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.hours, hours) || other.hours == hours) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, hours, timestamp);

  @override
  String toString() {
    return 'SleepLog(id: $id, userId: $userId, hours: $hours, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class _$SleepLogCopyWith<$Res>
    implements $SleepLogCopyWith<$Res> {
  factory _$SleepLogCopyWith(_SleepLog value, $Res Function(_SleepLog) _then) =
      __$SleepLogCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      double hours,
      @TimestampConverter() DateTime timestamp});
}

/// @nodoc
class __$SleepLogCopyWithImpl<$Res> implements _$SleepLogCopyWith<$Res> {
  __$SleepLogCopyWithImpl(this._self, this._then);

  final _SleepLog _self;
  final $Res Function(_SleepLog) _then;

  /// Create a copy of SleepLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? hours = null,
    Object? timestamp = null,
  }) {
    return _then(_SleepLog(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      hours: null == hours
          ? _self.hours
          : hours // ignore: cast_nullable_to_non_nullable
              as double,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
