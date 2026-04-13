import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/auth/domain/auth_repository.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';

class AuthController extends StateNotifier<AsyncValue<void>> {
  AuthController({required this.repository}) : super(const AsyncData(null));

  final AuthRepository repository;

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => 
      repository.signInWithEmail(email: email, password: password)
    );
  }

  Future<void> signUp(String email, String password, String name) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => 
      repository.signUpWithEmail(email: email, password: password, name: name)
    );
  }

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repository.signOut());
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AsyncValue<void>>((ref) {
  return AuthController(repository: ref.watch(authRepositoryProvider));
});