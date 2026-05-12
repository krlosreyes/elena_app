import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/domain/repositories/user_profile_repository.dart';

class OnboardingController extends StateNotifier<AsyncValue<void>> {
  // SPEC-50.5: UserProfileRepository (no UserRepository).
  final UserProfileRepository _repository;
  OnboardingController(this._repository) : super(const AsyncValue.data(null));

  Future<void> completeOnboarding(UserModel user) async {
    state = const AsyncValue.loading();
    try {
      // SPEC-73 §RF-73-07: la preservación de campos MR pre-existentes
      // (subscription_active, purchases, programs, etc.) está
      // garantizada por `FirestoreUserProfileV1Source.saveProfile`, que
      // ya usa `set(..., SetOptions(merge: true))`. Los campos que el
      // UserModel no conoce se mantienen intactos en Firestore.
      await _repository.saveProfile(user);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final onboardingControllerProvider =
    StateNotifierProvider<OnboardingController, AsyncValue<void>>((ref) {
  return OnboardingController(ref.watch(userProfileRepositoryProvider));
});
