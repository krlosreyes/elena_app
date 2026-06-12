// SPEC-205 inc4: tests de FirestorePostSource con fake_cloud_firestore.

import 'package:elena_app/src/features/content/data/firestore_post_source.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FakeFirebaseFirestore db;
  late FirestorePostSource source;

  setUp(() {
    db = FakeFirebaseFirestore();
    source = FirestorePostSource(firestore: db);
  });

  Future<void> seedPost(String id,
      {String status = 'published',
      String publishedAt = '2026-05-01T00:00:00.000Z',
      int views = 0}) {
    return db.collection(FirestorePostSource.kCollection).doc(id).set({
      'title': 'Post $id',
      'pillar': 'nutricion',
      'content': 'x',
      'status': status,
      'publishedAt': publishedAt,
      'analytics': {'views': views, 'clicks': 0, 'conversions': 0},
    });
  }

  test('fetchPublishedRaw solo trae published e inyecta id', () async {
    await seedPost('a', publishedAt: '2026-05-02T00:00:00.000Z');
    await seedPost('b', publishedAt: '2026-05-03T00:00:00.000Z');
    await seedPost('draft', status: 'draft');

    final raw = await source.fetchPublishedRaw(limit: 10);

    final ids = raw.map((m) => m['id']).toList();
    expect(ids, containsAll(['a', 'b']));
    expect(ids, isNot(contains('draft')));
    // orden desc por publishedAt → b antes que a.
    expect(ids.first, 'b');
  });

  test('incrementViews suma 1 a analytics.views', () async {
    await seedPost('a', views: 5);
    await source.incrementViews('a');
    final doc =
        await db.collection(FirestorePostSource.kCollection).doc('a').get();
    final analytics = doc.data()!['analytics'] as Map<String, dynamic>;
    expect(analytics['views'], 6);
  });

  test('markRead + watchReadIds refleja el post leído', () async {
    await source.markRead(userId: 'u1', postId: 'a');
    await source.markRead(userId: 'u1', postId: 'b');

    final ids = await source.watchReadIds('u1').first;
    expect(ids, {'a', 'b'});
  });

  test('watchReadIds de usuario sin lecturas → vacío', () async {
    final ids = await source.watchReadIds('nadie').first;
    expect(ids, isEmpty);
  });
}
