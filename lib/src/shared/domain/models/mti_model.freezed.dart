// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'mti_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

MtiModel _$MtiModelFromJson(Map<String, dynamic> json) {
  return _MtiModel.fromJson(json);
}

/// @nodoc
mixin _$MtiModel {
  String get id => throw _privateConstructorUsedError;
  double get score => throw _privateConstructorUsedError;
  double get bodyScore => throw _privateConstructorUsedError;
  double get metabolicScore => throw _privateConstructorUsedError;
  double get lifestyleScore => throw _privateConstructorUsedError;
  MtiClassification get classification => throw _privateConstructorUsedError;
  DateTime get calculatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MtiModelCopyWith<MtiModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MtiModelCopyWith<$Res> {
  factory $MtiModelCopyWith(MtiModel value, $Res Function(MtiModel) then) =
      _$MtiModelCopyWithImpl<$Res, MtiModel>;
  @useResult
  $Res call(
      {String id,
      double score,
      double bodyScore,
      double metabolicScore,
      double lifestyleScore,
      MtiClassification classification,
      DateTime calculatedAt});
}

/// @nodoc
class _$MtiModelCopyWithImpl<$Res, $Val extends MtiModel>
    implements $MtiModelCopyWith<$Res> {
  _$MtiModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? score = null,
    Object? bodyScore = null,
    Object? metabolicScore = null,
    Object? lifestyleScore = null,
    Object? classification = null,
    Object? calculatedAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      bodyScore: null == bodyScore
          ? _value.bodyScore
          : bodyScore // ignore: cast_nullable_to_non_nullable
              as double,
      metabolicScore: null == metabolicScore
          ? _value.metabolicScore
          : metabolicScore // ignore: cast_nullable_to_non_nullable
              as double,
      lifestyleScore: null == lifestyleScore
          ? _value.lifestyleScore
          : lifestyleScore // ignore: cast_nullable_to_non_nullable
              as double,
      classification: null == classification
          ? _value.classification
          : classification // ignore: cast_nullable_to_non_nullable
              as MtiClassification,
      calculatedAt: null == calculatedAt
          ? _value.calculatedAt
          : calculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MtiModelImplCopyWith<$Res>
    implements $MtiModelCopyWith<$Res> {
  factory _$$MtiModelImplCopyWith(
          _$MtiModelImpl value, $Res Function(_$MtiModelImpl) then) =
      __$$MtiModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      double score,
      double bodyScore,
      double metabolicScore,
      double lifestyleScore,
      MtiClassification classification,
      DateTime calculatedAt});
}

/// @nodoc
class __$$MtiModelImplCopyWithImpl<$Res>
    extends _$MtiModelCopyWithImpl<$Res, _$MtiModelImpl>
    implements _$$MtiModelImplCopyWith<$Res> {
  __$$MtiModelImplCopyWithImpl(
      _$MtiModelImpl _value, $Res Function(_$MtiModelImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? score = null,
    Object? bodyScore = null,
    Object? metabolicScore = null,
    Object? lifestyleScore = null,
    Object? classification = null,
    Object? calculatedAt = null,
  }) {
    return _then(_$MtiModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      score: null == score
          ? _value.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      bodyScore: null == bodyScore
          ? _value.bodyScore
          : bodyScore // ignore: cast_nullable_to_non_nullable
              as double,
      metabolicScore: null == metabolicScore
          ? _value.metabolicScore
          : metabolicScore // ignore: cast_nullable_to_non_nullable
              as double,
      lifestyleScore: null == lifestyleScore
          ? _value.lifestyleScore
          : lifestyleScore // ignore: cast_nullable_to_non_nullable
              as double,
      classification: null == classification
          ? _value.classification
          : classification // ignore: cast_nullable_to_non_nullable
              as MtiClassification,
      calculatedAt: null == calculatedAt
          ? _value.calculatedAt
          : calculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MtiModelImpl implements _MtiModel {
  const _$MtiModelImpl(
      {required this.id,
      required this.score,
      required this.bodyScore,
      required this.metabolicScore,
      required this.lifestyleScore,
      required this.classification,
      required this.calculatedAt});

  factory _$MtiModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$MtiModelImplFromJson(json);

  @override
  final String id;
  @override
  final double score;
  @override
  final double bodyScore;
  @override
  final double metabolicScore;
  @override
  final double lifestyleScore;
  @override
  final MtiClassification classification;
  @override
  final DateTime calculatedAt;

  @override
  String toString() {
    return 'MtiModel(id: $id, score: $score, bodyScore: $bodyScore, metabolicScore: $metabolicScore, lifestyleScore: $lifestyleScore, classification: $classification, calculatedAt: $calculatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MtiModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.bodyScore, bodyScore) ||
                other.bodyScore == bodyScore) &&
            (identical(other.metabolicScore, metabolicScore) ||
                other.metabolicScore == metabolicScore) &&
            (identical(other.lifestyleScore, lifestyleScore) ||
                other.lifestyleScore == lifestyleScore) &&
            (identical(other.classification, classification) ||
                other.classification == classification) &&
            (identical(other.calculatedAt, calculatedAt) ||
                other.calculatedAt == calculatedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, score, bodyScore,
      metabolicScore, lifestyleScore, classification, calculatedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MtiModelImplCopyWith<_$MtiModelImpl> get copyWith =>
      __$$MtiModelImplCopyWithImpl<_$MtiModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MtiModelImplToJson(
      this,
    );
  }
}

abstract class _MtiModel implements MtiModel {
  const factory _MtiModel(
      {required final String id,
      required final double score,
      required final double bodyScore,
      required final double metabolicScore,
      required final double lifestyleScore,
      required final MtiClassification classification,
      required final DateTime calculatedAt}) = _$MtiModelImpl;

  factory _MtiModel.fromJson(Map<String, dynamic> json) =
      _$MtiModelImpl.fromJson;

  @override
  String get id;
  @override
  double get score;
  @override
  double get bodyScore;
  @override
  double get metabolicScore;
  @override
  double get lifestyleScore;
  @override
  MtiClassification get classification;
  @override
  DateTime get calculatedAt;
  @override
  @JsonKey(ignore: true)
  _$$MtiModelImplCopyWith<_$MtiModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
