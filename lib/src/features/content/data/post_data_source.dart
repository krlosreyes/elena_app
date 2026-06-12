// SPEC-205 inc1: data source del feed. Abstrae Firestore para poder
// inyectar un fake en tests.

abstract class PostDataSource {
  /// Lee los docs publicados de `metamorfosis_posts` como maps crudos
  /// (cada uno con su `id` inyectado). Ordenados por `publishedAt` desc.
  Future<List<Map<String, dynamic>>> fetchPublishedRaw({int limit});
}
