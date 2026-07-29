// Coherencia del copy del Día Metabólico (2026-07-28).
//
// QUÉ IMPIDE ESTE TEST
// --------------------
// "Día Metabólico" aparecía en 10 pantallas y en ninguna se explicaba.
// Al escribir la explicación aparecen dos riesgos, y los dos ya nos han
// mordido antes en este repo:
//
//   1. Que el texto prometa una hora. METABOLIC_DAY_CONSTITUTION §1
//      prohíbe expresamente toda referencia al reloj: el ciclo lo marcan
//      los eventos del usuario. Un copy que diga "empieza a las 6:00"
//      contradice al motor y el usuario ve otra cosa en pantalla.
//
//   2. Que los números del cierre automático se escriban a mano y se
//      queden viejos. Es exactamente el bug de la notificación de
//      autofagia a las 16 h: el número vivía en dos sitios y solo se
//      actualizó uno.
//
// Estos tests atan el texto a las constantes reales del resolver.

import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle_resolver.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_day_copy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('el copy no promete horas de reloj', () {
    // La constitución (§1) es tajante: "CERO referencia al reloj del
    // calendario". Si alguien añade "a las 6 de la mañana" para hacerlo
    // más concreto, esto falla y le manda a leer el porqué.
    final textosDelUsuario = <String, String>{
      'definición': kMetabolicDayCoreDefinition,
      'porqué': kMetabolicDayRationale,
      'inicio': kMetabolicDayStartBody,
      'fin': kMetabolicDayEndBody,
    };

    test('ninguno da una hora concreta del día', () {
      // Formatos de hora: "6:00", "06:00", "6 h de la mañana", "18h".
      final horaDeReloj = RegExp(r'\b\d{1,2}\s*[:h]\s*\d{2}\b');
      textosDelUsuario.forEach((nombre, texto) {
        expect(horaDeReloj.hasMatch(texto), isFalse,
            reason: 'el copy de "$nombre" da una hora de reloj: "$texto". '
                'El día metabólico lo marcan los eventos del usuario, no '
                'el reloj (METABOLIC_DAY_CONSTITUTION §1).');
      });
    });

    test('la definición nombra el gesto que de verdad abre el ciclo', () {
      // El único evento que abre ciclo es el tap de iniciar ayuno
      // (constitución §2). Si la definición dijera "cuando te despiertas"
      // estaría describiendo algo que el motor no hace.
      expect(kMetabolicDayCoreDefinition.toLowerCase(), contains('ayuno'));
      expect(kMetabolicDayStartBody.toLowerCase(), contains('ayuno'));
    });

    test('la definición dice explícitamente que NO es la medianoche', () {
      // Es la confusión que venimos a deshacer: sin negarlo de frente,
      // el usuario asume calendario porque es lo que asume todo el mundo.
      expect(kMetabolicDayCoreDefinition.toLowerCase(), contains('medianoche'));
    });

    test('el fin se describe como el inicio del siguiente ciclo', () {
      expect(kMetabolicDayEndBody.toLowerCase(), contains('siguiente'));
    });
  });

  group('los cierres automáticos salen de las constantes del resolver', () {
    test('el aviso nombra la gracia real tras la ventana', () {
      final horas = kFallbackAfterWindowGrace.inHours;
      expect(kMetabolicDayAutoCloseBody, contains('$horas h'),
          reason: 'si cambia kFallbackAfterWindowGrace, el texto tiene que '
              'cambiar con él — es el bug de la autofagia a las 16 h '
              'repetido');
    });

    test('el aviso nombra el tope absoluto real', () {
      final horas = kAbsoluteCycleLimit.inHours;
      expect(kMetabolicDayAutoCloseBody, contains('$horas h'));
    });

    test('menciona los tres disparadores, no solo el más fácil', () {
      // El usuario ve cierres que no pidió. Si solo explicamos uno, los
      // otros dos siguen siendo inexplicables.
      final texto = kMetabolicDayAutoCloseBody.toLowerCase();
      expect(texto, contains('sin comer'));
      expect(texto, contains('dormi'));
      expect(texto, contains('tope'));
    });

    test('promete decir cuál fue el motivo, y la app puede cumplirlo', () {
      // `cycle_detail_sheet._humanReason` ya traduce cada ClosureReason a
      // lenguaje humano, así que la promesa es cumplible. Si algún día se
      // quita esa traducción, esta promesa queda vacía.
      expect(kMetabolicDayAutoCloseBody.toLowerCase(), contains('cuál fue'));
    });
  });

  group('el modo calendárico se explica a quien le aplica', () {
    test('usaDiaCalendario coincide con el resolver', () {
      // Wrapper fino a propósito: la UI no debe conocer el literal
      // 'Ninguno'. Este test evita que se despeguen.
      expect(usaDiaCalendario(kNoProtocol), isTrue);
      expect(usaDiaCalendario('16:8'), isFalse);
      expect(usaDiaCalendario('14:10'), isFalse);
    });

    test('el texto calendárico sí puede hablar de medianoche', () {
      // Es la única excepción legítima: con protocolo 'Ninguno' el cierre
      // ES calendárico (MetabolicCycleResolver.calendarFallbackCloseAt
      // devuelve 23:59:59.999). Aquí decir "medianoche" es exacto, no una
      // violación de §1.
      expect(kMetabolicDayCalendarBody.toLowerCase(), contains('medianoche'));
    });

    test('explica que la regla cambia al elegir protocolo', () {
      // Sin esto, quien pase de 'Ninguno' a 16:8 vería cambiar el
      // comportamiento de su día sin explicación.
      expect(kMetabolicDayCalendarBody.toLowerCase(), contains('protocolo'));
    });

    test('el cierre calendárico real es el final del día local', () {
      // Ata el texto al comportamiento: si alguien cambiara
      // calendarFallbackCloseAt a otra hora, "medianoche" pasaría a ser
      // mentira y este test lo cazaría.
      final cierre = MetabolicCycleResolver.calendarFallbackCloseAt(
        DateTime(2026, 7, 28, 10, 30),
      );
      expect(cierre.hour, 23);
      expect(cierre.minute, 59);
      expect(cierre.day, 28, reason: 'cierra el mismo día, no el siguiente');
    });
  });

  group('una sola definición, no diez', () {
    test('la frase núcleo no está vacía ni es un placeholder', () {
      expect(kMetabolicDayCoreDefinition.trim().length, greaterThan(40));
    });

    test('todos los bloques tienen título y cuerpo', () {
      final bloques = <String, String>{
        kMetabolicDayStartTitle: kMetabolicDayStartBody,
        kMetabolicDayEndTitle: kMetabolicDayEndBody,
        kMetabolicDayAutoCloseTitle: kMetabolicDayAutoCloseBody,
        kMetabolicDayCalendarTitle: kMetabolicDayCalendarBody,
      };
      bloques.forEach((titulo, cuerpo) {
        expect(titulo.trim(), isNotEmpty);
        expect(cuerpo.trim().length, greaterThan(20),
            reason: '"$titulo" tiene un cuerpo demasiado corto para '
                'explicar nada');
      });
    });
  });
}
