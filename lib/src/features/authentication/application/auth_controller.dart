import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/utils/web_utils.dart';
import '../data/auth_repository.dart';
import '../../profile/data/user_repository.dart';
import '../../../core/exceptions/exceptions.dart';
import '../../onboarding/application/onboarding_controller.dart';

part 'auth_controller.g.dart';

/// ✅ MEJORA DE ARQUITECTURA:
/// Uso de `@riverpod` y `AsyncNotifier`. Permite manejar internamente el
/// loading y error asíncrono minimizando flags booleanos mutables y propensos as fallos en UI.
@riverpod
class AuthController extends _$AuthController {
  bool _mounted = true;

  @override
  FutureOr<void> build() {
    ref.onDispose(() => _mounted = false);
    return null;
  }

  User? get currentUser => ref.read(authRepositoryProvider).currentUser;

  Future<void> signOut() async {
    state = const AsyncLoading();
    final result = await guardAuthExceptions(
        () => ref.read(authRepositoryProvider).signOut());
    if (!ref.exists(authControllerProvider)) return;
    if (_mounted) {
      ref.read(onboardingJustFinishedProvider.notifier).state = false;
      state = result;
    }
  }

  Future<void> deleteAccount() async {
    final user = currentUser;
    if (user == null) return;

    state = const AsyncLoading();

    // 🛡️ PRE-CHECK: Si la sesión es antigua, Firebase bloqueará el borrado de Auth.
    // Abortamos antes de tocar NADA para mantener la integridad.
    final lastSignIn = user.metadata.lastSignInTime;
    if (lastSignIn != null) {
      final diff = DateTime.now().difference(lastSignIn);
      if (diff.inMinutes > 2) {
        // 2 minutos para ser extra seguros en Web
        state = AsyncError(
          const AppException(
            'Por seguridad, esta acción requiere una sesión muy reciente. Por favor, cierra sesión y vuelve a entrar para confirmar el borrado total de tu perfil.',
            'auth/requires-recent-login',
          ),
          StackTrace.current,
        );
        return;
      }
    }

    final result = await guardAuthExceptions(() async {
      // 1. Marcar estado de borrado para el Router
      ref.read(isDeletingAccountProvider.notifier).state = true;

      try {
        final uid = user.uid; // Guardamos el UID antes de borrar Auth

        // 2. Limpiamos Firestore PRIMERO mientras la sesión de Auth es válida.
        // Si borramos Auth antes, perdemos permisos (request.auth == null)
        // y Firestore bloqueará el borrado de los datos personales.
        await ref.read(userRepositoryProvider).deleteUser(uid);

        // 3. Borramos la cuenta de Auth al final.
        await ref.read(authRepositoryProvider).deleteAccount();
      } catch (authError) {
        // Si llegamos aquí y el error es requires-recent-login rescatado por guardAuthExceptions
        // El estado ya tendrá el error. Pero si fue un error de red u otro:
        ref.read(isDeletingAccountProvider.notifier).state = false;
        rethrow;
      }
    });

    if (!ref.exists(authControllerProvider)) return;
    if (_mounted) {
      state = result;
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncLoading();
    final result = await guardAuthExceptions(() => ref
        .read(authRepositoryProvider)
        .signInWithEmailAndPassword(email, password));
    if (_mounted) {
      state = result;
    }
  }

  Future<void> createUserWithEmailAndPassword(
      String email, String password) async {
    state = const AsyncLoading();
    final result = await guardAuthExceptions(() => ref
        .read(authRepositoryProvider)
        .createUserWithEmailAndPassword(email, password));
    if (_mounted) {
      state = result;
    }
  }
}

@riverpod
Stream<User?> authStateChanges(AuthStateChangesRef ref) {
  return ref.watch(authRepositoryProvider).authStateChanges();
}

/// Provider para bloquear el router durante el borrado de cuenta
final isDeletingAccountProvider = StateProvider<bool>((ref) => false);
