// SPEC-247 (2026-07-07): widget tests para las pantallas de onboarding
// rediseñadas con principios Cialdini anclados a identidad ElenaApp.
//
// Cubre:
//   100 — IntroWelcomeStep    (Identidad: Unidad + Autoridad)
//   105 — IntroProtocolStep   (Compromiso y coherencia)
//   101 — IntroInsightStep    (Reciprocidad — adaptado por protocolo)
//   104 — IntroNotificationsStep (Prueba social + callbacks)
//
// Los tests de clases eliminadas (IntroImrStep, IntroDataStep,
// IntroMetabolicDayStep) fueron removidos en este SPEC.

import 'package:elena_app/src/features/onboarding/presentation/widgets/intro_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) => MaterialApp(
      home: Scaffold(
        backgroundColor: const Color(0xFF020617),
        body: SafeArea(child: child),
      ),
    );

// Viewport extendido para ListView con botones en el fondo.
void _bigViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1080, 2600);
  tester.view.devicePixelRatio = 1.0;
}

void main() {
  // ── Paso 100: Identidad ─────────────────────────────────────────────
  group('SPEC-247 — IntroWelcomeStep (Identidad)', () {
    testWidgets('renderea headline de identidad metabólica', (tester) async {
      await tester.pumpWidget(_wrap(const IntroWelcomeStep(isDark: true)));
      expect(
        find.textContaining('La mayoría sigue dietas'),
        findsOneWidget,
      );
      expect(
        find.textContaining('entender tu metabolismo'),
        findsOneWidget,
      );
    });

    testWidgets('renderea al menos una citation pill con NEJM', (tester) async {
      await tester.pumpWidget(_wrap(const IntroWelcomeStep(isDark: true)));
      expect(find.textContaining('NEJM'), findsWidgets);
    });

    // Fix P0 (validación de ejecución real, 23-jul-2026): el Nobel de
    // Fisiología o Medicina 2016 por el descubrimiento de los mecanismos
    // de la autofagia fue para Yoshinori Ohsumi, no para "Levine 2017"
    // (Beth Levine nunca recibió el Nobel). Test actualizado junto con
    // el copy real en intro_screens.dart.
    testWidgets('renderea citation pill de Ohsumi 2016', (tester) async {
      await tester.pumpWidget(_wrap(const IntroWelcomeStep(isDark: true)));
      expect(find.textContaining('Ohsumi 2016'), findsWidgets);
    });

    testWidgets('renderea sin voseo', (tester) async {
      await tester.pumpWidget(_wrap(const IntroWelcomeStep(isDark: true)));
      // Asegura que el copy no contiene argentinismos.
      expect(find.textContaining('empezás'), findsNothing);
      expect(find.textContaining('cumplís'), findsNothing);
      expect(find.textContaining('tenés'), findsNothing);
    });
  });

  // ── Paso 105: Protocolo ─────────────────────────────────────────────
  group('SPEC-247 — IntroProtocolStep (Compromiso)', () {
    testWidgets('renderea los 3 protocolos', (tester) async {
      await tester.pumpWidget(
        _wrap(IntroProtocolStep(
          isDark: true,
          selectedProtocol: '16:8',
          onProtocolSelected: (_) {},
        )),
      );
      expect(find.textContaining('14/10'), findsWidgets);
      expect(find.textContaining('16/8'), findsWidgets);
      expect(find.textContaining('18/6'), findsWidgets);
    });

    testWidgets('16:8 tiene badge Popular', (tester) async {
      await tester.pumpWidget(
        _wrap(IntroProtocolStep(
          isDark: true,
          selectedProtocol: '16:8',
          onProtocolSelected: (_) {},
        )),
      );
      expect(find.text('Popular'), findsOneWidget);
    });

    // SPEC-257 LIMPIEZA: el id real de la card 14/10 era '14:8' — bug
    // (14+8=22, no 24h) que este test enshrined en vez de atrapar. El
    // string no coincidía con ningún protocolo del catálogo real
    // (`FastingEligibility.ladder`), así que un usuario Novato que
    // elegía "14/10" en su primer gesto de onboarding quedaba invisible
    // para el gate médico y para el mecanismo de días de descanso
    // (SPEC-257 §3.1). Corregido a '14:10'.
    testWidgets('tap en 14:10 dispara onProtocolSelected con "14:10"',
        (tester) async {
      String? selected;
      await tester.pumpWidget(
        _wrap(IntroProtocolStep(
          isDark: true,
          selectedProtocol: '16:8',
          onProtocolSelected: (p) => selected = p,
        )),
      );
      // Tap en la tarjeta del 14/10.
      await tester.tap(find.textContaining('14/10').first);
      await tester.pump();
      expect(selected, equals('14:10'));
    });

    testWidgets('tap en 18:6 dispara onProtocolSelected con "18:6"',
        (tester) async {
      String? selected;
      await tester.pumpWidget(
        _wrap(IntroProtocolStep(
          isDark: true,
          selectedProtocol: '16:8',
          onProtocolSelected: (p) => selected = p,
        )),
      );
      await tester.tap(find.textContaining('18/6').first);
      await tester.pump();
      expect(selected, equals('18:6'));
    });

    testWidgets('nota de cambio en perfil visible', (tester) async {
      // BUGFIX (auditoría 2026-07-12): la nota va DESPUÉS de las 3 tarjetas
      // de protocolo dentro de un ListView — en el viewport chico por
      // defecto de flutter_test, ese texto queda fuera del cache extent y
      // el sliver nunca lo infla en el árbol, así que `find` no lo
      // encontraba (mismo motivo por el que otros tests de este archivo ya
      // usan `_bigViewport` para contenido al fondo de un ListView).
      _bigViewport(tester);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _wrap(IntroProtocolStep(
          isDark: true,
          selectedProtocol: '16:8',
          onProtocolSelected: (_) {},
        )),
      );
      expect(
        find.textContaining('Puedes cambiar de protocolo'),
        findsOneWidget,
      );
    });
  });

  // ── Paso 101: Insight personalizado ────────────────────────────────
  group('SPEC-247 — IntroInsightStep (Reciprocidad)', () {
    // Estos tres tests exigían `find.textContaining('Ohsumi')` en el
    // timeline, y el de 18:6 se llamaba "menciona autofagia y Ohsumi".
    // Estaban blindando el problema: la cita del Nobel iba puesta debajo
    // de "Autofagia a las 16 h", un umbral que Ohsumi nunca publicó — su
    // premio fue por el mecanismo de la autofagia en levaduras. Con el
    // timeline derivado de `FastingPhase`, ningún protocolo llega a la
    // autofagia (empieza a las 24 h) y esa cita ya no pinta nada aquí.
    // Ohsumi sigue —correctamente— en las citation pills del paso 100.
    testWidgets('protocolo 16:8 muestra timeline de 16 horas', (tester) async {
      _bigViewport(tester);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _wrap(const IntroInsightStep(isDark: true, protocol: '16:8')),
      );
      expect(find.textContaining('16 horas'), findsWidgets);
      expect(find.textContaining('Cahill'), findsWidgets);
      expect(find.textContaining('Ohsumi'), findsNothing);
    });

    testWidgets('protocolo 14:10 muestra timeline de 14 horas', (tester) async {
      _bigViewport(tester);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _wrap(const IntroInsightStep(isDark: true, protocol: '14:10')),
      );
      expect(find.textContaining('14 horas'), findsWidgets);
      expect(find.textContaining('Cahill'), findsWidgets);
    });

    testWidgets('protocolo 18:6 llega a quema de grasa, no a autofagia',
        (tester) async {
      _bigViewport(tester);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _wrap(const IntroInsightStep(isDark: true, protocol: '18:6')),
      );
      // 18 h coincide con el umbral de `fatBurning`, así que la meta y la
      // fase se anuncian juntas. Es el único protocolo que alcanza una
      // fase más allá de la cetogénesis.
      expect(find.textContaining('Hora 18'), findsWidgets);
      expect(find.textContaining('quema de grasa'), findsWidgets);
      expect(find.textContaining('Ohsumi'), findsNothing);
    });

    testWidgets('default (sin protocolo) usa 16:8', (tester) async {
      _bigViewport(tester);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _wrap(const IntroInsightStep(isDark: true)),
      );
      expect(find.textContaining('16 horas'), findsWidgets);
    });

    testWidgets('renderea sin voseo', (tester) async {
      await tester.pumpWidget(
        _wrap(const IntroInsightStep(isDark: true, protocol: '16:8')),
      );
      expect(find.textContaining('empezás'), findsNothing);
      expect(find.textContaining('cumplís'), findsNothing);
    });
  });

  // ── Paso 104: Notificaciones ──────────────────────────────────────
  group('SPEC-247 — IntroNotificationsStep', () {
    // Este test decía `expect(find.text('78%'), findsOneWidget)`: afirmaba
    // que la pantalla mostrara una estadística que el propio código
    // admitía inventada ("estimado conservador (beta)"). Estaba
    // blindando el problema en vez de protegerlo — el mismo patrón que el
    // test que afirmaba imperativos en voseo, encontrado esa misma
    // mañana. Se invierte: ahora vigila que NO vuelva.
    testWidgets('no muestra estadísticas de adherencia sin fuente',
        (tester) async {
      _bigViewport(tester);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _wrap(IntroNotificationsStep(
          isDark: true,
          onActivate: () {},
          onSkip: () {},
        )),
      );
      expect(find.text('78%'), findsNothing);
      expect(find.text('31%'), findsNothing);
      expect(find.textContaining('el doble de días'), findsNothing);
    });

    testWidgets('explica para qué sirven los avisos, sin inventar datos',
        (tester) async {
      _bigViewport(tester);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _wrap(IntroNotificationsStep(
          isDark: true,
          onActivate: () {},
          onSkip: () {},
        )),
      );
      // Las dos cosas que los avisos hacen de verdad, y que se pueden
      // comprobar en NotificationScheduler y EatingWindowState.
      expect(find.textContaining('cambia de fase'), findsOneWidget);
      expect(find.textContaining('cierre de tu ventana'), findsOneWidget);
    });

    testWidgets('renderea 2 ejemplos con cita', (tester) async {
      _bigViewport(tester);
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        _wrap(IntroNotificationsStep(
          isDark: true,
          onActivate: () {},
          onSkip: () {},
        )),
      );
      expect(find.textContaining('Cahill'), findsWidgets);
      expect(find.textContaining('Spiegel'), findsWidgets);
    });

    testWidgets('tap "Activar notificaciones" dispara onActivate',
        (tester) async {
      _bigViewport(tester);
      addTearDown(tester.view.reset);
      var activated = false;
      await tester.pumpWidget(
        _wrap(IntroNotificationsStep(
          isDark: true,
          onActivate: () => activated = true,
          onSkip: () {},
        )),
      );
      await tester.tap(find.text('Activar notificaciones'));
      await tester.pump();
      expect(activated, isTrue);
    });

    testWidgets('tap "Ahora no" dispara onSkip', (tester) async {
      _bigViewport(tester);
      addTearDown(tester.view.reset);
      var skipped = false;
      await tester.pumpWidget(
        _wrap(IntroNotificationsStep(
          isDark: true,
          onActivate: () {},
          onSkip: () => skipped = true,
        )),
      );
      await tester.tap(find.text('Ahora no'));
      await tester.pump();
      expect(skipped, isTrue);
    });
  });
}
