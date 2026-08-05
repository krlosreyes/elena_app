// SPEC-263: contrato de la fuente de datos de retos.
//
// Dos documentos por reto (ver firestore.rules): la metadata en
// `challenges/{code}` y el puntaje de cada quien en
// `challenges/{code}/scores/{uid}`. Cada usuario escribe SOLO su propio
// puntaje; el tablero se arma leyendo la subcolección completa.

abstract class ChallengeDataSource {
  /// Retos donde el usuario es miembro (query por `memberIds array-contains`).
  Stream<List<Map<String, dynamic>>> watchMyChallenges(String userId);

  /// Un reto por su código (== id del doc). null si no existe.
  Stream<Map<String, dynamic>?> watchChallenge(String code);

  /// Tablero: todos los puntajes del reto.
  Stream<List<Map<String, dynamic>>> watchScores(String code);

  /// Crea un reto nuevo (el creador es el único miembro inicial).
  Future<void> createChallenge(String code, Map<String, dynamic> data);

  /// Unirse: reemplaza `memberIds` con la lista ya extendida (incluye al que
  /// se une). La regla exige que el único cambio sea agregarte a ti mismo.
  Future<void> joinChallenge(String code, List<String> memberIds);

  /// Publica/actualiza MI puntaje en el reto.
  Future<void> publishScore(String code, String uid, Map<String, dynamic> data);

  /// Borra MI puntaje (salir del reto).
  Future<void> removeScore(String code, String uid);

  /// Borra el reto (solo lo permite la regla al dueño).
  Future<void> deleteChallenge(String code);
}
