// SPEC-257 RF-257-VERIFICACION: tests del gate médico de elegibilidad
// (Eje A). Cubre las 8 reglas en orden de severidad definidas en
// `FastingEligibility.assess` — ver specs/SPEC-257-clasificacion-protocolo-ayuno.md §4.

import 'package:elena_app/src/features/streak/domain/fasting_eligibility.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user({
  int age = 30,
  double weight = 65,
  double height = 165,
  List<String> pathologies = const ['Ninguna'],
}) =>
    UserModel(
      age: age,
      gender: 'F',
      weight: weight,
      height: height,
      pathologies: pathologies,
      profile: CircadianProfile(
        wakeUpTime: DateTime(2026, 1, 1, 7),
        sleepTime: DateTime(2026, 1, 1, 23),
      ),
    );

void main() {
  group('FastingEligibility.assess', () {
    test('sin patologías, IMC normal → tope 22:2, sin bloqueo', () {
      final e = FastingEligibility.assess(_user());
      expect(e.maxProtocol, '22:2');
      expect(e.blocked, isFalse);
      expect(e.hasMedicalSupervision, isFalse);
      expect(e.allows('20:4'), isTrue);
      expect(e.allows('OMAD'), isFalse);
    });

    test('menor de edad → bloqueado, sin excepción', () {
      final e = FastingEligibility.assess(_user(age: 16));
      expect(e.maxProtocol, 'Ninguno');
      expect(e.blocked, isTrue);
    });

    test('embarazo/lactancia → bloqueado', () {
      final e = FastingEligibility.assess(
        _user(pathologies: [FastingPathologyFlags.embarazoLactancia]),
      );
      expect(e.blocked, isTrue);
      expect(e.maxProtocol, 'Ninguno');
    });

    test('trastorno alimentario declarado → bloqueado', () {
      final e = FastingEligibility.assess(
        _user(pathologies: [FastingPathologyFlags.trastornoAlimentario]),
      );
      expect(e.blocked, isTrue);
    });

    test('IMC < 18.5 → bloqueado', () {
      final e = FastingEligibility.assess(_user(weight: 48, height: 165));
      expect(e.blocked, isTrue);
      expect(e.maxProtocol, 'Ninguno');
    });

    test('IMC 18.5–20 → tope 20:4, no bloqueado', () {
      final e = FastingEligibility.assess(_user(weight: 53, height: 165));
      expect(e.blocked, isFalse);
      expect(e.maxProtocol, '20:4');
    });

    test('diabetes medicada sin supervisión → tope 14:10', () {
      final e = FastingEligibility.assess(
        _user(pathologies: [FastingPathologyFlags.diabetesMedicada]),
      );
      expect(e.blocked, isFalse);
      expect(e.maxProtocol, '14:10');
      expect(e.hasMedicalSupervision, isFalse);
    });

    test('diabetes medicada CON supervisión → desbloquea OMAD (regla de severidad: supervisión gana)', () {
      final e = FastingEligibility.assess(
        _user(pathologies: [
          FastingPathologyFlags.diabetesMedicada,
          FastingPathologyFlags.supervisionMedicaActiva,
        ]),
      );
      expect(e.maxProtocol, 'OMAD');
      expect(e.hasMedicalSupervision, isTrue);
    });

    test('supervisión médica activa sola → desbloquea catálogo completo', () {
      final e = FastingEligibility.assess(
        _user(pathologies: [FastingPathologyFlags.supervisionMedicaActiva]),
      );
      expect(e.maxProtocol, 'OMAD');
      expect(e.blocked, isFalse);
      expect(e.allows('OMAD'), isTrue);
    });
  });

  group('FastingEligibility.allows / clamp', () {
    test('allows() respeta el orden de la escalera, no el nombre', () {
      const e = FastingEligibility(
        maxProtocol: '16:8',
        blocked: false,
        hasMedicalSupervision: false,
      );
      expect(e.allows('12:12'), isTrue);
      expect(e.allows('16:8'), isTrue);
      expect(e.allows('18:6'), isFalse);
      expect(e.allows('OMAD'), isFalse);
    });

    test('clamp() recorta un deseo por encima del tope', () {
      const e = FastingEligibility(
        maxProtocol: '16:8',
        blocked: false,
        hasMedicalSupervision: false,
      );
      expect(e.clamp('20:4'), '16:8');
      expect(e.clamp('14:10'), '14:10');
    });

    test('clamp() con protocolo desconocido cae al tope (conservador)', () {
      const e = FastingEligibility(
        maxProtocol: '16:8',
        blocked: false,
        hasMedicalSupervision: false,
      );
      expect(e.clamp('36h'), '16:8');
    });
  });
}
