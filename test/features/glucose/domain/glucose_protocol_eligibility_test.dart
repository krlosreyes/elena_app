// Módulo "Tu Glucosa" — tests de GlucoseProtocolEligibility (propuesta
// §5.2/§11, R1). Mismo patrón de construcción de UserModel que
// streak/domain/fasting_eligibility_test.dart.

import 'package:elena_app/src/features/glucose/domain/glucose_protocol_eligibility.dart';
import 'package:elena_app/src/features/streak/domain/fasting_eligibility.dart'
    show FastingPathologyFlags;
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user({List<String> pathologies = const ['Ninguna']}) => UserModel(
      age: 30,
      gender: 'F',
      weight: 65,
      height: 165,
      pathologies: pathologies,
      profile: CircadianProfile(
        wakeUpTime: DateTime(2026, 1, 1, 7),
        sleepTime: DateTime(2026, 1, 1, 23),
      ),
    );

void main() {
  group('GlucoseProtocolEligibility.assess', () {
    test('sin patologías relevantes → no elegible', () {
      final e = GlucoseProtocolEligibility.assess(_user());
      expect(e.eligible, isFalse);
      expect(e.reason, isNull);
    });

    test('prediabetes → elegible con razón', () {
      final e = GlucoseProtocolEligibility.assess(
        _user(pathologies: [GlucosePathologyFlags.prediabetes]),
      );
      expect(e.eligible, isTrue);
      expect(e.reason, isNotNull);
    });

    test('diabetes T2 → elegible', () {
      final e = GlucoseProtocolEligibility.assess(
        _user(pathologies: [GlucosePathologyFlags.diabetesT2]),
      );
      expect(e.eligible, isTrue);
    });

    test('diabetes medicada (insulina/sulfonilureas) → NO elegible, '
        'aunque también declare prediabetes', () {
      final e = GlucoseProtocolEligibility.assess(
        _user(pathologies: [
          GlucosePathologyFlags.prediabetes,
          FastingPathologyFlags.diabetesMedicada,
        ]),
      );
      expect(e.eligible, isFalse);
      expect(e.reason, contains('médico'));
    });

    test('diabetes medicada sola (sin prediabetes/T2) → no elegible', () {
      final e = GlucoseProtocolEligibility.assess(
        _user(pathologies: [FastingPathologyFlags.diabetesMedicada]),
      );
      expect(e.eligible, isFalse);
    });
  });
}
