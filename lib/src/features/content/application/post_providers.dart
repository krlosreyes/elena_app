// SPEC-205 inc1: providers del feed de artículos.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/features/content/data/firestore_post_source.dart';
import 'package:elena_app/src/features/content/data/post_data_source.dart';
import 'package:elena_app/src/features/content/data/post_repository_impl.dart';
import 'package:elena_app/src/features/content/domain/post.dart';
import 'package:elena_app/src/features/content/domain/post_repository.dart';

/// Fuente de datos (Firestore). Sobrescribible en tests con un fake.
final postDataSourceProvider = Provider<PostDataSource>((ref) {
  return FirestorePostSource();
});

/// Repositorio con caché offline.
final postRepositoryProvider = Provider<PostRepository>((ref) {
  return PostRepositoryImpl(
    source: ref.watch(postDataSourceProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

/// Posts publicados (red con fallback a caché). El feed personalizado
/// (inc2) se construye encima de esta lista.
final publishedPostsProvider = FutureProvider<List<Post>>((ref) async {
  return ref.watch(postRepositoryProvider).fetchPublished();
});
