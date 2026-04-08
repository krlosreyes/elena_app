// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WorkoutLog implements DiagnosticableTreeMixin {
  String get id;
  String get templateId;
  @TimestampConverter()
  DateTime get date;
  int get sessionRirScore;
  List<Map<String, dynamic>> get completedExercises;
  int? get durationMinutes;
  int? get caloriesBurned;
  bool get isFasted;
  String get type;

  /// Create a copy of WorkoutLog
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $WorkoutLogCopyWith<WorkoutLog> get copyWith =>
      _$WorkoutLogCopyWithImpl<WorkoutLog>(this as WorkoutLog, _$identity);

  /// Serializes this WorkoutLog to a JSON map.
  Map<String, dynamic> toJson();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'WorkoutLog'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('templateId', templateId))
      ..add(DiagnosticsProperty('date', date))
      ..add(DiagnosticsProperty('sessionRirScore', sessionRirScore))
      ..add(DiagnosticsProperty('completedExercises', completedExercises))
      ..add(DiagnosticsProperty('durationMinutes', durationMinutes))
      ..add(DiagnosticsProperty('caloriesBurned', caloriesBurned))
      ..add(DiagnosticsProperty('isFasted', isFasted))
      ..add(DiagnosticsProperty('type', type));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is WorkoutLog &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.templateId, templateId) ||
                other.templateId == templateId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.sessionRirScore, sessionRirScore) ||
                other.sessionRirScore == sessionRirScore) &&
            const DeepCollectionEquality()
                .equals(other.completedExercises, completedExercises) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.caloriesBurned, caloriesBurned) ||
                other.caloriesBurned == caloriesBurned) &&
            (identical(other.isFasted, isFasted) ||
                other.isFasted == isFasted) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      templateId,
      date,
      sessionRirScore,
      const DeepCollectionEquality().hash(completedExercises),
      durationMinutes,
      caloriesBurned,
      isFasted,
      type);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'WorkoutLog(id: $id, templateId: $templateId, date: $date, sessionRirScore: $sessionRirScore, completedExercises: $completedExercises, durationMinutes: $durationMinutes, caloriesBurned: $caloriesBurned, isFasted: $isFasted, type: $type)';
  }
}

/// @nodoc
abstract mixin class $WorkoutLogCopyWith<$Res> {
  factory $WorkoutLogCopyWith(
          WorkoutLog value, $Res Function(WorkoutLog) _then) =
      _$WorkoutLogCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      String templateId,
      @TimestampConverter() DateTime date,
      int sessionRirScore,
      List<Map<String, dynamic>> completedExercises,
      int? durationMinutes,
      int? caloriesBurned,
      bool isFasted,
      String type});
}

/// @nodoc
class _$WorkoutLogCopyWithImpl<$Res> implements $WorkoutLogCopyWith<$Res> {
  _$WorkoutLogCopyWithImpl(this._self, this._then);

  final WorkoutLog _self;
  final $Res Function(WorkoutLog) _then;

  /// Create a copy of WorkoutLog
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? templateId = null,
    Object? date = null,
    Object? sessionRirScore = null,
    Object? completedExercises = null,
    Object? durationMinutes = freezed,
    Object? caloriesBurned = freezed,
    Object? isFasted = null,
    Object? type = null,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: null == templateId
          ? _self.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      sessionRirScore: null == sessionRirScore
          ? _self.sessionRirScore
          : sessionRirScore // ignore: cast_nullable_to_non_nullable
              as int,
      completedExercises: null == completedExercises
          ? _self.completedExercises
          : completedExercises // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      durationMinutes: freezed == durationMinutes
          ? _self.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      caloriesBurned: freezed == caloriesBurned
          ? _self.caloriesBurned
          : caloriesBurned // ignore: cast_nullable_to_non_nullable
              as int?,
      isFasted: null == isFasted
          ? _self.isFasted
          : isFasted // ignore: cast_nullable_to_non_nullable
              as bool,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// Adds pattern-matching-related methods to [WorkoutLog].
extension WorkoutLogPatterns on WorkoutLog {
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
    TResult Function(_WorkoutLog value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WorkoutLog() when $default != null:
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
    TResult Function(_WorkoutLog value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutLog():
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
    TResult? Function(_WorkoutLog value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutLog() when $default != null:
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
            String templateId,
            @TimestampConverter() DateTime date,
            int sessionRirScore,
            List<Map<String, dynamic>> completedExercises,
            int? durationMinutes,
            int? caloriesBurned,
            bool isFasted,
            String type)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _WorkoutLog() when $default != null:
        return $default(
            _that.id,
            _that.templateId,
            _that.date,
            _that.sessionRirScore,
            _that.completedExercises,
            _that.durationMinutes,
            _that.caloriesBurned,
            _that.isFasted,
            _that.type);
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
            String templateId,
            @TimestampConverter() DateTime date,
            int sessionRirScore,
            List<Map<String, dynamic>> completedExercises,
            int? durationMinutes,
            int? caloriesBurned,
            bool isFasted,
            String type)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutLog():
        return $default(
            _that.id,
            _that.templateId,
            _that.date,
            _that.sessionRirScore,
            _that.completedExercises,
            _that.durationMinutes,
            _that.caloriesBurned,
            _that.isFasted,
            _that.type);
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
            String templateId,
            @TimestampConverter() DateTime date,
            int sessionRirScore,
            List<Map<String, dynamic>> completedExercises,
            int? durationMinutes,
            int? caloriesBurned,
            bool isFasted,
            String type)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _WorkoutLog() when $default != null:
        return $default(
            _that.id,
            _that.templateId,
            _that.date,
            _that.sessionRirScore,
            _that.completedExercises,
            _that.durationMinutes,
            _that.caloriesBurned,
            _that.isFasted,
            _that.type);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _WorkoutLog extends WorkoutLog with DiagnosticableTreeMixin {
  const _WorkoutLog(
      {required this.id,
      required this.templateId,
      @TimestampConverter() required this.date,
      required this.sessionRirScore,
      required final List<Map<String, dynamic>> completedExercises,
      this.durationMinutes,
      this.caloriesBurned,
      this.isFasted = false,
      this.type = 'Fuerza'})
      : _completedExercises = completedExercises,
        super._();
  factory _WorkoutLog.fromJson(Map<String, dynamic> json) =>
      _$WorkoutLogFromJson(json);

  @override
  final String id;
  @override
  final String templateId;
  @override
  @TimestampConverter()
  final DateTime date;
  @override
  final int sessionRirScore;
  final List<Map<String, dynamic>> _completedExercises;
  @override
  List<Map<String, dynamic>> get completedExercises {
    if (_completedExercises is EqualUnmodifiableListView)
      return _completedExercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_completedExercises);
  }

  @override
  final int? durationMinutes;
  @override
  final int? caloriesBurned;
  @override
  @JsonKey()
  final bool isFasted;
  @override
  @JsonKey()
  final String type;

  /// Create a copy of WorkoutLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$WorkoutLogCopyWith<_WorkoutLog> get copyWith =>
      __$WorkoutLogCopyWithImpl<_WorkoutLog>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$WorkoutLogToJson(
      this,
    );
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    properties
      ..add(DiagnosticsProperty('type', 'WorkoutLog'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('templateId', templateId))
      ..add(DiagnosticsProperty('date', date))
      ..add(DiagnosticsProperty('sessionRirScore', sessionRirScore))
      ..add(DiagnosticsProperty('completedExercises', completedExercises))
      ..add(DiagnosticsProperty('durationMinutes', durationMinutes))
      ..add(DiagnosticsProperty('caloriesBurned', caloriesBurned))
      ..add(DiagnosticsProperty('isFasted', isFasted))
      ..add(DiagnosticsProperty('type', type));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _WorkoutLog &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.templateId, templateId) ||
                other.templateId == templateId) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.sessionRirScore, sessionRirScore) ||
                other.sessionRirScore == sessionRirScore) &&
            const DeepCollectionEquality()
                .equals(other._completedExercises, _completedExercises) &&
            (identical(other.durationMinutes, durationMinutes) ||
                other.durationMinutes == durationMinutes) &&
            (identical(other.caloriesBurned, caloriesBurned) ||
                other.caloriesBurned == caloriesBurned) &&
            (identical(other.isFasted, isFasted) ||
                other.isFasted == isFasted) &&
            (identical(other.type, type) || other.type == type));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      templateId,
      date,
      sessionRirScore,
      const DeepCollectionEquality().hash(_completedExercises),
      durationMinutes,
      caloriesBurned,
      isFasted,
      type);

  @override
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'WorkoutLog(id: $id, templateId: $templateId, date: $date, sessionRirScore: $sessionRirScore, completedExercises: $completedExercises, durationMinutes: $durationMinutes, caloriesBurned: $caloriesBurned, isFasted: $isFasted, type: $type)';
  }
}

/// @nodoc
abstract mixin class _$WorkoutLogCopyWith<$Res>
    implements $WorkoutLogCopyWith<$Res> {
  factory _$WorkoutLogCopyWith(
          _WorkoutLog value, $Res Function(_WorkoutLog) _then) =
      __$WorkoutLogCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      String templateId,
      @TimestampConverter() DateTime date,
      int sessionRirScore,
      List<Map<String, dynamic>> completedExercises,
      int? durationMinutes,
      int? caloriesBurned,
      bool isFasted,
      String type});
}

/// @nodoc
class __$WorkoutLogCopyWithImpl<$Res> implements _$WorkoutLogCopyWith<$Res> {
  __$WorkoutLogCopyWithImpl(this._self, this._then);

  final _WorkoutLog _self;
  final $Res Function(_WorkoutLog) _then;

  /// Create a copy of WorkoutLog
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? templateId = null,
    Object? date = null,
    Object? sessionRirScore = null,
    Object? completedExercises = null,
    Object? durationMinutes = freezed,
    Object? caloriesBurned = freezed,
    Object? isFasted = null,
    Object? type = null,
  }) {
    return _then(_WorkoutLog(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: null == templateId
          ? _self.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      sessionRirScore: null == sessionRirScore
          ? _self.sessionRirScore
          : sessionRirScore // ignore: cast_nullable_to_non_nullable
              as int,
      completedExercises: null == completedExercises
          ? _self._completedExercises
          : completedExercises // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      durationMinutes: freezed == durationMinutes
          ? _self.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      caloriesBurned: freezed == caloriesBurned
          ? _self.caloriesBurned
          : caloriesBurned // ignore: cast_nullable_to_non_nullable
              as int?,
      isFasted: null == isFasted
          ? _self.isFasted
          : isFasted // ignore: cast_nullable_to_non_nullable
              as bool,
      type: null == type
          ? _self.type
          : type // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

// dart format on
