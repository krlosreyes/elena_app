// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'routine_cycle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RoutineCycle {
  DateTime get startDate;
  List<RoutineWeek> get weeks;
  String get goalDescriptive;

  /// Create a copy of RoutineCycle
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RoutineCycleCopyWith<RoutineCycle> get copyWith =>
      _$RoutineCycleCopyWithImpl<RoutineCycle>(
          this as RoutineCycle, _$identity);

  /// Serializes this RoutineCycle to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RoutineCycle &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            const DeepCollectionEquality().equals(other.weeks, weeks) &&
            (identical(other.goalDescriptive, goalDescriptive) ||
                other.goalDescriptive == goalDescriptive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, startDate,
      const DeepCollectionEquality().hash(weeks), goalDescriptive);

  @override
  String toString() {
    return 'RoutineCycle(startDate: $startDate, weeks: $weeks, goalDescriptive: $goalDescriptive)';
  }
}

/// @nodoc
abstract mixin class $RoutineCycleCopyWith<$Res> {
  factory $RoutineCycleCopyWith(
          RoutineCycle value, $Res Function(RoutineCycle) _then) =
      _$RoutineCycleCopyWithImpl;
  @useResult
  $Res call(
      {DateTime startDate, List<RoutineWeek> weeks, String goalDescriptive});
}

/// @nodoc
class _$RoutineCycleCopyWithImpl<$Res> implements $RoutineCycleCopyWith<$Res> {
  _$RoutineCycleCopyWithImpl(this._self, this._then);

  final RoutineCycle _self;
  final $Res Function(RoutineCycle) _then;

  /// Create a copy of RoutineCycle
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? startDate = null,
    Object? weeks = null,
    Object? goalDescriptive = null,
  }) {
    return _then(_self.copyWith(
      startDate: null == startDate
          ? _self.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      weeks: null == weeks
          ? _self.weeks
          : weeks // ignore: cast_nullable_to_non_nullable
              as List<RoutineWeek>,
      goalDescriptive: null == goalDescriptive
          ? _self.goalDescriptive
          : goalDescriptive // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [RoutineCycle].
extension RoutineCyclePatterns on RoutineCycle {
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
    TResult Function(_RoutineCycle value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RoutineCycle() when $default != null:
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
    TResult Function(_RoutineCycle value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineCycle():
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
    TResult? Function(_RoutineCycle value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineCycle() when $default != null:
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
    TResult Function(DateTime startDate, List<RoutineWeek> weeks,
            String goalDescriptive)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RoutineCycle() when $default != null:
        return $default(_that.startDate, _that.weeks, _that.goalDescriptive);
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
            DateTime startDate, List<RoutineWeek> weeks, String goalDescriptive)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineCycle():
        return $default(_that.startDate, _that.weeks, _that.goalDescriptive);
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
    TResult? Function(DateTime startDate, List<RoutineWeek> weeks,
            String goalDescriptive)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineCycle() when $default != null:
        return $default(_that.startDate, _that.weeks, _that.goalDescriptive);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RoutineCycle implements RoutineCycle {
  const _RoutineCycle(
      {required this.startDate,
      required final List<RoutineWeek> weeks,
      required this.goalDescriptive})
      : _weeks = weeks;
  factory _RoutineCycle.fromJson(Map<String, dynamic> json) =>
      _$RoutineCycleFromJson(json);

  @override
  final DateTime startDate;
  final List<RoutineWeek> _weeks;
  @override
  List<RoutineWeek> get weeks {
    if (_weeks is EqualUnmodifiableListView) return _weeks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_weeks);
  }

  @override
  final String goalDescriptive;

  /// Create a copy of RoutineCycle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RoutineCycleCopyWith<_RoutineCycle> get copyWith =>
      __$RoutineCycleCopyWithImpl<_RoutineCycle>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RoutineCycleToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RoutineCycle &&
            (identical(other.startDate, startDate) ||
                other.startDate == startDate) &&
            const DeepCollectionEquality().equals(other._weeks, _weeks) &&
            (identical(other.goalDescriptive, goalDescriptive) ||
                other.goalDescriptive == goalDescriptive));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, startDate,
      const DeepCollectionEquality().hash(_weeks), goalDescriptive);

  @override
  String toString() {
    return 'RoutineCycle(startDate: $startDate, weeks: $weeks, goalDescriptive: $goalDescriptive)';
  }
}

/// @nodoc
abstract mixin class _$RoutineCycleCopyWith<$Res>
    implements $RoutineCycleCopyWith<$Res> {
  factory _$RoutineCycleCopyWith(
          _RoutineCycle value, $Res Function(_RoutineCycle) _then) =
      __$RoutineCycleCopyWithImpl;
  @override
  @useResult
  $Res call(
      {DateTime startDate, List<RoutineWeek> weeks, String goalDescriptive});
}

/// @nodoc
class __$RoutineCycleCopyWithImpl<$Res>
    implements _$RoutineCycleCopyWith<$Res> {
  __$RoutineCycleCopyWithImpl(this._self, this._then);

  final _RoutineCycle _self;
  final $Res Function(_RoutineCycle) _then;

  /// Create a copy of RoutineCycle
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? startDate = null,
    Object? weeks = null,
    Object? goalDescriptive = null,
  }) {
    return _then(_RoutineCycle(
      startDate: null == startDate
          ? _self.startDate
          : startDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      weeks: null == weeks
          ? _self._weeks
          : weeks // ignore: cast_nullable_to_non_nullable
              as List<RoutineWeek>,
      goalDescriptive: null == goalDescriptive
          ? _self.goalDescriptive
          : goalDescriptive // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
mixin _$RoutineWeek {
  int get weekNumber; // 1 through 8
  bool get isDeload; // True if weekNumber == 5
  List<RoutineDay> get days;

  /// Create a copy of RoutineWeek
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RoutineWeekCopyWith<RoutineWeek> get copyWith =>
      _$RoutineWeekCopyWithImpl<RoutineWeek>(this as RoutineWeek, _$identity);

  /// Serializes this RoutineWeek to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RoutineWeek &&
            (identical(other.weekNumber, weekNumber) ||
                other.weekNumber == weekNumber) &&
            (identical(other.isDeload, isDeload) ||
                other.isDeload == isDeload) &&
            const DeepCollectionEquality().equals(other.days, days));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, weekNumber, isDeload,
      const DeepCollectionEquality().hash(days));

  @override
  String toString() {
    return 'RoutineWeek(weekNumber: $weekNumber, isDeload: $isDeload, days: $days)';
  }
}

/// @nodoc
abstract mixin class $RoutineWeekCopyWith<$Res> {
  factory $RoutineWeekCopyWith(
          RoutineWeek value, $Res Function(RoutineWeek) _then) =
      _$RoutineWeekCopyWithImpl;
  @useResult
  $Res call({int weekNumber, bool isDeload, List<RoutineDay> days});
}

/// @nodoc
class _$RoutineWeekCopyWithImpl<$Res> implements $RoutineWeekCopyWith<$Res> {
  _$RoutineWeekCopyWithImpl(this._self, this._then);

  final RoutineWeek _self;
  final $Res Function(RoutineWeek) _then;

  /// Create a copy of RoutineWeek
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? weekNumber = null,
    Object? isDeload = null,
    Object? days = null,
  }) {
    return _then(_self.copyWith(
      weekNumber: null == weekNumber
          ? _self.weekNumber
          : weekNumber // ignore: cast_nullable_to_non_nullable
              as int,
      isDeload: null == isDeload
          ? _self.isDeload
          : isDeload // ignore: cast_nullable_to_non_nullable
              as bool,
      days: null == days
          ? _self.days
          : days // ignore: cast_nullable_to_non_nullable
              as List<RoutineDay>,
    ));
  }
}

/// Adds pattern-matching-related methods to [RoutineWeek].
extension RoutineWeekPatterns on RoutineWeek {
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
    TResult Function(_RoutineWeek value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RoutineWeek() when $default != null:
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
    TResult Function(_RoutineWeek value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineWeek():
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
    TResult? Function(_RoutineWeek value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineWeek() when $default != null:
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
    TResult Function(int weekNumber, bool isDeload, List<RoutineDay> days)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RoutineWeek() when $default != null:
        return $default(_that.weekNumber, _that.isDeload, _that.days);
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
    TResult Function(int weekNumber, bool isDeload, List<RoutineDay> days)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineWeek():
        return $default(_that.weekNumber, _that.isDeload, _that.days);
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
    TResult? Function(int weekNumber, bool isDeload, List<RoutineDay> days)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineWeek() when $default != null:
        return $default(_that.weekNumber, _that.isDeload, _that.days);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RoutineWeek implements RoutineWeek {
  const _RoutineWeek(
      {required this.weekNumber,
      this.isDeload = false,
      required final List<RoutineDay> days})
      : _days = days;
  factory _RoutineWeek.fromJson(Map<String, dynamic> json) =>
      _$RoutineWeekFromJson(json);

  @override
  final int weekNumber;
// 1 through 8
  @override
  @JsonKey()
  final bool isDeload;
// True if weekNumber == 5
  final List<RoutineDay> _days;
// True if weekNumber == 5
  @override
  List<RoutineDay> get days {
    if (_days is EqualUnmodifiableListView) return _days;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_days);
  }

  /// Create a copy of RoutineWeek
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RoutineWeekCopyWith<_RoutineWeek> get copyWith =>
      __$RoutineWeekCopyWithImpl<_RoutineWeek>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RoutineWeekToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RoutineWeek &&
            (identical(other.weekNumber, weekNumber) ||
                other.weekNumber == weekNumber) &&
            (identical(other.isDeload, isDeload) ||
                other.isDeload == isDeload) &&
            const DeepCollectionEquality().equals(other._days, _days));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, weekNumber, isDeload,
      const DeepCollectionEquality().hash(_days));

  @override
  String toString() {
    return 'RoutineWeek(weekNumber: $weekNumber, isDeload: $isDeload, days: $days)';
  }
}

/// @nodoc
abstract mixin class _$RoutineWeekCopyWith<$Res>
    implements $RoutineWeekCopyWith<$Res> {
  factory _$RoutineWeekCopyWith(
          _RoutineWeek value, $Res Function(_RoutineWeek) _then) =
      __$RoutineWeekCopyWithImpl;
  @override
  @useResult
  $Res call({int weekNumber, bool isDeload, List<RoutineDay> days});
}

/// @nodoc
class __$RoutineWeekCopyWithImpl<$Res> implements _$RoutineWeekCopyWith<$Res> {
  __$RoutineWeekCopyWithImpl(this._self, this._then);

  final _RoutineWeek _self;
  final $Res Function(_RoutineWeek) _then;

  /// Create a copy of RoutineWeek
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? weekNumber = null,
    Object? isDeload = null,
    Object? days = null,
  }) {
    return _then(_RoutineWeek(
      weekNumber: null == weekNumber
          ? _self.weekNumber
          : weekNumber // ignore: cast_nullable_to_non_nullable
              as int,
      isDeload: null == isDeload
          ? _self.isDeload
          : isDeload // ignore: cast_nullable_to_non_nullable
              as bool,
      days: null == days
          ? _self._days
          : days // ignore: cast_nullable_to_non_nullable
              as List<RoutineDay>,
    ));
  }
}

/// @nodoc
mixin _$RoutineDay {
  int get dayNumber; // 1 through 7
  bool get isRestDay;
  String get type; // "Full Body", "Cardio Zona 2", "Descanso Activo"
  String get description;
  List<RoutineExercise> get exercises;

  /// Create a copy of RoutineDay
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RoutineDayCopyWith<RoutineDay> get copyWith =>
      _$RoutineDayCopyWithImpl<RoutineDay>(this as RoutineDay, _$identity);

  /// Serializes this RoutineDay to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RoutineDay &&
            (identical(other.dayNumber, dayNumber) ||
                other.dayNumber == dayNumber) &&
            (identical(other.isRestDay, isRestDay) ||
                other.isRestDay == isRestDay) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other.exercises, exercises));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, dayNumber, isRestDay, type,
      description, const DeepCollectionEquality().hash(exercises));

  @override
  String toString() {
    return 'RoutineDay(dayNumber: $dayNumber, isRestDay: $isRestDay, type: $type, description: $description, exercises: $exercises)';
  }
}

/// @nodoc
abstract mixin class $RoutineDayCopyWith<$Res> {
  factory $RoutineDayCopyWith(
          RoutineDay value, $Res Function(RoutineDay) _then) =
      _$RoutineDayCopyWithImpl;
  @useResult
  $Res call(
      {int dayNumber,
      bool isRestDay,
      String type,
      String description,
      List<RoutineExercise> exercises});
}

/// @nodoc
class _$RoutineDayCopyWithImpl<$Res> implements $RoutineDayCopyWith<$Res> {
  _$RoutineDayCopyWithImpl(this._self, this._then);

  final RoutineDay _self;
  final $Res Function(RoutineDay) _then;

  /// Create a copy of RoutineDay
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? dayNumber = null,
    Object? isRestDay = null,
    Object? type = null,
    Object? description = null,
    Object? exercises = null,
  }) {
    return _then(_self.copyWith(
      dayNumber: null == dayNumber
          ? _self.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      isRestDay: null == isRestDay
          ? _self.isRestDay
          : isRestDay // ignore: cast_nullable_to_non_nullable
              as bool,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      exercises: null == exercises
          ? _self.exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<RoutineExercise>,
    ));
  }
}

/// Adds pattern-matching-related methods to [RoutineDay].
extension RoutineDayPatterns on RoutineDay {
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
    TResult Function(_RoutineDay value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RoutineDay() when $default != null:
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
    TResult Function(_RoutineDay value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineDay():
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
    TResult? Function(_RoutineDay value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineDay() when $default != null:
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
    TResult Function(int dayNumber, bool isRestDay, String type,
            String description, List<RoutineExercise> exercises)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RoutineDay() when $default != null:
        return $default(_that.dayNumber, _that.isRestDay, _that.type,
            _that.description, _that.exercises);
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
    TResult Function(int dayNumber, bool isRestDay, String type,
            String description, List<RoutineExercise> exercises)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineDay():
        return $default(_that.dayNumber, _that.isRestDay, _that.type,
            _that.description, _that.exercises);
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
    TResult? Function(int dayNumber, bool isRestDay, String type,
            String description, List<RoutineExercise> exercises)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RoutineDay() when $default != null:
        return $default(_that.dayNumber, _that.isRestDay, _that.type,
            _that.description, _that.exercises);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _RoutineDay implements RoutineDay {
  const _RoutineDay(
      {required this.dayNumber,
      required this.isRestDay,
      this.type = 'Descanso',
      this.description = '',
      final List<RoutineExercise> exercises = const []})
      : _exercises = exercises;
  factory _RoutineDay.fromJson(Map<String, dynamic> json) =>
      _$RoutineDayFromJson(json);

  @override
  final int dayNumber;
// 1 through 7
  @override
  final bool isRestDay;
  @override
  @JsonKey()
  final String type;
// "Full Body", "Cardio Zona 2", "Descanso Activo"
  @override
  @JsonKey()
  final String description;
  final List<RoutineExercise> _exercises;
  @override
  @JsonKey()
  List<RoutineExercise> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  /// Create a copy of RoutineDay
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RoutineDayCopyWith<_RoutineDay> get copyWith =>
      __$RoutineDayCopyWithImpl<_RoutineDay>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$RoutineDayToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RoutineDay &&
            (identical(other.dayNumber, dayNumber) ||
                other.dayNumber == dayNumber) &&
            (identical(other.isRestDay, isRestDay) ||
                other.isRestDay == isRestDay) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality()
                .equals(other._exercises, _exercises));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, dayNumber, isRestDay, type,
      description, const DeepCollectionEquality().hash(_exercises));

  @override
  String toString() {
    return 'RoutineDay(dayNumber: $dayNumber, isRestDay: $isRestDay, type: $type, description: $description, exercises: $exercises)';
  }
}

/// @nodoc
abstract mixin class _$RoutineDayCopyWith<$Res>
    implements $RoutineDayCopyWith<$Res> {
  factory _$RoutineDayCopyWith(
          _RoutineDay value, $Res Function(_RoutineDay) _then) =
      __$RoutineDayCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int dayNumber,
      bool isRestDay,
      String type,
      String description,
      List<RoutineExercise> exercises});
}

/// @nodoc
class __$RoutineDayCopyWithImpl<$Res> implements _$RoutineDayCopyWith<$Res> {
  __$RoutineDayCopyWithImpl(this._self, this._then);

  final _RoutineDay _self;
  final $Res Function(_RoutineDay) _then;

  /// Create a copy of RoutineDay
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? dayNumber = null,
    Object? isRestDay = null,
    Object? type = null,
    Object? description = null,
    Object? exercises = null,
  }) {
    return _then(_RoutineDay(
      dayNumber: null == dayNumber
          ? _self.dayNumber
          : dayNumber // ignore: cast_nullable_to_non_nullable
              as int,
      isRestDay: null == isRestDay
          ? _self.isRestDay
          : isRestDay // ignore: cast_nullable_to_non_nullable
              as bool,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _self.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      exercises: null == exercises
          ? _self._exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<RoutineExercise>,
    ));
  }
}

// dart format on
