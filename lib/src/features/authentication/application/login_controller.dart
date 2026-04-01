import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_controller.dart';
import '../../profile/application/user_controller.dart';

class LoginController extends StateNotifier<AsyncValue<bool>> {
  final Ref _ref;

  LoginController(this._ref) : super(const AsyncValue.data(false));

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final authController = _ref.read(authControllerProvider.notifier);
      await authController.signInWithEmailAndPassword(email, password);

      final currentUser = authController.currentUser;
      if (currentUser == null) {
        throw Exception('Usuario no autenticado tras login');
      }

      try {
        final userModel = await _ref
            .read(userControllerProvider.notifier)
            .getUser(currentUser.uid);
        // Guard: controller may have been disposed during navigation
        if (mounted) {
          state = AsyncValue.data(userModel == null); // true = needs onboarding
        }
      } catch (e) {
        // Controller may have been disposed during navigation — ignore.
        debugPrint('LoginController: Ignored post-login error: $e');
      }
    } catch (e, st) {
      try {
        if (mounted) state = AsyncValue.error(e, st);
      } catch (_) {}
    }
  }
}

final loginControllerProvider =
    StateNotifierProvider.autoDispose<LoginController, AsyncValue<bool>>((ref) {
  return LoginController(ref);
});
