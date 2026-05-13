// SPEC-82 §6 — Test integración: tras completeOnboarding, el repository
// recibe un `updateCurrentImr` con un IMR baseline (imrScore <= 50)
// para que el sitio web Metamorfosis Real tenga score visible.

import 'package:elena_app/src/features/auth/domain/app_account.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/onboarding/application/onboarding_controller.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/domain/repositories/user_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-82 — completeOnboarding persiste imr.current baseline', () {
    late _CapturingRepo repo;
    late ProviderContainer container;

    setUp(() async {
      repo = _CapturingRepo();
      container = ProviderContainer(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(repo),
          authStateProvider.overrideWith(
            (ref) => Stream<AppAccount?>.value(_fakeAccount),
          ),
        ],
      );
      // Esperar al primer emit del authStateProvider override.
      await container.read(authStateProvider.future);
    });

    tearDown(() {
      container.dispose();
    });

    test('repo.updateCurrentImr recibe el baseline con imrScore <= 50',
        () async {
      final controller =
          container.read(onboardingControllerProvider.notifier);
      await controller.completeOnboarding(_testUser());

      expect(repo.capturedUid, 'test-uid');
      expect(repo.capturedImr, isNotNull);
      final imr = repo.capturedImr!;
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

    test('imr.current contiene los campos canónicos derivados', () async {
      final controller =
          container.read(onboardingControllerProvider.notifier);
      await controller.completeOnboarding(_testUser());

      final imr = repo.capturedImr!;
      expect(imr.containsKey('imrScore'), isTrue);
      expect(imr.containsKey('label'), isTrue);
      expect(imr.containsKey('blocks'), isTrue);
      expect(imr.containsKey('imc'), isTrue);
      expect(imr.containsKey('tmb'), isTrue);
      expect(imr.containsKey('metabolicAge'), isTrue);
      expect(imr.containsKey('ica'), isTrue);
      expect(imr.containsKey('ffmi'), isTrue);
      expect(imr.containsKey('whtr'), isTrue);
    });

    test('saveProfile también se llamó (preserva flujo legacy)', () async {
      final controller =
          container.read(onboardingControllerProvider.notifier);
      await controller.completeOnboarding(_testUser());

      expect(repo.savedUser, isNotNull);
      expect(repo.savedUser!.id, 'test-uid');
    });
  });

  group('SPEC-85 — proteger imr.current pre-existente', () {
    late _CapturingRepo repo;
    late ProviderContainer container;

    setUp(() async {
      repo = _CapturingRepo();
      container = ProviderContainer(
        overrides: [
          userProfileRepositoryProvider.overrideWithValue(repo),
          // Cuenta MR con imr.current pre-existente del sitio.
          authStateProvider.overrideWith(
            (ref) => Stream<AppAccount?>.value(_fakeAccountWithSiteImr),
          ),
        ],
      );
      await container.read(authStateProvider.future);
    });

    tearDown(() {
      container.dispose();
    });

    test('NO persiste baseline cuando imr.current ya existe en rawProfile',
        () async {
      final controller =
          container.read(onboardingControllerProvider.notifier);
      await controller.completeOnboarding(_testUser());

      // saveProfile sí se llamó (legacy preservado).
      expect(repo.savedUser, isNotNull);
      // updateCurrentImr NO se llamó: respetamos el 52 del sitio.
      expect(repo.capturedImr, isNull);
      expect(repo.capturedUid, isNull);
    });
  });
}

// ─────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────

const AppAccount _fakeAccount = AppAccount(
  uid: 'test-uid',
  email: 'test@example.com',
  profileStatus: AppProfileStatus.completeProfile,
);

// SPEC-85: usuario que ya tiene imr.current escrito por el sitio web.
const AppAccount _fakeAccountWithSiteImr = AppAccount(
  uid: 'test-uid',
  email: 'test@example.com',
  profileStatus: AppProfileStatus.completeProfile,
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

UserModel _testUser({
  String id = 'test-uid',
  String name = 'Test',
}) {
  return UserModel(
    id: id,
    name: name,
    age: 30,
    gender: 'M',
    weight: 80,
    height: 180,
    waistCircumference: 85,
    bodyFatPercentage: 18,
    profile: CircadianProfile(
      wakeUpTime: DateTime(2026, 1, 1, 6),
      sleepTime: DateTime(2026, 1, 1, 22),
      firstMealGoal: DateTime(2026, 1, 1, 8),
      lastMealGoal: DateTime(2026, 1, 1, 18),
    ),
  );
}

/// Captura las llamadas a `saveProfile` y `updateCurrentImr` para
/// que el test verifique que el OnboardingController las disparó.
class _CapturingRepo implements UserProfileRepository {
  UserModel? savedUser;
  String? capturedUid;
  Map<String, dynamic>? capturedImr;

  @override
  Future<void> saveProfile(UserModel user) async {
    savedUser = user;
  }

  @override
  Future<void> updateCurrentImr(
    String userId,
    Map<String, dynamic> imrCurrent,
  ) async {
    capturedUid = userId;
    capturedImr = imrCurrent;
  }

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
  Stream<UserModel?> watchProfile(String userId) => Stream.value(null);

  @override
  Stream<Map<String, dynamic>?> watchCurrentImr(String userId) =>
      Stream.value(null);
}
