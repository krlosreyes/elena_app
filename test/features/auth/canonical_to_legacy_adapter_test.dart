// SPEC-84 §6 — Tests del adapter inverso canónico → legacy.

import 'package:elena_app/src/features/auth/domain/canonical_to_legacy_adapter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-84 — CanonicalToLegacyAdapter casos límite', () {
    test('null → mapa vacío', () {
      expect(CanonicalToLegacyAdapter.deriveLegacyFields(null), isEmpty);
    });

    test('mapa vacío → mapa vacío', () {
      expect(CanonicalToLegacyAdapter.deriveLegacyFields({}), isEmpty);
    });

    test('shape solo con campos desconocidos → mapa vacío', () {
      expect(
        CanonicalToLegacyAdapter.deriveLegacyFields({
          'random_field': 'x',
          'subscription_active': true,
        }),
        isEmpty,
      );
    });
  });

  group('SPEC-84 — name y gender', () {
    test('displayName → name', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'displayName': 'Carlos MR',
      });
      expect(r['name'], 'Carlos MR');
    });

    test('genderCanonical "male" → gender "M"', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'genderCanonical': 'male',
      });
      expect(r['gender'], 'M');
    });

    test('genderCanonical "female" → gender "F"', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'genderCanonical': 'female',
      });
      expect(r['gender'], 'F');
    });

    test('genderCanonical desconocido → gender omitido', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'genderCanonical': 'no-binario',
      });
      expect(r.containsKey('gender'), isFalse);
    });
  });

  group('SPEC-84 — age desde birthDate / birthYear', () {
    test('birthDate ISO → age derivado', () {
      // Una persona nacida en 1985 hoy (2026) tiene 41 (si ya cumplió)
      // o 40 (si no). Aceptamos ambos.
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'birthDate': '1985-06-15',
      });
      final age = r['age'] as int;
      expect(age, anyOf(40, 41));
    });

    test('birthYear directo → age', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'birthYear': 1990,
      });
      final age = r['age'] as int;
      expect(age, anyOf(35, 36));
    });

    test('age plano gana sobre birthDate (legacy explícito)', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'age': 38,
        'birthDate': '1990-01-01',
      });
      expect(r['age'], 38);
    });

    test('birthYear absurdo → age omitido', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'birthYear': 1800,
      });
      expect(r.containsKey('age'), isFalse);
    });
  });

  group('SPEC-84 — bio.* mapean a campos legacy', () {
    test('bio completo se traduce correctamente', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'bio': {
          'heightCm': 180,
          'weightKg': 80.5,
          'waistCm': 85,
          'neckCm': 39,
          'bodyFatPct': 18,
        },
      });
      expect(r['height'], 180);
      expect(r['weight'], 80.5);
      expect(r['waistCircumference'], 85);
      expect(r['neckCircumference'], 39);
      expect(r['bodyFatPercentage'], 18);
    });

    test('bio parcial omite campos faltantes', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'bio': {'heightCm': 175},
      });
      expect(r['height'], 175);
      expect(r.containsKey('weight'), isFalse);
      expect(r.containsKey('waistCircumference'), isFalse);
    });
  });

  group('SPEC-84 — habits.* mapean inverso', () {
    test('fastingHours 0 → fastingProtocol "Ninguno"', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'habits': {'fastingHours': 0},
      });
      expect(r['fastingProtocol'], 'Ninguno');
    });

    test('fastingHours 16 → "16:8"', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'habits': {'fastingHours': 16},
      });
      expect(r['fastingProtocol'], '16:8');
    });

    test('fastingHours 18 → "18:6"', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'habits': {'fastingHours': 18},
      });
      expect(r['fastingProtocol'], '18:6');
    });

    test('fastingHours 20 → "20:4"', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'habits': {'fastingHours': 20},
      });
      expect(r['fastingProtocol'], '20:4');
    });

    test('fastingHours desconocido → omitido', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'habits': {'fastingHours': 22},
      });
      expect(r.containsKey('fastingProtocol'), isFalse);
    });

    test('exerciseMinutesPerDay → exerciseGoalMinutes', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'habits': {'exerciseMinutesPerDay': 30},
      });
      expect(r['exerciseGoalMinutes'], 30);
    });

    test('lastMealHour 21.5 → DateTime con hora 21:30', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'habits': {'lastMealHour': 21.5},
      });
      final dt = r['lastMealGoal'] as DateTime;
      expect(dt.hour, 21);
      expect(dt.minute, 30);
    });

    test('dinnerHour como fallback de lastMealHour', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'habits': {'dinnerHour': 19.0},
      });
      final dt = r['lastMealGoal'] as DateTime;
      expect(dt.hour, 19);
      expect(dt.minute, 0);
    });
  });

  group('SPEC-84 — healthDisclaimerAccepted', () {
    test('true se propaga al map legacy', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'healthDisclaimerAccepted': true,
      });
      expect(r['healthDisclaimerAccepted'], isTrue);
    });

    test('false también se propaga', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'healthDisclaimerAccepted': false,
      });
      expect(r['healthDisclaimerAccepted'], isFalse);
    });

    test('ausente → no aparece en el output', () {
      expect(
        CanonicalToLegacyAdapter.deriveLegacyFields({
          'displayName': 'X',
        }).containsKey('healthDisclaimerAccepted'),
        isFalse,
      );
    });
  });

  group('SPEC-84 — shape canónico completo', () {
    test('un usuario MR completo se mapea íntegramente', () {
      final r = CanonicalToLegacyAdapter.deriveLegacyFields({
        'displayName': 'Carlos',
        'genderCanonical': 'male',
        'birthYear': 1985,
        'bio': {
          'heightCm': 180,
          'weightKg': 82,
          'waistCm': 88,
          'neckCm': 40,
          'bodyFatPct': 19,
        },
        'habits': {
          'fastingHours': 16,
          'exerciseMinutesPerDay': 30,
          'lastMealHour': 19.5,
        },
        'healthDisclaimerAccepted': true,
      });
      expect(r['name'], 'Carlos');
      expect(r['gender'], 'M');
      expect(r['age'], anyOf(40, 41));
      expect(r['height'], 180);
      expect(r['weight'], 82);
      expect(r['waistCircumference'], 88);
      expect(r['neckCircumference'], 40);
      expect(r['bodyFatPercentage'], 19);
      expect(r['fastingProtocol'], '16:8');
      expect(r['exerciseGoalMinutes'], 30);
      expect((r['lastMealGoal'] as DateTime).hour, 19);
      expect((r['lastMealGoal'] as DateTime).minute, 30);
      expect(r['healthDisclaimerAccepted'], isTrue);
    });
  });
}
