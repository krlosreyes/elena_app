// SPEC-86 §6 — Tests del displayedImrProvider.
//
// Verifica la regla de decisión: local gana cuando tiene contribución
// behavioral; persistido gana cuando local es baseline; local
// fallback cuando no hay persistido.

import 'dart:async';

import 'package:elena_app/src/core/engine/imr_persistence_provider.dart';
import 'package:elena_app/src/core/engine/metabolic_state_provider.dart';
import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/features/auth/domain/app_account.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/domain/repositories/user_profile_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-86 — displayedImrProvider regla de decisión', () {
    test('local con behavior > 0 gana sobre persistido', () {
      final container = ProviderContainer(overrides: [
        imrProvider.overrideWith((ref) => const IMRv2Result(
              totalScore: 72,
              structureScore: 0.7,
              metabolicScore: 0.6, // > 0 → tiene behavior
              behaviorScore: 0.5,
              circadianAlignment: 1.0,
              zone: 'FUNCIONAL',
              description: '',
              imc: 24,
              tmb: 1700,
              metabolicAge: 35,
              ica: 0.5,
              ffmi: 20,
              whtr: 0.5,
            )),
        authStateProvider.overrideWith(
          (ref) => Stream<AppAccount?>.value(_fakeAccount),
        ),
        userProfileRepositoryProvider.overrideWithValue(
          _RepoWithPersistedImr({'imrScore': 52, 'label': 'INESTABLE'}),
        ),
      ]);
      addTearDown(container.dispose);

      final displayed = container.read(displayedImrProvider);
      expect(displayed.score, 72);
      expect(displayed.zone, 'FUNCIONAL');
      expect(displayed.hasFullLocal, isTrue);
    });

    test('local baseline + persistido existente → usa persistido', () async {
      final container = ProviderContainer(overrides: [
        imrProvider.overrideWith((ref) => const IMRv2Result(
              totalScore: 37,
              structureScore: 0.74,
              metabolicScore: 0,
              behaviorScore: 0,
              circadianAlignment: 0,
              zone: 'DETERIORADO',
              description: 'Baseline',
              imc: 24,
              tmb: 1700,
              metabolicAge: 35,
              ica: 0.5,
              ffmi: 20,
              whtr: 0.5,
            )),
        authStateProvider.overrideWith(
          (ref) => Stream<AppAccount?>.value(_fakeAccount),
        ),
        userProfileRepositoryProvider.overrideWithValue(
          _RepoWithPersistedImr({'imrScore': 52, 'label': 'INESTABLE'}),
        ),
      ]);
      addTearDown(container.dispose);

      final displayed = await _waitForDisplayed(
        container,
        (d) => d.score == 52,
      );
      expect(displayed.zone, 'INESTABLE');
      expect(displayed.hasFullLocal, isFalse);
    });

    test('local baseline + persistido null → usa local', () async {
      final container = ProviderContainer(overrides: [
        imrProvider.overrideWith((ref) => const IMRv2Result(
              totalScore: 37,
              structureScore: 0.74,
              metabolicScore: 0,
              behaviorScore: 0,
              circadianAlignment: 0,
              zone: 'DETERIORADO',
              description: 'Baseline',
              imc: 24,
              tmb: 1700,
              metabolicAge: 35,
              ica: 0.5,
              ffmi: 20,
              whtr: 0.5,
            )),
        authStateProvider.overrideWith(
          (ref) => Stream<AppAccount?>.value(_fakeAccount),
        ),
        userProfileRepositoryProvider.overrideWithValue(
          _RepoWithPersistedImr(null),
        ),
      ]);
      addTearDown(container.dispose);

      // Cuando el repo retorna null, el displayed cae al local
      // baseline = 37.
      final displayed = await _waitForDisplayed(
        container,
        (d) => d.score == 37 && d.zone == 'DETERIORADO',
      );
      expect(displayed.score, 37);
    });

    test('imrScore persistido se clamp a [0, 100]', () async {
      final container = ProviderContainer(overrides: [
        imrProvider.overrideWith((ref) => IMRv2Result.empty()),
        authStateProvider.overrideWith(
          (ref) => Stream<AppAccount?>.value(_fakeAccount),
        ),
        userProfileRepositoryProvider.overrideWithValue(
          _RepoWithPersistedImr({'imrScore': 150, 'label': 'X'}),
        ),
      ]);
      addTearDown(container.dispose);

      final displayed = await _waitForDisplayed(
        container,
        (d) => d.score == 100,
      );
      expect(displayed.score, 100);
    });
  });
}

const AppAccount _fakeAccount = AppAccount(
  uid: 'test-uid',
  email: 'test@example.com',
  profileStatus: AppProfileStatus.completeProfile,
);

/// Escucha `displayedImrProvider` y resuelve con el primer valor que
/// cumpla el predicado. Lanza TimeoutException si excede 3s.
Future<DisplayedImr> _waitForDisplayed(
  ProviderContainer container,
  bool Function(DisplayedImr) predicate,
) async {
  final completer = Completer<DisplayedImr>();
  late final ProviderSubscription<DisplayedImr> sub;
  void onValue(DisplayedImr value) {
    if (predicate(value) && !completer.isCompleted) {
      completer.complete(value);
    }
  }

  sub = container.listen<DisplayedImr>(
    displayedImrProvider,
    (prev, next) => onValue(next),
    fireImmediately: true,
  );

  try {
    return await completer.future.timeout(const Duration(seconds: 3));
  } finally {
    sub.close();
  }
}

/// Repository de test que retorna un imr.current fijo via stream.
class _RepoWithPersistedImr implements UserProfileRepository {
  final Map<String, dynamic>? imrCurrent;

  _RepoWithPersistedImr(this.imrCurrent);

  @override
  Stream<Map<String, dynamic>?> watchCurrentImr(String userId) {
    return Stream.value(imrCurrent);
  }

  @override
  Stream<UserModel?> watchProfile(String userId) => Stream.value(null);

  @override
  Future<void> saveProfile(UserModel user) async {}

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
}
