import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/data/auth_repository.dart';
import '../../fasting/data/fasting_repository.dart';
import '../../fasting/domain/fasting_session.dart';

// Provider que maneja el stream del ayuno activo del usuario ACTUAL.
// Se auto-destruye y recrea cuando cambia la autenticación.
final activeFastProvider = StreamProvider.autoDispose<FastingSession?>((ref) {
  // PASO 1: VIGILAR AL USUARIO (Esto es lo que faltaba)
  // Si el usuario cambia (Log out o nuevo Log in), esta línea fuerza
  // a que todo el provider se reinicie desde cero.
  final authState = ref.watch(authStateChangesProvider);
  
  // Obtenemos el usuario actual del estado
  final user = authState.value;

  // PASO 2: SI NO HAY USUARIO, CORTAR EL STREAM
  if (user == null) {
    return Stream.value(null); // No hay usuario, no hay ayuno.
  }

  // PASO 3: SI HAY USUARIO, PEDIR DATOS CON SU UID ESPECÍFICO
  print("🔄 Cambiando stream de ayuno para usuario: ${user.uid}");
  final repository = ref.watch(fastingRepositoryProvider);
  
  // Usamos el UID verificado del estado de auth
  return repository.getActiveFastStream(user.uid);
});
