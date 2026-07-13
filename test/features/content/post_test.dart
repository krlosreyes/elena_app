// SPEC-205 inc1: tests del parser puro de Post (sin Firestore ni Flutter).

import 'package:elena_app/src/features/content/domain/post.dart';
import 'package:flutter_test/flutter_test.dart';

/// Doc real recortado de `metamorfosis_posts` (2026-06-11).
Map<String, dynamic> _realishDoc() => {
      'id': 'doc-123',
      'analytics': {'clicks': 0, 'conversions': 0, 'views': 1023},
      'content': 'palabra ' * 400, // 400 palabras → 2 min de lectura
      'createdAt': '2026-05-12T15:18:27.689Z',
      'images': [
        'https://storage.googleapis.com/elena/posts/img-1.jpeg',
      ],
      'metadata': {
        'slug': 'por-que-sigues-con-hambre',
        'title': 'Por qué sigues con hambre',
      },
      'pillar': 'nutricion',
      'publishedAt': '2026-05-01T15:18:00.000Z',
      'quiz': [
        {
          'correctAnswer': 1,
          'options': ['A) ...', 'B) ...', 'C) ...', 'D) ...'],
          'question': '¿Cómo actúa la insulina?',
        },
      ],
      'references': [
        'Saltiel & Kahn (2001). Nature.',
        'Ludwig & Ebbeling (2018). JAMA.',
      ],
      'slug': 'por-que-sigues-con-hambre',
      'status': 'published',
      'title': 'Por qué sigues con hambre',
    };

void main() {
  group('PillarTag.parse', () {
    test('valores canónicos', () {
      expect(PillarTag.parse('ayuno'), PillarTag.ayuno);
      expect(PillarTag.parse('sueno'), PillarTag.sueno);
      expect(PillarTag.parse('hidratacion'), PillarTag.hidratacion);
      expect(PillarTag.parse('ejercicio'), PillarTag.ejercicio);
      expect(PillarTag.parse('nutricion'), PillarTag.nutricion);
    });

    test('tolera acentos y mayúsculas', () {
      expect(PillarTag.parse('Nutrición'), PillarTag.nutricion);
      expect(PillarTag.parse('  SUEÑO '), PillarTag.sueno);
    });

    test('desconocido / vacío / null → general', () {
      expect(PillarTag.parse('peso'), PillarTag.general);
      expect(PillarTag.parse(''), PillarTag.general);
      expect(PillarTag.parse(null), PillarTag.general);
    });
  });

  group('Post.fromMap', () {
    test('mapea todos los campos del doc real', () {
      final p = Post.fromMap(_realishDoc());
      expect(p.id, 'doc-123');
      expect(p.title, 'Por qué sigues con hambre');
      expect(p.slug, 'por-que-sigues-con-hambre');
      expect(p.pillar, PillarTag.nutricion);
      expect(p.imageUrl, 'https://storage.googleapis.com/elena/posts/img-1.jpeg');
      expect(p.references.length, 2);
      expect(p.quiz.length, 1);
      expect(p.status, 'published');
      expect(p.publishedAt, DateTime.parse('2026-05-01T15:18:00.000Z'));
      expect(p.hasScientificBacking, isTrue);
      expect(p.hasQuiz, isTrue);
    });

    test('tiempo de lectura ≈ palabras/200, mínimo 1', () {
      final p = Post.fromMap(_realishDoc());
      expect(p.readingMinutes, 2); // 400 palabras
      final short = Post.fromMap({..._realishDoc(), 'content': 'hola'});
      expect(short.readingMinutes, 1);
    });

    test('quiz: índice correcto preservado y clampeado', () {
      final p = Post.fromMap(_realishDoc());
      expect(p.quiz.first.correctIndex, 1);
      expect(p.quiz.first.isCorrect(1), isTrue);
      expect(p.quiz.first.isCorrect(0), isFalse);

      final outOfRange = QuizQuestion.fromMap({
        'question': 'x',
        'options': ['a', 'b'],
        'correctAnswer': 9,
      });
      expect(outOfRange.correctIndex, 1); // clamp a último válido
    });

    test('campos faltantes → defaults sin crashear', () {
      final p = Post.fromMap({'id': 'x'});
      expect(p.title, '');
      expect(p.pillar, PillarTag.general);
      expect(p.imageUrl, isNull);
      expect(p.references, isEmpty);
      expect(p.quiz, isEmpty);
      expect(p.contentMarkdown, '');
      expect(p.readingMinutes, 1);
    });

    test('images vacío → imageUrl null', () {
      final p = Post.fromMap({...
        _realishDoc(),
        'images': <String>[],
      });
      expect(p.imageUrl, isNull);
    });

    // Bug reportado 2026-07-13: todos los artículos del feed caían al
    // placeholder de emoji del pilar en vez de mostrar la imagen real.
    test('images[] con Map {url: ...} en vez de string se extrae igual', () {
      final p = Post.fromMap({
        ..._realishDoc(),
        'images': [
          {'url': 'https://storage.googleapis.com/elena/posts/img-2.jpeg'},
        ],
      });
      expect(p.imageUrl, 'https://storage.googleapis.com/elena/posts/img-2.jpeg');
    });

    test('images[] con Map {src: ...} (shape alterno) se extrae igual', () {
      final p = Post.fromMap({
        ..._realishDoc(),
        'images': [
          {'src': 'https://storage.googleapis.com/elena/posts/img-3.jpeg'},
        ],
      });
      expect(p.imageUrl, 'https://storage.googleapis.com/elena/posts/img-3.jpeg');
    });

    test('images[] con referencia gs:// se normaliza a URL descargable', () {
      final p = Post.fromMap({
        ..._realishDoc(),
        'images': ['gs://elena-app-prod.appspot.com/posts/img-4.jpeg'],
      });
      expect(
        p.imageUrl,
        'https://firebasestorage.googleapis.com/v0/b/elena-app-prod.appspot.com/o/posts%2Fimg-4.jpeg?alt=media',
      );
    });

    test('images[] con gs:// sin ruta (solo bucket) → imageUrl null', () {
      final p = Post.fromMap({
        ..._realishDoc(),
        'images': ['gs://elena-app-prod.appspot.com'],
      });
      expect(p.imageUrl, isNull);
    });

    test('images[] con URL https ya válida no se toca', () {
      final p = Post.fromMap(_realishDoc());
      expect(p.imageUrl, 'https://storage.googleapis.com/elena/posts/img-1.jpeg');
    });

    test('title cae a metadata si falta top-level', () {
      final doc = {..._realishDoc()}..remove('title');
      final p = Post.fromMap(doc);
      expect(p.title, 'Por qué sigues con hambre');
    });

    test('publishedAt cae a createdAt si falta', () {
      final doc = {..._realishDoc()}..remove('publishedAt');
      final p = Post.fromMap(doc);
      expect(p.publishedAt, DateTime.parse('2026-05-12T15:18:27.689Z'));
    });
  });

  group('toCache ↔ fromMap roundtrip', () {
    test('serializar a caché y volver a parsear conserva lo esencial', () {
      final original = Post.fromMap(_realishDoc());
      final restored = Post.fromMap(original.toCache());
      expect(restored.id, original.id);
      expect(restored.title, original.title);
      expect(restored.pillar, original.pillar);
      expect(restored.imageUrl, original.imageUrl);
      expect(restored.references, original.references);
      expect(restored.quiz.length, original.quiz.length);
      expect(restored.quiz.first.correctIndex, original.quiz.first.correctIndex);
      expect(restored.publishedAt, original.publishedAt);
      expect(restored.status, original.status);
    });
  });
}
