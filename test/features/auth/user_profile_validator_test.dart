// SPEC-73 §CA-73-07: tests del invariante "perfil completo".
//
// El validador es puro (sin Firebase, sin Riverpod). Cubre las 3 ramas
// que el AuthRepository consume para clasificar AppProfileStatus:
//   - isCompleteFromRaw(missing field) → false
//   - isCompleteFromRaw(MR shape) → false
//   - isCompleteFromRaw(complete) → true
// y los wrappers `isComplete(UserModel)` para coherencia.

import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/domain/validators/user_profile_validator.dart';

void main() {
  group('UserProfileValidator.isCompleteFromRaw', () {
    test('mapa vacío → incompleto', () {
      expect(UserProfileValidator.isCompleteFromRaw({}), isFalse);
    });

    test('shape MR típico (name, email, subscription) → incompleto', () {
      final raw = {
        'name': 'Carlos',
        'email': 'carlos@mr.com',
        'subscription_active': true,
      };
      expect(UserProfileValidator.isCompleteFromRaw(raw), isFalse);
    });

    test('age cero → incompleto', () {
      final raw = {
        'age': 0,
        'gender': 'M',
        'weight': 80.0,
        'height': 175.0,
        'profile': {'wakeUpTime': DateTime.now().toIso8601String()},
      };
      expect(UserProfileValidator.isCompleteFromRaw(raw), isFalse);
    });

    test('weight cero → incompleto', () {
      final raw = {
        'age': 35,
        'gender': 'M',
        'weight': 0.0,
        'height': 175.0,
        'profile': {'wakeUpTime': DateTime.now().toIso8601String()},
      };
      expect(UserProfileValidator.isCompleteFromRaw(raw), isFalse);
    });

    test('profile ausente → incompleto', () {
      final raw = {
        'age': 35,
        'gender': 'M',
        'weight': 80.0,
        'height': 175.0,
      };
      expect(UserProfileValidator.isCompleteFromRaw(raw), isFalse);
    });

    test('todos los campos mínimos presentes → completo', () {
      final raw = {
        'age': 35,
        'gender': 'M',
        'weight': 80.0,
        'height': 175.0,
        'profile': {
          'wakeUpTime': DateTime.now().toIso8601String(),
          'sleepTime': DateTime.now().toIso8601String(),
        },
      };
      expect(UserProfileValidator.isCompleteFromRaw(raw), isTrue);
    });

    test('tolera Numeric/double coerción (Firestore puede devolver int)', () {
      final raw = {
        'age': 35,
        'gender': 'M',
        'weight': 80, // int en lugar de double
        'height': 175, // int en lugar de double
        'profile': {'wakeUpTime': DateTime.now().toIso8601String()},
      };
      expect(UserProfileValidator.isCompleteFromRaw(raw), isTrue);
    });
  });

  group('UserProfileValidator.isComplete (UserModel)', () {
    UserModel buildUser({
      int age = 0,
      double weight = 0.0,
      double height = 0.0,
    }) {
      return UserModel(
        id: 'u1',
        age: age,
        gender: 'M',
        weight: weight,
        height: height,
        profile: CircadianProfile(
          wakeUpTime: DateTime(2026, 1, 1, 7),
          sleepTime: DateTime(2026, 1, 1, 22),
        ),
      );
    }

    test('UserModel default (age/weight/height 0) → incompleto', () {
      expect(UserProfileValidator.isComplete(buildUser()), isFalse);
    });

    test('UserModel con todos los valores positivos → completo', () {
      expect(
        UserProfileValidator.isComplete(
          buildUser(age: 35, weight: 80.0, height: 175.0),
        ),
        isTrue,
      );
    });
  });
}
