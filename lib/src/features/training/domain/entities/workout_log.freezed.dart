// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_log.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

WorkoutLog _$WorkoutLogFromJson(Map<String, dynamic> json) {
  return _WorkoutLog.fromJson(json);
}

/// @nodoc
mixin _$WorkoutLog {
  String get id => throw _privateConstructorUsedError;
  String get templateId => throw _privateConstructorUsedError;
  @TimestampConverter()
  DateTime get date => throw _privateConstructorUsedError;
  int get sessionRirScore => throw _privateConstructorUsedError;
  List<Map<String, dynamic>> get completedExercises =>
      throw _privateConstructorUsedError;
  int? get durationMinutes => throw _privateConstructorUsedError;
  int? get caloriesBurned => throw _privateConstructorUsedError;
  bool get isFasted => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $WorkoutLogCopyWith<WorkoutLog> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $WorkoutLogCopyWith<$Res> {
  factory $WorkoutLogCopyWith(
          WorkoutLog value, $Res Function(WorkoutLog) then) =
      _$WorkoutLogCopyWithImpl<$Res, WorkoutLog>;
  @useResult
  $Res call(
      {String id,
      String templateId,
      @TimestampConverter() DateTime date,
      int sessionRirScore,
      List<Map<String, dynamic>> completedExercises,
      int? durationMinutes,
      int? caloriesBurned,
      bool isFasted});
}

/// @nodoc
class _$WorkoutLogCopyWithImpl<$Res, $Val extends WorkoutLog>
    implements $WorkoutLogCopyWith<$Res> {
  _$WorkoutLogCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

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
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: null == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      sessionRirScore: null == sessionRirScore
          ? _value.sessionRirScore
          : sessionRirScore // ignore: cast_nullable_to_non_nullable
              as int,
      completedExercises: null == completedExercises
          ? _value.completedExercises
          : completedExercises // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      durationMinutes: freezed == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      caloriesBurned: freezed == caloriesBurned
          ? _value.caloriesBurned
          : caloriesBurned // ignore: cast_nullable_to_non_nullable
              as int?,
      isFasted: null == isFasted
          ? _value.isFasted
          : isFasted // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$WorkoutLogImplCopyWith<$Res>
    implements $WorkoutLogCopyWith<$Res> {
  factory _$$WorkoutLogImplCopyWith(
          _$WorkoutLogImpl value, $Res Function(_$WorkoutLogImpl) then) =
      __$$WorkoutLogImplCopyWithImpl<$Res>;
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
      bool isFasted});
}

/// @nodoc
class __$$WorkoutLogImplCopyWithImpl<$Res>
    extends _$WorkoutLogCopyWithImpl<$Res, _$WorkoutLogImpl>
    implements _$$WorkoutLogImplCopyWith<$Res> {
  __$$WorkoutLogImplCopyWithImpl(
      _$WorkoutLogImpl _value, $Res Function(_$WorkoutLogImpl) _then)
      : super(_value, _then);

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
  }) {
    return _then(_$WorkoutLogImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      templateId: null == templateId
          ? _value.templateId
          : templateId // ignore: cast_nullable_to_non_nullable
              as String,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      sessionRirScore: null == sessionRirScore
          ? _value.sessionRirScore
          : sessionRirScore // ignore: cast_nullable_to_non_nullable
              as int,
      completedExercises: null == completedExercises
          ? _value._completedExercises
          : completedExercises // ignore: cast_nullable_to_non_nullable
              as List<Map<String, dynamic>>,
      durationMinutes: freezed == durationMinutes
          ? _value.durationMinutes
          : durationMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
      caloriesBurned: freezed == caloriesBurned
          ? _value.caloriesBurned
          : caloriesBurned // ignore: cast_nullable_to_non_nullable
              as int?,
      isFasted: null == isFasted
          ? _value.isFasted
          : isFasted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$WorkoutLogImpl extends _WorkoutLog with DiagnosticableTreeMixin {
  const _$WorkoutLogImpl(
      {required this.id,
      required this.templateId,
      @TimestampConverter() required this.date,
      required this.sessionRirScore,
      required final List<Map<String, dynamic>> completedExercises,
      this.durationMinutes,
      this.caloriesBurned,
      this.isFasted = false})
      : _completedExercises = completedExercises,
        super._();

  factory _$WorkoutLogImpl.fromJson(Map<String, dynamic> json) =>
      _$$WorkoutLogImplFromJson(json);

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
  String toString({DiagnosticLevel minLevel = DiagnosticLevel.info}) {
    return 'WorkoutLog(id: $id, templateId: $templateId, date: $date, sessionRirScore: $sessionRirScore, completedExercises: $completedExercises, durationMinutes: $durationMinutes, caloriesBurned: $caloriesBurned, isFasted: $isFasted)';
  }

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty('type', 'WorkoutLog'))
      ..add(DiagnosticsProperty('id', id))
      ..add(DiagnosticsProperty('templateId', templateId))
      ..add(DiagnosticsProperty('date', date))
      ..add(DiagnosticsProperty('sessionRirScore', sessionRirScore))
      ..add(DiagnosticsProperty('completedExercises', completedExercises))
      ..add(DiagnosticsProperty('durationMinutes', durationMinutes))
      ..add(DiagnosticsProperty('caloriesBurned', caloriesBurned))
      ..add(DiagnosticsProperty('isFasted', isFasted));
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$WorkoutLogImpl &&
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
                other.isFasted == isFasted));
  }

  @JsonKey(ignore: true)
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
      isFasted);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$WorkoutLogImplCopyWith<_$WorkoutLogImpl> get copyWith =>
      __$$WorkoutLogImplCopyWithImpl<_$WorkoutLogImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$WorkoutLogImplToJson(
      this,
    );
  }
}

abstract class _WorkoutLog extends WorkoutLog {
  const factory _WorkoutLog(
      {required final String id,
      required final String templateId,
      @TimestampConverter() required final DateTime date,
      required final int sessionRirScore,
      required final List<Map<String, dynamic>> completedExercises,
      final int? durationMinutes,
      final int? caloriesBurned,
      final bool isFasted}) = _$WorkoutLogImpl;
  const _WorkoutLog._() : super._();

  factory _WorkoutLog.fromJson(Map<String, dynamic> json) =
      _$WorkoutLogImpl.fromJson;

  @override
  String get id;
  @override
  String get templateId;
  @override
  @TimestampConverter()
  DateTime get date;
  @override
  int get sessionRirScore;
  @override
  List<Map<String, dynamic>> get completedExercises;
  @override
  int? get durationMinutes;
  @override
  int? get caloriesBurned;
  @override
  bool get isFasted;
  @override
  @JsonKey(ignore: true)
  _$$WorkoutLogImplCopyWith<_$WorkoutLogImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
