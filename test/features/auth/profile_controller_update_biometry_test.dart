// SPEC-88 + SPEC-143: tests del método `ProfileController.updateBiometry`.
//
// Pre-SPEC-143 verificaba que `saveProfile` recibía un UserModel.copyWith
// con los cambios. Tras SPEC-143 el controller delega en
// `BiometricHistoryService.updateFromProfileEdit(currentUser, delta)`, que
// internamente versiona biometric_history + actualiza el doc raíz
// atómicamente. La signature pública del controller no cambió.
//
// Estos tests verifican el nuevo contrato: el delta llega al servicio con
// los campos correctos, los campos no pasados quedan null en el delta
// (los preserva el baseline al aplicarlo), y el estado del notifier
// refleja éxito/error.

import 'package:elena_app/src/features/auth/application/profile_controller.dart';
import 'package:elena_app/src/features/progress/application/biometric_history_service.dart';
import 'package:elena_app/src/features/progress/data/biometric_repository.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';
import 'package:elena_app/src/features/progress/domain/biometric_delta.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-88 + SPEC-143 — ProfileController.updateBiometry', () {
    late _CapturingHistoryService captured;
    late ProviderContainer container;

    setUp(() {
      captured = _CapturingHistoryService();
      container = ProviderContainer(overrides: [
        biometricHistoryServiceProvider.overrideWithValue(captured),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    test('weight individual → delta con weight, otros campos null', () async {
      final user = _testUser(weight: 80);
      await container
          .read(profileControllerProvider.notifier)
          .updateBiometry(currentUser: user, weight: 82.5);

      expect(captured.capturedDelta, isNotNull);
      expect(captured.capturedDelta!.weight, 82.5);
      expect(captured.capturedDelta!.waistCircumference, isNull);
      expect(captured.capturedDelta!.neckCircumference, isNull);
      expect(captured.capturedDelta!.bodyFatPercentage, isNull);
      expect(captured.capturedUser!.id, user.id);
    });

    test('campos no pasados quedan null en el delta (baseline preserva)',
        () async {
      final user = _testUser(weight: 80, waist: 85, neck: 38, bodyFat: 18);
      await container.read(profileControllerProvider.notifier).updateBiometry(
            currentUser: user,
            bodyFatPercentage: 16.5,
          );

      expect(captured.capturedDelta!.bodyFatPercentage, 16.5);
      expect(captured.capturedDelta!.weight, isNull,
          reason: 'No se pasó weight → delta no debe tener weight');
      expect(captured.capturedDelta!.waistCircumference, isNull);
      expect(captured.capturedDelta!.neckCircumference, isNull);
      // El baseline currentUser preserva los valores actuales — el servicio
      // los re-aplica via delta.applyTo() internamente al construir el snapshot.
      expect(captured.capturedUser!.weight, 80);
      expect(captured.capturedUser!.waistCircumference, 85);
    });

    test('múltiples campos en una llamada → delta con varios', () async {
      final user = _testUser(weight: 80, waist: 85);
      await container.read(profileControllerProvider.notifier).updateBiometry(
            currentUser: user,
            weight: 78,
            waistCircumference: 82,
          );

      expect(captured.capturedDelta!.weight, 78);
      expect(captured.capturedDelta!.waistCircumference, 82);
      expect(captured.capturedDelta!.neckCircumference, isNull);
    });

    test('estado savedSuccessfully tras save exitoso', () async {
      final user = _testUser();
      await container
          .read(profileControllerProvider.notifier)
          .updateBiometry(currentUser: user, weight: 80);

      final state = container.read(profileControllerProvider);
      expect(state.isSaving, isFalse);
      expect(state.savedSuccessfully, isTrue);
      expect(state.errorMessage, isNull);
    });

    test('error del servicio → estado con errorMessage', () async {
      captured.shouldFail = true;
      final user = _testUser();
      await container
          .read(profileControllerProvider.notifier)
          .updateBiometry(currentUser: user, weight: 80);

      final state = container.read(profileControllerProvider);
      expect(state.isSaving, isFalse);
      expect(state.errorMessage, contains('biométricos'));
    });
  });
}

UserModel _testUser({
  double weight = 80,
  double? waist = 80,
  double? neck = 38,
  double bodyFat = 20,
}) {
  return UserModel(
    id: 'test-uid',
    name: 'Test',
    age: 35,
    gender: 'M',
    weight: weight,
    height: 180,
    waistCircumference: waist,
    neckCircumference: neck,
    bodyFatPercentage: bodyFat,
    profile: CircadianProfile(
      wakeUpTime: DateTime(2026, 1, 1, 6),
      sleepTime: DateTime(2026, 1, 1, 22),
      firstMealGoal: DateTime(2026, 1, 1, 8),
      lastMealGoal: DateTime(2026, 1, 1, 18),
    ),
  );
}

/// Fake del BiometricHistoryService que captura los argumentos de
/// `updateFromProfileEdit` para verificar el delta y el currentUser
/// que el controller construye y envía.
///
/// Hereda del servicio real con un FakeFirebaseFirestore-backed repo
/// (no-op porque sobrescribimos updateFromProfileEdit antes de tocar el
/// repo). Esto evita tener que extraer una interfaz solo para tests.
class _CapturingHistoryService extends BiometricHistoryService {
  _CapturingHistoryService()
      : super(biometricRepo: BiometricRepository(FakeFirebaseFirestore()));

  UserModel? capturedUser;
  BiometricDelta? capturedDelta;
  bool shouldFail = false;

  @override
  Future<void> updateFromProfileEdit({
    required UserModel currentUser,
    required BiometricDelta delta,
  }) async {
    if (shouldFail) throw Exception('disk full');
    capturedUser = currentUser;
    capturedDelta = delta;
  }

  // Métodos no usados en estos tests — los dejamos como no-op para que
  // accidentalmente no escriban al fake firestore si alguien los llama.

  @override
  Future<void> updateFromCheckInSheet({
    required UserModel currentUser,
    required BiometricCheckIn checkInData,
  }) async {}

  @override
  Future<void> updateFromHealthKitSync({
    required UserModel currentUser,
    required BiometricDelta delta,
  }) async {}

  @override
  Future<void> updateFromBodyFatRecompute({
    required UserModel currentUser,
    required double newBodyFatPercentage,
  }) async {}

  @override
  Future<void> writeOnboardingBaseline({
    required UserModel currentUser,
  }) async {}

  @override
  Future<void> writeSpec143BackfillEntry({
    required UserModel currentUser,
  }) async {}
}
