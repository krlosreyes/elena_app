// SPEC-182 §RF-182-08 (2026-06-05): widget tests de las pantallas
// re-tonadas + las 2 nuevas (Día Metabólico y Notificaciones).
//
// Validan que el copy nuevo se renderiza y que los CTAs del paso 104
// disparan los callbacks correctos.

import 'package:elena_app/src/features/onboarding/presentation/widgets/intro_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF020617),
        body: SafeArea(child: child),
      ),
    );

void main() {
  group('SPEC-182 — IntroWelcomeStep', () {
    testWidgets('renderea el headline coach-not-tracker', (tester) async {
      await tester.pumpWidget(
        _wrap(const IntroWelcomeStep(isDark: true)),
      );
      expect(find.text('Te acompañamos a leer tu cuerpo'), findsOneWidget);
      expect(find.textContaining('No es un cuaderno digital'),
          findsOneWidget);
    });
  });

  group('SPEC-182 — IntroImrStep (Dos números)', () {
    testWidgets('renderea HOY + IMR con texto explicativo', (tester) async {
      await tester.pumpWidget(
        _wrap(const IntroImrStep(isDark: true)),
      );
      expect(find.text('Tus dos números'), findsOneWidget);
      expect(find.textContaining('HOY es cómo viviste hoy'),
          findsOneWidget);
      expect(find.textContaining('IMR es tu base metabólica'),
          findsOneWidget);
    });
  });

  group('SPEC-182 — IntroDataStep', () {
    testWidgets('renderea privacidad con tono nuevo', (tester) async {
      await tester.pumpWidget(
        _wrap(const IntroDataStep(isDark: true)),
      );
      expect(find.text('Tus datos son tuyos'), findsOneWidget);
      expect(find.textContaining('No vendemos ni compartimos'),
          findsOneWidget);
    });
  });

  group('SPEC-182 §RF-182-04 — IntroMetabolicDayStep', () {
    testWidgets('renderea headline + body del Día Metabólico',
        (tester) async {
      await tester.pumpWidget(
        _wrap(const IntroMetabolicDayStep(isDark: true)),
      );
      expect(find.text('El día empieza cuando empezás a ayunar'),
          findsOneWidget);
      expect(find.textContaining('no se cierra a medianoche'),
          findsOneWidget);
      expect(find.textContaining('feedback del día con cita'),
          findsOneWidget);
    });
  });

  group('SPEC-182 §RF-182-05 — IntroNotificationsStep', () {
    testWidgets('renderea 3 ejemplos con cita', (tester) async {
      await tester.pumpWidget(
        _wrap(IntroNotificationsStep(
          isDark: true,
          onActivate: () {},
          onSkip: () {},
        )),
      );
      expect(find.text('16 horas — Limpieza profunda'), findsOneWidget);
      expect(find.text('3 horas antes de dormir'), findsOneWidget);
      expect(find.text('Cortisol peak: hora ideal'), findsOneWidget);
      // Citas en el formato "· Autor Año".
      expect(find.text('· Levine 2017'), findsOneWidget);
      expect(find.text('· Sutton 2018'), findsOneWidget);
      expect(find.text('· Adan 2012'), findsOneWidget);
    });

    testWidgets('tap "Activar coaching" dispara onActivate', (tester) async {
      // El paso es scrollable (ListView): con el viewport chico de test los
      // botones del fondo no se construyen. Agrandamos el viewport para que
      // se rendericen y sean tappables (triage 2026-06-07).
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      var activated = false;
      await tester.pumpWidget(
        _wrap(IntroNotificationsStep(
          isDark: true,
          onActivate: () => activated = true,
          onSkip: () {},
        )),
      );
      await tester.tap(find.text('Activar coaching por notificaciones'));
      await tester.pump();
      expect(activated, isTrue);
    });

    testWidgets('tap "Más tarde" dispara onSkip', (tester) async {
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      var skipped = false;
      await tester.pumpWidget(
        _wrap(IntroNotificationsStep(
          isDark: true,
          onActivate: () {},
          onSkip: () => skipped = true,
        )),
      );
      await tester.tap(find.text('Más tarde'));
      await tester.pump();
      expect(skipped, isTrue);
    });
  });
}
