// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'metabolic_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MetabolicState {
  DateTime get date;
  double get sleepHours;
  int get sorenessLevel;
  String get nutritionStatus;
  double get energyLevel;
  String? get insightMessage;

  /// Create a copy of MetabolicState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MetabolicStateCopyWith<MetabolicState> get copyWith =>
      _$MetabolicStateCopyWithImpl<MetabolicState>(
          this as MetabolicState, _$identity);

  /// Serializes this MetabolicState to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MetabolicState &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.sleepHours, sleepHours) ||
                other.sleepHours == sleepHours) &&
            (identical(other.sorenessLevel, sorenessLevel) ||
                other.sorenessLevel == sorenessLevel) &&
            (identical(other.nutritionStatus, nutritionStatus) ||
                other.nutritionStatus == nutritionStatus) &&
            (identical(other.energyLevel, energyLevel) ||
                other.energyLevel == energyLevel) &&
            (identical(other.insightMessage, insightMessage) ||
                other.insightMessage == insightMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, date, sleepHours, sorenessLevel,
      nutritionStatus, energyLevel, insightMessage);

  @override
  String toString() {
    return 'MetabolicState(date: $date, sleepHours: $sleepHours, sorenessLevel: $sorenessLevel, nutritionStatus: $nutritionStatus, energyLevel: $energyLevel, insightMessage: $insightMessage)';
  }
}

/// @nodoc
abstract mixin class $MetabolicStateCopyWith<$Res> {
  factory $MetabolicStateCopyWith(
          MetabolicState value, $Res Function(MetabolicState) _then) =
      _$MetabolicStateCopyWithImpl;
  @useResult
  $Res call(
      {DateTime date,
      double sleepHours,
      int sorenessLevel,
      String nutritionStatus,
      double energyLevel,
      String? insightMessage});
}

/// @nodoc
class _$MetabolicStateCopyWithImpl<$Res>
    implements $MetabolicStateCopyWith<$Res> {
  _$MetabolicStateCopyWithImpl(this._self, this._then);

  final MetabolicState _self;
  final $Res Function(MetabolicState) _then;

  /// Create a copy of MetabolicState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? sleepHours = null,
    Object? sorenessLevel = null,
    Object? nutritionStatus = null,
    Object? energyLevel = null,
    Object? insightMessage = freezed,
  }) {
    return _then(_self.copyWith(
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      sleepHours: null == sleepHours
          ? _self.sleepHours
          : sleepHours // ignore: cast_nullable_to_non_nullable
              as double,
      sorenessLevel: null == sorenessLevel
          ? _self.sorenessLevel
          : sorenessLevel // ignore: cast_nullable_to_non_nullable
              as int,
      nutritionStatus: null == nutritionStatus
          ? _self.nutritionStatus
          : nutritionStatus // ignore: cast_nullable_to_non_nullable
              as String,
      energyLevel: null == energyLevel
          ? _self.energyLevel
          : energyLevel // ignore: cast_nullable_to_non_nullable
              as double,
      insightMessage: freezed == insightMessage
          ? _self.insightMessage
          : insightMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [MetabolicState].
extension MetabolicStatePatterns on MetabolicState {
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
    TResult Function(_MetabolicState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MetabolicState() when $default != null:
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
    TResult Function(_MetabolicState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MetabolicState():
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
    TResult? Function(_MetabolicState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MetabolicState() when $default != null:
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
    TResult Function(DateTime date, double sleepHours, int sorenessLevel,
            String nutritionStatus, double energyLevel, String? insightMessage)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MetabolicState() when $default != null:
        return $default(_that.date, _that.sleepHours, _that.sorenessLevel,
            _that.nutritionStatus, _that.energyLevel, _that.insightMessage);
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
    TResult Function(DateTime date, double sleepHours, int sorenessLevel,
            String nutritionStatus, double energyLevel, String? insightMessage)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MetabolicState():
        return $default(_that.date, _that.sleepHours, _that.sorenessLevel,
            _that.nutritionStatus, _that.energyLevel, _that.insightMessage);
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
    TResult? Function(DateTime date, double sleepHours, int sorenessLevel,
            String nutritionStatus, double energyLevel, String? insightMessage)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MetabolicState() when $default != null:
        return $default(_that.date, _that.sleepHours, _that.sorenessLevel,
            _that.nutritionStatus, _that.energyLevel, _that.insightMessage);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MetabolicState implements MetabolicState {
  const _MetabolicState(
      {required this.date,
      required this.sleepHours,
      required this.sorenessLevel,
      required this.nutritionStatus,
      required this.energyLevel,
      required this.insightMessage});
  factory _MetabolicState.fromJson(Map<String, dynamic> json) =>
      _$MetabolicStateFromJson(json);

  @override
  final DateTime date;
  @override
  final double sleepHours;
  @override
  final int sorenessLevel;
  @override
  final String nutritionStatus;
  @override
  final double energyLevel;
  @override
  final String? insightMessage;

  /// Create a copy of MetabolicState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MetabolicStateCopyWith<_MetabolicState> get copyWith =>
      __$MetabolicStateCopyWithImpl<_MetabolicState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MetabolicStateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MetabolicState &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.sleepHours, sleepHours) ||
                other.sleepHours == sleepHours) &&
            (identical(other.sorenessLevel, sorenessLevel) ||
                other.sorenessLevel == sorenessLevel) &&
            (identical(other.nutritionStatus, nutritionStatus) ||
                other.nutritionStatus == nutritionStatus) &&
            (identical(other.energyLevel, energyLevel) ||
                other.energyLevel == energyLevel) &&
            (identical(other.insightMessage, insightMessage) ||
                other.insightMessage == insightMessage));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, date, sleepHours, sorenessLevel,
      nutritionStatus, energyLevel, insightMessage);

  @override
  String toString() {
    return 'MetabolicState(date: $date, sleepHours: $sleepHours, sorenessLevel: $sorenessLevel, nutritionStatus: $nutritionStatus, energyLevel: $energyLevel, insightMessage: $insightMessage)';
  }
}

/// @nodoc
abstract mixin class _$MetabolicStateCopyWith<$Res>
    implements $MetabolicStateCopyWith<$Res> {
  factory _$MetabolicStateCopyWith(
          _MetabolicState value, $Res Function(_MetabolicState) _then) =
      __$MetabolicStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DateTime date,
      double sleepHours,
      int sorenessLevel,
      String nutritionStatus,
      double energyLevel,
      String? insightMessage});
}

/// @nodoc
class __$MetabolicStateCopyWithImpl<$Res>
    implements _$MetabolicStateCopyWith<$Res> {
  __$MetabolicStateCopyWithImpl(this._self, this._then);

  final _MetabolicState _self;
  final $Res Function(_MetabolicState) _then;

  /// Create a copy of MetabolicState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? date = null,
    Object? sleepHours = null,
    Object? sorenessLevel = null,
    Object? nutritionStatus = null,
    Object? energyLevel = null,
    Object? insightMessage = freezed,
  }) {
    return _then(_MetabolicState(
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      sleepHours: null == sleepHours
          ? _self.sleepHours
          : sleepHours // ignore: cast_nullable_to_non_nullable
              as double,
      sorenessLevel: null == sorenessLevel
          ? _self.sorenessLevel
          : sorenessLevel // ignore: cast_nullable_to_non_nullable
              as int,
      nutritionStatus: null == nutritionStatus
          ? _self.nutritionStatus
          : nutritionStatus // ignore: cast_nullable_to_non_nullable
              as String,
      energyLevel: null == energyLevel
          ? _self.energyLevel
          : energyLevel // ignore: cast_nullable_to_non_nullable
              as double,
      insightMessage: freezed == insightMessage
          ? _self.insightMessage
          : insightMessage // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
