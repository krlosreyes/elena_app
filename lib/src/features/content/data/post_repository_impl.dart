// SPEC-205 inc1: implementación del PostRepository.
//
// Estrategia (SPEC-205 §4.1):
//   1. Intenta leer de Firestore vía el data source.
//   2. Éxito → persiste la caché local y devuelve los posts.
//   3. Error (offline / Firestore) → devuelve la última caché.
//   4. Sin red ni caché → lista vacía (UI muestra estado vacío digno).

import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/features/content/data/post_data_source.dart';
import 'package:elena_app/src/features/content/domain/post.dart';
import 'package:elena_app/src/features/content/domain/post_repository.dart';

class PostRepositoryImpl implements PostRepository {
  final PostDataSource _source;
  final SharedPreferences _prefs;

  PostRepositoryImpl({
    required PostDataSource source,
    required SharedPreferences prefs,
  })  : _source = source,
        _prefs = prefs;

  static const String kCacheKey = 'spec205_posts_cache_v1';

  @override
  Future<List<Post>> fetchPublished({int limit = 30}) async {
    try {
      final raw = await _source.fetchPublishedRaw(limit: limit);
      final posts = raw.map(Post.fromMap).toList();
      await _writeCache(posts);
      return posts;
    } catch (_) {
      // Offline o error de Firestore: servimos la última caché.
      return _readCache();
    }
  }

  Future<void> _writeCache(List<Post> posts) async {
    try {
      final encoded = jsonEncode(posts.map((p) => p.toCache()).toList());
      await _prefs.setString(kCacheKey, encoded);
    } catch (_) {
      // La caché es best-effort: si falla, no rompemos el flujo principal.
    }
  }

  List<Post> _readCache() {
    final encoded = _prefs.getString(kCacheKey);
    if (encoded == null || encoded.isEmpty) return const [];
    try {
      final decoded = jsonDecode(encoded);
      if (decoded is! List) return const [];
      return decoded
          .whereType<Map>()
          .map((m) => Post.fromMap(m.cast<String, dynamic>()))
          .toList();
    } catch (_) {
      return const [];
    }
  }
}
