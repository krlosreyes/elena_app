// SPEC-148 §RF-148-05 (2026-06-05): widget tests del TransformationCard.
//
// El widget stateless puro no depende de Riverpod — los tests le
// pasan el snapshot y la narrativa directamente.

import 'package:elena_app/src/features/analysis/application/transformation_narrator.dart';
import 'package:elena_app/src/features/analysis/domain/transformation_snapshot.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/transformation_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF020617),
        body: Center(child: SizedBox(width: 360, child: child)),
      ),
    );

TransformationSnapshot _fullSnapshot() {
  return TransformationSnapshot(
    weightKg: const TransformationDelta<double>(
      past: 85.2,
      current: 84.0,
      label: 'Peso',
      unit: 'kg',
    ),
    imr: const TransformationDelta<int>(
      past: 58,
      current: 64,
      label: 'IMR',
      unit: '',
    ),
    waistCm: const TransformationDelta<double>(
      past: 96.0,
      current: 94.0,
      label: 'Cintura',
      unit: 'cm',
    ),
    bodyFatPct: const TransformationDelta<double>(
      past: 24.0,
      current: 22.5,
      label: '% Grasa',
      unit: '%',
    ),
    sleepHoursAvg: const TransformationDelta<double>(
      past: 6.2,
      current: 6.8,
      label: 'Sueño',
      unit: 'h prom',
    ),
    fastingDaysOf7: const TransformationDelta<int>(
      past: 4,
      current: 6,
      label: 'Ayuno',
      unit: 'd/7',
    ),
    // SPEC-138 (2026-06-05): nuevo delta UPF añadido al snapshot.
    upfSharePct: TransformationDelta.empty(
      label: 'Ultraprocesado',
      unit: '%',
    ),
  );
}

void main() {
  group('SPEC-148 §RF-148-05 — TransformationCard render completo', () {
    testWidgets('renderea las 6 etiquetas de indicadores', (tester) async {
      await tester.pumpWidget(_wrap(
        TransformationCard(
          snapshot: _fullSnapshot(),
          narrative: const TransformationNarrative(
            id: 'test-id',
            headline: 'Tu cambio se ve.',
            citation: 'Mattson 2017',
          ),
        ),
      ));
      expect(find.text('Peso'), findsOneWidget);
      expect(find.text('IMR'), findsOneWidget);
      expect(find.text('Cintura'), findsOneWidget);
      expect(find.text('% Grasa'), findsOneWidget);
      expect(find.text('Sueño'), findsOneWidget);
      expect(find.text('Ayuno'), findsOneWidget);
    });

    testWidgets('renderea headers HACE 30 DÍAS y HOY', (tester) async {
      await tester.pumpWidget(_wrap(
        TransformationCard(
          snapshot: _fullSnapshot(),
          narrative: null,
        ),
      ));
      expect(find.text('HACE 30 DÍAS'), findsOneWidget);
      expect(find.text('HOY'), findsOneWidget);
    });

    testWidgets('valores past y current se renderizan', (tester) async {
      await tester.pumpWidget(_wrap(
        TransformationCard(
          snapshot: _fullSnapshot(),
          narrative: null,
        ),
      ));
      // Peso 85.2 → 84.0
      expect(find.text('85.2'), findsOneWidget);
      expect(find.text('84'), findsOneWidget); // 84.0 rounded
      // IMR 58 → 64
      expect(find.text('58'), findsOneWidget);
      expect(find.text('64'), findsOneWidget);
    });

    testWidgets('delta pills con flecha + valor', (tester) async {
      await tester.pumpWidget(_wrap(
        TransformationCard(
          snapshot: _fullSnapshot(),
          narrative: null,
        ),
      ));
      // Peso: -1.2 → ↓1.2
      expect(find.text('↓1.2'), findsOneWidget);
      // IMR: +6 → ↑6
      expect(find.text('↑6'), findsOneWidget);
      // Cintura: -2 → ↓2
      expect(find.text('↓2'), findsOneWidget);
      // Sueño: +0.6 → ↑0.6
      expect(find.text('↑0.6'), findsOneWidget);
      // Ayuno: +2 → ↑2
      expect(find.text('↑2'), findsOneWidget);
    });

    testWidgets('narrativa headline y cita renderizan', (tester) async {
      await tester.pumpWidget(_wrap(
        TransformationCard(
          snapshot: _fullSnapshot(),
          narrative: const TransformationNarrative(
            id: 'p',
            headline: 'Tu ayuno está haciendo el trabajo.',
            citation: 'Mattson 2017',
          ),
        ),
      ));
      expect(find.text('TU INTERPRETACIÓN'), findsOneWidget);
      expect(find.textContaining('Tu ayuno está haciendo'), findsOneWidget);
      expect(find.text('· Mattson 2017'), findsOneWidget);
    });

    testWidgets('narrativa sin cita no renderiza la línea de cita',
        (tester) async {
      await tester.pumpWidget(_wrap(
        TransformationCard(
          snapshot: _fullSnapshot(),
          narrative: const TransformationNarrative(
            id: 'p',
            headline: 'Seguí registrando.',
            citation: null,
          ),
        ),
      ));
      expect(find.textContaining('· '), findsNothing);
    });

    testWidgets('snapshot con un indicador sin past muestra "—" en past',
        (tester) async {
      final snap = TransformationSnapshot(
        weightKg: const TransformationDelta<double>(
          past: null,
          current: 80.0,
          label: 'Peso',
          unit: 'kg',
        ),
        imr: const TransformationDelta<int>(
          past: 58,
          current: 64,
          label: 'IMR',
          unit: '',
        ),
        waistCm: TransformationDelta.empty(label: 'Cintura', unit: 'cm'),
        bodyFatPct: TransformationDelta.empty(label: '% Grasa', unit: '%'),
        sleepHoursAvg:
            TransformationDelta.empty(label: 'Sueño', unit: 'h prom'),
        fastingDaysOf7:
            TransformationDelta.empty(label: 'Ayuno', unit: 'd/7'),
        upfSharePct: TransformationDelta.empty(
          label: 'Ultraprocesado',
          unit: '%',
        ),
      );
      await tester.pumpWidget(_wrap(
        TransformationCard(snapshot: snap, narrative: null),
      ));
      // Peso debe mostrar "—" en past y "80" en current.
      expect(find.text('—'), findsWidgets);
      expect(find.text('80'), findsOneWidget);
    });
  });
}
