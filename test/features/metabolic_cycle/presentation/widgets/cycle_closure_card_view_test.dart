// SPEC-149 §8.4: tests del CycleClosureCardView.
//
// El View es stateless puro — recibe MetabolicCycle + callbacks por
// constructor, sin Riverpod. Los tests verifican render variations y
// que los callbacks se invocan correctamente.

import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/cycle_feedback.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/metabolic_cycle/presentation/widgets/cycle_closure_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

MetabolicCycle _closedCycle({
  int score = 87,
  List<String> achievements = const [
    'Ayuno 16.0h — autofagia activa (Mattson 2017)',
    'Sueño reparador — leptina/grelina equilibradas (Walker 2017)',
  ],
  List<String> gaps = const [
    'Hidratación 65% — mañana 2L para mantener termorregulación',
  ],
  String insight =
      'Cerrar tu ventana temprano hoy mejora tu glucosa de mañana.',
  String? citation = 'Lopez-Minguez 2018, Clin Nutr',
}) {
  final started = DateTime(2026, 6, 1, 21);
  return MetabolicCycle.open(
    startedAt: started,
    fastingProtocol: '16:8',
    tzOffsetMinutes: -300,
  ).close(
    closedAt: started.add(const Duration(hours: 24)),
    reason: ClosureReason.manualNextFasting,
    fastingDurationHours: 16,
    feedingWindowHours: 8,
    dailyScore: score,
    pillarsCompleted: const CyclePillarsCompleted(
      fasting: true,
      sleep: true,
      hydration: false,
      exercise: true,
      nutrition: true,
    ),
    magnitudes: const CycleMagnitudes(
      fastingMagnitude: 1.0,
      sleepQualityScore: 0.85,
      hydrationMagnitude: 0.65,
      exerciseMagnitude: 1.0,
      nutritionMagnitude: 0.9,
    ),
    feedback: CycleFeedback(
      achievements: achievements,
      gaps: gaps,
      insight: insight,
      citation: citation,
    ),
  );
}

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        body: Center(child: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  group('SPEC-149 §8.4 — CycleClosureCardView render', () {
    testWidgets('Renderiza score, header, achievements, gaps, insight',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          CycleClosureCardView(
            cycle: _closedCycle(),
            onDismiss: () {},
            onStartNextFasting: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Header + dismiss button + score number.
      expect(find.text('TU CICLO METABÓLICO CERRÓ'), findsOneWidget);
      expect(find.text('87'), findsOneWidget);
      expect(find.text('/100'), findsOneWidget);
      expect(
        find.byKey(const Key('cycle_closure_dismiss_button')),
        findsOneWidget,
      );

      // Sections + bullets.
      expect(find.text('LOGRASTE'), findsOneWidget);
      expect(find.text('TE FALTÓ'), findsOneWidget);
      expect(
        find.textContaining('autofagia activa'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Hidratación 65%'),
        findsOneWidget,
      );

      // Insight + citation.
      expect(
        find.textContaining('glucosa de mañana'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Lopez-Minguez 2018'),
        findsOneWidget,
      );

      // CTA visible cuando hay callback.
      expect(
        find.byKey(
          const Key('cycle_closure_start_next_fasting_button'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Oculta CTA cuando onStartNextFasting es null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CycleClosureCardView(
            cycle: _closedCycle(),
            onDismiss: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const Key('cycle_closure_start_next_fasting_button'),
        ),
        findsNothing,
      );
    });

    testWidgets('Oculta sección LOGRASTE si achievements vacío',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          CycleClosureCardView(
            cycle: _closedCycle(achievements: const []),
            onDismiss: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('LOGRASTE'), findsNothing);
      expect(find.text('TE FALTÓ'), findsOneWidget);
    });

    testWidgets('Oculta sección TE FALTÓ si gaps vacío', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CycleClosureCardView(
            cycle: _closedCycle(gaps: const []),
            onDismiss: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('TE FALTÓ'), findsNothing);
      expect(find.text('LOGRASTE'), findsOneWidget);
    });

    testWidgets('Oculta citation si es null', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CycleClosureCardView(
            cycle: _closedCycle(citation: null),
            onDismiss: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Lopez-Minguez'), findsNothing);
      expect(find.textContaining('glucosa de mañana'), findsOneWidget);
    });

    testWidgets('Score 100 se renderiza correctamente (caso día perfecto)',
        (tester) async {
      await tester.pumpWidget(
        _wrap(
          CycleClosureCardView(
            cycle: _closedCycle(score: 100),
            onDismiss: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('100'), findsOneWidget);
    });

    testWidgets('Score 0 se renderiza correctamente', (tester) async {
      await tester.pumpWidget(
        _wrap(
          CycleClosureCardView(
            cycle: _closedCycle(score: 0),
            onDismiss: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('0'), findsOneWidget);
    });
  });

  group('SPEC-149 §8.4 — Interacciones', () {
    testWidgets('Tap en ✕ invoca onDismiss', (tester) async {
      var dismissed = false;
      await tester.pumpWidget(
        _wrap(
          CycleClosureCardView(
            cycle: _closedCycle(),
            onDismiss: () => dismissed = true,
            onStartNextFasting: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cycle_closure_dismiss_button')));
      await tester.pumpAndSettle();
      expect(dismissed, isTrue);
    });

    testWidgets('Tap en CTA invoca onStartNextFasting', (tester) async {
      var ctaTapped = false;
      await tester.pumpWidget(
        _wrap(
          CycleClosureCardView(
            cycle: _closedCycle(),
            onDismiss: () {},
            onStartNextFasting: () => ctaTapped = true,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(
          const Key('cycle_closure_start_next_fasting_button'),
        ),
      );
      await tester.pumpAndSettle();
      expect(ctaTapped, isTrue);
    });
  });

  group('SPEC-149 §8.4 — Assertions de precondición', () {
    testWidgets('Falla si el cycle no está cerrado (assert en debug)',
        (tester) async {
      final open = MetabolicCycle.open(
        startedAt: DateTime(2026, 6, 1, 21),
        fastingProtocol: '16:8',
        tzOffsetMinutes: 0,
      );
      // El wrapper CycleClosureCard valida; aquí testeamos que el View
      // dispara assert cuando se le pasa un ciclo abierto (defensa).
      await tester.pumpWidget(
        _wrap(
          CycleClosureCardView(
            cycle: open,
            onDismiss: () {},
          ),
        ),
      );
      expect(tester.takeException(), isA<AssertionError>());
    });
  });
}
