// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'interactive_routine.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

InteractiveExercise _$InteractiveExerciseFromJson(Map<String, dynamic> json) {
  return _InteractiveExercise.fromJson(json);
}

/// @nodoc
mixin _$InteractiveExercise {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get targetRir => throw _privateConstructorUsedError; // e.g. "2-3"
  List<InteractiveSet> get sets => throw _privateConstructorUsedError;
  bool get requiresWeight => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InteractiveExerciseCopyWith<InteractiveExercise> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InteractiveExerciseCopyWith<$Res> {
  factory $InteractiveExerciseCopyWith(
          InteractiveExercise value, $Res Function(InteractiveExercise) then) =
      _$InteractiveExerciseCopyWithImpl<$Res, InteractiveExercise>;
  @useResult
  $Res call(
      {String id,
      String name,
      String targetRir,
      List<InteractiveSet> sets,
      bool requiresWeight});
}

/// @nodoc
class _$InteractiveExerciseCopyWithImpl<$Res, $Val extends InteractiveExercise>
    implements $InteractiveExerciseCopyWith<$Res> {
  _$InteractiveExerciseCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? targetRir = null,
    Object? sets = null,
    Object? requiresWeight = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      targetRir: null == targetRir
          ? _value.targetRir
          : targetRir // ignore: cast_nullable_to_non_nullable
              as String,
      sets: null == sets
          ? _value.sets
          : sets // ignore: cast_nullable_to_non_nullable
              as List<InteractiveSet>,
      requiresWeight: null == requiresWeight
          ? _value.requiresWeight
          : requiresWeight // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InteractiveExerciseImplCopyWith<$Res>
    implements $InteractiveExerciseCopyWith<$Res> {
  factory _$$InteractiveExerciseImplCopyWith(_$InteractiveExerciseImpl value,
          $Res Function(_$InteractiveExerciseImpl) then) =
      __$$InteractiveExerciseImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String targetRir,
      List<InteractiveSet> sets,
      bool requiresWeight});
}

/// @nodoc
class __$$InteractiveExerciseImplCopyWithImpl<$Res>
    extends _$InteractiveExerciseCopyWithImpl<$Res, _$InteractiveExerciseImpl>
    implements _$$InteractiveExerciseImplCopyWith<$Res> {
  __$$InteractiveExerciseImplCopyWithImpl(_$InteractiveExerciseImpl _value,
      $Res Function(_$InteractiveExerciseImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? targetRir = null,
    Object? sets = null,
    Object? requiresWeight = null,
  }) {
    return _then(_$InteractiveExerciseImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      targetRir: null == targetRir
          ? _value.targetRir
          : targetRir // ignore: cast_nullable_to_non_nullable
              as String,
      sets: null == sets
          ? _value._sets
          : sets // ignore: cast_nullable_to_non_nullable
              as List<InteractiveSet>,
      requiresWeight: null == requiresWeight
          ? _value.requiresWeight
          : requiresWeight // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InteractiveExerciseImpl implements _InteractiveExercise {
  const _$InteractiveExerciseImpl(
      {required this.id,
      required this.name,
      required this.targetRir,
      final List<InteractiveSet> sets = const [],
      this.requiresWeight = true})
      : _sets = sets;

  factory _$InteractiveExerciseImpl.fromJson(Map<String, dynamic> json) =>
      _$$InteractiveExerciseImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String targetRir;
// e.g. "2-3"
  final List<InteractiveSet> _sets;
// e.g. "2-3"
  @override
  @JsonKey()
  List<InteractiveSet> get sets {
    if (_sets is EqualUnmodifiableListView) return _sets;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_sets);
  }

  @override
  @JsonKey()
  final bool requiresWeight;

  @override
  String toString() {
    return 'InteractiveExercise(id: $id, name: $name, targetRir: $targetRir, sets: $sets, requiresWeight: $requiresWeight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InteractiveExerciseImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.targetRir, targetRir) ||
                other.targetRir == targetRir) &&
            const DeepCollectionEquality().equals(other._sets, _sets) &&
            (identical(other.requiresWeight, requiresWeight) ||
                other.requiresWeight == requiresWeight));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, name, targetRir,
      const DeepCollectionEquality().hash(_sets), requiresWeight);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InteractiveExerciseImplCopyWith<_$InteractiveExerciseImpl> get copyWith =>
      __$$InteractiveExerciseImplCopyWithImpl<_$InteractiveExerciseImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InteractiveExerciseImplToJson(
      this,
    );
  }
}

abstract class _InteractiveExercise implements InteractiveExercise {
  const factory _InteractiveExercise(
      {required final String id,
      required final String name,
      required final String targetRir,
      final List<InteractiveSet> sets,
      final bool requiresWeight}) = _$InteractiveExerciseImpl;

  factory _InteractiveExercise.fromJson(Map<String, dynamic> json) =
      _$InteractiveExerciseImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get targetRir;
  @override // e.g. "2-3"
  List<InteractiveSet> get sets;
  @override
  bool get requiresWeight;
  @override
  @JsonKey(ignore: true)
  _$$InteractiveExerciseImplCopyWith<_$InteractiveExerciseImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

InteractiveSet _$InteractiveSetFromJson(Map<String, dynamic> json) {
  return _InteractiveSet.fromJson(json);
}

/// @nodoc
mixin _$InteractiveSet {
  int get setIndex => throw _privateConstructorUsedError;
  String get targetReps => throw _privateConstructorUsedError;
  double get weight => throw _privateConstructorUsedError;
  int? get reps => throw _privateConstructorUsedError;
  bool get isDone => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $InteractiveSetCopyWith<InteractiveSet> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $InteractiveSetCopyWith<$Res> {
  factory $InteractiveSetCopyWith(
          InteractiveSet value, $Res Function(InteractiveSet) then) =
      _$InteractiveSetCopyWithImpl<$Res, InteractiveSet>;
  @useResult
  $Res call(
      {int setIndex, String targetReps, double weight, int? reps, bool isDone});
}

/// @nodoc
class _$InteractiveSetCopyWithImpl<$Res, $Val extends InteractiveSet>
    implements $InteractiveSetCopyWith<$Res> {
  _$InteractiveSetCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? setIndex = null,
    Object? targetReps = null,
    Object? weight = null,
    Object? reps = freezed,
    Object? isDone = null,
  }) {
    return _then(_value.copyWith(
      setIndex: null == setIndex
          ? _value.setIndex
          : setIndex // ignore: cast_nullable_to_non_nullable
              as int,
      targetReps: null == targetReps
          ? _value.targetReps
          : targetReps // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
      reps: freezed == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int?,
      isDone: null == isDone
          ? _value.isDone
          : isDone // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$InteractiveSetImplCopyWith<$Res>
    implements $InteractiveSetCopyWith<$Res> {
  factory _$$InteractiveSetImplCopyWith(_$InteractiveSetImpl value,
          $Res Function(_$InteractiveSetImpl) then) =
      __$$InteractiveSetImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int setIndex, String targetReps, double weight, int? reps, bool isDone});
}

/// @nodoc
class __$$InteractiveSetImplCopyWithImpl<$Res>
    extends _$InteractiveSetCopyWithImpl<$Res, _$InteractiveSetImpl>
    implements _$$InteractiveSetImplCopyWith<$Res> {
  __$$InteractiveSetImplCopyWithImpl(
      _$InteractiveSetImpl _value, $Res Function(_$InteractiveSetImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? setIndex = null,
    Object? targetReps = null,
    Object? weight = null,
    Object? reps = freezed,
    Object? isDone = null,
  }) {
    return _then(_$InteractiveSetImpl(
      setIndex: null == setIndex
          ? _value.setIndex
          : setIndex // ignore: cast_nullable_to_non_nullable
              as int,
      targetReps: null == targetReps
          ? _value.targetReps
          : targetReps // ignore: cast_nullable_to_non_nullable
              as String,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
      reps: freezed == reps
          ? _value.reps
          : reps // ignore: cast_nullable_to_non_nullable
              as int?,
      isDone: null == isDone
          ? _value.isDone
          : isDone // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$InteractiveSetImpl implements _InteractiveSet {
  const _$InteractiveSetImpl(
      {required this.setIndex,
      this.targetReps = '8-12',
      this.weight = 5.0,
      this.reps,
      this.isDone = false});

  factory _$InteractiveSetImpl.fromJson(Map<String, dynamic> json) =>
      _$$InteractiveSetImplFromJson(json);

  @override
  final int setIndex;
  @override
  @JsonKey()
  final String targetReps;
  @override
  @JsonKey()
  final double weight;
  @override
  final int? reps;
  @override
  @JsonKey()
  final bool isDone;

  @override
  String toString() {
    return 'InteractiveSet(setIndex: $setIndex, targetReps: $targetReps, weight: $weight, reps: $reps, isDone: $isDone)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$InteractiveSetImpl &&
            (identical(other.setIndex, setIndex) ||
                other.setIndex == setIndex) &&
            (identical(other.targetReps, targetReps) ||
                other.targetReps == targetReps) &&
            (identical(other.weight, weight) || other.weight == weight) &&
            (identical(other.reps, reps) || other.reps == reps) &&
            (identical(other.isDone, isDone) || other.isDone == isDone));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, setIndex, targetReps, weight, reps, isDone);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$InteractiveSetImplCopyWith<_$InteractiveSetImpl> get copyWith =>
      __$$InteractiveSetImplCopyWithImpl<_$InteractiveSetImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$InteractiveSetImplToJson(
      this,
    );
  }
}

abstract class _InteractiveSet implements InteractiveSet {
  const factory _InteractiveSet(
      {required final int setIndex,
      final String targetReps,
      final double weight,
      final int? reps,
      final bool isDone}) = _$InteractiveSetImpl;

  factory _InteractiveSet.fromJson(Map<String, dynamic> json) =
      _$InteractiveSetImpl.fromJson;

  @override
  int get setIndex;
  @override
  String get targetReps;
  @override
  double get weight;
  @override
  int? get reps;
  @override
  bool get isDone;
  @override
  @JsonKey(ignore: true)
  _$$InteractiveSetImplCopyWith<_$InteractiveSetImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
