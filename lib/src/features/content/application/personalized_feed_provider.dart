// SPEC-205 inc2: provider del feed "Para ti".
//
// Combina las observaciones (SPEC-201) + los posts publicados (inc1) + los
// ids ya leídos, y delega en `FeedMatcher` (puro). Degrada con gracia: si las
// observaciones fallan o aún no hay señal, el feed muestra artículos recientes
// sin línea de contexto.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/analysis/application/observations_provider.dart';
import 'package:elena_app/src/features/analysis/domain/observation.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/content/application/feed_matcher.dart';
import 'package:elena_app/src/features/content/application/post_providers.dart';
import 'package:elena_app/src/features/content/domain/personalized_feed.dart';

/// Ids de posts ya leídos por el usuario (vivo desde `users/{uid}/post_reads`).
/// Sin sesión → vacío.
final readPostIdsProvider = StreamProvider.autoDispose<Set<String>>((ref) {
  final uid = ref.watch(authStateProvider).value?.uid;
  if (uid == null) return Stream.value(const <String>{});
  return ref.watch(postRepositoryProvider).watchReadIds(uid);
});

final personalizedFeedProvider =
    Provider.autoDispose<AsyncValue<PersonalizedFeed>>((ref) {
  final postsAsync = ref.watch(publishedPostsProvider);
  final obsAsync = ref.watch(observationsProvider);
  final readIds =
      ref.watch(readPostIdsProvider).valueOrNull ?? const <String>{};

  return postsAsync.when(
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
    data: (posts) {
      // Las observaciones son opcionales: si fallan o cargan, seguimos con
      // artículos recientes (sin contexto).
      final observations = obsAsync.maybeWhen(
        data: (o) => o,
        orElse: () => const <Observation>[],
      );
      final feed = FeedMatcher.build(
        observations: observations,
        posts: posts,
        readPostIds: readIds,
      );
      return AsyncValue.data(feed);
    },
  );
});
