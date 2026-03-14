import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../application/auth_controller.dart';

class RegisterController extends StateNotifier<AsyncValue<void>> {
  final Ref _ref;

  RegisterController(this._ref) : super(const AsyncValue.data(null));

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    try {
      final authController = _ref.read(authControllerProvider.notifier);
      await authController.createUserWithEmailAndPassword(email, password);

      final user = authController.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload();
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final registerControllerProvider =
    StateNotifierProvider.autoDispose<RegisterController, AsyncValue<void>>((ref) {
  return RegisterController(ref);
});
