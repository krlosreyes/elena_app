// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'imr_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ImrModel {
  String get id;
  double get score;
  double get bodyScore;
  double get metabolicScore;
  double get lifestyleScore;
  ImrClassification get classification;
  DateTime get calculatedAt;

  /// Create a copy of ImrModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ImrModelCopyWith<ImrModel> get copyWith =>
      _$ImrModelCopyWithImpl<ImrModel>(this as ImrModel, _$identity);

  /// Serializes this ImrModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ImrModel &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, score, bodyScore,
      metabolicScore, lifestyleScore, classification, calculatedAt);

  @override
  String toString() {
    return 'ImrModel(id: $id, score: $score, bodyScore: $bodyScore, metabolicScore: $metabolicScore, lifestyleScore: $lifestyleScore, classification: $classification, calculatedAt: $calculatedAt)';
  }
}

/// @nodoc
abstract mixin class $ImrModelCopyWith<$Res> {
  factory $ImrModelCopyWith(ImrModel value, $Res Function(ImrModel) _then) =
      _$ImrModelCopyWithImpl;
  @useResult
  $Res call(
      {String id,
      double score,
      double bodyScore,
      double metabolicScore,
      double lifestyleScore,
      ImrClassification classification,
      DateTime calculatedAt});
}

/// @nodoc
class _$ImrModelCopyWithImpl<$Res> implements $ImrModelCopyWith<$Res> {
  _$ImrModelCopyWithImpl(this._self, this._then);

  final ImrModel _self;
  final $Res Function(ImrModel) _then;

  /// Create a copy of ImrModel
  /// with the given fields replaced by the non-null parameter values.
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
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      score: null == score
          ? _self.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      bodyScore: null == bodyScore
          ? _self.bodyScore
          : bodyScore // ignore: cast_nullable_to_non_nullable
              as double,
      metabolicScore: null == metabolicScore
          ? _self.metabolicScore
          : metabolicScore // ignore: cast_nullable_to_non_nullable
              as double,
      lifestyleScore: null == lifestyleScore
          ? _self.lifestyleScore
          : lifestyleScore // ignore: cast_nullable_to_non_nullable
              as double,
      classification: null == classification
          ? _self.classification
          : classification // ignore: cast_nullable_to_non_nullable
              as ImrClassification,
      calculatedAt: null == calculatedAt
          ? _self.calculatedAt
          : calculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// Adds pattern-matching-related methods to [ImrModel].
extension ImrModelPatterns on ImrModel {
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
    TResult Function(_ImrModel value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ImrModel() when $default != null:
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
    TResult Function(_ImrModel value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImrModel():
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
    TResult? Function(_ImrModel value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImrModel() when $default != null:
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
            double score,
            double bodyScore,
            double metabolicScore,
            double lifestyleScore,
            ImrClassification classification,
            DateTime calculatedAt)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ImrModel() when $default != null:
        return $default(
            _that.id,
            _that.score,
            _that.bodyScore,
            _that.metabolicScore,
            _that.lifestyleScore,
            _that.classification,
            _that.calculatedAt);
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
            double score,
            double bodyScore,
            double metabolicScore,
            double lifestyleScore,
            ImrClassification classification,
            DateTime calculatedAt)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImrModel():
        return $default(
            _that.id,
            _that.score,
            _that.bodyScore,
            _that.metabolicScore,
            _that.lifestyleScore,
            _that.classification,
            _that.calculatedAt);
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
            double score,
            double bodyScore,
            double metabolicScore,
            double lifestyleScore,
            ImrClassification classification,
            DateTime calculatedAt)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ImrModel() when $default != null:
        return $default(
            _that.id,
            _that.score,
            _that.bodyScore,
            _that.metabolicScore,
            _that.lifestyleScore,
            _that.classification,
            _that.calculatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ImrModel implements ImrModel {
  const _ImrModel(
      {required this.id,
      required this.score,
      required this.bodyScore,
      required this.metabolicScore,
      required this.lifestyleScore,
      required this.classification,
      required this.calculatedAt});
  factory _ImrModel.fromJson(Map<String, dynamic> json) =>
      _$ImrModelFromJson(json);

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
  final ImrClassification classification;
  @override
  final DateTime calculatedAt;

  /// Create a copy of ImrModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ImrModelCopyWith<_ImrModel> get copyWith =>
      __$ImrModelCopyWithImpl<_ImrModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ImrModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ImrModel &&
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

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, score, bodyScore,
      metabolicScore, lifestyleScore, classification, calculatedAt);

  @override
  String toString() {
    return 'ImrModel(id: $id, score: $score, bodyScore: $bodyScore, metabolicScore: $metabolicScore, lifestyleScore: $lifestyleScore, classification: $classification, calculatedAt: $calculatedAt)';
  }
}

/// @nodoc
abstract mixin class _$ImrModelCopyWith<$Res>
    implements $ImrModelCopyWith<$Res> {
  factory _$ImrModelCopyWith(_ImrModel value, $Res Function(_ImrModel) _then) =
      __$ImrModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String id,
      double score,
      double bodyScore,
      double metabolicScore,
      double lifestyleScore,
      ImrClassification classification,
      DateTime calculatedAt});
}

/// @nodoc
class __$ImrModelCopyWithImpl<$Res> implements _$ImrModelCopyWith<$Res> {
  __$ImrModelCopyWithImpl(this._self, this._then);

  final _ImrModel _self;
  final $Res Function(_ImrModel) _then;

  /// Create a copy of ImrModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? score = null,
    Object? bodyScore = null,
    Object? metabolicScore = null,
    Object? lifestyleScore = null,
    Object? classification = null,
    Object? calculatedAt = null,
  }) {
    return _then(_ImrModel(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      score: null == score
          ? _self.score
          : score // ignore: cast_nullable_to_non_nullable
              as double,
      bodyScore: null == bodyScore
          ? _self.bodyScore
          : bodyScore // ignore: cast_nullable_to_non_nullable
              as double,
      metabolicScore: null == metabolicScore
          ? _self.metabolicScore
          : metabolicScore // ignore: cast_nullable_to_non_nullable
              as double,
      lifestyleScore: null == lifestyleScore
          ? _self.lifestyleScore
          : lifestyleScore // ignore: cast_nullable_to_non_nullable
              as double,
      classification: null == classification
          ? _self.classification
          : classification // ignore: cast_nullable_to_non_nullable
              as ImrClassification,
      calculatedAt: null == calculatedAt
          ? _self.calculatedAt
          : calculatedAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
