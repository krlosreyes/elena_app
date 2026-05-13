// SPEC-88: tests del nuevo método `ProfileController.updateBiometry`.
// Verifica que `saveProfile` se llama con el UserModel.copyWith
// esperado para cada campo biométrico y combinaciones.

import 'package:elena_app/src/features/auth/application/profile_controller.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/domain/repositories/user_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-88 — ProfileController.updateBiometry', () {
    late _CapturingRepo repo;
    late ProviderContainer container;

    setUp(() {
      repo = _CapturingRepo();
      container = ProviderContainer(overrides: [
        userProfileRepositoryProvider.overrideWithValue(repo),
      ]);
    });

    tearDown(() {
      container.dispose();
    });

    test('weight individual → saveProfile con weight actualizado', () async {
      final user = _testUser(weight: 80);
      await container
          .read(profileControllerProvider.notifier)
          .updateBiometry(currentUser: user, weight: 82.5);

      expect(repo.savedUser, isNotNull);
      expect(repo.savedUser!.weight, 82.5);
      expect(repo.savedUser!.waistCircumference, user.waistCircumference);
    });

    test('campos no pasados se preservan del usuario actual', () async {
      final user = _testUser(weight: 80, waist: 85, neck: 38, bodyFat: 18);
      await container.read(profileControllerProvider.notifier).updateBiometry(
            currentUser: user,
            bodyFatPercentage: 16.5,
          );

      expect(repo.savedUser!.bodyFatPercentage, 16.5);
      expect(repo.savedUser!.weight, 80);
      expect(repo.savedUser!.waistCircumference, 85);
      expect(repo.savedUser!.neckCircumference, 38);
    });

    test('múltiples campos en una llamada', () async {
      final user = _testUser(weight: 80, waist: 85);
      await container.read(profileControllerProvider.notifier).updateBiometry(
            currentUser: user,
            weight: 78,
            waistCircumference: 82,
          );

      expect(repo.savedUser!.weight, 78);
      expect(repo.savedUser!.waistCircumference, 82);
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

    test('error de repo → estado con errorMessage', () async {
      repo.shouldFail = true;
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

class _CapturingRepo implements UserProfileRepository {
  UserModel? savedUser;
  bool shouldFail = false;

  @override
  Future<void> saveProfile(UserModel user) async {
    if (shouldFail) throw Exception('disk full');
    savedUser = user;
  }

  // ── No-ops ─────────────────────────────────────────────────────────

  @override
  Stream<UserModel?> watchProfile(String userId) => Stream.value(null);

  @override
  Future<void> updateWeeklyAdherence(String userId, double adherence) async {}

  @override
  Future<void> saveProtocolAdjustment(
    String userId,
    Map<String, dynamic> adjustment,
  ) async {}

  @override
  Future<void> applyProtocolAdjustment({
    required String userId,
    String? newFastingProtocol,
    int? newExerciseGoal,
  }) async {}

  @override
  Future<void> updateCurrentImr(
    String userId,
    Map<String, dynamic> imrCurrent,
  ) async {}

  @override
  Stream<Map<String, dynamic>?> watchCurrentImr(String userId) =>
      Stream.value(null);
}
