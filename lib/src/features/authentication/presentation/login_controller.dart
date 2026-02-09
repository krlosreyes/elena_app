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
    try {
      final authRepo = ref.read(authRepositoryProvider);
      await authRepo.signInWithEmailAndPassword(email, password);
      
      final currentUser = authRepo.currentUser;
      if (currentUser == null) throw Exception('Usuario no autenticado tras login');

      // Check if user profile exists in Firestore
      // Note: We await this. If navigation happens during this await (due to authStateChanges),
      // this controller might be disposed.
      final userModel = await ref.read(userRepositoryProvider).getUser(currentUser.uid);
      
      // If logic reaches here and controller is disposed, setting state might throw.
      // However, we'll try to set it.
      state = AsyncValue.data(userModel == null);
    } catch (e, st) {
      print("LoginController Error: $e");
      // Check for specific "Future already completed" error strings if needed, 
      // but usually AsyncValue.error handles it. 
      // If the controller is disposed, this assignment will be ignored or throw a different error.
      state = AsyncValue.error(e, st);
    }
  }
}
