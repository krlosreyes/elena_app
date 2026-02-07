import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/auth_repository.dart';

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
    
    // Explicit try-catch to log errors as requested
    try {
      final repository = ref.read(authRepositoryProvider);
      await repository.createUserWithEmailAndPassword(email, password);
      // Update display name after successful creation
      final user = repository.currentUser;
      if (user != null) {
        await user.updateDisplayName(name);
        await user.reload(); // Refresh user data
      }
      state = const AsyncData(null);
    } catch (e, st) {
      print('CONTROLLER ERROR: $e');
      // Revert to formatting error for UI if it's a FirebaseAuthException or unexpected
       if (e is FirebaseAuthException) {
         // The repository already converts this to AppException, but if direct access happened:
         print('Detailed Firebase Error: ${e.message}');
       }
      state = AsyncError(e, st);
    }
  }
}
