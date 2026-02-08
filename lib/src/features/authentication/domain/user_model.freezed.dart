// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'user_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AppUser _$AppUserFromJson(Map<String, dynamic> json) {
  return _AppUser.fromJson(json);
}

/// @nodoc
mixin _$AppUser {
  String get uid => throw _privateConstructorUsedError;
  String get email => throw _privateConstructorUsedError;
  String get displayName => throw _privateConstructorUsedError;
  bool get onboardingCompleted => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $AppUserCopyWith<AppUser> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AppUserCopyWith<$Res> {
  factory $AppUserCopyWith(AppUser value, $Res Function(AppUser) then) =
      _$AppUserCopyWithImpl<$Res, AppUser>;
  @useResult
  $Res call(
      {String uid, String email, String displayName, bool onboardingCompleted});
}

/// @nodoc
class _$AppUserCopyWithImpl<$Res, $Val extends AppUser>
    implements $AppUserCopyWith<$Res> {
  _$AppUserCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? email = null,
    Object? displayName = null,
    Object? onboardingCompleted = null,
  }) {
    return _then(_value.copyWith(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      onboardingCompleted: null == onboardingCompleted
          ? _value.onboardingCompleted
          : onboardingCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AppUserImplCopyWith<$Res> implements $AppUserCopyWith<$Res> {
  factory _$$AppUserImplCopyWith(
          _$AppUserImpl value, $Res Function(_$AppUserImpl) then) =
      __$$AppUserImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String uid, String email, String displayName, bool onboardingCompleted});
}

/// @nodoc
class __$$AppUserImplCopyWithImpl<$Res>
    extends _$AppUserCopyWithImpl<$Res, _$AppUserImpl>
    implements _$$AppUserImplCopyWith<$Res> {
  __$$AppUserImplCopyWithImpl(
      _$AppUserImpl _value, $Res Function(_$AppUserImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? uid = null,
    Object? email = null,
    Object? displayName = null,
    Object? onboardingCompleted = null,
  }) {
    return _then(_$AppUserImpl(
      uid: null == uid
          ? _value.uid
          : uid // ignore: cast_nullable_to_non_nullable
              as String,
      email: null == email
          ? _value.email
          : email // ignore: cast_nullable_to_non_nullable
              as String,
      displayName: null == displayName
          ? _value.displayName
          : displayName // ignore: cast_nullable_to_non_nullable
              as String,
      onboardingCompleted: null == onboardingCompleted
          ? _value.onboardingCompleted
          : onboardingCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AppUserImpl implements _AppUser {
  const _$AppUserImpl(
      {required this.uid,
      required this.email,
      required this.displayName,
      this.onboardingCompleted = false});

  factory _$AppUserImpl.fromJson(Map<String, dynamic> json) =>
      _$$AppUserImplFromJson(json);

  @override
  final String uid;
  @override
  final String email;
  @override
  final String displayName;
  @override
  @JsonKey()
  final bool onboardingCompleted;

  @override
  String toString() {
    return 'AppUser(uid: $uid, email: $email, displayName: $displayName, onboardingCompleted: $onboardingCompleted)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AppUserImpl &&
            (identical(other.uid, uid) || other.uid == uid) &&
            (identical(other.email, email) || other.email == email) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.onboardingCompleted, onboardingCompleted) ||
                other.onboardingCompleted == onboardingCompleted));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode =>
      Object.hash(runtimeType, uid, email, displayName, onboardingCompleted);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$AppUserImplCopyWith<_$AppUserImpl> get copyWith =>
      __$$AppUserImplCopyWithImpl<_$AppUserImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AppUserImplToJson(
      this,
    );
  }
}

abstract class _AppUser implements AppUser {
  const factory _AppUser(
      {required final String uid,
      required final String email,
      required final String displayName,
      final bool onboardingCompleted}) = _$AppUserImpl;

  factory _AppUser.fromJson(Map<String, dynamic> json) = _$AppUserImpl.fromJson;

  @override
  String get uid;
  @override
  String get email;
  @override
  String get displayName;
  @override
  bool get onboardingCompleted;
  @override
  @JsonKey(ignore: true)
  _$$AppUserImplCopyWith<_$AppUserImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

MedicalProfile _$MedicalProfileFromJson(Map<String, dynamic> json) {
  return _MedicalProfile.fromJson(json);
}

/// @nodoc
mixin _$MedicalProfile {
  DateTime get birthDate => throw _privateConstructorUsedError;
  double get heightCm => throw _privateConstructorUsedError;
  double get startWeightKg => throw _privateConstructorUsedError;
  double get currentWeightKg => throw _privateConstructorUsedError;

  /// Critical metric for cardiovascular risk assessment.
  double get waistCircumferenceCm => throw _privateConstructorUsedError;
  bool get hasPrediabetes => throw _privateConstructorUsedError;
  double? get targetWeightKg => throw _privateConstructorUsedError;
  MetabolicStage get metabolicStage => throw _privateConstructorUsedError;
  ActivityLevel get activityLevel => throw _privateConstructorUsedError;
  Gender get gender => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $MedicalProfileCopyWith<MedicalProfile> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $MedicalProfileCopyWith<$Res> {
  factory $MedicalProfileCopyWith(
          MedicalProfile value, $Res Function(MedicalProfile) then) =
      _$MedicalProfileCopyWithImpl<$Res, MedicalProfile>;
  @useResult
  $Res call(
      {DateTime birthDate,
      double heightCm,
      double startWeightKg,
      double currentWeightKg,
      double waistCircumferenceCm,
      bool hasPrediabetes,
      double? targetWeightKg,
      MetabolicStage metabolicStage,
      ActivityLevel activityLevel,
      Gender gender});
}

/// @nodoc
class _$MedicalProfileCopyWithImpl<$Res, $Val extends MedicalProfile>
    implements $MedicalProfileCopyWith<$Res> {
  _$MedicalProfileCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? birthDate = null,
    Object? heightCm = null,
    Object? startWeightKg = null,
    Object? currentWeightKg = null,
    Object? waistCircumferenceCm = null,
    Object? hasPrediabetes = null,
    Object? targetWeightKg = freezed,
    Object? metabolicStage = null,
    Object? activityLevel = null,
    Object? gender = null,
  }) {
    return _then(_value.copyWith(
      birthDate: null == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      heightCm: null == heightCm
          ? _value.heightCm
          : heightCm // ignore: cast_nullable_to_non_nullable
              as double,
      startWeightKg: null == startWeightKg
          ? _value.startWeightKg
          : startWeightKg // ignore: cast_nullable_to_non_nullable
              as double,
      currentWeightKg: null == currentWeightKg
          ? _value.currentWeightKg
          : currentWeightKg // ignore: cast_nullable_to_non_nullable
              as double,
      waistCircumferenceCm: null == waistCircumferenceCm
          ? _value.waistCircumferenceCm
          : waistCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double,
      hasPrediabetes: null == hasPrediabetes
          ? _value.hasPrediabetes
          : hasPrediabetes // ignore: cast_nullable_to_non_nullable
              as bool,
      targetWeightKg: freezed == targetWeightKg
          ? _value.targetWeightKg
          : targetWeightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      metabolicStage: null == metabolicStage
          ? _value.metabolicStage
          : metabolicStage // ignore: cast_nullable_to_non_nullable
              as MetabolicStage,
      activityLevel: null == activityLevel
          ? _value.activityLevel
          : activityLevel // ignore: cast_nullable_to_non_nullable
              as ActivityLevel,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as Gender,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$MedicalProfileImplCopyWith<$Res>
    implements $MedicalProfileCopyWith<$Res> {
  factory _$$MedicalProfileImplCopyWith(_$MedicalProfileImpl value,
          $Res Function(_$MedicalProfileImpl) then) =
      __$$MedicalProfileImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {DateTime birthDate,
      double heightCm,
      double startWeightKg,
      double currentWeightKg,
      double waistCircumferenceCm,
      bool hasPrediabetes,
      double? targetWeightKg,
      MetabolicStage metabolicStage,
      ActivityLevel activityLevel,
      Gender gender});
}

/// @nodoc
class __$$MedicalProfileImplCopyWithImpl<$Res>
    extends _$MedicalProfileCopyWithImpl<$Res, _$MedicalProfileImpl>
    implements _$$MedicalProfileImplCopyWith<$Res> {
  __$$MedicalProfileImplCopyWithImpl(
      _$MedicalProfileImpl _value, $Res Function(_$MedicalProfileImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? birthDate = null,
    Object? heightCm = null,
    Object? startWeightKg = null,
    Object? currentWeightKg = null,
    Object? waistCircumferenceCm = null,
    Object? hasPrediabetes = null,
    Object? targetWeightKg = freezed,
    Object? metabolicStage = null,
    Object? activityLevel = null,
    Object? gender = null,
  }) {
    return _then(_$MedicalProfileImpl(
      birthDate: null == birthDate
          ? _value.birthDate
          : birthDate // ignore: cast_nullable_to_non_nullable
              as DateTime,
      heightCm: null == heightCm
          ? _value.heightCm
          : heightCm // ignore: cast_nullable_to_non_nullable
              as double,
      startWeightKg: null == startWeightKg
          ? _value.startWeightKg
          : startWeightKg // ignore: cast_nullable_to_non_nullable
              as double,
      currentWeightKg: null == currentWeightKg
          ? _value.currentWeightKg
          : currentWeightKg // ignore: cast_nullable_to_non_nullable
              as double,
      waistCircumferenceCm: null == waistCircumferenceCm
          ? _value.waistCircumferenceCm
          : waistCircumferenceCm // ignore: cast_nullable_to_non_nullable
              as double,
      hasPrediabetes: null == hasPrediabetes
          ? _value.hasPrediabetes
          : hasPrediabetes // ignore: cast_nullable_to_non_nullable
              as bool,
      targetWeightKg: freezed == targetWeightKg
          ? _value.targetWeightKg
          : targetWeightKg // ignore: cast_nullable_to_non_nullable
              as double?,
      metabolicStage: null == metabolicStage
          ? _value.metabolicStage
          : metabolicStage // ignore: cast_nullable_to_non_nullable
              as MetabolicStage,
      activityLevel: null == activityLevel
          ? _value.activityLevel
          : activityLevel // ignore: cast_nullable_to_non_nullable
              as ActivityLevel,
      gender: null == gender
          ? _value.gender
          : gender // ignore: cast_nullable_to_non_nullable
              as Gender,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$MedicalProfileImpl implements _MedicalProfile {
  const _$MedicalProfileImpl(
      {required this.birthDate,
      required this.heightCm,
      required this.startWeightKg,
      required this.currentWeightKg,
      required this.waistCircumferenceCm,
      this.hasPrediabetes = false,
      this.targetWeightKg,
      this.metabolicStage = MetabolicStage.recovery,
      this.activityLevel = ActivityLevel.sedentary,
      this.gender = Gender.female});

  factory _$MedicalProfileImpl.fromJson(Map<String, dynamic> json) =>
      _$$MedicalProfileImplFromJson(json);

  @override
  final DateTime birthDate;
  @override
  final double heightCm;
  @override
  final double startWeightKg;
  @override
  final double currentWeightKg;

  /// Critical metric for cardiovascular risk assessment.
  @override
  final double waistCircumferenceCm;
  @override
  @JsonKey()
  final bool hasPrediabetes;
  @override
  final double? targetWeightKg;
  @override
  @JsonKey()
  final MetabolicStage metabolicStage;
  @override
  @JsonKey()
  final ActivityLevel activityLevel;
  @override
  @JsonKey()
  final Gender gender;

  @override
  String toString() {
    return 'MedicalProfile(birthDate: $birthDate, heightCm: $heightCm, startWeightKg: $startWeightKg, currentWeightKg: $currentWeightKg, waistCircumferenceCm: $waistCircumferenceCm, hasPrediabetes: $hasPrediabetes, targetWeightKg: $targetWeightKg, metabolicStage: $metabolicStage, activityLevel: $activityLevel, gender: $gender)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$MedicalProfileImpl &&
            (identical(other.birthDate, birthDate) ||
                other.birthDate == birthDate) &&
            (identical(other.heightCm, heightCm) ||
                other.heightCm == heightCm) &&
            (identical(other.startWeightKg, startWeightKg) ||
                other.startWeightKg == startWeightKg) &&
            (identical(other.currentWeightKg, currentWeightKg) ||
                other.currentWeightKg == currentWeightKg) &&
            (identical(other.waistCircumferenceCm, waistCircumferenceCm) ||
                other.waistCircumferenceCm == waistCircumferenceCm) &&
            (identical(other.hasPrediabetes, hasPrediabetes) ||
                other.hasPrediabetes == hasPrediabetes) &&
            (identical(other.targetWeightKg, targetWeightKg) ||
                other.targetWeightKg == targetWeightKg) &&
            (identical(other.metabolicStage, metabolicStage) ||
                other.metabolicStage == metabolicStage) &&
            (identical(other.activityLevel, activityLevel) ||
                other.activityLevel == activityLevel) &&
            (identical(other.gender, gender) || other.gender == gender));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      birthDate,
      heightCm,
      startWeightKg,
      currentWeightKg,
      waistCircumferenceCm,
      hasPrediabetes,
      targetWeightKg,
      metabolicStage,
      activityLevel,
      gender);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$MedicalProfileImplCopyWith<_$MedicalProfileImpl> get copyWith =>
      __$$MedicalProfileImplCopyWithImpl<_$MedicalProfileImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$MedicalProfileImplToJson(
      this,
    );
  }
}

abstract class _MedicalProfile implements MedicalProfile {
  const factory _MedicalProfile(
      {required final DateTime birthDate,
      required final double heightCm,
      required final double startWeightKg,
      required final double currentWeightKg,
      required final double waistCircumferenceCm,
      final bool hasPrediabetes,
      final double? targetWeightKg,
      final MetabolicStage metabolicStage,
      final ActivityLevel activityLevel,
      final Gender gender}) = _$MedicalProfileImpl;

  factory _MedicalProfile.fromJson(Map<String, dynamic> json) =
      _$MedicalProfileImpl.fromJson;

  @override
  DateTime get birthDate;
  @override
  double get heightCm;
  @override
  double get startWeightKg;
  @override
  double get currentWeightKg;
  @override

  /// Critical metric for cardiovascular risk assessment.
  double get waistCircumferenceCm;
  @override
  bool get hasPrediabetes;
  @override
  double? get targetWeightKg;
  @override
  MetabolicStage get metabolicStage;
  @override
  ActivityLevel get activityLevel;
  @override
  Gender get gender;
  @override
  @JsonKey(ignore: true)
  _$$MedicalProfileImplCopyWith<_$MedicalProfileImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
