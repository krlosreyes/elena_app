// SPEC-194 inc3 + SPEC-197 — widget test del card "Tu siguiente paso".

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/features/billing/application/billing_providers.dart';
import 'package:elena_app/src/features/billing/application/feature_gate.dart';
import 'package:elena_app/src/features/coaching/application/coaching_providers.dart';
import 'package:elena_app/src/features/coaching/domain/action_source.dart';
import 'package:elena_app/src/features/coaching/domain/coaching_action.dart';
import 'package:elena_app/src/features/coaching/domain/confidence_level.dart';
import 'package:elena_app/src/features/coaching/domain/scoring/coaching_scorer.dart';
import 'package:elena_app/src/features/coaching/presentation/widgets/next_best_action_card.dart';

CoachingAction _action() => const CoachingAction(
      id: 'weak_pillar_sleep',
      title: 'Tu siguiente paso',
      actionText: 'Apaga pantallas 1h antes de dormir.',
      reason: 'Tu sueño es el que más arrastra esta semana.',
      pillar: Pillar.sleep,
      confidence: ConfidenceLevel.medium,
      citation: '· Walker 2017',
      source: ActionSource.weakPillar,
      urgencyKind: ActionUrgencyKind.habit,
      circadianImpact: 0.8,
    );

CoachingAction _secondary() => const CoachingAction(
      id: 'circadian_morning_hydrate',
      title: 'Secundaria',
      actionText: 'Toma agua al despertar.',
      reason: 'Hidratación matutina.',
      pillar: Pillar.hydration,
      confidence: ConfidenceLevel.low,
      citation: '· Biological Dial',
      source: ActionSource.circadian,
      urgencyKind: ActionUrgencyKind.phaseOpportunity,
      circadianImpact: 0.3,
    );

String _todayKey() {
  final n = DateTime.now();
  return '${n.year.toString().padLeft(4, '0')}-'
      '${n.month.toString().padLeft(2, '0')}-'
      '${n.day.toString().padLeft(2, '0')}';
}

Widget _wrap(
  CoachingSelection selection,
  SharedPreferences prefs, {
  bool premium = false,
}) {
  return ProviderScope(
    overrides: [
      coachingSelectionProvider.overrideWith((ref) => selection),
      sharedPreferencesProvider.overrideWithValue(prefs),
      featureGateProvider.overrideWithValue(FeatureGate(isPremium: premium)),
    ],
    child: const MaterialApp(home: Scaffold(body: NextBestActionCard())),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('renderiza la acción principal con CTA "Saber más"',
      (tester) async {
    await tester.pumpWidget(_wrap(CoachingSelection(primary: _action()), prefs));
    expect(find.text('Tu siguiente paso'), findsOneWidget);
    expect(find.text('Apaga pantallas 1h antes de dormir.'), findsOneWidget);
    expect(find.text('Sueño'), findsOneWidget); // chip de pilar
    expect(find.text('Saber más'), findsOneWidget);
  });

  testWidgets('tap "Saber más" abre el explainer con la cita', (tester) async {
    await tester.pumpWidget(_wrap(CoachingSelection(primary: _action()), prefs));
    await tester.tap(find.text('Saber más'));
    await tester.pumpAndSettle();
    expect(find.text('Por qué'), findsOneWidget);
    expect(find.text('· Walker 2017'), findsOneWidget);
  });

  testWidgets('selección vacía → no renderiza card', (tester) async {
    await tester.pumpWidget(_wrap(const CoachingSelection(), prefs));
    expect(find.text('Tu siguiente paso'), findsNothing);
    expect(find.byType(NextBestActionCard), findsOneWidget); // existe pero vacío
  });

  group('SPEC-197 gating', () {
    testWidgets('Free oculta la acción secundaria', (tester) async {
      await tester.pumpWidget(_wrap(
        CoachingSelection(primary: _action(), secondary: _secondary()),
        prefs,
      ));
      expect(find.text('Tu siguiente paso'), findsOneWidget); // primaria visible
      expect(find.textContaining('También:'), findsNothing); // secundaria oculta
    });

    testWidgets('Premium muestra la acción secundaria', (tester) async {
      await tester.pumpWidget(_wrap(
        CoachingSelection(primary: _action(), secondary: _secondary()),
        prefs,
        premium: true,
      ));
      expect(find.textContaining('También:'), findsOneWidget);
    });

    testWidgets('Free + acción distinta ya vista hoy → card de upgrade',
        (tester) async {
      // Sembrar el store anti-fatiga: ya se mostró OTRA acción hoy.
      SharedPreferences.setMockInitialValues({
        'coaching.fatigue.v1': jsonEncode({
          'lastDate': _todayKey(),
          'shown': ['otra_accion_distinta'],
          'completed': <String>[],
          'ignored': <String, int>{},
        }),
      });
      final seeded = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        _wrap(CoachingSelection(primary: _action()), seeded),
      );

      expect(find.text('Desbloquea coaching ilimitado'), findsOneWidget);
      expect(find.text('Desbloquear'), findsOneWidget);
      // La acción real NO se muestra.
      expect(find.text('Apaga pantallas 1h antes de dormir.'), findsNothing);
    });

    testWidgets('Premium + acción distinta ya vista hoy → SÍ muestra la acción',
        (tester) async {
      SharedPreferences.setMockInitialValues({
        'coaching.fatigue.v1': jsonEncode({
          'lastDate': _todayKey(),
          'shown': ['otra_accion_distinta'],
          'completed': <String>[],
          'ignored': <String, int>{},
        }),
      });
      final seeded = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        _wrap(CoachingSelection(primary: _action()), seeded, premium: true),
      );

      expect(find.text('Apaga pantallas 1h antes de dormir.'), findsOneWidget);
      expect(find.text('Desbloquea coaching ilimitado'), findsNothing);
    });
  });
}
