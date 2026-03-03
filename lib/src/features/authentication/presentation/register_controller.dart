import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../application/auth_controller.dart';

part 'register_controller.g.dart';

@riverpod
class RegisterController extends _$RegisterController {
  @override
  FutureOr<void> build() {
    // nothing to initialize
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();

    try {
      final repository = ref.read(authControllerProvider.notifier);
      await repository.createUserWithEmailAndPassword(email, password);

      // Update display name after successful creation
      final user = repository.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload(); // Refresh user data
        // Explicitly wait slightly to ensure Firebase auth stream propagates if needed,
        // though typically the router listens to the stream.
        // The flicker happens if the stream emits "Authenticated" -> Router goes Home -> Then we try Onboarding.
        // To fix: The router likely redirects to Home on auth. 
        // We should handle the onboarding flow via the router possibly, but here we enforce local state success.
      }
      state = const AsyncData(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
