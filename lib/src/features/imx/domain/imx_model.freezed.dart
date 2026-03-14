// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'imx_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ImxModel _$ImxModelFromJson(Map<String, dynamic> json) {
  return _ImxModel.fromJson(json);
}

/// @nodoc
mixin _$ImxModel {
  String get id => throw _privateConstructorUsedError;
  double get score => throw _privateConstructorUsedError;
  double get bodyScore => throw _privateConstructorUsedError;
  double get metabolicScore => throw _privateConstructorUsedError;
  double get lifestyleScore => throw _privateConstructorUsedError;
  ImxClassification get classification => throw _privateConstructorUsedError;
  DateTime get calculatedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ImxModelCopyWith<ImxModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ImxModelCopyWith<$Res> {
  factory $ImxModelCopyWith(ImxModel value, $Res Function(ImxModel) then) =
      _$ImxModelCopyWithImpl<$Res, ImxModel>;
  @useResult
  $Res call(
      {String id,
      double score,
      double bodyScore,
      double metabolicScore,
      double lifestyleScore,
      ImxClassification classification,
      DateTime calculatedAt});
}

/// @nodoc
class _$ImxModelCopyWithImpl<$Res, $Val extends ImxModel>
    implements $ImxModelCopyWith<$Res> {
  _$ImxModelCopyWithImpl(this._value, this._then);

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
              as ImxClassification,
      calculatedAt: null == calculatedAt
          ? _value.calculatedAt
          : calculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ImxModelImplCopyWith<$Res>
    implements $ImxModelCopyWith<$Res> {
  factory _$$ImxModelImplCopyWith(
          _$ImxModelImpl value, $Res Function(_$ImxModelImpl) then) =
      __$$ImxModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      double score,
      double bodyScore,
      double metabolicScore,
      double lifestyleScore,
      ImxClassification classification,
      DateTime calculatedAt});
}

/// @nodoc
class __$$ImxModelImplCopyWithImpl<$Res>
    extends _$ImxModelCopyWithImpl<$Res, _$ImxModelImpl>
    implements _$$ImxModelImplCopyWith<$Res> {
  __$$ImxModelImplCopyWithImpl(
      _$ImxModelImpl _value, $Res Function(_$ImxModelImpl) _then)
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
    return _then(_$ImxModelImpl(
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
              as ImxClassification,
      calculatedAt: null == calculatedAt
          ? _value.calculatedAt
          : calculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ImxModelImpl implements _ImxModel {
  const _$ImxModelImpl(
      {required this.id,
      required this.score,
      required this.bodyScore,
      required this.metabolicScore,
      required this.lifestyleScore,
      required this.classification,
      required this.calculatedAt});

  factory _$ImxModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ImxModelImplFromJson(json);

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
  final ImxClassification classification;
  @override
  final DateTime calculatedAt;

  @override
  String toString() {
    return 'ImxModel(id: $id, score: $score, bodyScore: $bodyScore, metabolicScore: $metabolicScore, lifestyleScore: $lifestyleScore, classification: $classification, calculatedAt: $calculatedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ImxModelImpl &&
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
  _$$ImxModelImplCopyWith<_$ImxModelImpl> get copyWith =>
      __$$ImxModelImplCopyWithImpl<_$ImxModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ImxModelImplToJson(
      this,
    );
  }
}

abstract class _ImxModel implements ImxModel {
  const factory _ImxModel(
      {required final String id,
      required final double score,
      required final double bodyScore,
      required final double metabolicScore,
      required final double lifestyleScore,
      required final ImxClassification classification,
      required final DateTime calculatedAt}) = _$ImxModelImpl;

  factory _ImxModel.fromJson(Map<String, dynamic> json) =
      _$ImxModelImpl.fromJson;

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
  ImxClassification get classification;
  @override
  DateTime get calculatedAt;
  @override
  @JsonKey(ignore: true)
  _$$ImxModelImplCopyWith<_$ImxModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
