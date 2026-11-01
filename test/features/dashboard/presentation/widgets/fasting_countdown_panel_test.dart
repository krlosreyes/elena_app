// Rediseño ayuno (2026-11-01): etapas de la barra y color ámbar → verde.

import 'package:elena_app/src/features/dashboard/presentation/widgets/fasting_countdown_panel.dart';
import 'package:elena_app/src/features/fasting/domain/fasting_status.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('16:8 → dos tramos: 0 h y 12 h', () {
    final s = stagesForTarget(16);
    expect(s.map((e) => e.$2), [0, 12]);
    expect(s.first.$1, FastingPhase.postAbsorption);
    expect(s.last.$1, FastingPhase.transition);
  });

  test('20:4 → aparece quema de grasa a las 18 h', () {
    expect(stagesForTarget(20).map((e) => e.$2), [0, 12, 18]);
  });

  test('el color nunca es rojo: arranca ámbar y termina verde', () {
    expect(fastingProgressColor(0), const Color(0xFFEF9F27));
    expect(fastingProgressColor(1), const Color(0xFF1D9E75));
    final mid = fastingProgressColor(0.5);
    expect((mid.r * 255).round() < 0xE2, isTrue);
  });

  testWidgets('muestra la cuenta regresiva con segundos', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: FastingCountdownPanel(
          startTime: DateTime.now().subtract(const Duration(hours: 1)),
          targetHours: 16,
        ),
      ),
    ));
    expect(find.text('Te falta'), findsOneWidget);
    expect(find.textContaining(RegExp(r'^1[45]:\d\d:\d\d$')), findsOneWidget);
    expect(find.text('Bajando insulina'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });
}
