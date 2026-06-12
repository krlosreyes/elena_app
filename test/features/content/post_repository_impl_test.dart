// SPEC-205 inc1: tests del PostRepositoryImpl (red + fallback a caché).

import 'package:elena_app/src/features/content/data/post_data_source.dart';
import 'package:elena_app/src/features/content/data/post_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _FakeSource implements PostDataSource {
  _FakeSource(this._docs, {this.throwError = false});
  final List<Map<String, dynamic>> _docs;
  final bool throwError;
  int calls = 0;

  final List<String> readMarks = [];
  final List<String> viewMarks = [];

  @override
  Future<List<Map<String, dynamic>>> fetchPublishedRaw({int limit = 30}) async {
    calls++;
    if (throwError) throw Exception('offline');
    return _docs;
  }

  @override
  Future<void> incrementViews(String postId) async {
    if (throwError) throw Exception('offline');
    viewMarks.add(postId);
  }

  @override
  Future<void> markRead({
    required String userId,
    required String postId,
  }) async {
    if (throwError) throw Exception('offline');
    readMarks.add('$userId/$postId');
  }

  @override
  Stream<Set<String>> watchReadIds(String userId) =>
      Stream.value(const <String>{});
}

Map<String, dynamic> _doc(String id, String pillar) => {
      'id': id,
      'title': 'Post $id',
      'slug': id,
      'pillar': pillar,
      'content': 'contenido de prueba',
      'images': ['https://x/$id.jpg'],
      'references': ['Ref 1'],
      'quiz': [
        {
          'question': 'q',
          'options': ['a', 'b'],
          'correctAnswer': 1,
        }
      ],
      'publishedAt': '2026-05-01T00:00:00.000Z',
      'status': 'published',
    };

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<SharedPreferences> prefs() => SharedPreferences.getInstance();

  test('red OK → devuelve posts y persiste caché', () async {
    final source = _FakeSource([_doc('a', 'nutricion'), _doc('b', 'ayuno')]);
    final repo = PostRepositoryImpl(source: source, prefs: await prefs());

    final posts = await repo.fetchPublished();

    expect(posts.length, 2);
    expect(posts.first.id, 'a');
    final p = await prefs();
    expect(p.getString(PostRepositoryImpl.kCacheKey), isNotNull);
  });

  test('sin red pero con caché previa → sirve la caché', () async {
    final sp = await prefs();
    // Primera llamada con red OK llena la caché.
    final okRepo = PostRepositoryImpl(
      source: _FakeSource([_doc('a', 'nutricion')]),
      prefs: sp,
    );
    await okRepo.fetchPublished();

    // Segunda con source que falla: debe devolver la caché.
    final offlineRepo = PostRepositoryImpl(
      source: _FakeSource(const [], throwError: true),
      prefs: sp,
    );
    final posts = await offlineRepo.fetchPublished();

    expect(posts.length, 1);
    expect(posts.first.id, 'a');
    expect(posts.first.pillar.name, 'nutricion');
  });

  test('sin red ni caché → lista vacía (no crashea)', () async {
    final repo = PostRepositoryImpl(
      source: _FakeSource(const [], throwError: true),
      prefs: await prefs(),
    );
    final posts = await repo.fetchPublished();
    expect(posts, isEmpty);
  });

  test('registerView/markRead delegan al source', () async {
    final source = _FakeSource([_doc('a', 'nutricion')]);
    final repo = PostRepositoryImpl(source: source, prefs: await prefs());
    await repo.registerView('a');
    await repo.markRead(userId: 'u1', postId: 'a');
    expect(source.viewMarks, ['a']);
    expect(source.readMarks, ['u1/a']);
  });

  test('registerView no propaga errores (best-effort)', () async {
    final source = _FakeSource(const [], throwError: true);
    final repo = PostRepositoryImpl(source: source, prefs: await prefs());
    // No debe lanzar aunque el source falle.
    await repo.registerView('a');
    await repo.markRead(userId: 'u1', postId: 'a');
  });

  test('la caché sobrevive a roundtrip JSON con quiz y referencias', () async {
    final sp = await prefs();
    await PostRepositoryImpl(source: _FakeSource([_doc('a', 'sueno')]), prefs: sp)
        .fetchPublished();

    final offline = await PostRepositoryImpl(
      source: _FakeSource(const [], throwError: true),
      prefs: sp,
    ).fetchPublished();

    expect(offline.first.quiz.length, 1);
    expect(offline.first.quiz.first.correctIndex, 1);
    expect(offline.first.references, ['Ref 1']);
    expect(offline.first.imageUrl, 'https://x/a.jpg');
  });
}
