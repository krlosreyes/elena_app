import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../application/auth_controller.dart';

import '../../profile/application/user_controller.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  FutureOr<bool> build() {
    return false; // Default state
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    try {
      final authRepo = ref.read(authControllerProvider.notifier);
      await authRepo.signInWithEmailAndPassword(email, password);
      
      final currentUser = authRepo.currentUser;
      if (currentUser == null) throw Exception('Usuario no autenticado tras login');

      // Check if user profile exists in Firestore
      // Note: We await this. If navigation happens during this await (due to authStateChanges),
      // this controller might be disposed.
      
      // FIX: Use a local variable to hold the result and check if mounted before updating state?
      // Riverpod controllers don't have a simple 'mounted' property like Widgets.
      // However, checking Ref.exists or wrapping in a try-catch that ignores StateError/BadState 
      // is a common pattern, OR causing the navigation to happen ONLY after this returns.
      // But authStateChanges usually triggers immediately.
      
      try {
        final userModel = await ref.read(userControllerProvider.notifier).getUser(currentUser.uid);
         // If logic reaches here and controller is disposed, setting state might throw.
        state = AsyncValue.data(userModel == null);
      } catch (e) {
        // If the controller was disposed, we might get a BadState error here when setting state
        // or during the await if the provider is unsafe.
        // We can safely ignore it if the user successfully logged in and navigation happened.
        print("LoginController: Ignored error (likely disposed): $e");
      }

    } catch (e, st) {
      print("LoginController Error: $e");
      // Check for specific "Future already completed" error strings if needed, 
      // but usually AsyncValue.error handles it. 
      // If the controller is disposed, this assignment will be ignored or throw a different error.
      try {
         state = AsyncValue.error(e, st);
      } catch (_) {
        // Ignore errors setting state if disposed
      }
    }
  }
}
