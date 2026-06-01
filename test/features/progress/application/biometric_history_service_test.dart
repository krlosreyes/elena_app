// SPEC-143 §8.1: tests del BiometricHistoryService.
//
// Estrategia: FakeFirebaseFirestore + BiometricRepository real. Verifica
// tanto la lógica del servicio como la transacción atómica del batch.

import 'package:elena_app/src/features/progress/application/biometric_history_service.dart';
import 'package:elena_app/src/features/progress/data/biometric_repository.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:elena_app/src/features/progress/domain/biometric_delta.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

final _defaultProfile = CircadianProfile(
  wakeUpTime: DateTime(2026, 1, 1, 7, 0),
  sleepTime: DateTime(2026, 1, 1, 23, 0),
);

UserModel _user({
  String id = 'u1',
  double weight = 75.0,
  double? waistCircumference = 90.0,
  double? neckCircumference = 38.0,
  double? bodyFatPercentage = 20.0,
  bool isMeasurementEstimated = false,
}) =>
    UserModel(
      id: id,
      age: 35,
      gender: 'M',
      weight: weight,
      height: 175,
      waistCircumference: waistCircumference,
      neckCircumference: neckCircumference,
      bodyFatPercentage: bodyFatPercentage,
      isMeasurementEstimated: isMeasurementEstimated,
      profile: _defaultProfile,
    );

Future<Map<String, dynamic>?> _readUserDoc(
  FakeFirebaseFirestore fs,
  String uid,
) async {
  final snap = await fs.collection('users').doc(uid).get();
  return snap.data();
}

Future<Map<String, dynamic>?> _readHistoryDoc(
  FakeFirebaseFirestore fs,
  String uid,
  String date,
) async {
  final snap = await fs
      .collection('users')
      .doc(uid)
      .collection('biometric_history')
      .doc(date)
      .get();
  return snap.data();
}

String _todayKey(DateTime now) =>
    '${now.year.toString().padLeft(4, '0')}-'
    '${now.month.toString().padLeft(2, '0')}-'
    '${now.day.toString().padLeft(2, '0')}';

void main() {
  late FakeFirebaseFirestore firestore;
  late BiometricRepository repo;
  late BiometricHistoryService service;
  final fixedNow = DateTime(2026, 6, 1, 10, 30);

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    repo = BiometricRepository(firestore);
    service = BiometricHistoryService(
      biometricRepo: repo,
      clock: () => fixedNow,
    );
    // Doc raíz del usuario debe existir para que `batch.update` funcione.
    await firestore.collection('users').doc('u1').set(<String, dynamic>{
      'id': 'u1',
      'weight': 75.0,
      'waistCircumference': 90.0,
      'neckCircumference': 38.0,
      'bodyFatPercentage': 20.0,
      'isMeasurementEstimated': false,
    });
  });

  group('SPEC-143 §8.1 — updateFromProfileEdit', () {
    test('Escribe a ambos lugares atómicamente con source profile_edit', () async {
      await service.updateFromProfileEdit(
        currentUser: _user(),
        delta: const BiometricDelta(weight: 73.0),
      );

      final userDoc = await _readUserDoc(firestore, 'u1');
      expect(userDoc!['weight'], 73.0);
      expect(userDoc['waistCircumference'], 90.0, reason: 'No tocado');

      final histDoc = await _readHistoryDoc(firestore, 'u1', _todayKey(fixedNow));
      expect(histDoc!['weight'], 73.0);
      expect(histDoc['source'], BiometricSource.profileEdit);
      expect(histDoc['previousValues'], isA<Map<String, dynamic>>());
      expect(histDoc['previousValues']['weight'], 75.0);
    });

    test('Delta vacío → no escribe nada', () async {
      await service.updateFromProfileEdit(
        currentUser: _user(),
        delta: const BiometricDelta(),
      );

      final histDoc = await _readHistoryDoc(firestore, 'u1', _todayKey(fixedNow));
      expect(histDoc, isNull, reason: 'No debería existir doc histórico');
    });

    test('Múltiples campos cambiados → previousValues incluye solo los movidos',
        () async {
      await service.updateFromProfileEdit(
        currentUser: _user(),
        delta: const BiometricDelta(
          weight: 73.0,
          bodyFatPercentage: 18.0,
        ),
      );

      final histDoc = await _readHistoryDoc(firestore, 'u1', _todayKey(fixedNow));
      final prev = histDoc!['previousValues'] as Map<String, dynamic>;
      expect(prev['weight'], 75.0);
      expect(prev['bodyFatPercentage'], 20.0);
      expect(prev.containsKey('waistCircumference'), isFalse);
    });
  });

  group('SPEC-143 §8.1 — updateFromCheckInSheet', () {
    test('Preserva notes e imrScore del sheet', () async {
      final checkin = BiometricCheckIn(
        date: _todayKey(fixedNow),
        userId: 'u1',
        weight: 74.0,
        waistCircumference: 89.0,
        notes: 'check-in semanal',
        imrScore: 72,
        createdAt: fixedNow,
      );
      await service.updateFromCheckInSheet(
        currentUser: _user(),
        checkInData: checkin,
      );

      final histDoc = await _readHistoryDoc(firestore, 'u1', _todayKey(fixedNow));
      expect(histDoc!['source'], BiometricSource.checkinSheet);
      expect(histDoc['notes'], 'check-in semanal');
      expect(histDoc['imrScore'], 72);
    });
  });

  group('SPEC-143 §8.1 — updateFromHealthKitSync', () {
    test('Delta < 0.5% → NO escribe (ruido del sensor)', () async {
      await service.updateFromHealthKitSync(
        currentUser: _user(weight: 75.0),
        delta: const BiometricDelta(weight: 75.2),
      );

      final histDoc = await _readHistoryDoc(firestore, 'u1', _todayKey(fixedNow));
      expect(histDoc, isNull);
    });

    test('Delta significativo → SÍ escribe con source healthkit_sync', () async {
      await service.updateFromHealthKitSync(
        currentUser: _user(weight: 75.0),
        delta: const BiometricDelta(weight: 73.0),
      );

      final histDoc = await _readHistoryDoc(firestore, 'u1', _todayKey(fixedNow));
      expect(histDoc, isNotNull);
      expect(histDoc!['source'], BiometricSource.healthkitSync);
    });
  });

  group('SPEC-143 §8.1 — updateFromBodyFatRecompute (con throttle R-08)', () {
    test('Primera llamada → escribe con source bodyfat_recompute', () async {
      await service.updateFromBodyFatRecompute(
        currentUser: _user(),
        newBodyFatPercentage: 18.5,
      );

      final histDoc = await _readHistoryDoc(firestore, 'u1', _todayKey(fixedNow));
      expect(histDoc!['source'], BiometricSource.bodyFatRecompute);
      expect(histDoc['bodyFatPercentage'], 18.5);
    });

    test('Solo actualiza bodyFatPercentage, preserva otros campos', () async {
      await service.updateFromBodyFatRecompute(
        currentUser: _user(),
        newBodyFatPercentage: 18.5,
      );

      final userDoc = await _readUserDoc(firestore, 'u1');
      expect(userDoc!['bodyFatPercentage'], 18.5);
      expect(userDoc['weight'], 75.0, reason: 'No tocado');
      expect(userDoc['waistCircumference'], 90.0, reason: 'No tocado');
    });

    test('Throttle: segunda llamada en < 30s → NO escribe', () async {
      // Usar clock que avanza solo 10 segundos.
      var clockNow = DateTime(2026, 6, 1, 10, 30);
      final throttledService = BiometricHistoryService(
        biometricRepo: repo,
        clock: () => clockNow,
      );

      await throttledService.updateFromBodyFatRecompute(
        currentUser: _user(),
        newBodyFatPercentage: 18.5,
      );

      clockNow = clockNow.add(const Duration(seconds: 10));

      await throttledService.updateFromBodyFatRecompute(
        currentUser: _user(bodyFatPercentage: 18.5),
        newBodyFatPercentage: 18.2,
      );

      final userDoc = await _readUserDoc(firestore, 'u1');
      expect(userDoc!['bodyFatPercentage'], 18.5,
          reason: 'Segunda llamada throttled, debe quedar el primer valor');
    });

    test('Después de 30s+ → segunda llamada SÍ escribe', () async {
      var clockNow = DateTime(2026, 6, 1, 10, 30);
      final throttledService = BiometricHistoryService(
        biometricRepo: repo,
        clock: () => clockNow,
      );

      await throttledService.updateFromBodyFatRecompute(
        currentUser: _user(),
        newBodyFatPercentage: 18.5,
      );

      clockNow = clockNow.add(const Duration(seconds: 31));

      await throttledService.updateFromBodyFatRecompute(
        currentUser: _user(bodyFatPercentage: 18.5),
        newBodyFatPercentage: 18.2,
      );

      final userDoc = await _readUserDoc(firestore, 'u1');
      expect(userDoc!['bodyFatPercentage'], 18.2,
          reason: '> 30s, throttle expirado');
    });
  });

  group('SPEC-143 §8.1 — writeOnboardingBaseline', () {
    test('Crea primera entrada del historial con source onboarding_baseline',
        () async {
      await service.writeOnboardingBaseline(currentUser: _user());

      final histDoc = await _readHistoryDoc(firestore, 'u1', _todayKey(fixedNow));
      expect(histDoc, isNotNull);
      expect(histDoc!['source'], BiometricSource.onboardingBaseline);
      expect(histDoc['previousValues'], isNull,
          reason: 'Primera entrada — no hay versión anterior');
      expect(histDoc['weight'], 75.0);
    });

    test('NO actualiza el doc raíz del usuario (onboarding ya lo persistió)',
        () async {
      await firestore.collection('users').doc('u1').update({'weight': 100.0});
      await service.writeOnboardingBaseline(currentUser: _user(weight: 75.0));

      final userDoc = await _readUserDoc(firestore, 'u1');
      expect(userDoc!['weight'], 100.0,
          reason: 'El baseline NO debe pisar el doc raíz');
    });
  });

  group('SPEC-143 §8.1 — múltiples updates mismo día', () {
    test('Sobrescriben el mismo doc PK yyyy-MM-dd, último gana', () async {
      await service.updateFromProfileEdit(
        currentUser: _user(weight: 75.0),
        delta: const BiometricDelta(weight: 74.0),
      );
      await service.updateFromProfileEdit(
        currentUser: _user(weight: 74.0),
        delta: const BiometricDelta(weight: 73.0),
      );

      final histDoc = await _readHistoryDoc(firestore, 'u1', _todayKey(fixedNow));
      expect(histDoc!['weight'], 73.0,
          reason: 'Último write del día gana');
      expect(histDoc['previousValues']['weight'], 74.0,
          reason: 'previousValues apunta al penúltimo, no al primer original');
    });

    test('Una sola entrada en biometric_history para ese día', () async {
      await service.updateFromProfileEdit(
        currentUser: _user(weight: 75.0),
        delta: const BiometricDelta(weight: 74.0),
      );
      await service.updateFromProfileEdit(
        currentUser: _user(weight: 74.0),
        delta: const BiometricDelta(weight: 73.0),
      );

      final snap = await firestore
          .collection('users')
          .doc('u1')
          .collection('biometric_history')
          .get();
      expect(snap.docs.length, 1);
    });
  });

  group('SPEC-143 §8.1 — writeSpec143BackfillEntry', () {
    test('Persiste con source spec_143_backfill', () async {
      await service.writeSpec143BackfillEntry(currentUser: _user());

      final histDoc = await _readHistoryDoc(firestore, 'u1', _todayKey(fixedNow));
      expect(histDoc!['source'], BiometricSource.spec143Backfill);
    });
  });
}
