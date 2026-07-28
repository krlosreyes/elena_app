// Recorrido en Simulador, 27-jul-2026 — C-01, instancia número ocho.
//
// QUÉ IMPIDE ESTE TEST
// --------------------
// El copy del check-in de las 16 h decía "Tu cuerpo inició la autofagia".
// Según `FastingPhase.startsAt` la autofagia empieza a las 24 h: a las
// 16 h el usuario sigue en `transition`. Y como estos textos se programan
// además como notificación push al iniciar el ayuno, todo usuario de 16:8
// recibía a diario, en la pantalla de bloqueo, una afirmación que la
// propia app desmiente en la leyenda del reloj ("24 h autofagia").
//
// Fue la octava aparición de la misma incoherencia repartida por archivos
// distintos. Arreglar los ocho no sirve de nada si la novena llega con la
// siguiente feature, así que esto barre el copy contra el enum en vez de
// comprobar una cadena concreta.
//
// CÓMO FUNCIONA
// -------------
// Para cada hito de check-in se pide el prompt real y se comprueba que no
// nombre ninguna fase cuyo umbral canónico esté por delante de esa hora.
// El vocabulario sale de `FastingPhase`, no de una lista escrita a mano:
// si mañana cambia un umbral o un nombre de fase, este test se entera.

import 'package:elena_app/src/features/coaching/application/predictive_trigger_engine.dart';
import 'package:elena_app/src/features/fasting/domain/fasting_status.dart';
import 'package:elena_app/src/features/onboarding/presentation/widgets/intro_screens.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Palabras que delatan que se está nombrando una fase, con la hora a
/// partir de la cual es legítimo usarlas.
///
/// Se derivan del enum —`milestoneName` y `displayName` cubren los
/// nombres que ve el usuario— y no de una lista escrita a mano: si
/// mañana cambia un umbral o un nombre de fase, los tests se enteran.
Map<String, Duration> _vocabularioDeFases() => <String, Duration>{
      for (final fase in FastingPhase.values) ...{
        fase.milestoneName.toLowerCase(): fase.startsAt,
        fase.displayName.toLowerCase(): fase.startsAt,
      },
      // `fatBurning.description` la llama "cetosis nutricional"; el copy
      // suele decir solo "cetosis". La cetogénesis (12 h) es otra cosa y
      // tiene su propia palabra, así que aquí solo entra la forma que
      // designa la cetosis establecida.
      'cetosis nutricional': FastingPhase.fatBurning.startsAt,
    }..removeWhere((palabra, _) => palabra.isEmpty);

/// Comprueba que [texto] no nombre ninguna fase cuyo umbral esté por
/// delante de [transcurrido].
void _noAdelantaFases(
  String texto,
  Duration transcurrido, {
  required String donde,
}) {
  final enMinusculas = texto.toLowerCase();
  _vocabularioDeFases().forEach((palabra, empiezaEn) {
    if (transcurrido >= empiezaEn) return; // ya se alcanzó: legítimo
    expect(
      enMinusculas.contains(palabra),
      isFalse,
      reason: '$donde dice "$palabra", pero esa fase no empieza hasta las '
          '${empiezaEn.inHours} h según FastingPhase.startsAt.\n'
          'Texto: "$texto"',
    );
  });
}

void main() {
  group('C-01 — el copy de check-in no adelanta fases del ayuno', () {
    for (final hito in PredictiveTriggerEngine.kCheckInMilestones) {
      test('el check-in de $hito h no promete nada que no haya llegado', () {
        final prompt = PredictiveTriggerEngine.checkInPrompt(
          fastingActive: true,
          fastingDuration: Duration(hours: hito),
          // Mediodía: dentro de la ventana de vigilia, para que el prompt
          // no se suprima por horario.
          now: DateTime(2026, 7, 27, 12),
          wakeHour: 6,
          sleepHour: 22,
        );

        expect(prompt, isNotNull,
            reason: 'el hito de $hito h debería producir un check-in');

        _noAdelantaFases(
          '${prompt!.title} ${prompt.message}',
          Duration(hours: hito),
          donde: 'El check-in de $hito h',
        );
      });
    }

    test('el caso concreto que se escapó: 16 h no menciona autofagia', () {
      final prompt = PredictiveTriggerEngine.checkInPrompt(
        fastingActive: true,
        fastingDuration: const Duration(hours: 16),
        now: DateTime(2026, 7, 27, 12),
        wakeHour: 6,
        sleepHour: 22,
      );

      final texto = '${prompt!.title} ${prompt.message}'.toLowerCase();
      expect(texto, isNot(contains('autofagia')));
      expect(texto, isNot(contains('limpieza profunda')));
    });

    test('la autofagia sí puede nombrarse a partir de las 24 h', () {
      // Guarda contra el exceso de celo: el test de arriba no debe
      // convertirse en "nunca menciones la autofagia". A las 24 h es
      // correcto, y si algún día se añade un hito ahí debe poder decirlo.
      expect(FastingPhase.autophagy.startsAt, const Duration(hours: 24));
      expect(
        PredictiveTriggerEngine.kCheckInMilestones.every((h) => h < 24),
        isTrue,
        reason: 'Si se añade un hito de 24 h o más, revisar que su copy '
            'sí nombre la autofagia — a esa altura ya es cierto.',
      );
    });
  });

  // ── La línea de tiempo del onboarding ──────────────────────────────
  //
  // Era la instancia más visible de C-01: tres tablas de umbrales
  // escritos a mano, una por protocolo, que no coincidían ni con el motor
  // ni entre sí. La autofagia se anunciaba a las 16 h —firmada con
  // Ohsumi— cuando el enum la sitúa en 24, y el mismo evento cambiaba de
  // hora según el protocolo elegido, cosa que la fisiología no hace.
  //
  // Ahora las filas se derivan de `FastingPhase`, pero eso solo no basta:
  // nada impide que alguien vuelva a escribir una fila a mano mañana. El
  // test mira lo que se RENDERIZA, no cómo se construye.
  group('C-01 — la línea de tiempo del onboarding no adelanta fases', () {
    // Los tres del catálogo real (`_ProtocolCard` del paso 105).
    const protocolos = {'14:10': 14, '16:8': 16, '18:6': 18};

    /// Marca el inicio del pie de pantalla, que se excluye del barrido.
    ///
    /// El pie dice, a propósito, "La autofagia empieza alrededor de las
    /// 24 h: tu protocolo no llega ahí". Nombrar una fase para decir que
    /// NO se alcanza es lo contrario del defecto que este grupo vigila —
    /// pero un barrido por palabras no distingue una cosa de la otra. La
    /// primera versión de este test tumbaba los tres protocolos por esa
    /// frase, que es justamente la parte honesta de la pantalla.
    ///
    /// Así que el barrido se limita a las filas de la línea de tiempo,
    /// que son las que afirman "a la hora X pasa Y". El contenido del pie
    /// lo comprueba su propio test, más abajo.
    const inicioDelPie = 'Estos eventos son automáticos';

    Future<List<String>> filasDeTimeline(
      WidgetTester tester,
      String protocolo,
    ) async {
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: IntroInsightStep(isDark: true, protocol: protocolo),
        ),
      ));
      await tester.pumpAndSettle();

      return tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .where((t) => !t.startsWith(inicioDelPie))
          .toList();
    }

    Future<String> textoCompleto(
      WidgetTester tester,
      String protocolo,
    ) async {
      tester.view.physicalSize = const Size(1080, 2600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: IntroInsightStep(isDark: true, protocol: protocolo),
        ),
      ));
      await tester.pumpAndSettle();

      return tester
          .widgetList<Text>(find.byType(Text))
          .map((t) => t.data ?? '')
          .join(' ');
    }

    protocolos.forEach((protocolo, horas) {
      testWidgets('$protocolo no anuncia fases que no alcanza', (tester) async {
        final filas = await filasDeTimeline(tester, protocolo);
        for (final fila in filas) {
          _noAdelantaFases(
            fila,
            Duration(hours: horas),
            donde: 'La línea de tiempo de $protocolo',
          );
        }
      });
    });

    testWidgets('ningún protocolo promete autofagia', (tester) async {
      // El caso concreto que se escapó, y el que más pesa: un usuario de
      // 16:8 recibía la promesa explícita —con el Nobel debajo— de que
      // cada día alcanzaba la autofagia. El Dashboard nunca se lo iba a
      // confirmar, porque para el motor a las 16 h sigue en transición.
      for (final protocolo in protocolos.keys) {
        final texto = (await textoCompleto(tester, protocolo)).toLowerCase();
        expect(
          texto.contains('autofagia activa') ||
              texto.contains('limpieza celular'),
          isFalse,
          reason: '$protocolo sigue anunciando la autofagia como alcanzable',
        );
      }
    });

    testWidgets('el pie dice dónde empieza la autofagia de verdad',
        (tester) async {
      // La contrapartida honesta de no prometerla: decir el número. Que
      // coincida con el de la leyenda del reloj es justo lo que la app
      // promete en su primera pantalla ("te damos las fuentes").
      final texto = await textoCompleto(tester, '16:8');
      expect(
        texto.contains('${FastingPhase.autophagy.startsAt.inHours} h'),
        isTrue,
        reason: 'El pie debería nombrar las 24 h de la autofagia',
      );
    });

    testWidgets('el mismo evento cae a la misma hora en los tres protocolos',
        (tester) async {
      // El síntoma que delató que los números estaban ajustados a mano:
      // "quema de grasa" aparecía a las 12 h en 14:10 y 16:8, pero a las
      // 10 h en 18:6. La biología no sabe qué protocolo se eligió.
      final cetogenesis = FastingPhase.transition.startsAt.inHours;
      for (final protocolo in protocolos.keys) {
        final texto = await textoCompleto(tester, protocolo);
        expect(texto, contains('Hora $cetogenesis'),
            reason: '$protocolo debería situar la cetogénesis en la misma '
                'hora que los demás');
      }
    });
  });
}
