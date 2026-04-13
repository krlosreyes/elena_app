import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';

class OnboardingController extends StateNotifier<AsyncValue<void>> {
  final UserRepository _repository;
  OnboardingController(this._repository) : super(const AsyncValue.data(null));

  Future<void> completeOnboarding(UserModel user) async {
    state = const AsyncValue.loading();
    try {
      // Aquí el ScoreEngine (o un servicio específico) podría realizar 
      // un primer diagnóstico antes de guardar.
      await _repository.saveUser(user);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final onboardingControllerProvider = 
    StateNotifierProvider<OnboardingController, AsyncValue<void>>((ref) {
  return OnboardingController(ref.watch(userRepositoryProvider));
});