// SPEC-50.4: contrato de almacenamiento físico para intervalos de
// ayuno.
//
// La operación atómica `closeAllOpenAndCreate` refleja la realidad
// transaccional del storage — cerrar todos los abiertos y crear uno
// nuevo debe pasar en un mismo batch para evitar estados intermedios
// inconsistentes (dos abiertos simultáneamente, ninguno abierto, etc.).

abstract class FastingIntervalDataSource {
  /// Stream del último intervalo (más reciente por `startTime`)
  /// del usuario. Emite `null` cuando no hay historial.
  Stream<Map<String, dynamic>?> streamLatest(String userId);

  /// Atómicamente cierra todos los intervalos abiertos del usuario
  /// (set endTime al `closeAt`) y crea uno nuevo con la data dada.
  /// El docId del nuevo se genera por la implementación.
  Future<String> closeAllOpenAndCreate({
    required String userId,
    required DateTime closeAt,
    required Map<String, dynamic> Function(String newDocId) buildNewData,
  });

  /// SPEC-97: muta el `startTime` del único intervalo abierto del
  /// usuario (`endTime == null`). NO cierra ni crea — solo edita el
  /// existente para reflejar "empecé a esta hora real".
  ///
  /// Si no hay intervalo abierto, lanza [StateError]. El caller debe
  /// validar antes (ej. con `state.isActive` en el notifier).
  Future<void> updateOpenIntervalStartTime({
    required String userId,
    required DateTime newStartTime,
  });
}
