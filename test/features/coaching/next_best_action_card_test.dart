// SPEC-194 inc3 — widget test del card "Tu siguiente paso".

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
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

Widget _wrap(CoachingSelection selection, SharedPreferences prefs) {
  return ProviderScope(
    overrides: [
      coachingSelectionProvider.overrideWith((ref) => selection),
      // RF-2.5: el card usa el store anti-fatiga (SharedPreferences) en
      // recordShown; en tests inyectamos un prefs mockeado.
      sharedPreferencesProvider.overrideWithValue(prefs),
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
}
