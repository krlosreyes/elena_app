// SPEC-50.5: contrato de almacenamiento físico para perfil de usuario.

abstract class UserProfileDataSource {
  /// Stream del documento del perfil. `null` cuando el doc no existe.
  Stream<Map<String, dynamic>?> streamProfile(String userId);

  /// Persiste el documento completo del perfil con merge=true.
  Future<void> saveProfile({
    required String userId,
    required Map<String, dynamic> data,
  });

  /// Actualiza un subset de campos del perfil. Usa Firestore.update
  /// (NO crea el doc si no existe — saveProfile cubre ese caso).
  Future<void> updateProfileFields({
    required String userId,
    required Map<String, dynamic> updates,
  });

  /// Añade una entrada a la subcolección `protocol_adjustments` del
  /// usuario. La impl inyecta `timestamp` server-side.
  Future<void> appendProtocolAdjustment({
    required String userId,
    required Map<String, dynamic> adjustment,
  });
}
