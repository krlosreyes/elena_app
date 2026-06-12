// SPEC-205 inc3: widget test de ForYouSection (provider sobrescrito).

import 'package:elena_app/src/features/analysis/domain/observation.dart';
import 'package:elena_app/src/features/content/application/personalized_feed_provider.dart';
import 'package:elena_app/src/features/content/domain/personalized_feed.dart';
import 'package:elena_app/src/features/content/domain/post.dart';
import 'package:elena_app/src/features/content/presentation/for_you_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

Post _post(String id, PillarTag pillar) => Post(
      id: id,
      title: 'Título $id',
      slug: id,
      pillar: pillar,
      contentMarkdown: 'texto',
      imageUrl: null, // sin red en tests → placeholder
      references: const ['Ref'],
      quiz: const [],
      publishedAt: DateTime(2026, 5, 1),
      status: 'published',
    );

Widget _wrap(PersonalizedFeed feed) {
  return ProviderScope(
    overrides: [
      personalizedFeedProvider.overrideWith(
        (ref) => AsyncValue.data(feed),
      ),
    ],
    child: const MaterialApp(
      home: Scaffold(body: SingleChildScrollView(child: ForYouSection())),
    ),
  );
}

void main() {
  testWidgets('renderiza destacado + adicionales + contexto', (tester) async {
    final feed = PersonalizedFeed(
      context: const Observation(
        type: ObservationType.baseline,
        subject: 'Ejercicio',
        headline: 'Tu ejercicio viene bajo esta semana.',
        detail: 'd',
        action: 'movete',
        strength: 0.6,
      ),
      forYou: _post('e1', PillarTag.ejercicio),
      more: [_post('n1', PillarTag.nutricion)],
    );

    await tester.pumpWidget(_wrap(feed));
    await tester.pump();

    expect(find.text('Para ti'), findsOneWidget);
    expect(find.text('Tu ejercicio viene bajo esta semana.'), findsOneWidget);
    expect(find.text('Título e1'), findsOneWidget);
    expect(find.text('Más para leer'), findsOneWidget);
    expect(find.text('Título n1'), findsOneWidget);
  });

  testWidgets('feed vacío → mensaje de estado', (tester) async {
    await tester.pumpWidget(_wrap(PersonalizedFeed.empty));
    await tester.pump();

    expect(find.text('Para ti'), findsOneWidget);
    expect(find.textContaining('Pronto vas a ver'), findsOneWidget);
  });

  testWidgets('sin contexto → solo artículos, sin línea de contexto',
      (tester) async {
    final feed = PersonalizedFeed(
      forYou: _post('n1', PillarTag.nutricion),
      more: const [],
    );
    await tester.pumpWidget(_wrap(feed));
    await tester.pump();

    expect(find.text('Título n1'), findsOneWidget);
    expect(find.text('Más para leer'), findsNothing);
  });
}
