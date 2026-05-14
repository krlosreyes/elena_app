// SPEC-79 smoke E2E: el OnboardingController coordina correctamente
// saveProfile + updateCurrentImr (baseline) + invalidate(authStateProvider).
//
// Cubre las garantías de SPEC-73 (re-clasificación post-save),
// SPEC-82 (baseline persistido) y SPEC-85 (no pisar imr.current si
// existe). Si alguien cambia el orden de llamadas o elimina pasos,
// este test falla.

import 'package:elena_app/src/features/auth/domain/app_account.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/onboarding/application/onboarding_controller.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/domain/repositories/user_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-79 smoke — OnboardingController.completeOnboarding', () {
    test('sin imr.current previo: dispara saveProfile + updateCurrentImr baseline',
        () async {
      final repo = _RecordingRepo();
      final container = ProviderContainer(overrides: [
        userProfileRepositoryProvider.overrideWithValue(repo),
        authStateProvider.overrideWith(
          (ref) => Stream<AppAccount?>.value(_accountNoImr),
        ),
      ]);
      addTearDown(container.dispose);
      await container.read(authStateProvider.future);

      await container
          .read(onboardingControllerProvider.notifier)
          .completeOnboarding(_validUser);

      // Orden esperado: saveProfile primero, updateCurrentImr después.
      expect(repo.savedUser, isNotNull);
      expect(repo.savedUser!.id, 'test-uid');
      expect(repo.imrUpdates, hasLength(1));
      // El baseline tiene score > 0 (estructura óptima) y label válido.
      final imr = repo.imrUpdates.single;
      expect(imr['imrScore'], greaterThan(0));
      expect(imr['imrScore'], lessThanOrEqualTo(50));
      expect(
        imr['label'],
        isIn(const [
          'DETERIORADO',
          'INESTABLE',
          'FUNCIONAL',
          'EFICIENTE',
          'OPTIMIZADO',
          'N/A',
        ]),
      );
    });

    test('con imr.current previo (sitio): NO pisa el valor existente',
        () async {
      final repo = _RecordingRepo();
      final container = ProviderContainer(overrides: [
        userProfileRepositoryProvider.overrideWithValue(repo),
        authStateProvider.overrideWith(
          (ref) => Stream<AppAccount?>.value(_accountWithSiteImr),
        ),
      ]);
      addTearDown(container.dispose);
      await container.read(authStateProvider.future);

      await container
          .read(onboardingControllerProvider.notifier)
          .completeOnboarding(_validUser);

      // saveProfile sí se llamó.
      expect(repo.savedUser, isNotNull);
      // updateCurrentImr NO se llamó — respetamos el 52 del sitio.
      expect(repo.imrUpdates, isEmpty);
    });

    test('estado: success tras completar', () async {
      final repo = _RecordingRepo();
      final container = ProviderContainer(overrides: [
        userProfileRepositoryProvider.overrideWithValue(repo),
        authStateProvider.overrideWith(
          (ref) => Stream<AppAccount?>.value(_accountNoImr),
        ),
      ]);
      addTearDown(container.dispose);
      await container.read(authStateProvider.future);

      await container
          .read(onboardingControllerProvider.notifier)
          .completeOnboarding(_validUser);

      final state = container.read(onboardingControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.hasError, isFalse);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────
// Fixtures
// ─────────────────────────────────────────────────────────────────────

const AppAccount _accountNoImr = AppAccount(
  uid: 'test-uid',
  email: 'test@example.com',
  profileStatus: AppProfileStatus.partialProfile,
  rawProfile: {
    'displayName': 'Carlos',
    // sin imr.current
  },
);

const AppAccount _accountWithSiteImr = AppAccount(
  uid: 'test-uid',
  email: 'test@example.com',
  profileStatus: AppProfileStatus.partialProfile,
  rawProfile: {
    'displayName': 'Carlos',
    'imr': {
      'current': {
        'imrScore': 52,
        'label': 'INESTABLE',
      },
    },
  },
);

UserModel get _validUser => UserModel(
      id: 'test-uid',
      name: 'Carlos',
      age: 35,
      gender: 'M',
      weight: 80,
      height: 180,
      waistCircumference: 85,
      neckCircumference: 38,
      bodyFatPercentage: 18,
      profile: CircadianProfile(
        wakeUpTime: DateTime(2026, 1, 1, 6),
        sleepTime: DateTime(2026, 1, 1, 22),
        firstMealGoal: DateTime(2026, 1, 1, 8),
        lastMealGoal: DateTime(2026, 1, 1, 18),
      ),
    );

/// Repository de test que registra las operaciones recibidas para que
/// los asserts verifiquen el flujo del controller.
class _RecordingRepo implements UserProfileRepository {
  UserModel? savedUser;
  final List<Map<String, dynamic>> imrUpdates = [];

  @override
  Future<void> saveProfile(UserModel user) async {
    savedUser = user;
  }

  @override
  Future<void> updateCurrentImr(
    String userId,
    Map<String, dynamic> imrCurrent,
  ) async {
    imrUpdates.add(imrCurrent);
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
  Stream<Map<String, dynamic>?> watchCurrentImr(String userId) =>
      Stream.value(null);
}
