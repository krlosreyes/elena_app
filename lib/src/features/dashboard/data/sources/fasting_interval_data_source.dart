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

  /// SPEC-101: stream del último FastingInterval **cerrado y de
  /// tipo ayuno** del usuario (`isFasting==true`, `endTime!=null`).
  /// Útil para evaluar si el usuario ya completó su ayuno del día.
  /// Emite null cuando no hay ningún ayuno cerrado en historial.
  Stream<Map<String, dynamic>?> streamLastCompletedFasting(String userId);

  /// SPEC-97: muta el `startTime` del único intervalo abierto del
  /// usuario (`endTime == null`). NO cierra ni crea — solo edita el
  /// existente para reflejar "empecé a esta hora real".
  ///
  /// SPEC-100: el parámetro opcional `isFastingFilter` permite limitar
  /// la mutación a docs con un `isFasting` específico. Útil cuando
  /// hay data legacy con docs fantasma abiertos de otro tipo
  /// (ej. ventana de comida con endTime null) que NO deben mutarse al
  /// corregir un ayuno.
  ///
  /// Si no hay intervalo abierto que cumpla el filtro, lanza
  /// [StateError]. El caller debe validar antes.
  Future<void> updateOpenIntervalStartTime({
    required String userId,
    required DateTime newStartTime,
    bool? isFastingFilter,
  });
}
