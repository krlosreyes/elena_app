// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'routine_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

RoutineExercise _$RoutineExerciseFromJson(Map<String, dynamic> json) {
  return _RoutineExercise.fromJson(json);
}

/// @nodoc
mixin _$RoutineExercise {
  String get exerciseId => throw _privateConstructorUsedError;
  int get order => throw _privateConstructorUsedError;
  int get sets => throw _privateConstructorUsedError;
  String get repsRange => throw _privateConstructorUsedError;
  int get targetRir => throw _privateConstructorUsedError;
  int get restSeconds => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RoutineExerciseCopyWith<RoutineExercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoutineExerciseCopyWith<$Res> {
  factory $RoutineExerciseCopyWith(
          RoutineExercise value, $Res Function(RoutineExercise) then) =
      _$RoutineExerciseCopyWithImpl<$Res, RoutineExercise>;
  @useResult
  $Res call(
      {String exerciseId,
      int order,
      int sets,
      String repsRange,
      int targetRir,
      int restSeconds});
}

/// @nodoc
class _$RoutineExerciseCopyWithImpl<$Res, $Val extends RoutineExercise>
    implements $RoutineExerciseCopyWith<$Res> {
  _$RoutineExerciseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? order = null,
    Object? sets = null,
    Object? repsRange = null,
    Object? targetRir = null,
    Object? restSeconds = null,
  }) {
    return _then(_value.copyWith(
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      sets: null == sets
          ? _value.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as int,
      repsRange: null == repsRange
          ? _value.repsRange
          : repsRange // ignore: cast_nullable_to_non_nullable
              as String,
      targetRir: null == targetRir
          ? _value.targetRir
          : targetRir // ignore: cast_nullable_to_non_nullable
              as int,
      restSeconds: null == restSeconds
          ? _value.restSeconds
          : restSeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoutineExerciseImplCopyWith<$Res>
    implements $RoutineExerciseCopyWith<$Res> {
  factory _$$RoutineExerciseImplCopyWith(_$RoutineExerciseImpl value,
          $Res Function(_$RoutineExerciseImpl) then) =
      __$$RoutineExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String exerciseId,
      int order,
      int sets,
      String repsRange,
      int targetRir,
      int restSeconds});
}

/// @nodoc
class __$$RoutineExerciseImplCopyWithImpl<$Res>
    extends _$RoutineExerciseCopyWithImpl<$Res, _$RoutineExerciseImpl>
    implements _$$RoutineExerciseImplCopyWith<$Res> {
  __$$RoutineExerciseImplCopyWithImpl(
      _$RoutineExerciseImpl _value, $Res Function(_$RoutineExerciseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? exerciseId = null,
    Object? order = null,
    Object? sets = null,
    Object? repsRange = null,
    Object? targetRir = null,
    Object? restSeconds = null,
  }) {
    return _then(_$RoutineExerciseImpl(
      exerciseId: null == exerciseId
          ? _value.exerciseId
          : exerciseId // ignore: cast_nullable_to_non_nullable
              as String,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as int,
      sets: null == sets
          ? _value.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as int,
      repsRange: null == repsRange
          ? _value.repsRange
          : repsRange // ignore: cast_nullable_to_non_nullable
              as String,
      targetRir: null == targetRir
          ? _value.targetRir
          : targetRir // ignore: cast_nullable_to_non_nullable
              as int,
      restSeconds: null == restSeconds
          ? _value.restSeconds
          : restSeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RoutineExerciseImpl implements _RoutineExercise {
  const _$RoutineExerciseImpl(
      {required this.exerciseId,
      required this.order,
      required this.sets,
      required this.repsRange,
      required this.targetRir,
      required this.restSeconds});

  factory _$RoutineExerciseImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoutineExerciseImplFromJson(json);

  @override
  final String exerciseId;
  @override
  final int order;
  @override
  final int sets;
  @override
  final String repsRange;
  @override
  final int targetRir;
  @override
  final int restSeconds;

  @override
  String toString() {
    return 'RoutineExercise(exerciseId: $exerciseId, order: $order, sets: $sets, repsRange: $repsRange, targetRir: $targetRir, restSeconds: $restSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoutineExerciseImpl &&
            (identical(other.exerciseId, exerciseId) ||
                other.exerciseId == exerciseId) &&
            (identical(other.order, order) || other.order == order) &&
            (identical(other.sets, sets) || other.sets == sets) &&
            (identical(other.repsRange, repsRange) ||
                other.repsRange == repsRange) &&
            (identical(other.targetRir, targetRir) ||
                other.targetRir == targetRir) &&
            (identical(other.restSeconds, restSeconds) ||
                other.restSeconds == restSeconds));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType, exerciseId, order, sets, repsRange, targetRir, restSeconds);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RoutineExerciseImplCopyWith<_$RoutineExerciseImpl> get copyWith =>
      __$$RoutineExerciseImplCopyWithImpl<_$RoutineExerciseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoutineExerciseImplToJson(
      this,
    );
  }
}

abstract class _RoutineExercise implements RoutineExercise {
  const factory _RoutineExercise(
      {required final String exerciseId,
      required final int order,
      required final int sets,
      required final String repsRange,
      required final int targetRir,
      required final int restSeconds}) = _$RoutineExerciseImpl;

  factory _RoutineExercise.fromJson(Map<String, dynamic> json) =
      _$RoutineExerciseImpl.fromJson;

  @override
  String get exerciseId;
  @override
  int get order;
  @override
  int get sets;
  @override
  String get repsRange;
  @override
  int get targetRir;
  @override
  int get restSeconds;
  @override
  @JsonKey(ignore: true)
  _$$RoutineExerciseImplCopyWith<_$RoutineExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RoutineTemplate _$RoutineTemplateFromJson(Map<String, dynamic> json) {
  return _RoutineTemplate.fromJson(json);
}

/// @nodoc
mixin _$RoutineTemplate {
  String get id => throw _privateConstructorUsedError;
  String get goal => throw _privateConstructorUsedError;
  String get level => throw _privateConstructorUsedError;
  String get target =>
      throw _privateConstructorUsedError; // e.g., "Full Body", "Upper"
  int get estimatedMinutes => throw _privateConstructorUsedError;
  List<RoutineExercise> get exercises => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $RoutineTemplateCopyWith<RoutineTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RoutineTemplateCopyWith<$Res> {
  factory $RoutineTemplateCopyWith(
          RoutineTemplate value, $Res Function(RoutineTemplate) then) =
      _$RoutineTemplateCopyWithImpl<$Res, RoutineTemplate>;
  @useResult
  $Res call(
      {String id,
      String goal,
      String level,
      String target,
      int estimatedMinutes,
      List<RoutineExercise> exercises});
}

/// @nodoc
class _$RoutineTemplateCopyWithImpl<$Res, $Val extends RoutineTemplate>
    implements $RoutineTemplateCopyWith<$Res> {
  _$RoutineTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? goal = null,
    Object? level = null,
    Object? target = null,
    Object? estimatedMinutes = null,
    Object? exercises = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      goal: null == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as String,
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as String,
      estimatedMinutes: null == estimatedMinutes
          ? _value.estimatedMinutes
          : estimatedMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      exercises: null == exercises
          ? _value.exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<RoutineExercise>,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RoutineTemplateImplCopyWith<$Res>
    implements $RoutineTemplateCopyWith<$Res> {
  factory _$$RoutineTemplateImplCopyWith(_$RoutineTemplateImpl value,
          $Res Function(_$RoutineTemplateImpl) then) =
      __$$RoutineTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String goal,
      String level,
      String target,
      int estimatedMinutes,
      List<RoutineExercise> exercises});
}

/// @nodoc
class __$$RoutineTemplateImplCopyWithImpl<$Res>
    extends _$RoutineTemplateCopyWithImpl<$Res, _$RoutineTemplateImpl>
    implements _$$RoutineTemplateImplCopyWith<$Res> {
  __$$RoutineTemplateImplCopyWithImpl(
      _$RoutineTemplateImpl _value, $Res Function(_$RoutineTemplateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? goal = null,
    Object? level = null,
    Object? target = null,
    Object? estimatedMinutes = null,
    Object? exercises = null,
  }) {
    return _then(_$RoutineTemplateImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      goal: null == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as String,
      level: null == level
          ? _value.level
          : level // ignore: cast_nullable_to_non_nullable
              as String,
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as String,
      estimatedMinutes: null == estimatedMinutes
          ? _value.estimatedMinutes
          : estimatedMinutes // ignore: cast_nullable_to_non_nullable
              as int,
      exercises: null == exercises
          ? _value._exercises
          : exercises // ignore: cast_nullable_to_non_nullable
              as List<RoutineExercise>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RoutineTemplateImpl implements _RoutineTemplate {
  const _$RoutineTemplateImpl(
      {required this.id,
      required this.goal,
      required this.level,
      required this.target,
      required this.estimatedMinutes,
      required final List<RoutineExercise> exercises})
      : _exercises = exercises;

  factory _$RoutineTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$RoutineTemplateImplFromJson(json);

  @override
  final String id;
  @override
  final String goal;
  @override
  final String level;
  @override
  final String target;
// e.g., "Full Body", "Upper"
  @override
  final int estimatedMinutes;
  final List<RoutineExercise> _exercises;
  @override
  List<RoutineExercise> get exercises {
    if (_exercises is EqualUnmodifiableListView) return _exercises;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_exercises);
  }

  @override
  String toString() {
    return 'RoutineTemplate(id: $id, goal: $goal, level: $level, target: $target, estimatedMinutes: $estimatedMinutes, exercises: $exercises)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RoutineTemplateImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.goal, goal) || other.goal == goal) &&
            (identical(other.level, level) || other.level == level) &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.estimatedMinutes, estimatedMinutes) ||
                other.estimatedMinutes == estimatedMinutes) &&
            const DeepCollectionEquality()
                .equals(other._exercises, _exercises));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, goal, level, target,
      estimatedMinutes, const DeepCollectionEquality().hash(_exercises));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$RoutineTemplateImplCopyWith<_$RoutineTemplateImpl> get copyWith =>
      __$$RoutineTemplateImplCopyWithImpl<_$RoutineTemplateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RoutineTemplateImplToJson(
      this,
    );
  }
}

abstract class _RoutineTemplate implements RoutineTemplate {
  const factory _RoutineTemplate(
      {required final String id,
      required final String goal,
      required final String level,
      required final String target,
      required final int estimatedMinutes,
      required final List<RoutineExercise> exercises}) = _$RoutineTemplateImpl;

  factory _RoutineTemplate.fromJson(Map<String, dynamic> json) =
      _$RoutineTemplateImpl.fromJson;

  @override
  String get id;
  @override
  String get goal;
  @override
  String get level;
  @override
  String get target;
  @override // e.g., "Full Body", "Upper"
  int get estimatedMinutes;
  @override
  List<RoutineExercise> get exercises;
  @override
  @JsonKey(ignore: true)
  _$$RoutineTemplateImplCopyWith<_$RoutineTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
