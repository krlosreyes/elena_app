// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'training_engine_provider.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TrainingSessionState {
  int get currentIndex;
  bool get isDeload;
  bool get isSessionActive;
  bool get isExecuting; // Dynamic Feedback Visibility
  bool get isResting; // New: Track Rest State
  TrainingStatus get status;

  /// Create a copy of TrainingSessionState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TrainingSessionStateCopyWith<TrainingSessionState> get copyWith =>
      _$TrainingSessionStateCopyWithImpl<TrainingSessionState>(
          this as TrainingSessionState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TrainingSessionState &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            (identical(other.isDeload, isDeload) ||
                other.isDeload == isDeload) &&
            (identical(other.isSessionActive, isSessionActive) ||
                other.isSessionActive == isSessionActive) &&
            (identical(other.isExecuting, isExecuting) ||
                other.isExecuting == isExecuting) &&
            (identical(other.isResting, isResting) ||
                other.isResting == isResting) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentIndex, isDeload,
      isSessionActive, isExecuting, isResting, status);

  @override
  String toString() {
    return 'TrainingSessionState(currentIndex: $currentIndex, isDeload: $isDeload, isSessionActive: $isSessionActive, isExecuting: $isExecuting, isResting: $isResting, status: $status)';
  }
}

/// @nodoc
abstract mixin class $TrainingSessionStateCopyWith<$Res> {
  factory $TrainingSessionStateCopyWith(TrainingSessionState value,
          $Res Function(TrainingSessionState) _then) =
      _$TrainingSessionStateCopyWithImpl;
  @useResult
  $Res call(
      {int currentIndex,
      bool isDeload,
      bool isSessionActive,
      bool isExecuting,
      bool isResting,
      TrainingStatus status});
}

/// @nodoc
class _$TrainingSessionStateCopyWithImpl<$Res>
    implements $TrainingSessionStateCopyWith<$Res> {
  _$TrainingSessionStateCopyWithImpl(this._self, this._then);

  final TrainingSessionState _self;
  final $Res Function(TrainingSessionState) _then;

  /// Create a copy of TrainingSessionState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currentIndex = null,
    Object? isDeload = null,
    Object? isSessionActive = null,
    Object? isExecuting = null,
    Object? isResting = null,
    Object? status = null,
  }) {
    return _then(_self.copyWith(
      currentIndex: null == currentIndex
          ? _self.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isDeload: null == isDeload
          ? _self.isDeload
          : isDeload // ignore: cast_nullable_to_non_nullable
              as bool,
      isSessionActive: null == isSessionActive
          ? _self.isSessionActive
          : isSessionActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isExecuting: null == isExecuting
          ? _self.isExecuting
          : isExecuting // ignore: cast_nullable_to_non_nullable
              as bool,
      isResting: null == isResting
          ? _self.isResting
          : isResting // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as TrainingStatus,
    ));
  }
}

/// Adds pattern-matching-related methods to [TrainingSessionState].
extension TrainingSessionStatePatterns on TrainingSessionState {
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
    TResult Function(_TrainingSessionState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TrainingSessionState() when $default != null:
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
    TResult Function(_TrainingSessionState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrainingSessionState():
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
    TResult? Function(_TrainingSessionState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrainingSessionState() when $default != null:
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
    TResult Function(int currentIndex, bool isDeload, bool isSessionActive,
            bool isExecuting, bool isResting, TrainingStatus status)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TrainingSessionState() when $default != null:
        return $default(
            _that.currentIndex,
            _that.isDeload,
            _that.isSessionActive,
            _that.isExecuting,
            _that.isResting,
            _that.status);
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
    TResult Function(int currentIndex, bool isDeload, bool isSessionActive,
            bool isExecuting, bool isResting, TrainingStatus status)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrainingSessionState():
        return $default(
            _that.currentIndex,
            _that.isDeload,
            _that.isSessionActive,
            _that.isExecuting,
            _that.isResting,
            _that.status);
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
    TResult? Function(int currentIndex, bool isDeload, bool isSessionActive,
            bool isExecuting, bool isResting, TrainingStatus status)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TrainingSessionState() when $default != null:
        return $default(
            _that.currentIndex,
            _that.isDeload,
            _that.isSessionActive,
            _that.isExecuting,
            _that.isResting,
            _that.status);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TrainingSessionState implements TrainingSessionState {
  const _TrainingSessionState(
      {this.currentIndex = 0,
      this.isDeload = false,
      this.isSessionActive = false,
      this.isExecuting = false,
      this.isResting = false,
      this.status = TrainingStatus.needsDiagnostic});

  @override
  @JsonKey()
  final int currentIndex;
  @override
  @JsonKey()
  final bool isDeload;
  @override
  @JsonKey()
  final bool isSessionActive;
  @override
  @JsonKey()
  final bool isExecuting;
// Dynamic Feedback Visibility
  @override
  @JsonKey()
  final bool isResting;
// New: Track Rest State
  @override
  @JsonKey()
  final TrainingStatus status;

  /// Create a copy of TrainingSessionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TrainingSessionStateCopyWith<_TrainingSessionState> get copyWith =>
      __$TrainingSessionStateCopyWithImpl<_TrainingSessionState>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TrainingSessionState &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            (identical(other.isDeload, isDeload) ||
                other.isDeload == isDeload) &&
            (identical(other.isSessionActive, isSessionActive) ||
                other.isSessionActive == isSessionActive) &&
            (identical(other.isExecuting, isExecuting) ||
                other.isExecuting == isExecuting) &&
            (identical(other.isResting, isResting) ||
                other.isResting == isResting) &&
            (identical(other.status, status) || other.status == status));
  }

  @override
  int get hashCode => Object.hash(runtimeType, currentIndex, isDeload,
      isSessionActive, isExecuting, isResting, status);

  @override
  String toString() {
    return 'TrainingSessionState(currentIndex: $currentIndex, isDeload: $isDeload, isSessionActive: $isSessionActive, isExecuting: $isExecuting, isResting: $isResting, status: $status)';
  }
}

/// @nodoc
abstract mixin class _$TrainingSessionStateCopyWith<$Res>
    implements $TrainingSessionStateCopyWith<$Res> {
  factory _$TrainingSessionStateCopyWith(_TrainingSessionState value,
          $Res Function(_TrainingSessionState) _then) =
      __$TrainingSessionStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int currentIndex,
      bool isDeload,
      bool isSessionActive,
      bool isExecuting,
      bool isResting,
      TrainingStatus status});
}

/// @nodoc
class __$TrainingSessionStateCopyWithImpl<$Res>
    implements _$TrainingSessionStateCopyWith<$Res> {
  __$TrainingSessionStateCopyWithImpl(this._self, this._then);

  final _TrainingSessionState _self;
  final $Res Function(_TrainingSessionState) _then;

  /// Create a copy of TrainingSessionState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? currentIndex = null,
    Object? isDeload = null,
    Object? isSessionActive = null,
    Object? isExecuting = null,
    Object? isResting = null,
    Object? status = null,
  }) {
    return _then(_TrainingSessionState(
      currentIndex: null == currentIndex
          ? _self.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isDeload: null == isDeload
          ? _self.isDeload
          : isDeload // ignore: cast_nullable_to_non_nullable
              as bool,
      isSessionActive: null == isSessionActive
          ? _self.isSessionActive
          : isSessionActive // ignore: cast_nullable_to_non_nullable
              as bool,
      isExecuting: null == isExecuting
          ? _self.isExecuting
          : isExecuting // ignore: cast_nullable_to_non_nullable
              as bool,
      isResting: null == isResting
          ? _self.isResting
          : isResting // ignore: cast_nullable_to_non_nullable
              as bool,
      status: null == status
          ? _self.status
          : status // ignore: cast_nullable_to_non_nullable
              as TrainingStatus,
    ));
  }
}

// dart format on
