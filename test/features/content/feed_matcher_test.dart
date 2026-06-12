// SPEC-205 inc2: tests del FeedMatcher (puro).

import 'package:elena_app/src/features/analysis/domain/observation.dart';
import 'package:elena_app/src/features/content/application/feed_matcher.dart';
import 'package:elena_app/src/features/content/domain/post.dart';
import 'package:flutter_test/flutter_test.dart';

Post _post(String id, PillarTag pillar, {int day = 1}) => Post(
      id: id,
      title: 'Post $id',
      slug: id,
      pillar: pillar,
      contentMarkdown: 'x',
      imageUrl: null,
      references: const [],
      quiz: const [],
      publishedAt: DateTime(2026, 5, day),
      status: 'published',
    );

Observation _baselineBelow(String label, {double strength = 0.5}) => Observation(
      type: ObservationType.baseline,
      subject: label,
      headline: 'h',
      detail: 'd',
      action: 'hacé algo',
      strength: strength,
    );

Observation _streak(String label, {double strength = 0.9}) => Observation(
      type: ObservationType.streak,
      subject: 'racha-$label',
      headline: 'h',
      detail: 'd',
      strength: strength,
    );

void main() {
  group('pillarOfObservation', () {
    test('baseline usa el label directo', () {
      expect(FeedMatcher.pillarOfObservation(_baselineBelow('Ejercicio')).name,
          'ejercicio');
      expect(FeedMatcher.pillarOfObservation(_baselineBelow('Hidratación')).name,
          'hidratacion');
    });
    test('racha- y meta- se desprefijan', () {
      expect(FeedMatcher.pillarOfObservation(_streak('Sueño')).name, 'sueno');
      final goal = Observation(
        type: ObservationType.goalProximity,
        subject: 'meta-hidratacion',
        headline: 'h',
        detail: 'd',
        strength: 0.5,
      );
      expect(FeedMatcher.pillarOfObservation(goal).name, 'hidratacion');
    });
  });

  group('FeedMatcher.build', () {
    test('empareja el destacado al pilar de la observación accionable', () {
      final posts = [
        _post('n1', PillarTag.nutricion, day: 5),
        _post('e1', PillarTag.ejercicio, day: 4),
        _post('a1', PillarTag.ayuno, day: 3),
      ];
      final feed = FeedMatcher.build(
        observations: [_baselineBelow('Ejercicio', strength: 0.6)],
        posts: posts,
      );
      expect(feed.context, isNotNull);
      expect(feed.forYou!.pillar, PillarTag.ejercicio);
      expect(feed.forYou!.id, 'e1');
    });

    test('prioriza observación accionable sobre racha más fuerte', () {
      // La racha (0.9) es más fuerte, pero no es accionable; la baseline
      // accionable (0.5) define el pilar objetivo.
      final posts = [
        _post('s1', PillarTag.sueno, day: 5),
        _post('h1', PillarTag.hidratacion, day: 4),
      ];
      final feed = FeedMatcher.build(
        observations: [
          _streak('Sueño', strength: 0.9),
          _baselineBelow('Hidratación', strength: 0.5),
        ],
        posts: posts,
      );
      expect(feed.forYou!.pillar, PillarTag.hidratacion);
    });

    test('excluye posts ya leídos del destacado', () {
      final posts = [
        _post('e1', PillarTag.ejercicio, day: 5),
        _post('e2', PillarTag.ejercicio, day: 4),
      ];
      final feed = FeedMatcher.build(
        observations: [_baselineBelow('Ejercicio')],
        posts: posts,
        readPostIds: {'e1'},
      );
      expect(feed.forYou!.id, 'e2');
    });

    test('único del pilar ya leído → prefiere fresco antes que repetir', () {
      final posts = [
        _post('e1', PillarTag.ejercicio, day: 5),
        _post('n1', PillarTag.nutricion, day: 4),
      ];
      final feed = FeedMatcher.build(
        observations: [_baselineBelow('Ejercicio')],
        posts: posts,
        readPostIds: {'e1'}, // único de ejercicio, ya leído
      );
      // No repetir e1 (leído); mostrar el más reciente no leído.
      expect(feed.forYou!.id, 'n1');
    });

    test('todos leídos → cae al del pilar (mejor relevante que vacío)', () {
      final posts = [
        _post('e1', PillarTag.ejercicio, day: 5),
        _post('n1', PillarTag.nutricion, day: 4),
      ];
      final feed = FeedMatcher.build(
        observations: [_baselineBelow('Ejercicio')],
        posts: posts,
        readPostIds: {'e1', 'n1'}, // todo leído
      );
      expect(feed.forYou!.id, 'e1');
    });

    test('adicionales diversifican el pilar y respetan el tope', () {
      final posts = [
        _post('e1', PillarTag.ejercicio, day: 6),
        _post('e2', PillarTag.ejercicio, day: 5),
        _post('n1', PillarTag.nutricion, day: 4),
        _post('a1', PillarTag.ayuno, day: 3),
      ];
      final feed = FeedMatcher.build(
        observations: [_baselineBelow('Ejercicio')],
        posts: posts,
        maxMore: 2,
      );
      expect(feed.forYou!.id, 'e1');
      expect(feed.more.length, 2);
      // Prefiere pilares distintos a ejercicio.
      expect(feed.more.every((p) => p.pillar != PillarTag.ejercicio), isTrue);
    });

    test('sin observaciones → sin contexto, destacado = más reciente', () {
      final posts = [
        _post('n1', PillarTag.nutricion, day: 5),
        _post('e1', PillarTag.ejercicio, day: 4),
      ];
      final feed = FeedMatcher.build(observations: const [], posts: posts);
      expect(feed.context, isNull);
      expect(feed.forYou!.id, 'n1');
    });

    test('sin posts → feed vacío', () {
      final feed = FeedMatcher.build(
        observations: [_baselineBelow('Ejercicio')],
        posts: const [],
      );
      expect(feed.isEmpty, isTrue);
    });

    test('pilar general (observación no mapeable) → destacado más reciente', () {
      final posts = [
        _post('n1', PillarTag.nutricion, day: 5),
        _post('e1', PillarTag.ejercicio, day: 4),
      ];
      final feed = FeedMatcher.build(
        observations: [_baselineBelow('Peso corporal')],
        posts: posts,
      );
      expect(feed.forYou!.id, 'n1');
    });
  });
}
