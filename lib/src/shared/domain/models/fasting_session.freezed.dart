// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'fasting_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$FastingSession {
  String get uid;
  DateTime get startTime;
  DateTime? get endTime;
  int get plannedDurationHours;
  bool get isCompleted;

  /// Create a copy of FastingSession
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $FastingSessionCopyWith<FastingSession> get copyWith =>
      _$FastingSessionCopyWithImpl<FastingSession>(
          this as FastingSession, _$identity);

  /// Serializes this FastingSession to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is FastingSession &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.plannedDurationHours, plannedDurationHours) ||
                other.plannedDurationHours == plannedDurationHours) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, uid, startTime, endTime, plannedDurationHours, isCompleted);

  @override
  String toString() {
    return 'FastingSession(uid: $uid, startTime: $startTime, endTime: $endTime, plannedDurationHours: $plannedDurationHours, isCompleted: $isCompleted)';
  }
}

/// @nodoc
abstract mixin class $FastingSessionCopyWith<$Res> {
  factory $FastingSessionCopyWith(
          FastingSession value, $Res Function(FastingSession) _then) =
      _$FastingSessionCopyWithImpl;
  @useResult
  $Res call(
      {String uid,
      DateTime startTime,
      DateTime? endTime,
      int plannedDurationHours,
      bool isCompleted});
}

/// @nodoc
class _$FastingSessionCopyWithImpl<$Res>
    implements $FastingSessionCopyWith<$Res> {
  _$FastingSessionCopyWithImpl(this._self, this._then);

  final FastingSession _self;
  final $Res Function(FastingSession) _then;

  /// Create a copy of FastingSession
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? plannedDurationHours = null,
    Object? isCompleted = null,
  }) {
    return _then(_self.copyWith(
      uid: null == uid
          ? _self.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      plannedDurationHours: null == plannedDurationHours
          ? _self.plannedDurationHours
          : plannedDurationHours // ignore: cast_nullable_to_non_nullable
              as int,
      isCompleted: null == isCompleted
          ? _self.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// Adds pattern-matching-related methods to [FastingSession].
extension FastingSessionPatterns on FastingSession {
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
    TResult Function(_FastingSession value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FastingSession() when $default != null:
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
    TResult Function(_FastingSession value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FastingSession():
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
    TResult? Function(_FastingSession value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FastingSession() when $default != null:
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
    TResult Function(String uid, DateTime startTime, DateTime? endTime,
            int plannedDurationHours, bool isCompleted)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _FastingSession() when $default != null:
        return $default(_that.uid, _that.startTime, _that.endTime,
            _that.plannedDurationHours, _that.isCompleted);
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
    TResult Function(String uid, DateTime startTime, DateTime? endTime,
            int plannedDurationHours, bool isCompleted)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FastingSession():
        return $default(_that.uid, _that.startTime, _that.endTime,
            _that.plannedDurationHours, _that.isCompleted);
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
    TResult? Function(String uid, DateTime startTime, DateTime? endTime,
            int plannedDurationHours, bool isCompleted)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _FastingSession() when $default != null:
        return $default(_that.uid, _that.startTime, _that.endTime,
            _that.plannedDurationHours, _that.isCompleted);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _FastingSession implements FastingSession {
  const _FastingSession(
      {required this.uid,
      required this.startTime,
      this.endTime,
      required this.plannedDurationHours,
      this.isCompleted = false});
  factory _FastingSession.fromJson(Map<String, dynamic> json) =>
      _$FastingSessionFromJson(json);

  @override
  final String uid;
  @override
  final DateTime startTime;
  @override
  final DateTime? endTime;
  @override
  final int plannedDurationHours;
  @override
  @JsonKey()
  final bool isCompleted;

  /// Create a copy of FastingSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$FastingSessionCopyWith<_FastingSession> get copyWith =>
      __$FastingSessionCopyWithImpl<_FastingSession>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$FastingSessionToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _FastingSession &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.plannedDurationHours, plannedDurationHours) ||
                other.plannedDurationHours == plannedDurationHours) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, uid, startTime, endTime, plannedDurationHours, isCompleted);

  @override
  String toString() {
    return 'FastingSession(uid: $uid, startTime: $startTime, endTime: $endTime, plannedDurationHours: $plannedDurationHours, isCompleted: $isCompleted)';
  }
}

/// @nodoc
abstract mixin class _$FastingSessionCopyWith<$Res>
    implements $FastingSessionCopyWith<$Res> {
  factory _$FastingSessionCopyWith(
          _FastingSession value, $Res Function(_FastingSession) _then) =
      __$FastingSessionCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String uid,
      DateTime startTime,
      DateTime? endTime,
      int plannedDurationHours,
      bool isCompleted});
}

/// @nodoc
class __$FastingSessionCopyWithImpl<$Res>
    implements _$FastingSessionCopyWith<$Res> {
  __$FastingSessionCopyWithImpl(this._self, this._then);

  final _FastingSession _self;
  final $Res Function(_FastingSession) _then;

  /// Create a copy of FastingSession
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? uid = null,
    Object? startTime = null,
    Object? endTime = freezed,
    Object? plannedDurationHours = null,
    Object? isCompleted = null,
  }) {
    return _then(_FastingSession(
      uid: null == uid
          ? _self.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      startTime: null == startTime
          ? _self.startTime
          : startTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      endTime: freezed == endTime
          ? _self.endTime
          : endTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      plannedDurationHours: null == plannedDurationHours
          ? _self.plannedDurationHours
          : plannedDurationHours // ignore: cast_nullable_to_non_nullable
              as int,
      isCompleted: null == isCompleted
          ? _self.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

// dart format on
