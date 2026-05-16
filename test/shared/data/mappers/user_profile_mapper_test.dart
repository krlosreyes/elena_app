// SPEC-50.5: tests del UserProfileMapper.

import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/shared/data/mappers/user_profile_mapper.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = UserProfileMapper();

  CircadianProfile profile() => CircadianProfile(
        wakeUpTime: DateTime(2026, 5, 1, 6),
        sleepTime: DateTime(2026, 5, 1, 22),
      );

  UserModel user({
    String id = 'user-1',
    int age = 30,
    String gender = 'M',
    double weight = 75,
    double height = 175,
    // SPEC-92: bodyFatPercentage es nullable. Tests que necesiten un
    // valor concreto siguen pasándolo; los que prueban "sin medir"
    // pasan null explícito.
    double? bodyFatPercentage = 20,
  }) {
    return UserModel(
      id: id,
      age: age,
      gender: gender,
      weight: weight,
      height: height,
      bodyFatPercentage: bodyFatPercentage,
      profile: profile(),
    );
  }

  group('toMap (delegación a Freezed.toJson)', () {
    test('Persiste campos requeridos del UserModel', () {
      final map = mapper.toMap(user());
      expect(map['id'], 'user-1');
      expect(map['age'], 30);
      expect(map['gender'], 'M');
      expect(map['weight'], 75);
      expect(map['height'], 175);
    });

    test('Persiste el CircadianProfile como sub-objeto', () {
      final map = mapper.toMap(user());
      expect(map['profile'], isA<Map<String, dynamic>>());
    });
  });

  group('fromMap', () {
    test('Round-trip preserva campos primarios', () {
      final original = user();
      final map = mapper.toMap(original);
      final round = mapper.fromMap(map);
      expect(round.id, original.id);
      expect(round.age, original.age);
      expect(round.weight, original.weight);
    });
  });

  group('toMap — validaciones SPEC-62', () {
    test('rechaza id vacío con EmptyField', () {
      expect(
        () => mapper.toMap(user(id: '')),
        throwsA(isA<EmptyField>()
            .having((e) => e.fieldName, 'fieldName', 'UserModel.id')),
      );
    });

    test('rechaza age fuera de [0, 130] con OutOfRange', () {
      expect(
        () => mapper.toMap(user(age: -1)),
        throwsA(isA<OutOfRange>()),
      );
      expect(
        () => mapper.toMap(user(age: 200)),
        throwsA(isA<OutOfRange>()),
      );
    });

    test('rechaza weight <= 0 con OutOfRange', () {
      expect(
        () => mapper.toMap(user(weight: 0)),
        throwsA(isA<OutOfRange>()),
      );
      expect(
        () => mapper.toMap(user(weight: -10)),
        throwsA(isA<OutOfRange>()),
      );
    });

    test('rechaza height <= 0 con OutOfRange', () {
      expect(
        () => mapper.toMap(user(height: 0)),
        throwsA(isA<OutOfRange>()),
      );
    });

    test('rechaza bodyFatPercentage fuera de [0, 70] con OutOfRange', () {
      expect(
        () => mapper.toMap(user(bodyFatPercentage: -5)),
        throwsA(isA<OutOfRange>()),
      );
      expect(
        () => mapper.toMap(user(bodyFatPercentage: 80)),
        throwsA(isA<OutOfRange>()),
      );
    });

    test('Acepta valores en frontera', () {
      expect(() => mapper.toMap(user(age: 0)), returnsNormally);
      expect(() => mapper.toMap(user(age: 130)), returnsNormally);
      expect(
        () => mapper.toMap(user(bodyFatPercentage: 0)),
        returnsNormally,
      );
      expect(
        () => mapper.toMap(user(bodyFatPercentage: 70)),
        returnsNormally,
      );
    });

    test('SPEC-92: bodyFatPercentage null no lanza, persiste como null', () {
      expect(
        () => mapper.toMap(user(bodyFatPercentage: null)),
        returnsNormally,
      );
      final map = mapper.toMap(user(bodyFatPercentage: null));
      expect(map['bodyFatPercentage'], isNull);
    });
  });
}
