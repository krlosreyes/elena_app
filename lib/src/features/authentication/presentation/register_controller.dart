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
      state = AsyncValue.error(e, st);
    }
  }
}
