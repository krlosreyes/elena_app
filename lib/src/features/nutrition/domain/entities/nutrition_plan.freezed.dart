// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'nutrition_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NutritionPlan {
  String get id;
  String get userId;
  String get algorithmVersion;
  @TimestampConverter()
  DateTime get calculatedAt;
  BaseMetrics get baseMetrics;
  MacroTargets get macroTargets;
  VisualPlate get visualPlate;
  WeeklyAdjustment get weeklyAdjustment;

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NutritionPlanCopyWith<NutritionPlan> get copyWith =>
      _$NutritionPlanCopyWithImpl<NutritionPlan>(
          this as NutritionPlan, _$identity);

  /// Serializes this NutritionPlan to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is NutritionPlan &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.algorithmVersion, algorithmVersion) ||
                other.algorithmVersion == algorithmVersion) &&
            (identical(other.calculatedAt, calculatedAt) ||
                other.calculatedAt == calculatedAt) &&
            (identical(other.baseMetrics, baseMetrics) ||
                other.baseMetrics == baseMetrics) &&
            (identical(other.macroTargets, macroTargets) ||
                other.macroTargets == macroTargets) &&
            (identical(other.visualPlate, visualPlate) ||
                other.visualPlate == visualPlate) &&
            (identical(other.weeklyAdjustment, weeklyAdjustment) ||
                other.weeklyAdjustment == weeklyAdjustment));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, algorithmVersion,
      calculatedAt, baseMetrics, macroTargets, visualPlate, weeklyAdjustment);

  @override
  String toString() {
    return 'NutritionPlan(id: $id, userId: $userId, algorithmVersion: $algorithmVersion, calculatedAt: $calculatedAt, baseMetrics: $baseMetrics, macroTargets: $macroTargets, visualPlate: $visualPlate, weeklyAdjustment: $weeklyAdjustment)';
  }
}

/// @nodoc
abstract mixin class $NutritionPlanCopyWith<$Res> {
  factory $NutritionPlanCopyWith(
          NutritionPlan value, $Res Function(NutritionPlan) _then) =
      _$NutritionPlanCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String userId,
      String algorithmVersion,
      @TimestampConverter() DateTime calculatedAt,
      BaseMetrics baseMetrics,
      MacroTargets macroTargets,
      VisualPlate visualPlate,
      WeeklyAdjustment weeklyAdjustment});

  $BaseMetricsCopyWith<$Res> get baseMetrics;
  $MacroTargetsCopyWith<$Res> get macroTargets;
  $VisualPlateCopyWith<$Res> get visualPlate;
  $WeeklyAdjustmentCopyWith<$Res> get weeklyAdjustment;
}

/// @nodoc
class _$NutritionPlanCopyWithImpl<$Res>
    implements $NutritionPlanCopyWith<$Res> {
  _$NutritionPlanCopyWithImpl(this._self, this._then);

  final NutritionPlan _self;
  final $Res Function(NutritionPlan) _then;

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? algorithmVersion = null,
    Object? calculatedAt = null,
    Object? baseMetrics = null,
    Object? macroTargets = null,
    Object? visualPlate = null,
    Object? weeklyAdjustment = null,
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
      algorithmVersion: null == algorithmVersion
          ? _self.algorithmVersion
          : algorithmVersion // ignore: cast_nullable_to_non_nullable
              as String,
      calculatedAt: null == calculatedAt
          ? _self.calculatedAt
          : calculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      baseMetrics: null == baseMetrics
          ? _self.baseMetrics
          : baseMetrics // ignore: cast_nullable_to_non_nullable
              as BaseMetrics,
      macroTargets: null == macroTargets
          ? _self.macroTargets
          : macroTargets // ignore: cast_nullable_to_non_nullable
              as MacroTargets,
      visualPlate: null == visualPlate
          ? _self.visualPlate
          : visualPlate // ignore: cast_nullable_to_non_nullable
              as VisualPlate,
      weeklyAdjustment: null == weeklyAdjustment
          ? _self.weeklyAdjustment
          : weeklyAdjustment // ignore: cast_nullable_to_non_nullable
              as WeeklyAdjustment,
    ));
  }

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BaseMetricsCopyWith<$Res> get baseMetrics {
    return $BaseMetricsCopyWith<$Res>(_self.baseMetrics, (value) {
      return _then(_self.copyWith(baseMetrics: value));
    });
  }

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MacroTargetsCopyWith<$Res> get macroTargets {
    return $MacroTargetsCopyWith<$Res>(_self.macroTargets, (value) {
      return _then(_self.copyWith(macroTargets: value));
    });
  }

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VisualPlateCopyWith<$Res> get visualPlate {
    return $VisualPlateCopyWith<$Res>(_self.visualPlate, (value) {
      return _then(_self.copyWith(visualPlate: value));
    });
  }

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WeeklyAdjustmentCopyWith<$Res> get weeklyAdjustment {
    return $WeeklyAdjustmentCopyWith<$Res>(_self.weeklyAdjustment, (value) {
      return _then(_self.copyWith(weeklyAdjustment: value));
    });
  }
}

/// Adds pattern-matching-related methods to [NutritionPlan].
extension NutritionPlanPatterns on NutritionPlan {
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
    TResult Function(_NutritionPlan value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NutritionPlan() when $default != null:
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
    TResult Function(_NutritionPlan value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NutritionPlan():
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
    TResult? Function(_NutritionPlan value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NutritionPlan() when $default != null:
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
            String algorithmVersion,
            @TimestampConverter() DateTime calculatedAt,
            BaseMetrics baseMetrics,
            MacroTargets macroTargets,
            VisualPlate visualPlate,
            WeeklyAdjustment weeklyAdjustment)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _NutritionPlan() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.algorithmVersion,
            _that.calculatedAt,
            _that.baseMetrics,
            _that.macroTargets,
            _that.visualPlate,
            _that.weeklyAdjustment);
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
            String algorithmVersion,
            @TimestampConverter() DateTime calculatedAt,
            BaseMetrics baseMetrics,
            MacroTargets macroTargets,
            VisualPlate visualPlate,
            WeeklyAdjustment weeklyAdjustment)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NutritionPlan():
        return $default(
            _that.id,
            _that.userId,
            _that.algorithmVersion,
            _that.calculatedAt,
            _that.baseMetrics,
            _that.macroTargets,
            _that.visualPlate,
            _that.weeklyAdjustment);
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
            String algorithmVersion,
            @TimestampConverter() DateTime calculatedAt,
            BaseMetrics baseMetrics,
            MacroTargets macroTargets,
            VisualPlate visualPlate,
            WeeklyAdjustment weeklyAdjustment)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _NutritionPlan() when $default != null:
        return $default(
            _that.id,
            _that.userId,
            _that.algorithmVersion,
            _that.calculatedAt,
            _that.baseMetrics,
            _that.macroTargets,
            _that.visualPlate,
            _that.weeklyAdjustment);
      case _:
        return null;
    }
  }
}

/// @nodoc

@JsonSerializable(explicitToJson: true)
class _NutritionPlan implements NutritionPlan {
  const _NutritionPlan(
      {required this.id,
      required this.userId,
      this.algorithmVersion = '1.0.0',
      @TimestampConverter() required this.calculatedAt,
      required this.baseMetrics,
      required this.macroTargets,
      required this.visualPlate,
      required this.weeklyAdjustment});
  factory _NutritionPlan.fromJson(Map<String, dynamic> json) =>
      _$NutritionPlanFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  @JsonKey()
  final String algorithmVersion;
  @override
  @TimestampConverter()
  final DateTime calculatedAt;
  @override
  final BaseMetrics baseMetrics;
  @override
  final MacroTargets macroTargets;
  @override
  final VisualPlate visualPlate;
  @override
  final WeeklyAdjustment weeklyAdjustment;

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$NutritionPlanCopyWith<_NutritionPlan> get copyWith =>
      __$NutritionPlanCopyWithImpl<_NutritionPlan>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$NutritionPlanToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _NutritionPlan &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.algorithmVersion, algorithmVersion) ||
                other.algorithmVersion == algorithmVersion) &&
            (identical(other.calculatedAt, calculatedAt) ||
                other.calculatedAt == calculatedAt) &&
            (identical(other.baseMetrics, baseMetrics) ||
                other.baseMetrics == baseMetrics) &&
            (identical(other.macroTargets, macroTargets) ||
                other.macroTargets == macroTargets) &&
            (identical(other.visualPlate, visualPlate) ||
                other.visualPlate == visualPlate) &&
            (identical(other.weeklyAdjustment, weeklyAdjustment) ||
                other.weeklyAdjustment == weeklyAdjustment));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, algorithmVersion,
      calculatedAt, baseMetrics, macroTargets, visualPlate, weeklyAdjustment);

  @override
  String toString() {
    return 'NutritionPlan(id: $id, userId: $userId, algorithmVersion: $algorithmVersion, calculatedAt: $calculatedAt, baseMetrics: $baseMetrics, macroTargets: $macroTargets, visualPlate: $visualPlate, weeklyAdjustment: $weeklyAdjustment)';
  }
}

/// @nodoc
abstract mixin class _$NutritionPlanCopyWith<$Res>
    implements $NutritionPlanCopyWith<$Res> {
  factory _$NutritionPlanCopyWith(
          _NutritionPlan value, $Res Function(_NutritionPlan) _then) =
      __$NutritionPlanCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String algorithmVersion,
      @TimestampConverter() DateTime calculatedAt,
      BaseMetrics baseMetrics,
      MacroTargets macroTargets,
      VisualPlate visualPlate,
      WeeklyAdjustment weeklyAdjustment});

  @override
  $BaseMetricsCopyWith<$Res> get baseMetrics;
  @override
  $MacroTargetsCopyWith<$Res> get macroTargets;
  @override
  $VisualPlateCopyWith<$Res> get visualPlate;
  @override
  $WeeklyAdjustmentCopyWith<$Res> get weeklyAdjustment;
}

/// @nodoc
class __$NutritionPlanCopyWithImpl<$Res>
    implements _$NutritionPlanCopyWith<$Res> {
  __$NutritionPlanCopyWithImpl(this._self, this._then);

  final _NutritionPlan _self;
  final $Res Function(_NutritionPlan) _then;

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? algorithmVersion = null,
    Object? calculatedAt = null,
    Object? baseMetrics = null,
    Object? macroTargets = null,
    Object? visualPlate = null,
    Object? weeklyAdjustment = null,
  }) {
    return _then(_NutritionPlan(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _self.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      algorithmVersion: null == algorithmVersion
          ? _self.algorithmVersion
          : algorithmVersion // ignore: cast_nullable_to_non_nullable
              as String,
      calculatedAt: null == calculatedAt
          ? _self.calculatedAt
          : calculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
      baseMetrics: null == baseMetrics
          ? _self.baseMetrics
          : baseMetrics // ignore: cast_nullable_to_non_nullable
              as BaseMetrics,
      macroTargets: null == macroTargets
          ? _self.macroTargets
          : macroTargets // ignore: cast_nullable_to_non_nullable
              as MacroTargets,
      visualPlate: null == visualPlate
          ? _self.visualPlate
          : visualPlate // ignore: cast_nullable_to_non_nullable
              as VisualPlate,
      weeklyAdjustment: null == weeklyAdjustment
          ? _self.weeklyAdjustment
          : weeklyAdjustment // ignore: cast_nullable_to_non_nullable
              as WeeklyAdjustment,
    ));
  }

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BaseMetricsCopyWith<$Res> get baseMetrics {
    return $BaseMetricsCopyWith<$Res>(_self.baseMetrics, (value) {
      return _then(_self.copyWith(baseMetrics: value));
    });
  }

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MacroTargetsCopyWith<$Res> get macroTargets {
    return $MacroTargetsCopyWith<$Res>(_self.macroTargets, (value) {
      return _then(_self.copyWith(macroTargets: value));
    });
  }

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VisualPlateCopyWith<$Res> get visualPlate {
    return $VisualPlateCopyWith<$Res>(_self.visualPlate, (value) {
      return _then(_self.copyWith(visualPlate: value));
    });
  }

  /// Create a copy of NutritionPlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $WeeklyAdjustmentCopyWith<$Res> get weeklyAdjustment {
    return $WeeklyAdjustmentCopyWith<$Res>(_self.weeklyAdjustment, (value) {
      return _then(_self.copyWith(weeklyAdjustment: value));
    });
  }
}

/// @nodoc
mixin _$BaseMetrics {
  double get weightKg;
  double get bodyFatPercentage;
  double get fatFreeMassKg;
  double get bmr;
  double get tdee;
  double get activityMultiplier;

  /// Create a copy of BaseMetrics
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BaseMetricsCopyWith<BaseMetrics> get copyWith =>
      _$BaseMetricsCopyWithImpl<BaseMetrics>(this as BaseMetrics, _$identity);

  /// Serializes this BaseMetrics to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BaseMetrics &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.bodyFatPercentage, bodyFatPercentage) ||
                other.bodyFatPercentage == bodyFatPercentage) &&
            (identical(other.fatFreeMassKg, fatFreeMassKg) ||
                other.fatFreeMassKg == fatFreeMassKg) &&
            (identical(other.bmr, bmr) || other.bmr == bmr) &&
            (identical(other.tdee, tdee) || other.tdee == tdee) &&
            (identical(other.activityMultiplier, activityMultiplier) ||
                other.activityMultiplier == activityMultiplier));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, weightKg, bodyFatPercentage,
      fatFreeMassKg, bmr, tdee, activityMultiplier);

  @override
  String toString() {
    return 'BaseMetrics(weightKg: $weightKg, bodyFatPercentage: $bodyFatPercentage, fatFreeMassKg: $fatFreeMassKg, bmr: $bmr, tdee: $tdee, activityMultiplier: $activityMultiplier)';
  }
}

/// @nodoc
abstract mixin class $BaseMetricsCopyWith<$Res> {
  factory $BaseMetricsCopyWith(
          BaseMetrics value, $Res Function(BaseMetrics) _then) =
      _$BaseMetricsCopyWithImpl;
  @useResult
  $Res call(
      {double weightKg,
      double bodyFatPercentage,
      double fatFreeMassKg,
      double bmr,
      double tdee,
      double activityMultiplier});
}

/// @nodoc
class _$BaseMetricsCopyWithImpl<$Res> implements $BaseMetricsCopyWith<$Res> {
  _$BaseMetricsCopyWithImpl(this._self, this._then);

  final BaseMetrics _self;
  final $Res Function(BaseMetrics) _then;

  /// Create a copy of BaseMetrics
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weightKg = null,
    Object? bodyFatPercentage = null,
    Object? fatFreeMassKg = null,
    Object? bmr = null,
    Object? tdee = null,
    Object? activityMultiplier = null,
  }) {
    return _then(_self.copyWith(
      weightKg: null == weightKg
          ? _self.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double,
      bodyFatPercentage: null == bodyFatPercentage
          ? _self.bodyFatPercentage
          : bodyFatPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      fatFreeMassKg: null == fatFreeMassKg
          ? _self.fatFreeMassKg
          : fatFreeMassKg // ignore: cast_nullable_to_non_nullable
              as double,
      bmr: null == bmr
          ? _self.bmr
          : bmr // ignore: cast_nullable_to_non_nullable
              as double,
      tdee: null == tdee
          ? _self.tdee
          : tdee // ignore: cast_nullable_to_non_nullable
              as double,
      activityMultiplier: null == activityMultiplier
          ? _self.activityMultiplier
          : activityMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// Adds pattern-matching-related methods to [BaseMetrics].
extension BaseMetricsPatterns on BaseMetrics {
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
    TResult Function(_BaseMetrics value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BaseMetrics() when $default != null:
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
    TResult Function(_BaseMetrics value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BaseMetrics():
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
    TResult? Function(_BaseMetrics value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BaseMetrics() when $default != null:
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
            double weightKg,
            double bodyFatPercentage,
            double fatFreeMassKg,
            double bmr,
            double tdee,
            double activityMultiplier)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BaseMetrics() when $default != null:
        return $default(
            _that.weightKg,
            _that.bodyFatPercentage,
            _that.fatFreeMassKg,
            _that.bmr,
            _that.tdee,
            _that.activityMultiplier);
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
            double weightKg,
            double bodyFatPercentage,
            double fatFreeMassKg,
            double bmr,
            double tdee,
            double activityMultiplier)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BaseMetrics():
        return $default(
            _that.weightKg,
            _that.bodyFatPercentage,
            _that.fatFreeMassKg,
            _that.bmr,
            _that.tdee,
            _that.activityMultiplier);
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
            double weightKg,
            double bodyFatPercentage,
            double fatFreeMassKg,
            double bmr,
            double tdee,
            double activityMultiplier)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BaseMetrics() when $default != null:
        return $default(
            _that.weightKg,
            _that.bodyFatPercentage,
            _that.fatFreeMassKg,
            _that.bmr,
            _that.tdee,
            _that.activityMultiplier);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _BaseMetrics implements BaseMetrics {
  const _BaseMetrics(
      {required this.weightKg,
      required this.bodyFatPercentage,
      required this.fatFreeMassKg,
      required this.bmr,
      required this.tdee,
      required this.activityMultiplier});
  factory _BaseMetrics.fromJson(Map<String, dynamic> json) =>
      _$BaseMetricsFromJson(json);

  @override
  final double weightKg;
  @override
  final double bodyFatPercentage;
  @override
  final double fatFreeMassKg;
  @override
  final double bmr;
  @override
  final double tdee;
  @override
  final double activityMultiplier;

  /// Create a copy of BaseMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BaseMetricsCopyWith<_BaseMetrics> get copyWith =>
      __$BaseMetricsCopyWithImpl<_BaseMetrics>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BaseMetricsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BaseMetrics &&
            (identical(other.weightKg, weightKg) ||
                other.weightKg == weightKg) &&
            (identical(other.bodyFatPercentage, bodyFatPercentage) ||
                other.bodyFatPercentage == bodyFatPercentage) &&
            (identical(other.fatFreeMassKg, fatFreeMassKg) ||
                other.fatFreeMassKg == fatFreeMassKg) &&
            (identical(other.bmr, bmr) || other.bmr == bmr) &&
            (identical(other.tdee, tdee) || other.tdee == tdee) &&
            (identical(other.activityMultiplier, activityMultiplier) ||
                other.activityMultiplier == activityMultiplier));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, weightKg, bodyFatPercentage,
      fatFreeMassKg, bmr, tdee, activityMultiplier);

  @override
  String toString() {
    return 'BaseMetrics(weightKg: $weightKg, bodyFatPercentage: $bodyFatPercentage, fatFreeMassKg: $fatFreeMassKg, bmr: $bmr, tdee: $tdee, activityMultiplier: $activityMultiplier)';
  }
}

/// @nodoc
abstract mixin class _$BaseMetricsCopyWith<$Res>
    implements $BaseMetricsCopyWith<$Res> {
  factory _$BaseMetricsCopyWith(
          _BaseMetrics value, $Res Function(_BaseMetrics) _then) =
      __$BaseMetricsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double weightKg,
      double bodyFatPercentage,
      double fatFreeMassKg,
      double bmr,
      double tdee,
      double activityMultiplier});
}

/// @nodoc
class __$BaseMetricsCopyWithImpl<$Res> implements _$BaseMetricsCopyWith<$Res> {
  __$BaseMetricsCopyWithImpl(this._self, this._then);

  final _BaseMetrics _self;
  final $Res Function(_BaseMetrics) _then;

  /// Create a copy of BaseMetrics
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? weightKg = null,
    Object? bodyFatPercentage = null,
    Object? fatFreeMassKg = null,
    Object? bmr = null,
    Object? tdee = null,
    Object? activityMultiplier = null,
  }) {
    return _then(_BaseMetrics(
      weightKg: null == weightKg
          ? _self.weightKg
          : weightKg // ignore: cast_nullable_to_non_nullable
              as double,
      bodyFatPercentage: null == bodyFatPercentage
          ? _self.bodyFatPercentage
          : bodyFatPercentage // ignore: cast_nullable_to_non_nullable
              as double,
      fatFreeMassKg: null == fatFreeMassKg
          ? _self.fatFreeMassKg
          : fatFreeMassKg // ignore: cast_nullable_to_non_nullable
              as double,
      bmr: null == bmr
          ? _self.bmr
          : bmr // ignore: cast_nullable_to_non_nullable
              as double,
      tdee: null == tdee
          ? _self.tdee
          : tdee // ignore: cast_nullable_to_non_nullable
              as double,
      activityMultiplier: null == activityMultiplier
          ? _self.activityMultiplier
          : activityMultiplier // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
mixin _$MacroTargets {
  int get totalCalories;
  int get proteinGrams;
  int get fatGrams;
  int get carbsGrams;

  /// Create a copy of MacroTargets
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MacroTargetsCopyWith<MacroTargets> get copyWith =>
      _$MacroTargetsCopyWithImpl<MacroTargets>(
          this as MacroTargets, _$identity);

  /// Serializes this MacroTargets to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MacroTargets &&
            (identical(other.totalCalories, totalCalories) ||
                other.totalCalories == totalCalories) &&
            (identical(other.proteinGrams, proteinGrams) ||
                other.proteinGrams == proteinGrams) &&
            (identical(other.fatGrams, fatGrams) ||
                other.fatGrams == fatGrams) &&
            (identical(other.carbsGrams, carbsGrams) ||
                other.carbsGrams == carbsGrams));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, totalCalories, proteinGrams, fatGrams, carbsGrams);

  @override
  String toString() {
    return 'MacroTargets(totalCalories: $totalCalories, proteinGrams: $proteinGrams, fatGrams: $fatGrams, carbsGrams: $carbsGrams)';
  }
}

/// @nodoc
abstract mixin class $MacroTargetsCopyWith<$Res> {
  factory $MacroTargetsCopyWith(
          MacroTargets value, $Res Function(MacroTargets) _then) =
      _$MacroTargetsCopyWithImpl;
  @useResult
  $Res call(
      {int totalCalories, int proteinGrams, int fatGrams, int carbsGrams});
}

/// @nodoc
class _$MacroTargetsCopyWithImpl<$Res> implements $MacroTargetsCopyWith<$Res> {
  _$MacroTargetsCopyWithImpl(this._self, this._then);

  final MacroTargets _self;
  final $Res Function(MacroTargets) _then;

  /// Create a copy of MacroTargets
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? totalCalories = null,
    Object? proteinGrams = null,
    Object? fatGrams = null,
    Object? carbsGrams = null,
  }) {
    return _then(_self.copyWith(
      totalCalories: null == totalCalories
          ? _self.totalCalories
          : totalCalories // ignore: cast_nullable_to_non_nullable
              as int,
      proteinGrams: null == proteinGrams
          ? _self.proteinGrams
          : proteinGrams // ignore: cast_nullable_to_non_nullable
              as int,
      fatGrams: null == fatGrams
          ? _self.fatGrams
          : fatGrams // ignore: cast_nullable_to_non_nullable
              as int,
      carbsGrams: null == carbsGrams
          ? _self.carbsGrams
          : carbsGrams // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [MacroTargets].
extension MacroTargetsPatterns on MacroTargets {
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
    TResult Function(_MacroTargets value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MacroTargets() when $default != null:
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
    TResult Function(_MacroTargets value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MacroTargets():
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
    TResult? Function(_MacroTargets value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MacroTargets() when $default != null:
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
            int totalCalories, int proteinGrams, int fatGrams, int carbsGrams)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MacroTargets() when $default != null:
        return $default(_that.totalCalories, _that.proteinGrams, _that.fatGrams,
            _that.carbsGrams);
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
            int totalCalories, int proteinGrams, int fatGrams, int carbsGrams)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MacroTargets():
        return $default(_that.totalCalories, _that.proteinGrams, _that.fatGrams,
            _that.carbsGrams);
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
            int totalCalories, int proteinGrams, int fatGrams, int carbsGrams)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MacroTargets() when $default != null:
        return $default(_that.totalCalories, _that.proteinGrams, _that.fatGrams,
            _that.carbsGrams);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MacroTargets implements MacroTargets {
  const _MacroTargets(
      {required this.totalCalories,
      required this.proteinGrams,
      required this.fatGrams,
      required this.carbsGrams});
  factory _MacroTargets.fromJson(Map<String, dynamic> json) =>
      _$MacroTargetsFromJson(json);

  @override
  final int totalCalories;
  @override
  final int proteinGrams;
  @override
  final int fatGrams;
  @override
  final int carbsGrams;

  /// Create a copy of MacroTargets
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MacroTargetsCopyWith<_MacroTargets> get copyWith =>
      __$MacroTargetsCopyWithImpl<_MacroTargets>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MacroTargetsToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MacroTargets &&
            (identical(other.totalCalories, totalCalories) ||
                other.totalCalories == totalCalories) &&
            (identical(other.proteinGrams, proteinGrams) ||
                other.proteinGrams == proteinGrams) &&
            (identical(other.fatGrams, fatGrams) ||
                other.fatGrams == fatGrams) &&
            (identical(other.carbsGrams, carbsGrams) ||
                other.carbsGrams == carbsGrams));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, totalCalories, proteinGrams, fatGrams, carbsGrams);

  @override
  String toString() {
    return 'MacroTargets(totalCalories: $totalCalories, proteinGrams: $proteinGrams, fatGrams: $fatGrams, carbsGrams: $carbsGrams)';
  }
}

/// @nodoc
abstract mixin class _$MacroTargetsCopyWith<$Res>
    implements $MacroTargetsCopyWith<$Res> {
  factory _$MacroTargetsCopyWith(
          _MacroTargets value, $Res Function(_MacroTargets) _then) =
      __$MacroTargetsCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int totalCalories, int proteinGrams, int fatGrams, int carbsGrams});
}

/// @nodoc
class __$MacroTargetsCopyWithImpl<$Res>
    implements _$MacroTargetsCopyWith<$Res> {
  __$MacroTargetsCopyWithImpl(this._self, this._then);

  final _MacroTargets _self;
  final $Res Function(_MacroTargets) _then;

  /// Create a copy of MacroTargets
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? totalCalories = null,
    Object? proteinGrams = null,
    Object? fatGrams = null,
    Object? carbsGrams = null,
  }) {
    return _then(_MacroTargets(
      totalCalories: null == totalCalories
          ? _self.totalCalories
          : totalCalories // ignore: cast_nullable_to_non_nullable
              as int,
      proteinGrams: null == proteinGrams
          ? _self.proteinGrams
          : proteinGrams // ignore: cast_nullable_to_non_nullable
              as int,
      fatGrams: null == fatGrams
          ? _self.fatGrams
          : fatGrams // ignore: cast_nullable_to_non_nullable
              as int,
      carbsGrams: null == carbsGrams
          ? _self.carbsGrams
          : carbsGrams // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
mixin _$VisualPlate {
  double get vegetablesPercent;
  double get proteinPercent;
  double get carbsPercent;
  String get carbsType;

  /// Create a copy of VisualPlate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $VisualPlateCopyWith<VisualPlate> get copyWith =>
      _$VisualPlateCopyWithImpl<VisualPlate>(this as VisualPlate, _$identity);

  /// Serializes this VisualPlate to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is VisualPlate &&
            (identical(other.vegetablesPercent, vegetablesPercent) ||
                other.vegetablesPercent == vegetablesPercent) &&
            (identical(other.proteinPercent, proteinPercent) ||
                other.proteinPercent == proteinPercent) &&
            (identical(other.carbsPercent, carbsPercent) ||
                other.carbsPercent == carbsPercent) &&
            (identical(other.carbsType, carbsType) ||
                other.carbsType == carbsType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, vegetablesPercent, proteinPercent, carbsPercent, carbsType);

  @override
  String toString() {
    return 'VisualPlate(vegetablesPercent: $vegetablesPercent, proteinPercent: $proteinPercent, carbsPercent: $carbsPercent, carbsType: $carbsType)';
  }
}

/// @nodoc
abstract mixin class $VisualPlateCopyWith<$Res> {
  factory $VisualPlateCopyWith(
          VisualPlate value, $Res Function(VisualPlate) _then) =
      _$VisualPlateCopyWithImpl;
  @useResult
  $Res call(
      {double vegetablesPercent,
      double proteinPercent,
      double carbsPercent,
      String carbsType});
}

/// @nodoc
class _$VisualPlateCopyWithImpl<$Res> implements $VisualPlateCopyWith<$Res> {
  _$VisualPlateCopyWithImpl(this._self, this._then);

  final VisualPlate _self;
  final $Res Function(VisualPlate) _then;

  /// Create a copy of VisualPlate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? vegetablesPercent = null,
    Object? proteinPercent = null,
    Object? carbsPercent = null,
    Object? carbsType = null,
  }) {
    return _then(_self.copyWith(
      vegetablesPercent: null == vegetablesPercent
          ? _self.vegetablesPercent
          : vegetablesPercent // ignore: cast_nullable_to_non_nullable
              as double,
      proteinPercent: null == proteinPercent
          ? _self.proteinPercent
          : proteinPercent // ignore: cast_nullable_to_non_nullable
              as double,
      carbsPercent: null == carbsPercent
          ? _self.carbsPercent
          : carbsPercent // ignore: cast_nullable_to_non_nullable
              as double,
      carbsType: null == carbsType
          ? _self.carbsType
          : carbsType // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [VisualPlate].
extension VisualPlatePatterns on VisualPlate {
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
    TResult Function(_VisualPlate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _VisualPlate() when $default != null:
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
    TResult Function(_VisualPlate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VisualPlate():
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
    TResult? Function(_VisualPlate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VisualPlate() when $default != null:
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
    TResult Function(double vegetablesPercent, double proteinPercent,
            double carbsPercent, String carbsType)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _VisualPlate() when $default != null:
        return $default(_that.vegetablesPercent, _that.proteinPercent,
            _that.carbsPercent, _that.carbsType);
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
    TResult Function(double vegetablesPercent, double proteinPercent,
            double carbsPercent, String carbsType)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VisualPlate():
        return $default(_that.vegetablesPercent, _that.proteinPercent,
            _that.carbsPercent, _that.carbsType);
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
    TResult? Function(double vegetablesPercent, double proteinPercent,
            double carbsPercent, String carbsType)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VisualPlate() when $default != null:
        return $default(_that.vegetablesPercent, _that.proteinPercent,
            _that.carbsPercent, _that.carbsType);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _VisualPlate implements VisualPlate {
  const _VisualPlate(
      {required this.vegetablesPercent,
      required this.proteinPercent,
      required this.carbsPercent,
      required this.carbsType});
  factory _VisualPlate.fromJson(Map<String, dynamic> json) =>
      _$VisualPlateFromJson(json);

  @override
  final double vegetablesPercent;
  @override
  final double proteinPercent;
  @override
  final double carbsPercent;
  @override
  final String carbsType;

  /// Create a copy of VisualPlate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$VisualPlateCopyWith<_VisualPlate> get copyWith =>
      __$VisualPlateCopyWithImpl<_VisualPlate>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$VisualPlateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _VisualPlate &&
            (identical(other.vegetablesPercent, vegetablesPercent) ||
                other.vegetablesPercent == vegetablesPercent) &&
            (identical(other.proteinPercent, proteinPercent) ||
                other.proteinPercent == proteinPercent) &&
            (identical(other.carbsPercent, carbsPercent) ||
                other.carbsPercent == carbsPercent) &&
            (identical(other.carbsType, carbsType) ||
                other.carbsType == carbsType));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, vegetablesPercent, proteinPercent, carbsPercent, carbsType);

  @override
  String toString() {
    return 'VisualPlate(vegetablesPercent: $vegetablesPercent, proteinPercent: $proteinPercent, carbsPercent: $carbsPercent, carbsType: $carbsType)';
  }
}

/// @nodoc
abstract mixin class _$VisualPlateCopyWith<$Res>
    implements $VisualPlateCopyWith<$Res> {
  factory _$VisualPlateCopyWith(
          _VisualPlate value, $Res Function(_VisualPlate) _then) =
      __$VisualPlateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {double vegetablesPercent,
      double proteinPercent,
      double carbsPercent,
      String carbsType});
}

/// @nodoc
class __$VisualPlateCopyWithImpl<$Res> implements _$VisualPlateCopyWith<$Res> {
  __$VisualPlateCopyWithImpl(this._self, this._then);

  final _VisualPlate _self;
  final $Res Function(_VisualPlate) _then;

  /// Create a copy of VisualPlate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? vegetablesPercent = null,
    Object? proteinPercent = null,
    Object? carbsPercent = null,
    Object? carbsType = null,
  }) {
    return _then(_VisualPlate(
      vegetablesPercent: null == vegetablesPercent
          ? _self.vegetablesPercent
          : vegetablesPercent // ignore: cast_nullable_to_non_nullable
              as double,
      proteinPercent: null == proteinPercent
          ? _self.proteinPercent
          : proteinPercent // ignore: cast_nullable_to_non_nullable
              as double,
      carbsPercent: null == carbsPercent
          ? _self.carbsPercent
          : carbsPercent // ignore: cast_nullable_to_non_nullable
              as double,
      carbsType: null == carbsType
          ? _self.carbsType
          : carbsType // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$WeeklyAdjustment {
  bool get isAdjusted;
  @TimestampConverter()
  DateTime? get lastAdjustmentDate;
  String? get adjustmentReason;

  /// Create a copy of WeeklyAdjustment
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WeeklyAdjustmentCopyWith<WeeklyAdjustment> get copyWith =>
      _$WeeklyAdjustmentCopyWithImpl<WeeklyAdjustment>(
          this as WeeklyAdjustment, _$identity);

  /// Serializes this WeeklyAdjustment to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WeeklyAdjustment &&
            (identical(other.isAdjusted, isAdjusted) ||
                other.isAdjusted == isAdjusted) &&
            (identical(other.lastAdjustmentDate, lastAdjustmentDate) ||
                other.lastAdjustmentDate == lastAdjustmentDate) &&
            (identical(other.adjustmentReason, adjustmentReason) ||
                other.adjustmentReason == adjustmentReason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, isAdjusted, lastAdjustmentDate, adjustmentReason);

  @override
  String toString() {
    return 'WeeklyAdjustment(isAdjusted: $isAdjusted, lastAdjustmentDate: $lastAdjustmentDate, adjustmentReason: $adjustmentReason)';
  }
}

/// @nodoc
abstract mixin class $WeeklyAdjustmentCopyWith<$Res> {
  factory $WeeklyAdjustmentCopyWith(
          WeeklyAdjustment value, $Res Function(WeeklyAdjustment) _then) =
      _$WeeklyAdjustmentCopyWithImpl;
  @useResult
  $Res call(
      {bool isAdjusted,
      @TimestampConverter() DateTime? lastAdjustmentDate,
      String? adjustmentReason});
}

/// @nodoc
class _$WeeklyAdjustmentCopyWithImpl<$Res>
    implements $WeeklyAdjustmentCopyWith<$Res> {
  _$WeeklyAdjustmentCopyWithImpl(this._self, this._then);

  final WeeklyAdjustment _self;
  final $Res Function(WeeklyAdjustment) _then;

  /// Create a copy of WeeklyAdjustment
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isAdjusted = null,
    Object? lastAdjustmentDate = freezed,
    Object? adjustmentReason = freezed,
  }) {
    return _then(_self.copyWith(
      isAdjusted: null == isAdjusted
          ? _self.isAdjusted
          : isAdjusted // ignore: cast_nullable_to_non_nullable
              as bool,
      lastAdjustmentDate: freezed == lastAdjustmentDate
          ? _self.lastAdjustmentDate
          : lastAdjustmentDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      adjustmentReason: freezed == adjustmentReason
          ? _self.adjustmentReason
          : adjustmentReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [WeeklyAdjustment].
extension WeeklyAdjustmentPatterns on WeeklyAdjustment {
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
    TResult Function(_WeeklyAdjustment value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WeeklyAdjustment() when $default != null:
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
    TResult Function(_WeeklyAdjustment value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WeeklyAdjustment():
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
    TResult? Function(_WeeklyAdjustment value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WeeklyAdjustment() when $default != null:
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
            bool isAdjusted,
            @TimestampConverter() DateTime? lastAdjustmentDate,
            String? adjustmentReason)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WeeklyAdjustment() when $default != null:
        return $default(
            _that.isAdjusted, _that.lastAdjustmentDate, _that.adjustmentReason);
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
            bool isAdjusted,
            @TimestampConverter() DateTime? lastAdjustmentDate,
            String? adjustmentReason)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WeeklyAdjustment():
        return $default(
            _that.isAdjusted, _that.lastAdjustmentDate, _that.adjustmentReason);
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
            bool isAdjusted,
            @TimestampConverter() DateTime? lastAdjustmentDate,
            String? adjustmentReason)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WeeklyAdjustment() when $default != null:
        return $default(
            _that.isAdjusted, _that.lastAdjustmentDate, _that.adjustmentReason);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WeeklyAdjustment implements WeeklyAdjustment {
  const _WeeklyAdjustment(
      {this.isAdjusted = false,
      @TimestampConverter() this.lastAdjustmentDate,
      this.adjustmentReason});
  factory _WeeklyAdjustment.fromJson(Map<String, dynamic> json) =>
      _$WeeklyAdjustmentFromJson(json);

  @override
  @JsonKey()
  final bool isAdjusted;
  @override
  @TimestampConverter()
  final DateTime? lastAdjustmentDate;
  @override
  final String? adjustmentReason;

  /// Create a copy of WeeklyAdjustment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WeeklyAdjustmentCopyWith<_WeeklyAdjustment> get copyWith =>
      __$WeeklyAdjustmentCopyWithImpl<_WeeklyAdjustment>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WeeklyAdjustmentToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WeeklyAdjustment &&
            (identical(other.isAdjusted, isAdjusted) ||
                other.isAdjusted == isAdjusted) &&
            (identical(other.lastAdjustmentDate, lastAdjustmentDate) ||
                other.lastAdjustmentDate == lastAdjustmentDate) &&
            (identical(other.adjustmentReason, adjustmentReason) ||
                other.adjustmentReason == adjustmentReason));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, isAdjusted, lastAdjustmentDate, adjustmentReason);

  @override
  String toString() {
    return 'WeeklyAdjustment(isAdjusted: $isAdjusted, lastAdjustmentDate: $lastAdjustmentDate, adjustmentReason: $adjustmentReason)';
  }
}

/// @nodoc
abstract mixin class _$WeeklyAdjustmentCopyWith<$Res>
    implements $WeeklyAdjustmentCopyWith<$Res> {
  factory _$WeeklyAdjustmentCopyWith(
          _WeeklyAdjustment value, $Res Function(_WeeklyAdjustment) _then) =
      __$WeeklyAdjustmentCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool isAdjusted,
      @TimestampConverter() DateTime? lastAdjustmentDate,
      String? adjustmentReason});
}

/// @nodoc
class __$WeeklyAdjustmentCopyWithImpl<$Res>
    implements _$WeeklyAdjustmentCopyWith<$Res> {
  __$WeeklyAdjustmentCopyWithImpl(this._self, this._then);

  final _WeeklyAdjustment _self;
  final $Res Function(_WeeklyAdjustment) _then;

  /// Create a copy of WeeklyAdjustment
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? isAdjusted = null,
    Object? lastAdjustmentDate = freezed,
    Object? adjustmentReason = freezed,
  }) {
    return _then(_WeeklyAdjustment(
      isAdjusted: null == isAdjusted
          ? _self.isAdjusted
          : isAdjusted // ignore: cast_nullable_to_non_nullable
              as bool,
      lastAdjustmentDate: freezed == lastAdjustmentDate
          ? _self.lastAdjustmentDate
          : lastAdjustmentDate // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      adjustmentReason: freezed == adjustmentReason
          ? _self.adjustmentReason
          : adjustmentReason // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
