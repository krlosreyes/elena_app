// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$HealthPlan {
  String get protocol;
  int get hydrationGoal;
  int get maxHeartRate;
  String get exerciseStrategy;
  String get exerciseFrequency;
  String get nutritionStrategy;
  String get breakingFastTip;
  String? get glucoseStrategy;
  String get whyThisPlan;
  DateTime get generatedAt;

  /// Create a copy of HealthPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $HealthPlanCopyWith<HealthPlan> get copyWith =>
      _$HealthPlanCopyWithImpl<HealthPlan>(this as HealthPlan, _$identity);

  /// Serializes this HealthPlan to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is HealthPlan &&
            (identical(other.protocol, protocol) ||
                other.protocol == protocol) &&
            (identical(other.hydrationGoal, hydrationGoal) ||
                other.hydrationGoal == hydrationGoal) &&
            (identical(other.maxHeartRate, maxHeartRate) ||
                other.maxHeartRate == maxHeartRate) &&
            (identical(other.exerciseStrategy, exerciseStrategy) ||
                other.exerciseStrategy == exerciseStrategy) &&
            (identical(other.exerciseFrequency, exerciseFrequency) ||
                other.exerciseFrequency == exerciseFrequency) &&
            (identical(other.nutritionStrategy, nutritionStrategy) ||
                other.nutritionStrategy == nutritionStrategy) &&
            (identical(other.breakingFastTip, breakingFastTip) ||
                other.breakingFastTip == breakingFastTip) &&
            (identical(other.glucoseStrategy, glucoseStrategy) ||
                other.glucoseStrategy == glucoseStrategy) &&
            (identical(other.whyThisPlan, whyThisPlan) ||
                other.whyThisPlan == whyThisPlan) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      protocol,
      hydrationGoal,
      maxHeartRate,
      exerciseStrategy,
      exerciseFrequency,
      nutritionStrategy,
      breakingFastTip,
      glucoseStrategy,
      whyThisPlan,
      generatedAt);

  @override
  String toString() {
    return 'HealthPlan(protocol: $protocol, hydrationGoal: $hydrationGoal, maxHeartRate: $maxHeartRate, exerciseStrategy: $exerciseStrategy, exerciseFrequency: $exerciseFrequency, nutritionStrategy: $nutritionStrategy, breakingFastTip: $breakingFastTip, glucoseStrategy: $glucoseStrategy, whyThisPlan: $whyThisPlan, generatedAt: $generatedAt)';
  }
}

/// @nodoc
abstract mixin class $HealthPlanCopyWith<$Res> {
  factory $HealthPlanCopyWith(
          HealthPlan value, $Res Function(HealthPlan) _then) =
      _$HealthPlanCopyWithImpl;
  @useResult
  $Res call(
      {String protocol,
      int hydrationGoal,
      int maxHeartRate,
      String exerciseStrategy,
      String exerciseFrequency,
      String nutritionStrategy,
      String breakingFastTip,
      String? glucoseStrategy,
      String whyThisPlan,
      DateTime generatedAt});
}

/// @nodoc
class _$HealthPlanCopyWithImpl<$Res> implements $HealthPlanCopyWith<$Res> {
  _$HealthPlanCopyWithImpl(this._self, this._then);

  final HealthPlan _self;
  final $Res Function(HealthPlan) _then;

  /// Create a copy of HealthPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? protocol = null,
    Object? hydrationGoal = null,
    Object? maxHeartRate = null,
    Object? exerciseStrategy = null,
    Object? exerciseFrequency = null,
    Object? nutritionStrategy = null,
    Object? breakingFastTip = null,
    Object? glucoseStrategy = freezed,
    Object? whyThisPlan = null,
    Object? generatedAt = null,
  }) {
    return _then(_self.copyWith(
      protocol: null == protocol
          ? _self.protocol
          : protocol // ignore: cast_nullable_to_non_nullable
              as String,
      hydrationGoal: null == hydrationGoal
          ? _self.hydrationGoal
          : hydrationGoal // ignore: cast_nullable_to_non_nullable
              as int,
      maxHeartRate: null == maxHeartRate
          ? _self.maxHeartRate
          : maxHeartRate // ignore: cast_nullable_to_non_nullable
              as int,
      exerciseStrategy: null == exerciseStrategy
          ? _self.exerciseStrategy
          : exerciseStrategy // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseFrequency: null == exerciseFrequency
          ? _self.exerciseFrequency
          : exerciseFrequency // ignore: cast_nullable_to_non_nullable
              as String,
      nutritionStrategy: null == nutritionStrategy
          ? _self.nutritionStrategy
          : nutritionStrategy // ignore: cast_nullable_to_non_nullable
              as String,
      breakingFastTip: null == breakingFastTip
          ? _self.breakingFastTip
          : breakingFastTip // ignore: cast_nullable_to_non_nullable
              as String,
      glucoseStrategy: freezed == glucoseStrategy
          ? _self.glucoseStrategy
          : glucoseStrategy // ignore: cast_nullable_to_non_nullable
              as String?,
      whyThisPlan: null == whyThisPlan
          ? _self.whyThisPlan
          : whyThisPlan // ignore: cast_nullable_to_non_nullable
              as String,
      generatedAt: null == generatedAt
          ? _self.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [HealthPlan].
extension HealthPlanPatterns on HealthPlan {
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
    TResult Function(_HealthPlan value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HealthPlan() when $default != null:
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
    TResult Function(_HealthPlan value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HealthPlan():
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
    TResult? Function(_HealthPlan value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HealthPlan() when $default != null:
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
            String protocol,
            int hydrationGoal,
            int maxHeartRate,
            String exerciseStrategy,
            String exerciseFrequency,
            String nutritionStrategy,
            String breakingFastTip,
            String? glucoseStrategy,
            String whyThisPlan,
            DateTime generatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _HealthPlan() when $default != null:
        return $default(
            _that.protocol,
            _that.hydrationGoal,
            _that.maxHeartRate,
            _that.exerciseStrategy,
            _that.exerciseFrequency,
            _that.nutritionStrategy,
            _that.breakingFastTip,
            _that.glucoseStrategy,
            _that.whyThisPlan,
            _that.generatedAt);
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
            String protocol,
            int hydrationGoal,
            int maxHeartRate,
            String exerciseStrategy,
            String exerciseFrequency,
            String nutritionStrategy,
            String breakingFastTip,
            String? glucoseStrategy,
            String whyThisPlan,
            DateTime generatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HealthPlan():
        return $default(
            _that.protocol,
            _that.hydrationGoal,
            _that.maxHeartRate,
            _that.exerciseStrategy,
            _that.exerciseFrequency,
            _that.nutritionStrategy,
            _that.breakingFastTip,
            _that.glucoseStrategy,
            _that.whyThisPlan,
            _that.generatedAt);
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
            String protocol,
            int hydrationGoal,
            int maxHeartRate,
            String exerciseStrategy,
            String exerciseFrequency,
            String nutritionStrategy,
            String breakingFastTip,
            String? glucoseStrategy,
            String whyThisPlan,
            DateTime generatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _HealthPlan() when $default != null:
        return $default(
            _that.protocol,
            _that.hydrationGoal,
            _that.maxHeartRate,
            _that.exerciseStrategy,
            _that.exerciseFrequency,
            _that.nutritionStrategy,
            _that.breakingFastTip,
            _that.glucoseStrategy,
            _that.whyThisPlan,
            _that.generatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _HealthPlan implements HealthPlan {
  const _HealthPlan(
      {required this.protocol,
      required this.hydrationGoal,
      required this.maxHeartRate,
      required this.exerciseStrategy,
      required this.exerciseFrequency,
      required this.nutritionStrategy,
      required this.breakingFastTip,
      this.glucoseStrategy,
      required this.whyThisPlan,
      required this.generatedAt});
  factory _HealthPlan.fromJson(Map<String, dynamic> json) =>
      _$HealthPlanFromJson(json);

  @override
  final String protocol;
  @override
  final int hydrationGoal;
  @override
  final int maxHeartRate;
  @override
  final String exerciseStrategy;
  @override
  final String exerciseFrequency;
  @override
  final String nutritionStrategy;
  @override
  final String breakingFastTip;
  @override
  final String? glucoseStrategy;
  @override
  final String whyThisPlan;
  @override
  final DateTime generatedAt;

  /// Create a copy of HealthPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$HealthPlanCopyWith<_HealthPlan> get copyWith =>
      __$HealthPlanCopyWithImpl<_HealthPlan>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$HealthPlanToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _HealthPlan &&
            (identical(other.protocol, protocol) ||
                other.protocol == protocol) &&
            (identical(other.hydrationGoal, hydrationGoal) ||
                other.hydrationGoal == hydrationGoal) &&
            (identical(other.maxHeartRate, maxHeartRate) ||
                other.maxHeartRate == maxHeartRate) &&
            (identical(other.exerciseStrategy, exerciseStrategy) ||
                other.exerciseStrategy == exerciseStrategy) &&
            (identical(other.exerciseFrequency, exerciseFrequency) ||
                other.exerciseFrequency == exerciseFrequency) &&
            (identical(other.nutritionStrategy, nutritionStrategy) ||
                other.nutritionStrategy == nutritionStrategy) &&
            (identical(other.breakingFastTip, breakingFastTip) ||
                other.breakingFastTip == breakingFastTip) &&
            (identical(other.glucoseStrategy, glucoseStrategy) ||
                other.glucoseStrategy == glucoseStrategy) &&
            (identical(other.whyThisPlan, whyThisPlan) ||
                other.whyThisPlan == whyThisPlan) &&
            (identical(other.generatedAt, generatedAt) ||
                other.generatedAt == generatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      protocol,
      hydrationGoal,
      maxHeartRate,
      exerciseStrategy,
      exerciseFrequency,
      nutritionStrategy,
      breakingFastTip,
      glucoseStrategy,
      whyThisPlan,
      generatedAt);

  @override
  String toString() {
    return 'HealthPlan(protocol: $protocol, hydrationGoal: $hydrationGoal, maxHeartRate: $maxHeartRate, exerciseStrategy: $exerciseStrategy, exerciseFrequency: $exerciseFrequency, nutritionStrategy: $nutritionStrategy, breakingFastTip: $breakingFastTip, glucoseStrategy: $glucoseStrategy, whyThisPlan: $whyThisPlan, generatedAt: $generatedAt)';
  }
}

/// @nodoc
abstract mixin class _$HealthPlanCopyWith<$Res>
    implements $HealthPlanCopyWith<$Res> {
  factory _$HealthPlanCopyWith(
          _HealthPlan value, $Res Function(_HealthPlan) _then) =
      __$HealthPlanCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String protocol,
      int hydrationGoal,
      int maxHeartRate,
      String exerciseStrategy,
      String exerciseFrequency,
      String nutritionStrategy,
      String breakingFastTip,
      String? glucoseStrategy,
      String whyThisPlan,
      DateTime generatedAt});
}

/// @nodoc
class __$HealthPlanCopyWithImpl<$Res> implements _$HealthPlanCopyWith<$Res> {
  __$HealthPlanCopyWithImpl(this._self, this._then);

  final _HealthPlan _self;
  final $Res Function(_HealthPlan) _then;

  /// Create a copy of HealthPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? protocol = null,
    Object? hydrationGoal = null,
    Object? maxHeartRate = null,
    Object? exerciseStrategy = null,
    Object? exerciseFrequency = null,
    Object? nutritionStrategy = null,
    Object? breakingFastTip = null,
    Object? glucoseStrategy = freezed,
    Object? whyThisPlan = null,
    Object? generatedAt = null,
  }) {
    return _then(_HealthPlan(
      protocol: null == protocol
          ? _self.protocol
          : protocol // ignore: cast_nullable_to_non_nullable
              as String,
      hydrationGoal: null == hydrationGoal
          ? _self.hydrationGoal
          : hydrationGoal // ignore: cast_nullable_to_non_nullable
              as int,
      maxHeartRate: null == maxHeartRate
          ? _self.maxHeartRate
          : maxHeartRate // ignore: cast_nullable_to_non_nullable
              as int,
      exerciseStrategy: null == exerciseStrategy
          ? _self.exerciseStrategy
          : exerciseStrategy // ignore: cast_nullable_to_non_nullable
              as String,
      exerciseFrequency: null == exerciseFrequency
          ? _self.exerciseFrequency
          : exerciseFrequency // ignore: cast_nullable_to_non_nullable
              as String,
      nutritionStrategy: null == nutritionStrategy
          ? _self.nutritionStrategy
          : nutritionStrategy // ignore: cast_nullable_to_non_nullable
              as String,
      breakingFastTip: null == breakingFastTip
          ? _self.breakingFastTip
          : breakingFastTip // ignore: cast_nullable_to_non_nullable
              as String,
      glucoseStrategy: freezed == glucoseStrategy
          ? _self.glucoseStrategy
          : glucoseStrategy // ignore: cast_nullable_to_non_nullable
              as String?,
      whyThisPlan: null == whyThisPlan
          ? _self.whyThisPlan
          : whyThisPlan // ignore: cast_nullable_to_non_nullable
              as String,
      generatedAt: null == generatedAt
          ? _self.generatedAt
          : generatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
