import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/auth_repository.dart';

part 'auth_controller.g.dart';

/// ✅ MEJORA DE ARQUITECTURA:
/// Uso de `@riverpod` y `AsyncNotifier`. Permite manejar internamente el 
/// loading y error asíncrono minimizando flags booleanos mutables y propensos as fallos en UI.
@riverpod
class AuthController extends _$AuthController {
  @override
  FutureOr<void> build() {
    // Estado inicial de la mutación
    return null;
  }

  User? get currentUser => ref.read(authRepositoryProvider).currentUser;

  Future<void> signOut() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).signOut());
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).signInWithEmailAndPassword(email, password));
  }

  Future<void> createUserWithEmailAndPassword(String email, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(authRepositoryProvider).createUserWithEmailAndPassword(email, password));
  }
}

@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}
