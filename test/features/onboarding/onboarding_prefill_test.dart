// SPEC-74 §CA-74-03, 04, 07: tests del helper puro OnboardingPrefill.

import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/features/onboarding/domain/onboarding_prefill.dart';

void main() {
  group('OnboardingPrefill.from — casos límite', () {
    test('null → empty', () {
      expect(OnboardingPrefill.from(null), OnboardingPrefill.empty);
      expect(OnboardingPrefill.from(null).filledCount, 0);
      expect(OnboardingPrefill.from(null).isEmpty, isTrue);
    });

    test('mapa vacío → empty', () {
      expect(OnboardingPrefill.from({}), OnboardingPrefill.empty);
    });

    test('shape MR típico (name + subscription) → solo name prefilled', () {
      final p = OnboardingPrefill.from({
        'name': 'Carlos MR',
        'email': 'carlos@mr.com',
        'subscription_active': true,
        'purchases': ['programa_2025'],
      });
      expect(p.name, 'Carlos MR');
      expect(p.weight, isNull);
      expect(p.height, isNull);
      expect(p.gender, isNull);
      expect(p.filledCount, 1);
    });
  });

  group('OnboardingPrefill.from — campos válidos', () {
    test('CA-74-03: weight/height/gender se transfieren con tipos correctos',
        () {
      final p = OnboardingPrefill.from({
        'name': 'Carlos',
        'weight': 84.5,
        'height': 178,
        'gender': 'M',
      });
      expect(p.weight, 84.5);
      expect(p.height, 178.0);
      expect(p.gender, 'M');
      expect(p.filledCount, 4); // name + weight + height + gender
    });

    test('birthYear directo', () {
      final p = OnboardingPrefill.from({'birthYear': 1985});
      expect(p.birthYear, 1985);
    });

    test('birthDate ISO se convierte a birthYear', () {
      final p = OnboardingPrefill.from({'birthDate': '1985-03-12'});
      expect(p.birthYear, 1985);
    });

    test('gender normalizado desde "Masculino" → "M"', () {
      expect(OnboardingPrefill.from({'gender': 'Masculino'}).gender, 'M');
      expect(OnboardingPrefill.from({'gender': 'male'}).gender, 'M');
      expect(OnboardingPrefill.from({'gender': 'F'}).gender, 'F');
      expect(OnboardingPrefill.from({'sex': 'Female'}).gender, 'F');
    });

    test('shirtSize válido en mayúsculas', () {
      expect(OnboardingPrefill.from({'shirtSize': 'L'}).shirtSize, 'L');
      expect(OnboardingPrefill.from({'tshirtSize': 'xl'}).shirtSize, 'XL');
    });

    test('claves alternativas (waist en lugar de waistCircumference)', () {
      final p = OnboardingPrefill.from({'waist': 92.5, 'neck': 40.0});
      expect(p.waistCircumference, 92.5);
      expect(p.neckCircumference, 40.0);
    });
  });

  group('OnboardingPrefill.from — CA-74-04 valores inválidos descartados', () {
    test('weight negativo → null', () {
      expect(OnboardingPrefill.from({'weight': -5}).weight, isNull);
    });

    test('weight cero → null (fuera de rango)', () {
      expect(OnboardingPrefill.from({'weight': 0}).weight, isNull);
    });

    test('weight absurdamente alto → null', () {
      expect(OnboardingPrefill.from({'weight': 999}).weight, isNull);
    });

    test('height fuera de rango → null', () {
      expect(OnboardingPrefill.from({'height': 10}).height, isNull);
      expect(OnboardingPrefill.from({'height': 300}).height, isNull);
    });

    test('gender no reconocido → null', () {
      expect(
        OnboardingPrefill.from({'gender': 'XYZ'}).gender,
        isNull,
      );
    });

    test('shirtSize fuera del set válido → null', () {
      expect(
        OnboardingPrefill.from({'shirtSize': 'XXL'}).shirtSize,
        isNull,
      );
    });

    test('birthYear muy antiguo o futuro → null', () {
      expect(OnboardingPrefill.from({'birthYear': 1800}).birthYear, isNull);
      expect(OnboardingPrefill.from({'birthYear': 3000}).birthYear, isNull);
    });

    test('pantSize fuera de rango → null', () {
      expect(OnboardingPrefill.from({'pantSize': 100}).pantSize, isNull);
      expect(OnboardingPrefill.from({'pantSize': 5}).pantSize, isNull);
    });

    test('mezcla válido + inválido → solo válidos prefilled', () {
      final p = OnboardingPrefill.from({
        'weight': 80.0, // válido
        'height': -10, // inválido
        'name': '', // string vacío descartado
        'gender': 'M',
      });
      expect(p.weight, 80.0);
      expect(p.height, isNull);
      expect(p.name, isNull);
      expect(p.gender, 'M');
      expect(p.filledCount, 2);
    });
  });

  group('OnboardingPrefill — Equatable / igualdad por valor', () {
    test('dos prefills con mismos campos son iguales', () {
      const a = OnboardingPrefill(weight: 80, height: 175, gender: 'M');
      const b = OnboardingPrefill(weight: 80, height: 175, gender: 'M');
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
