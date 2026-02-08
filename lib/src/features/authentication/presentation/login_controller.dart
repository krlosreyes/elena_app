import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/auth_repository.dart';

import '../../profile/data/user_repository.dart';

part 'login_controller.g.dart';

@riverpod
class LoginController extends _$LoginController {
  @override
  FutureOr<bool> build() {
    return false; // Default state
  }

  Future<void> signIn({required String email, required String password}) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithEmailAndPassword(email, password);
      
      final currentUser = authRepo.currentUser;
      if (currentUser == null) throw Exception('Usuario no autenticado tras login');

      // Check if user profile exists in Firestore
      final userModel = await ref.read(userRepositoryProvider).getUser(currentUser.uid);
      
      // If userModel is null, they need onboarding
      return userModel == null;
    });
  }
}
