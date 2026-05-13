// SPEC-82 §6 — Tests del canonical mirror del UserProfileMapper.
//
// Verifica que `toMap` produce shape legacy + shape canónico en el
// mismo doc, sin colisiones y sin perder campos.

import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/shared/data/mappers/user_profile_mapper.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = UserProfileMapper();

  group('SPEC-82 — toMap shape canónico top-level', () {
    test('displayName = user.name (legacy intacto)', () {
      final user = _testUser(name: 'Carlos');
      final map = mapper.toMap(user);
      expect(map['displayName'], 'Carlos');
      expect(map['name'], 'Carlos');
    });

    test('genderCanonical: M → male, F → female (legacy gender intacto)', () {
      final male = mapper.toMap(_testUser(gender: 'M'));
      final female = mapper.toMap(_testUser(gender: 'F'));
      expect(male['genderCanonical'], 'male');
      expect(male['gender'], 'M');
      expect(female['genderCanonical'], 'female');
      expect(female['gender'], 'F');
    });

    test('meta.schemaVersion = 1 y createdAt ISO', () {
      final map = mapper.toMap(_testUser());
      final meta = map['meta'] as Map<String, dynamic>;
      expect(meta['schemaVersion'], 1);
      expect(meta['createdAt'], isA<String>());
      expect(DateTime.tryParse(meta['createdAt'] as String), isNotNull);
    });
  });

  group('SPEC-82 — bio agrupa biometría', () {
    test('campos de bio mapean desde UserModel', () {
      final user = _testUser(
        height: 180,
        weight: 80,
        waist: 85,
        neck: 39,
        bodyFat: 18,
      );
      final map = mapper.toMap(user);
      final bio = map['bio'] as Map<String, dynamic>;
      expect(bio['heightCm'], 180);
      expect(bio['weightKg'], 80);
      expect(bio['waistCm'], 85);
      expect(bio['neckCm'], 39);
      expect(bio['bodyFatPct'], 18);
      expect(bio['leanMassPct'], closeTo(82, 0.01));
      expect(bio['hipCm'], isNull);
      expect(bio['updatedAt'], isA<String>());
    });

    test('bio.waistCm puede ser null si no se midió', () {
      final user = _testUser(waist: null);
      final map = mapper.toMap(user);
      final bio = map['bio'] as Map<String, dynamic>;
      expect(bio['waistCm'], isNull);
    });
  });

  group('SPEC-82 — habits parsea hábitos del usuario', () {
    test('fastingHours mapea desde fastingProtocol', () {
      expect(_habits('Ninguno')['fastingHours'], 0);
      expect(_habits('16:8')['fastingHours'], 16);
      expect(_habits('18:6')['fastingHours'], 18);
      expect(_habits('20:4')['fastingHours'], 20);
    });

    test('fastingHours es null si protocol es desconocido', () {
      expect(_habits('inventado')['fastingHours'], isNull);
    });

    test('dinnerHour y lastMealHour son hora float (21:30 → 21.5)', () {
      final user = _testUser(
        lastMealGoal: DateTime(2026, 1, 1, 21, 30),
      );
      final map = mapper.toMap(user);
      final habits = map['habits'] as Map<String, dynamic>;
      expect(habits['dinnerHour'], 21.5);
      expect(habits['lastMealHour'], 21.5);
    });

    test('source es "self_report" por default', () {
      final habits =
          mapper.toMap(_testUser())['habits'] as Map<String, dynamic>;
      expect(habits['source'], 'self_report');
    });

    test('sleepQuality e hydrationLitresPerDay quedan null en write inicial',
        () {
      final habits =
          mapper.toMap(_testUser())['habits'] as Map<String, dynamic>;
      expect(habits['sleepQuality'], isNull);
      expect(habits['hydrationLitresPerDay'], isNull);
    });

    test('exerciseMinutesPerDay mapea desde exerciseGoalMinutes', () {
      final user = _testUser(exerciseGoalMinutes: 45);
      final habits = mapper.toMap(user)['habits'] as Map<String, dynamic>;
      expect(habits['exerciseMinutesPerDay'], 45);
    });
  });

  group('SPEC-82 — Coexistencia legacy + canónico', () {
    test('shape legacy intacto tras agregar canónico', () {
      final user = _testUser(
        id: 'uid-1',
        name: 'Carlos',
        gender: 'M',
        weight: 80,
        height: 180,
        waist: 85,
        bodyFat: 18,
      );
      final map = mapper.toMap(user);

      // Legacy presente.
      expect(map['id'], 'uid-1');
      expect(map['name'], 'Carlos');
      expect(map['age'], 30);
      expect(map['gender'], 'M');
      expect(map['weight'], 80);
      expect(map['height'], 180);
      expect(map['waistCircumference'], 85);
      expect(map['bodyFatPercentage'], 18);
      expect(map['profile'], isA<Map>());

      // Canónico también presente.
      expect(map['displayName'], 'Carlos');
      expect(map['genderCanonical'], 'male');
      expect(map['bio'], isA<Map>());
      expect(map['habits'], isA<Map>());
      expect(map['meta'], isA<Map>());
    });
  });

  group('SPEC-82 — imrToCanonicalMap', () {
    test('mapea IMRv2Result al shape que el sitio espera', () {
      const imr = IMRv2Result(
        totalScore: 72,
        structureScore: 0.8,
        metabolicScore: 0.6,
        behaviorScore: 0.7,
        circadianAlignment: 1.0,
        zone: 'FUNCIONAL',
        description: 'Estado metabólico funcional con margen de mejora.',
        imc: 24.6913580247,
        tmb: 1755,
        metabolicAge: 30,
        ica: 0.5,
        ffmi: 20.0,
        whtr: 0.5,
      );
      final map = imrToCanonicalMap(imr);

      expect(map['imrScore'], 72);
      expect(map['label'], 'FUNCIONAL');
      final blocks = map['blocks'] as Map<String, double>;
      expect(blocks['E'], 0.8);
      expect(blocks['M'], 0.6);
      expect(blocks['C'], 0.7);
      expect(map['imc'], closeTo(24.69, 0.01));
      expect(map['tmb'], 1755);
      expect(map['metabolicAge'], 30);
      expect(map['ica'], 0.5);
      expect(map['ffmi'], closeTo(20.0, 0.01));
      expect(map['whtr'], 0.5);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────

Map<String, dynamic> _habits(String protocol) {
  final user = _testUser(fastingProtocol: protocol);
  final map = const UserProfileMapper().toMap(user);
  return map['habits'] as Map<String, dynamic>;
}

UserModel _testUser({
  String id = 'test-uid',
  String name = 'Test',
  String gender = 'M',
  int age = 30,
  double weight = 80,
  double height = 180,
  double? waist = 80,
  double? neck = 38,
  double bodyFat = 18,
  String fastingProtocol = '16:8',
  int exerciseGoalMinutes = 20,
  DateTime? lastMealGoal,
}) {
  return UserModel(
    id: id,
    name: name,
    age: age,
    gender: gender,
    weight: weight,
    height: height,
    waistCircumference: waist,
    neckCircumference: neck,
    bodyFatPercentage: bodyFat,
    fastingProtocol: fastingProtocol,
    exerciseGoalMinutes: exerciseGoalMinutes,
    profile: CircadianProfile(
      wakeUpTime: DateTime(2026, 1, 1, 6),
      sleepTime: DateTime(2026, 1, 1, 22),
      firstMealGoal: DateTime(2026, 1, 1, 8),
      lastMealGoal: lastMealGoal ?? DateTime(2026, 1, 1, 18),
    ),
  );
}
