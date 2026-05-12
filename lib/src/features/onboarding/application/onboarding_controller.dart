// SPEC-73 BUGFIX (12-may-2026): después de saveProfile, el
// authStateProvider debe re-clasificar el AppAccount como
// completeProfile. Sin esto, el router seguía viendo el perfil viejo
// (partial/new) y devolvía al usuario a /onboarding en bucle.
//
// El stream de Firebase Auth NO se entera de cambios en Firestore —
// solo emite cuando cambia el estado de autenticación. Invalidando
// el provider forzamos una re-suscripción que vuelve a leer
// users/{uid} y reconstruye AppAccount con el nuevo shape.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/domain/repositories/user_profile_repository.dart';

class OnboardingController extends StateNotifier<AsyncValue<void>> {
  // SPEC-50.5: UserProfileRepository (no UserRepository).
  final UserProfileRepository _repository;
  final Ref _ref;

  OnboardingController(this._repository, this._ref)
      : super(const AsyncValue.data(null));

  Future<void> completeOnboarding(UserModel user) async {
    state = const AsyncValue.loading();
    try {
      // SPEC-73 §RF-73-07: preservación de campos MR pre-existentes
      // (subscription_active, purchases, programs, etc.) está garantizada
      // por FirestoreUserProfileV1Source.saveProfile, que usa
      // SetOptions(merge: true). Los campos que UserModel no conoce
      // se mantienen intactos en Firestore.
      await _repository.saveProfile(user);

      // SPEC-73 BUGFIX: forzar re-clasificación del AppAccount.
      // Sin esto, profileStatus queda en PARTIAL y el router
      // reenvía al usuario a /onboarding indefinidamente.
      _ref.invalidate(authStateProvider);

      // Esperar al primer emit del stream re-suscrito. Garantiza que
      // cuando la pantalla llame `context.go('/dashboard')`, el
      // redirect del router ya vea profileStatus == COMPLETE.
      await _ref.read(authStateProvider.future);

      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, AsyncValue<void>>((ref) {
  return OnboardingController(
    ref.watch(userProfileRepositoryProvider),
    ref,
  );
});
