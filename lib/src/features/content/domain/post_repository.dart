// SPEC-205 inc1: contrato del repositorio de artículos.

import 'package:elena_app/src/features/content/domain/post.dart';

abstract class PostRepository {
  /// Artículos publicados, ordenados por `publishedAt` descendente.
  ///
  /// Estrategia de robustez (SPEC-205 §4.1): intenta la red; si falla
  /// (offline / error Firestore) devuelve la última caché local. Si no hay
  /// red ni caché, devuelve lista vacía (la UI muestra estado vacío digno).
  Future<List<Post>> fetchPublished({int limit = 30});

  /// inc4: registra una vista del artículo (best-effort, no lanza).
  Future<void> registerView(String postId);

  /// inc4: marca el artículo como leído por el usuario (best-effort, no lanza).
  Future<void> markRead({required String userId, required String postId});

  /// inc4: stream de ids de artículos ya leídos por el usuario.
  Stream<Set<String>> watchReadIds(String userId);
}
