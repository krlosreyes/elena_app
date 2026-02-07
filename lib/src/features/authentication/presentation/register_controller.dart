import 'package:firebase_auth/firebase_auth.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../../core/exceptions/exceptions.dart';
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
      print('DEBUG: Iniciando registro...');
      final repository = ref.read(authRepositoryProvider);
      
      print('DEBUG: Llamando a createUserWithEmailAndPassword...');
      await repository.createUserWithEmailAndPassword(email, password);
      print('DEBUG: Usuario creado en Firebase.');

      // Update display name after successful creation
      final user = repository.currentUser;
      if (user != null) {
        print('DEBUG: Actualizando display name...');
        await user.updateDisplayName(name);
        print('DEBUG: Display name actualizado. Recargando usuario...');
        await user.reload(); // Refresh user data
        print('DEBUG: Usuario recargado.');
      } else {
        print('DEBUG: currentUser es null después de creación');
      }
      state = const AsyncData(null);
    } catch (e, st) {
      print('❌ ERROR EN REGISTRO (Tipo: ${e.runtimeType})');
      print('❌ MENSAJE: $e');
      print('❌ STACK TRACE:\n$st');
      
      // MODO DEBUG: Mostrar error exacto de Firebase
      final errorMsg = e.toString();
      state = AsyncValue.error(errorMsg, st);
    }
  }
}
