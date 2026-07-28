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
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('C-01 — el copy de check-in no adelanta fases del ayuno', () {
    /// Palabras que delatan que se está nombrando una fase, con la hora a
    /// partir de la cual es legítimo usarlas.
    ///
    /// Se derivan del enum: `milestoneName` y `displayName` cubren los
    /// nombres que ve el usuario ("Autofagia", "Quema de grasa"), y se
    /// añaden las raíces con las que el copy se refiere a esas mismas
    /// fases sin nombrarlas igual ("autofagia" dentro de una frase,
    /// "cetosis" para la cetosis nutricional de `fatBurning`).
    final vocabulario = <String, Duration>{
      for (final fase in FastingPhase.values) ...{
        fase.milestoneName.toLowerCase(): fase.startsAt,
        fase.displayName.toLowerCase(): fase.startsAt,
      },
      // `fatBurning.description` la llama "cetosis nutricional"; el copy
      // suele decir solo "cetosis". La cetogénesis (12 h) es otra cosa y
      // se distingue por su propia palabra, así que aquí solo entra la
      // forma que designa la cetosis establecida.
      'cetosis nutricional': FastingPhase.fatBurning.startsAt,
    }..removeWhere((palabra, _) => palabra.isEmpty);

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

        final texto = '${prompt!.title} ${prompt.message}'.toLowerCase();
        final transcurrido = Duration(hours: hito);

        vocabulario.forEach((palabra, empiezaEn) {
          if (transcurrido >= empiezaEn) return; // ya se alcanzó: legítimo
          expect(
            texto.contains(palabra),
            isFalse,
            reason: 'A las $hito h el copy dice "$palabra", pero esa fase '
                'no empieza hasta las ${empiezaEn.inHours} h según '
                'FastingPhase.startsAt.\n'
                'Copy actual: "${prompt.title} — ${prompt.message}"',
          );
        });
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
}
