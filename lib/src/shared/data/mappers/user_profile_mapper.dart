// SPEC-50.5: traductor entre Map<String, dynamic> y UserModel.
//
// UserModel es Freezed con json_serializable. El mapper delega
// serialización al modelo y solo añade validaciones SPEC-62.

import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

class UserProfileMapper {
  const UserProfileMapper();

  Map<String, dynamic> toMap(UserModel user) {
    _validate(user);
    return user.toJson();
  }

  UserModel fromMap(Map<String, dynamic> map) {
    return UserModel.fromJson(map);
  }

  void _validate(UserModel user) {
    if (user.id.isEmpty) {
      throw const EmptyField(field: 'UserModel.id');
    }
    if (user.age < 0 || user.age > 130) {
      throw OutOfRange(
        field: 'UserModel.age',
        value: user.age,
        min: 0,
        max: 130,
      );
    }
    if (user.weight <= 0) {
      throw OutOfRange(
        field: 'UserModel.weight',
        value: user.weight,
        min: 0.1,
        max: 500,
      );
    }
    if (user.height <= 0) {
      throw OutOfRange(
        field: 'UserModel.height',
        value: user.height,
        min: 30,
        max: 250,
      );
    }
    if (user.bodyFatPercentage < 0 || user.bodyFatPercentage > 70) {
      throw OutOfRange(
        field: 'UserModel.bodyFatPercentage',
        value: user.bodyFatPercentage,
        min: 0,
        max: 70,
      );
    }
  }
}
