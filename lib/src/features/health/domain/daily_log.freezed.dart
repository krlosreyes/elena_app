// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DailyLog {
  String get id;
  int get waterGlasses;
  int get calories;
  int get proteinGrams;
  int get carbsGrams;
  int get fatGrams;
  int get exerciseMinutes;
  int get sleepMinutes;
  @OptionalTimestampConverter()
  DateTime? get fastingStartTime;
  @OptionalTimestampConverter()
  DateTime? get fastingEndTime;
  @JsonKey(name: 'mtiScore')
  double get imrScore;
  List<Map<String, dynamic>> get mealEntries;
  List<Map<String, dynamic>> get exerciseEntries;

  /// Create a copy of DailyLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $DailyLogCopyWith<DailyLog> get copyWith =>
      _$DailyLogCopyWithImpl<DailyLog>(this as DailyLog, _$identity);

  /// Serializes this DailyLog to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is DailyLog &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.waterGlasses, waterGlasses) ||
                other.waterGlasses == waterGlasses) &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.proteinGrams, proteinGrams) ||
                other.proteinGrams == proteinGrams) &&
            (identical(other.carbsGrams, carbsGrams) ||
                other.carbsGrams == carbsGrams) &&
            (identical(other.fatGrams, fatGrams) ||
                other.fatGrams == fatGrams) &&
            (identical(other.exerciseMinutes, exerciseMinutes) ||
                other.exerciseMinutes == exerciseMinutes) &&
            (identical(other.sleepMinutes, sleepMinutes) ||
                other.sleepMinutes == sleepMinutes) &&
            (identical(other.fastingStartTime, fastingStartTime) ||
                other.fastingStartTime == fastingStartTime) &&
            (identical(other.fastingEndTime, fastingEndTime) ||
                other.fastingEndTime == fastingEndTime) &&
            (identical(other.imrScore, imrScore) ||
                other.imrScore == imrScore) &&
            const DeepCollectionEquality()
                .equals(other.mealEntries, mealEntries) &&
            const DeepCollectionEquality()
                .equals(other.exerciseEntries, exerciseEntries));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      waterGlasses,
      calories,
      proteinGrams,
      carbsGrams,
      fatGrams,
      exerciseMinutes,
      sleepMinutes,
      fastingStartTime,
      fastingEndTime,
      imrScore,
      const DeepCollectionEquality().hash(mealEntries),
      const DeepCollectionEquality().hash(exerciseEntries));

  @override
  String toString() {
    return 'DailyLog(id: $id, waterGlasses: $waterGlasses, calories: $calories, proteinGrams: $proteinGrams, carbsGrams: $carbsGrams, fatGrams: $fatGrams, exerciseMinutes: $exerciseMinutes, sleepMinutes: $sleepMinutes, fastingStartTime: $fastingStartTime, fastingEndTime: $fastingEndTime, imrScore: $imrScore, mealEntries: $mealEntries, exerciseEntries: $exerciseEntries)';
  }
}

/// @nodoc
abstract mixin class $DailyLogCopyWith<$Res> {
  factory $DailyLogCopyWith(DailyLog value, $Res Function(DailyLog) _then) =
      _$DailyLogCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      int waterGlasses,
      int calories,
      int proteinGrams,
      int carbsGrams,
      int fatGrams,
      int exerciseMinutes,
      int sleepMinutes,
      @OptionalTimestampConverter() DateTime? fastingStartTime,
      @OptionalTimestampConverter() DateTime? fastingEndTime,
      @JsonKey(name: 'mtiScore') double imrScore,
      List<Map<String, dynamic>> mealEntries,
      List<Map<String, dynamic>> exerciseEntries});
}

/// @nodoc
class _$DailyLogCopyWithImpl<$Res> implements $DailyLogCopyWith<$Res> {
  _$DailyLogCopyWithImpl(this._self, this._then);

  final DailyLog _self;
  final $Res Function(DailyLog) _then;

  /// Create a copy of DailyLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? waterGlasses = null,
    Object? calories = null,
    Object? proteinGrams = null,
    Object? carbsGrams = null,
    Object? fatGrams = null,
    Object? exerciseMinutes = null,
    Object? sleepMinutes = null,
    Object? fastingStartTime = freezed,
    Object? fastingEndTime = freezed,
    Object? imrScore = null,
    Object? mealEntries = null,
    Object? exerciseEntries = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      waterGlasses: null == waterGlasses
          ? _self.waterGlasses
          : waterGlasses // ignore: cast_nullable_to_non_nullable
              as int,
      calories: null == calories
          ? _self.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int,
      proteinGrams: null == proteinGrams
          ? _self.proteinGrams
          : proteinGrams // ignore: cast_nullable_to_non_nullable
              as int,
      carbsGrams: null == carbsGrams
          ? _self.carbsGrams
          : carbsGrams // ignore: cast_nullable_to_non_nullable
              as int,
      fatGrams: null == fatGrams
          ? _self.fatGrams
          : fatGrams // ignore: cast_nullable_to_non_nullable
              as int,
      exerciseMinutes: null == exerciseMinutes
          ? _self.exerciseMinutes
          : exerciseMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      sleepMinutes: null == sleepMinutes
          ? _self.sleepMinutes
          : sleepMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      fastingStartTime: freezed == fastingStartTime
          ? _self.fastingStartTime
          : fastingStartTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      fastingEndTime: freezed == fastingEndTime
          ? _self.fastingEndTime
          : fastingEndTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      imrScore: null == imrScore
          ? _self.imrScore
          : imrScore // ignore: cast_nullable_to_non_nullable
              as double,
      mealEntries: null == mealEntries
          ? _self.mealEntries
          : mealEntries // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      exerciseEntries: null == exerciseEntries
          ? _self.exerciseEntries
          : exerciseEntries // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ));
  }
}

/// Adds pattern-matching-related methods to [DailyLog].
extension DailyLogPatterns on DailyLog {
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
    TResult Function(_DailyLog value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DailyLog() when $default != null:
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
    TResult Function(_DailyLog value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyLog():
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
    TResult? Function(_DailyLog value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyLog() when $default != null:
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
            int waterGlasses,
            int calories,
            int proteinGrams,
            int carbsGrams,
            int fatGrams,
            int exerciseMinutes,
            int sleepMinutes,
            @OptionalTimestampConverter() DateTime? fastingStartTime,
            @OptionalTimestampConverter() DateTime? fastingEndTime,
            @JsonKey(name: 'mtiScore') double imrScore,
            List<Map<String, dynamic>> mealEntries,
            List<Map<String, dynamic>> exerciseEntries)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _DailyLog() when $default != null:
        return $default(
            _that.id,
            _that.waterGlasses,
            _that.calories,
            _that.proteinGrams,
            _that.carbsGrams,
            _that.fatGrams,
            _that.exerciseMinutes,
            _that.sleepMinutes,
            _that.fastingStartTime,
            _that.fastingEndTime,
            _that.imrScore,
            _that.mealEntries,
            _that.exerciseEntries);
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
            int waterGlasses,
            int calories,
            int proteinGrams,
            int carbsGrams,
            int fatGrams,
            int exerciseMinutes,
            int sleepMinutes,
            @OptionalTimestampConverter() DateTime? fastingStartTime,
            @OptionalTimestampConverter() DateTime? fastingEndTime,
            @JsonKey(name: 'mtiScore') double imrScore,
            List<Map<String, dynamic>> mealEntries,
            List<Map<String, dynamic>> exerciseEntries)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyLog():
        return $default(
            _that.id,
            _that.waterGlasses,
            _that.calories,
            _that.proteinGrams,
            _that.carbsGrams,
            _that.fatGrams,
            _that.exerciseMinutes,
            _that.sleepMinutes,
            _that.fastingStartTime,
            _that.fastingEndTime,
            _that.imrScore,
            _that.mealEntries,
            _that.exerciseEntries);
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
            int waterGlasses,
            int calories,
            int proteinGrams,
            int carbsGrams,
            int fatGrams,
            int exerciseMinutes,
            int sleepMinutes,
            @OptionalTimestampConverter() DateTime? fastingStartTime,
            @OptionalTimestampConverter() DateTime? fastingEndTime,
            @JsonKey(name: 'mtiScore') double imrScore,
            List<Map<String, dynamic>> mealEntries,
            List<Map<String, dynamic>> exerciseEntries)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _DailyLog() when $default != null:
        return $default(
            _that.id,
            _that.waterGlasses,
            _that.calories,
            _that.proteinGrams,
            _that.carbsGrams,
            _that.fatGrams,
            _that.exerciseMinutes,
            _that.sleepMinutes,
            _that.fastingStartTime,
            _that.fastingEndTime,
            _that.imrScore,
            _that.mealEntries,
            _that.exerciseEntries);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _DailyLog implements DailyLog {
  const _DailyLog(
      {required this.id,
      this.waterGlasses = 0,
      this.calories = 0,
      this.proteinGrams = 0,
      this.carbsGrams = 0,
      this.fatGrams = 0,
      this.exerciseMinutes = 0,
      this.sleepMinutes = 0,
      @OptionalTimestampConverter() this.fastingStartTime,
      @OptionalTimestampConverter() this.fastingEndTime,
      @JsonKey(name: 'mtiScore') this.imrScore = 0.0,
      final List<Map<String, dynamic>> mealEntries = const [],
      final List<Map<String, dynamic>> exerciseEntries = const []})
      : _mealEntries = mealEntries,
        _exerciseEntries = exerciseEntries;
  factory _DailyLog.fromJson(Map<String, dynamic> json) =>
      _$DailyLogFromJson(json);

  @override
  final String id;
  @override
  @JsonKey()
  final int waterGlasses;
  @override
  @JsonKey()
  final int calories;
  @override
  @JsonKey()
  final int proteinGrams;
  @override
  @JsonKey()
  final int carbsGrams;
  @override
  @JsonKey()
  final int fatGrams;
  @override
  @JsonKey()
  final int exerciseMinutes;
  @override
  @JsonKey()
  final int sleepMinutes;
  @override
  @OptionalTimestampConverter()
  final DateTime? fastingStartTime;
  @override
  @OptionalTimestampConverter()
  final DateTime? fastingEndTime;
  @override
  @JsonKey(name: 'mtiScore')
  final double imrScore;
  final List<Map<String, dynamic>> _mealEntries;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get mealEntries {
    if (_mealEntries is EqualUnmodifiableListView) return _mealEntries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_mealEntries);
  }

  final List<Map<String, dynamic>> _exerciseEntries;
  @override
  @JsonKey()
  List<Map<String, dynamic>> get exerciseEntries {
    if (_exerciseEntries is EqualUnmodifiableListView) return _exerciseEntries;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exerciseEntries);
  }

  /// Create a copy of DailyLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$DailyLogCopyWith<_DailyLog> get copyWith =>
      __$DailyLogCopyWithImpl<_DailyLog>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$DailyLogToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _DailyLog &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.waterGlasses, waterGlasses) ||
                other.waterGlasses == waterGlasses) &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.proteinGrams, proteinGrams) ||
                other.proteinGrams == proteinGrams) &&
            (identical(other.carbsGrams, carbsGrams) ||
                other.carbsGrams == carbsGrams) &&
            (identical(other.fatGrams, fatGrams) ||
                other.fatGrams == fatGrams) &&
            (identical(other.exerciseMinutes, exerciseMinutes) ||
                other.exerciseMinutes == exerciseMinutes) &&
            (identical(other.sleepMinutes, sleepMinutes) ||
                other.sleepMinutes == sleepMinutes) &&
            (identical(other.fastingStartTime, fastingStartTime) ||
                other.fastingStartTime == fastingStartTime) &&
            (identical(other.fastingEndTime, fastingEndTime) ||
                other.fastingEndTime == fastingEndTime) &&
            (identical(other.imrScore, imrScore) ||
                other.imrScore == imrScore) &&
            const DeepCollectionEquality()
                .equals(other._mealEntries, _mealEntries) &&
            const DeepCollectionEquality()
                .equals(other._exerciseEntries, _exerciseEntries));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      waterGlasses,
      calories,
      proteinGrams,
      carbsGrams,
      fatGrams,
      exerciseMinutes,
      sleepMinutes,
      fastingStartTime,
      fastingEndTime,
      imrScore,
      const DeepCollectionEquality().hash(_mealEntries),
      const DeepCollectionEquality().hash(_exerciseEntries));

  @override
  String toString() {
    return 'DailyLog(id: $id, waterGlasses: $waterGlasses, calories: $calories, proteinGrams: $proteinGrams, carbsGrams: $carbsGrams, fatGrams: $fatGrams, exerciseMinutes: $exerciseMinutes, sleepMinutes: $sleepMinutes, fastingStartTime: $fastingStartTime, fastingEndTime: $fastingEndTime, imrScore: $imrScore, mealEntries: $mealEntries, exerciseEntries: $exerciseEntries)';
  }
}

/// @nodoc
abstract mixin class _$DailyLogCopyWith<$Res>
    implements $DailyLogCopyWith<$Res> {
  factory _$DailyLogCopyWith(_DailyLog value, $Res Function(_DailyLog) _then) =
      __$DailyLogCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      int waterGlasses,
      int calories,
      int proteinGrams,
      int carbsGrams,
      int fatGrams,
      int exerciseMinutes,
      int sleepMinutes,
      @OptionalTimestampConverter() DateTime? fastingStartTime,
      @OptionalTimestampConverter() DateTime? fastingEndTime,
      @JsonKey(name: 'mtiScore') double imrScore,
      List<Map<String, dynamic>> mealEntries,
      List<Map<String, dynamic>> exerciseEntries});
}

/// @nodoc
class __$DailyLogCopyWithImpl<$Res> implements _$DailyLogCopyWith<$Res> {
  __$DailyLogCopyWithImpl(this._self, this._then);

  final _DailyLog _self;
  final $Res Function(_DailyLog) _then;

  /// Create a copy of DailyLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? waterGlasses = null,
    Object? calories = null,
    Object? proteinGrams = null,
    Object? carbsGrams = null,
    Object? fatGrams = null,
    Object? exerciseMinutes = null,
    Object? sleepMinutes = null,
    Object? fastingStartTime = freezed,
    Object? fastingEndTime = freezed,
    Object? imrScore = null,
    Object? mealEntries = null,
    Object? exerciseEntries = null,
  }) {
    return _then(_DailyLog(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      waterGlasses: null == waterGlasses
          ? _self.waterGlasses
          : waterGlasses // ignore: cast_nullable_to_non_nullable
              as int,
      calories: null == calories
          ? _self.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int,
      proteinGrams: null == proteinGrams
          ? _self.proteinGrams
          : proteinGrams // ignore: cast_nullable_to_non_nullable
              as int,
      carbsGrams: null == carbsGrams
          ? _self.carbsGrams
          : carbsGrams // ignore: cast_nullable_to_non_nullable
              as int,
      fatGrams: null == fatGrams
          ? _self.fatGrams
          : fatGrams // ignore: cast_nullable_to_non_nullable
              as int,
      exerciseMinutes: null == exerciseMinutes
          ? _self.exerciseMinutes
          : exerciseMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      sleepMinutes: null == sleepMinutes
          ? _self.sleepMinutes
          : sleepMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      fastingStartTime: freezed == fastingStartTime
          ? _self.fastingStartTime
          : fastingStartTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      fastingEndTime: freezed == fastingEndTime
          ? _self.fastingEndTime
          : fastingEndTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      imrScore: null == imrScore
          ? _self.imrScore
          : imrScore // ignore: cast_nullable_to_non_nullable
              as double,
      mealEntries: null == mealEntries
          ? _self._mealEntries
          : mealEntries // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      exerciseEntries: null == exerciseEntries
          ? _self._exerciseEntries
          : exerciseEntries // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
    ));
  }
}

// dart format on
