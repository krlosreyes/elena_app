// Recorrido en Simulador, 27-jul-2026 — el cribado médico desconectado.
//
// QUÉ IMPIDE ESTE TEST
// --------------------
// `FastingEligibility.assess()` es un cribado médico real y ya
// implementado: lee `pathologies` y con embarazo o trastorno alimentario
// declarados devuelve `maxProtocol: 'Ninguno'`, bloqueando el ayuno.
//
// El guardarraíl existía y funcionaba. Lo que fallaba es que **nunca
// recibía el dato**. La pantalla de contraindicaciones solo pedía marcar
// "he leído"; `pathologies` se quedaba en `['Ninguna']` salvo que el
// usuario descubriera por su cuenta un selector dos pantallas más
// adelante, tras una fila que ya mostraba "Ninguna" como si fuera un
// valor resuelto. Un diabético tipo 1 leía la advertencia, la aceptaba, y
// terminaba el onboarding con "Patologías: Ninguna" guardado.
//
// Estos tests fijan la conexión: lo que se declara en el disclaimer llega
// a `pathologies`, y desde ahí al gate.

import 'package:elena_app/src/features/auth/domain/health_disclaimer.dart';
import 'package:elena_app/src/features/streak/domain/fasting_eligibility.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Usuario mínimo sano, para preguntarle al gate qué haría. Mismo molde
/// que `fasting_eligibility_test.dart`.
UserModel _usuario({List<String> pathologies = const [kSinPatologias]}) =>
    UserModel(
      age: 30,
      gender: 'F',
      weight: 65,
      height: 165,
      pathologies: pathologies,
      profile: CircadianProfile(
        wakeUpTime: DateTime(2026, 1, 1, 7),
        sleepTime: DateTime(2026, 1, 1, 23),
      ),
    );

void main() {
  group('cada condición del disclaimer sabe qué escribir en pathologies', () {
    test('todas tienen flag y ninguna lo deja vacío', () {
      expect(kHealthDisclaimerConditions, isNotEmpty);
      for (final c in kHealthDisclaimerConditions) {
        expect(c.pathologyFlag.trim(), isNotEmpty,
            reason: '"${c.title}" no declara a qué flag corresponde, así '
                'que marcarla no llegaría a FastingEligibility');
      }
    });

    test('los flags son únicos: dos condiciones no comparten literal', () {
      final flags = kHealthDisclaimerConditions.map((c) => c.pathologyFlag);
      expect(flags.toSet().length, flags.length);
    });

    test('ninguna usa el literal reservado de "sin patologías"', () {
      for (final c in kHealthDisclaimerConditions) {
        expect(c.pathologyFlag, isNot(kSinPatologias));
      }
    });
  });

  group('pathologiesFromDisclaimer', () {
    test('sin nada marcado devuelve Ninguna, no lista vacía', () {
      // Una lista vacía sería ambigua aguas abajo. `['Ninguna']` es la
      // forma que el resto de la app ya entiende como "declarado sin
      // condiciones".
      expect(pathologiesFromDisclaimer({}), [kSinPatologias]);
    });

    test('traduce lo marcado a los flags del gate', () {
      final resultado = pathologiesFromDisclaimer({
        FastingPathologyFlags.embarazoLactancia,
      });
      expect(resultado, [FastingPathologyFlags.embarazoLactancia]);
      expect(resultado, isNot(contains(kSinPatologias)));
    });

    test('respeta el orden de la lista canónica con varias marcadas', () {
      final resultado = pathologiesFromDisclaimer({
        FastingPathologyFlags.trastornoAlimentario,
        FastingPathologyFlags.diabetesMedicada,
      });
      expect(resultado.length, 2);
      // Diabetes va antes que TCA en `kHealthDisclaimerConditions`.
      expect(resultado.first, FastingPathologyFlags.diabetesMedicada);
    });

    test('ignora flags que no pertenecen al disclaimer', () {
      expect(pathologiesFromDisclaimer({'Inventado'}), [kSinPatologias]);
    });
  });

  // ── La razón de ser de todo esto ──────────────────────────────────
  group('lo declarado en el disclaimer llega al gate y lo activa', () {
    test('embarazo declarado bloquea el ayuno', () {
      final pathologies = pathologiesFromDisclaimer({
        FastingPathologyFlags.embarazoLactancia,
      });
      expect(pathologies, contains(FastingPathologyFlags.embarazoLactancia),
          reason: 'es lo que assess() busca para devolver maxProtocol '
              '"Ninguno" — sin este literal el gate nunca se entera');
    });

    test('trastorno alimentario declarado bloquea el ayuno', () {
      final pathologies = pathologiesFromDisclaimer({
        FastingPathologyFlags.trastornoAlimentario,
      });
      expect(pathologies, contains(FastingPathologyFlags.trastornoAlimentario));
    });

    test('el caso concreto del informe: diabetes tipo 1', () {
      // Un diabético tipo 1 terminaba el onboarding con "Ninguna"
      // guardado pese a haber leído y aceptado la advertencia.
      final diabetes = kHealthDisclaimerConditions
          .firstWhere((c) => c.title.contains('Diabetes Tipo 1'));
      final pathologies = pathologiesFromDisclaimer({diabetes.pathologyFlag});

      expect(pathologies, isNot(contains(kSinPatologias)));
      expect(pathologies, contains(FastingPathologyFlags.diabetesMedicada),
          reason: 'debe mapear al flag que el gate ya reconoce');
    });
  });

  // ── El aviso de consecuencia ───────────────────────────────────────
  //
  // Verificado en Simulador (28-jul-2026): al declarar embarazo, el
  // usuario seguía viendo "Ayuno 16:8" durante todo el onboarding y solo
  // al terminar se encontraba el ayuno bloqueado, sin explicación. El
  // recorte lo hace `clamp` antes de guardar y no se puede adelantar
  // —el protocolo se elige en un paso anterior al cribado— pero sí se
  // puede avisar.
  group('efectoSobreElAyuno avisa exactamente lo que el gate hace', () {
    test('las tres condiciones con regla tienen aviso', () {
      for (final flag in [
        FastingPathologyFlags.embarazoLactancia,
        FastingPathologyFlags.trastornoAlimentario,
        FastingPathologyFlags.diabetesMedicada,
      ]) {
        final efecto = FastingEligibility.efectoSobreElAyuno(flag);
        expect(efecto, isNotNull,
            reason: '"$flag" cambia el protocolo en assess() pero no lo '
                'avisa: el usuario se enteraría al terminar');
        expect(efecto!.trim(), isNotEmpty);
      }
    });

    test('las que no afectan al ayuno no inventan un aviso', () {
      expect(
        FastingEligibility.efectoSobreElAyuno(
            DisclaimerOnlyFlags.insuficienciaRenal),
        isNull,
      );
      expect(
        FastingEligibility.efectoSobreElAyuno(
            DisclaimerOnlyFlags.sarcopeniaSevera),
        isNull,
      );
      expect(FastingEligibility.efectoSobreElAyuno('Inventado'), isNull);
    });

    test('supervisión médica no avisa: amplía el catálogo, no lo recorta', () {
      expect(
        FastingEligibility.efectoSobreElAyuno(
            FastingPathologyFlags.supervisionMedicaActiva),
        isNull,
      );
    });

    test('el aviso del embarazo dice que se desactiva, no que se limita', () {
      final efecto = FastingEligibility.efectoSobreElAyuno(
          FastingPathologyFlags.embarazoLactancia)!;
      expect(efecto.toLowerCase(), contains('desactiva'));
    });

    test('el aviso de diabetes medicada nombra el tope que assess() aplica',
        () {
      // Atado al comportamiento real, no a una cadena suelta: se pregunta
      // al gate cuál es el tope y se comprueba que el aviso lo nombre. Si
      // mañana cambia el tope, este test falla y obliga a actualizar el
      // texto en vez de dejar al usuario con un número equivocado.
      final gate = FastingEligibility.assess(_usuario(
        pathologies: [FastingPathologyFlags.diabetesMedicada],
      ));
      final efecto = FastingEligibility.efectoSobreElAyuno(
          FastingPathologyFlags.diabetesMedicada)!;

      // El id interno usa dos puntos ('14:10'); al usuario se le muestra
      // con barra ('14/10'), como en las tarjetas de protocolo.
      expect(efecto, contains(gate.maxProtocol.replaceAll(':', '/')));
      expect(gate.blocked, isFalse,
          reason: 'si pasara a bloquear, el aviso tendría que decir '
              '"desactivado", no "se limita"');
    });

    test('embarazo: el gate bloquea y el aviso lo dice', () {
      final gate = FastingEligibility.assess(_usuario(
        pathologies: [FastingPathologyFlags.embarazoLactancia],
      ));
      expect(gate.blocked, isTrue);
      expect(gate.maxProtocol, 'Ninguno');
    });
  });

  group('las dos condiciones sin gate quedan declaradas igualmente', () {
    // Insuficiencia renal y sarcopenia no bloquean el ayuno: el riesgo
    // que describe el propio disclaimer es de hidratación y de ingesta
    // proteica, no de ayunar. Pero deben quedar registradas para que la
    // revisión clínica externa pendiente (PRODUCTION_HARDENING §7) pueda
    // decidir si merecen gate propio.
    test('insuficiencia renal se persiste con su literal', () {
      expect(
        pathologiesFromDisclaimer({DisclaimerOnlyFlags.insuficienciaRenal}),
        [DisclaimerOnlyFlags.insuficienciaRenal],
      );
    });

    test('sarcopenia severa se persiste con su literal', () {
      expect(
        pathologiesFromDisclaimer({DisclaimerOnlyFlags.sarcopeniaSevera}),
        [DisclaimerOnlyFlags.sarcopeniaSevera],
      );
    });

    test('no coinciden con ningún flag de FastingPathologyFlags', () {
      // Si algún día se les da gate, este test falla y obliga a revisar
      // el comentario de arriba en vez de dejarlo desactualizado.
      const conGate = [
        FastingPathologyFlags.embarazoLactancia,
        FastingPathologyFlags.trastornoAlimentario,
        FastingPathologyFlags.diabetesMedicada,
        FastingPathologyFlags.supervisionMedicaActiva,
      ];
      expect(conGate, isNot(contains(DisclaimerOnlyFlags.insuficienciaRenal)));
      expect(conGate, isNot(contains(DisclaimerOnlyFlags.sarcopeniaSevera)));
    });
  });
}
