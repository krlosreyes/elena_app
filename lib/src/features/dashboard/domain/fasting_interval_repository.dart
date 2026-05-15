// SPEC-50.4: contrato de persistencia para intervalos de ayuno.
//
// Detalle clave: el storage de intervalos NO es nested bajo
// `users/{uid}/...` como los otros pilares. Es una colección flat
// (`fasting_history`) con `userId` como campo en cada doc. Decisión
// histórica preservada — esta SPEC no migra el schema, solo lo
// envuelve en el patrón Domain↔DataSource↔Mapper.
//
// El método `transitionTo` reemplaza al `startNewInterval` del
// UserRepository previo. La operación atómica (cerrar todo intervalo
// abierto + abrir uno nuevo) vive en el repositorio porque es
// transaccional al storage — no es responsabilidad del notifier.

import 'package:elena_app/src/shared/domain/models/user_model.dart'
    show FastingInterval;

abstract class FastingIntervalRepository {
  /// Stream del intervalo más reciente del usuario (puede ser ayuno
  /// activo, ventana de comida, o un intervalo histórico cerrado).
  /// Emite `null` cuando el usuario no tiene historial.
  Stream<FastingInterval?> watchLatest(String userId);

  /// Atómicamente cierra cualquier intervalo abierto del usuario y
  /// abre uno nuevo con `isFasting`. Si `startTime` es null usa el
  /// instante actual; útil para "viaje en el tiempo" en pruebas o
  /// para registrar entradas manuales con timestamp histórico.
  Future<void> transitionTo({
    required String userId,
    required bool isFasting,
    DateTime? startTime,
  });

  /// SPEC-97: corrige el `startTime` del intervalo abierto del usuario
  /// sin cerrarlo ni crear uno nuevo. Para cuando el usuario arrancó
  /// el ayuno tarde y necesita editar la hora real de inicio.
  ///
  /// Lanza [StateError] si no hay intervalo abierto. El caller debe
  /// verificar (`state.isActive` o equivalente) antes de invocar.
  Future<void> correctOpenIntervalStartTime({
    required String userId,
    required DateTime newStartTime,
  });
}
