// SPEC-205: data source del feed. Abstrae Firestore para poder
// inyectar un fake en tests.

abstract class PostDataSource {
  /// Lee los docs publicados de `metamorfosis_posts` como maps crudos
  /// (cada uno con su `id` inyectado). Ordenados por `publishedAt` desc.
  Future<List<Map<String, dynamic>>> fetchPublishedRaw({int limit});

  // ─── inc4: engagement ──────────────────────────────────────────────────

  /// Incrementa `analytics.views` del post (best-effort).
  Future<void> incrementViews(String postId);

  /// Marca un post como leído por el usuario.
  Future<void> markRead({required String userId, required String postId});

  /// Stream de ids de posts ya leídos por el usuario (vivo).
  Stream<Set<String>> watchReadIds(String userId);
}
