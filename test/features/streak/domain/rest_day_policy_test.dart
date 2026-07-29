// Día de descanso planificado (2026-07-28).
//
// QUÉ IMPIDE ESTE TEST
// --------------------
// Elena ya tenía reservas (SPEC-255) que perdonan un día fallado. Lo que
// NO tenía es la distinción entre el día que se te olvidó y el día que
// decidiste descansar: los dos gastaban una reserva. Es decir, la app le
// cobraba al usuario por descansar bien.
//
// Estos tests fijan las tres reglas que hacen que el descanso sea un plan
// y no una excusa, y una cuarta que es la que se rompe sola si alguien
// toca el motor sin leer el porqué:
//
//   1. Se declara por adelantado (nunca el mismo día).
//   2. Tiene suelo: hidratación + sueño.
//   3. No gasta reserva.
//   4. Es TRANSPARENTE para el contador de reservas — ni suma ni resetea.
//      Sin esto, el usuario con descanso semanal fijo jamás llegaría a 7
//      días reales seguidos y nunca ganaría una reserva: el más constante
//      se quedaría sin red. Y en el sentido contrario, si el descanso
//      volviera a satisfacer el `% 7 == 0`, descansar REGALARÍA reservas.

import 'package:elena_app/src/features/streak/domain/rest_day_policy.dart';
import 'package:elena_app/src/features/streak/domain/streak_engine.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Día que califica de sobra para la racha (5/5 pilares).
StreakEntry _real(String date) => StreakEntry(
      date: date,
      fastingCompleted: true,
      sleepCompleted: true,
      hydrationCompleted: true,
      exerciseLogged: true,
      nutritionLogged: true,
      imrScore: 80,
    );

/// Día de descanso que cumple el suelo: solo hidratación y sueño. NO
/// califica para la racha por sí mismo (2 pilares < 3), que es justo lo
/// que lo hace un caso interesante.
StreakEntry _descansoConSuelo(String date) => StreakEntry(
      date: date,
      fastingCompleted: false,
      sleepCompleted: true,
      hydrationCompleted: true,
      exerciseLogged: false,
      nutritionLogged: false,
      imrScore: 45,
    );

/// Día vacío: ni suelo ni pilares.
StreakEntry _fallado(String date) => StreakEntry(
      date: date,
      fastingCompleted: false,
      sleepCompleted: false,
      hydrationCompleted: false,
      exerciseLogged: false,
      nutritionLogged: false,
      imrScore: 10,
    );

void main() {
  // 2026-07-27 es lunes. Toda la aritmética de semanas cuelga de ahí.
  final lunes = DateTime(2026, 7, 27);

  group('el suelo separa descansar de desaparecer', () {
    test('hidratación + sueño cumple', () {
      expect(
        RestDayPolicy.meetsRestFloor(_descansoConSuelo('2026-07-27')),
        isTrue,
      );
    });

    test('sin hidratación no cumple, y lo dice', () {
      final entry = StreakEntry(
        date: '2026-07-27',
        fastingCompleted: false,
        sleepCompleted: true,
        hydrationCompleted: false,
        exerciseLogged: false,
        nutritionLogged: false,
        imrScore: 30,
      );
      expect(RestDayPolicy.meetsRestFloor(entry), isFalse);
      final miss = RestDayPolicy.restFloorMiss(entry)!;
      expect(miss.missingHydration, isTrue);
      expect(miss.missingSleep, isFalse);
      expect(miss.missingBoth, isFalse);
    });

    test('un día que cumple el suelo no reporta falta', () {
      expect(
        RestDayPolicy.restFloorMiss(_descansoConSuelo('2026-07-27')),
        isNull,
      );
    });

    test('el día vacío falla los dos', () {
      final miss = RestDayPolicy.restFloorMiss(_fallado('2026-07-27'))!;
      expect(miss.missingBoth, isTrue);
    });
  });

  group('qué día es el descanso', () {
    test('el día fijo cae en el weekday elegido de esa semana', () {
      // Miércoles = ISO 3. La semana del lunes 27-jul tiene su miércoles
      // el 29.
      const policy = RestDayPolicy(weeklyRestWeekday: 3);
      expect(policy.restDateForWeekOf(lunes), '2026-07-29');
      expect(policy.isRestDay('2026-07-29'), isTrue);
      expect(policy.isRestDay('2026-07-28'), isFalse);
    });

    test('domingo (ISO 7) cae al final de la semana, no al principio', () {
      // La trampa clásica de mezclar convenciones: en US-locale el domingo
      // abre la semana. Aquí es ISO, así que el domingo de la semana del
      // lunes 27 es el 2 de agosto.
      const policy = RestDayPolicy(weeklyRestWeekday: 7);
      expect(policy.restDateForWeekOf(lunes), '2026-08-02');
    });

    test('una fecha movida reemplaza al día fijo de SU semana', () {
      const base = RestDayPolicy(weeklyRestWeekday: 7); // domingo
      final policy = base.declare('2026-07-30', now: lunes); // jueves

      expect(policy.isRestDay('2026-07-30'), isTrue,
          reason: 'el jueves declarado es el descanso de esta semana');
      expect(policy.isRestDay('2026-08-02'), isFalse,
          reason: 'el domingo fijo queda desplazado: es UNO por semana, '
              'no dos');
    });

    test('mover una semana no afecta a las demás', () {
      const base = RestDayPolicy(weeklyRestWeekday: 7);
      final policy = base.declare('2026-07-30', now: lunes);

      // Semana siguiente: el domingo fijo sigue mandando.
      expect(policy.isRestDay('2026-08-09'), isTrue);
    });

    test('declarar dos veces en la misma semana reemplaza, no acumula', () {
      const base = RestDayPolicy(weeklyRestWeekday: 7);
      final policy = base
          .declare('2026-07-29', now: lunes)
          .declare('2026-07-30', now: lunes);

      expect(policy.movedDates, {'2026-07-30'});
      expect(policy.isRestDay('2026-07-29'), isFalse);
      expect(policy.isRestDay('2026-07-30'), isTrue);
    });

    test('sin día fijo y sin movidas no hay descanso', () {
      expect(RestDayPolicy.disabled.restDateForWeekOf(lunes), isNull);
      expect(RestDayPolicy.disabled.isEnabled, isFalse);
      expect(RestDayPolicy.disabled.isRestDay('2026-07-29'), isFalse);
    });

    test('cancelar la movida devuelve el día fijo de esa semana', () {
      const base = RestDayPolicy(weeklyRestWeekday: 7);
      final movida = base.declare('2026-07-30', now: lunes);
      final cancelada = movida.cancelMoveForWeekOf('2026-07-30');

      expect(cancelada.isRestDay('2026-08-02'), isTrue);
      expect(cancelada.isRestDay('2026-07-30'), isFalse);
    });
  });

  group('declarar solo hacia adelante', () {
    const policy = RestDayPolicy(weeklyRestWeekday: 7);

    test('mañana sí', () {
      expect(policy.canDeclare('2026-07-28', now: lunes), isTrue);
    });

    test('HOY no — esta es la regla que sostiene el mecanismo', () {
      // Si se pudiera declarar el mismo día, la función dejaría de ser
      // planificar el descanso y pasaría a ser deshacer un fallo: a las
      // 22:00, viendo que no llega, cualquiera marcaría "hoy descanso" y
      // la racha sería imposible de perder. Para ese caso ya está la
      // reserva, que es retroactiva a propósito y está topada.
      expect(policy.canDeclare('2026-07-27', now: lunes), isFalse);
    });

    test('ayer tampoco', () {
      expect(policy.canDeclare('2026-07-26', now: lunes), isFalse);
    });

    test('declarar tarde no cambia nada y no lanza', () {
      final sinCambios = policy.declare('2026-07-27', now: lunes);
      expect(sinCambios.movedDates, isEmpty);
      expect(sinCambios, policy);
    });

    test('la hora del día no altera la regla', () {
      // Declarar mañana a las 23:59 de hoy sigue siendo declarar mañana.
      final casiMedianoche = DateTime(2026, 7, 27, 23, 59);
      expect(policy.canDeclare('2026-07-28', now: casiMedianoche), isTrue);
      expect(policy.canDeclare('2026-07-27', now: casiMedianoche), isFalse);
    });
  });

  group('mover el descanso de una semana', () {
    const policy = RestDayPolicy(weeklyRestWeekday: 7); // domingo

    test('los candidatos son los días futuros de esa semana', () {
      // Lunes 27-jul. La semana va del 27 al 2-ago; solo quedan 28..2.
      final candidatos = policy.movableDatesInWeekOf(lunes, now: lunes);
      expect(candidatos, [
        '2026-07-28',
        '2026-07-29',
        '2026-07-30',
        '2026-07-31',
        '2026-08-01',
        '2026-08-02',
      ]);
    });

    test('no ofrece hoy ni los días ya pasados de la semana', () {
      final jueves = DateTime(2026, 7, 30);
      final candidatos = policy.movableDatesInWeekOf(jueves, now: jueves);
      expect(candidatos, ['2026-07-31', '2026-08-01', '2026-08-02']);
      expect(candidatos, isNot(contains('2026-07-30')));
      expect(candidatos, isNot(contains('2026-07-27')));
    });

    test('una semana que ya terminó no admite cambios', () {
      final semanaPasada = DateTime(2026, 7, 20);
      expect(
        policy.movableDatesInWeekOf(semanaPasada, now: lunes),
        isEmpty,
      );
    });

    test('todo candidato ofrecido es aceptado por declare', () {
      // La razón de que esta lista viva en el dominio: si la UI armara
      // la suya, podría ofrecer un día que `declare` rechaza en silencio
      // y el usuario tocaría sin que pasara nada.
      for (final fecha in policy.movableDatesInWeekOf(lunes, now: lunes)) {
        expect(policy.canDeclare(fecha, now: lunes), isTrue);
        expect(policy.declare(fecha, now: lunes).isRestDay(fecha), isTrue,
            reason: '"$fecha" se ofreció pero no se pudo declarar');
      }
    });

    test('isMovedWeekOf distingue la semana tocada de las demás', () {
      final movida = policy.declare('2026-07-30', now: lunes);
      expect(movida.isMovedWeekOf('2026-07-30'), isTrue);
      expect(movida.isMovedWeekOf('2026-08-02'), isTrue,
          reason:
              'el domingo 2-ago es de la MISMA semana ISO que el jueves 30');
      expect(movida.isMovedWeekOf('2026-08-09'), isFalse,
          reason: 'la semana siguiente no está movida');
    });

    test('sin día fijo no hay nada que mover, aunque haya fechas', () {
      expect(RestDayPolicy.disabled.isMovedWeekOf('2026-07-30'), isFalse);
    });
  });

  group('serialización', () {
    test('ida y vuelta preserva la política', () {
      const original = RestDayPolicy(
        weeklyRestWeekday: 3,
        movedDates: {'2026-07-30', '2026-08-06'},
      );
      expect(RestDayPolicy.fromMap(original.toMap()), original);
    });

    test('un weekday corrupto se descarta en vez de propagarse', () {
      // El peor resultado posible sería marcar como descanso un día que
      // el usuario nunca eligió.
      expect(
        RestDayPolicy.fromMap({'weeklyRestWeekday': 0}).weeklyRestWeekday,
        isNull,
      );
      expect(
        RestDayPolicy.fromMap({'weeklyRestWeekday': 8}).weeklyRestWeekday,
        isNull,
      );
    });

    test('fechas no parseables se descartan', () {
      final policy = RestDayPolicy.fromMap({
        'movedDates': ['2026-07-30', 'ayer', 42],
      });
      expect(policy.movedDates, {'2026-07-30'});
    });

    test('un doc vacío da la política desactivada', () {
      expect(RestDayPolicy.fromMap({}), RestDayPolicy.disabled);
    });

    test('pruneBefore no se lleva por delante las fechas vigentes', () {
      const policy = RestDayPolicy(
        movedDates: {'2026-06-01', '2026-07-30'},
      );
      final podada = policy.pruneBefore(DateTime(2026, 7, 1));
      expect(podada.movedDates, {'2026-07-30'});
    });
  });

  // ── La razón de ser de todo esto ────────────────────────────────────
  group('el descanso en el motor de racha', () {
    // Semana del lunes 27-jul: descanso fijo el miércoles 29.
    const policy = RestDayPolicy(weeklyRestWeekday: 3);

    test('un descanso con suelo mantiene la cadena viva', () {
      final history = [
        _real('2026-07-27'),
        _real('2026-07-28'),
        _descansoConSuelo('2026-07-29'), // descanso declarado
        _real('2026-07-30'),
      ];

      final conDescanso = StreakEngine.computeCurrentStreakWithFreezes(
        history,
        asOf: DateTime(2026, 7, 30),
        restPolicy: policy,
      );
      expect(conDescanso.currentStreak, 4);
      expect(conDescanso.currentStreakRestDays, 1);

      // Y sin la política, el mismo historial se parte: prueba de que es
      // la declaración —no la casualidad de los pilares— lo que salva
      // el día.
      final sinPolitica = StreakEngine.computeCurrentStreakWithFreezes(
        history,
        asOf: DateTime(2026, 7, 30),
      );
      expect(sinPolitica.currentStreak, 1);
    });

    test('el descanso NO gasta reserva', () {
      // 9 días reales seguidos (los 7 primeros ganan 1 reserva) y luego
      // el descanso declarado del miércoles 29. Si el descanso consumiera
      // la reserva —que es lo que hacía la app antes de existir
      // RestDayPolicy— `freezesAvailable` caería a 0.
      //
      // Nota sobre las fechas: el 29-jul-2026 es miércoles, que es el
      // `weeklyRestWeekday: 3` de `policy`. Los días 20 a 28 son reales
      // y contiguos, así que la cadena no tiene huecos.
      final history = <StreakEntry>[
        _real('2026-07-20'),
        _real('2026-07-21'),
        _real('2026-07-22'),
        _real('2026-07-23'),
        _real('2026-07-24'),
        _real('2026-07-25'),
        _real('2026-07-26'),
        _real('2026-07-27'),
        _real('2026-07-28'),
        _descansoConSuelo('2026-07-29'),
      ];

      final state = StreakEngine.computeCurrentStreakWithFreezes(
        history,
        asOf: DateTime(2026, 7, 29),
        restPolicy: policy,
      );

      expect(state.currentStreak, 10);
      expect(state.currentStreakRestDays, 1);
      expect(state.freezesAvailable, 1,
          reason: 'la reserva ganada con los 7 días reales sigue intacta: '
              'descansar no la gasta');
    });

    test('descansar NO regala reservas', () {
      // El bug que introduce cualquiera que haga el descanso "neutral"
      // sin la bandera earnedRealDay: el contador se queda en 7, y al día
      // siguiente vuelve a cumplir `% 7 == 0`, sumando otra reserva.
      final history = [
        _real('2026-07-20'),
        _real('2026-07-21'),
        _real('2026-07-22'),
        _real('2026-07-23'),
        _real('2026-07-24'),
        _real('2026-07-25'),
        _real('2026-07-26'),
        _real('2026-07-27'),
        _real('2026-07-28'),
        _descansoConSuelo('2026-07-29'),
      ];

      final state = StreakEngine.computeCurrentStreakWithFreezes(
        history,
        asOf: DateTime(2026, 7, 29),
        restPolicy: policy,
      );
      expect(state.freezesAvailable, 1,
          reason: 'exactamente una, la de los 7 primeros días reales');
    });

    test('el descanso es transparente: 6 reales + descanso + 1 real = 7', () {
      // Sin transparencia, el usuario con descanso semanal fijo NUNCA
      // llegaría a 7 reales seguidos y jamás ganaría una reserva — el más
      // constante se quedaría sin red para el día que de verdad se le
      // olvide. Este test es el que lo garantiza.
      final history = [
        _real('2026-07-23'),
        _real('2026-07-24'),
        _real('2026-07-25'),
        _real('2026-07-26'),
        _real('2026-07-27'),
        _real('2026-07-28'),
        _descansoConSuelo('2026-07-29'), // descanso fijo
        _real('2026-07-30'),
      ];

      final state = StreakEngine.computeCurrentStreakWithFreezes(
        history,
        asOf: DateTime(2026, 7, 30),
        restPolicy: policy,
      );
      expect(state.freezesAvailable, 1,
          reason: '6 reales + descanso + 1 real son los 7 días reales que '
              'ganan la reserva');
    });

    test('descanso declarado SIN suelo no cuenta: es un día fallado', () {
      final history = [
        _real('2026-07-27'),
        _real('2026-07-28'),
        _fallado('2026-07-29'), // declarado descanso, pero sin suelo
        _real('2026-07-30'),
      ];

      final state = StreakEngine.computeCurrentStreakWithFreezes(
        history,
        asOf: DateTime(2026, 7, 30),
        restPolicy: policy,
      );
      // Sin reserva disponible (solo 2 días reales previos), la cadena
      // se corta en el 30.
      expect(state.currentStreak, 1);
      expect(state.currentStreakRestDays, 0);
    });

    test('un descanso que además calificó cuenta como día real', () {
      // Descansaba, pero durmió, bebió, ayunó y comió bien igual. No se
      // le castiga por rendir de más: cuenta como real y suma para ganar
      // reservas.
      final history = [
        _real('2026-07-27'),
        _real('2026-07-28'),
        _real('2026-07-29'), // era su día de descanso
      ];

      final state = StreakEngine.computeCurrentStreakWithFreezes(
        history,
        asOf: DateTime(2026, 7, 29),
        restPolicy: policy,
      );
      expect(state.currentStreak, 3);
      expect(state.currentStreakRestDays, 0,
          reason: 'calificó de verdad, así que no se contabiliza como '
              'descanso');
    });

    test('computeRestDates solo devuelve descansos válidos', () {
      final history = [
        _real('2026-07-27'),
        _descansoConSuelo('2026-07-28'), // NO declarado: no es descanso
        _descansoConSuelo('2026-07-29'), // declarado y con suelo
      ];

      expect(
        StreakEngine.computeRestDates(history, restPolicy: policy),
        {'2026-07-29'},
      );
    });

    test('findBreakingEntry no culpa a un descanso planificado', () {
      final history = [
        _real('2026-07-27'),
        _real('2026-07-28'),
        _descansoConSuelo('2026-07-29'),
      ];
      final rest = StreakEngine.computeRestDates(history, restPolicy: policy);

      expect(
        StreakEngine.findBreakingEntry(history, const {}, restDates: rest),
        isNull,
        reason: 'señalar el descanso como "el día que te costó la racha" '
            'sería acusar al usuario de seguir su propio plan',
      );
    });
  });

  // ── La garantía que hace todo esto defendible ───────────────────────
  group('el descanso no toca la métrica honesta', () {
    const policy = RestDayPolicy(weeklyRestWeekday: 3);

    test('computeCurrentStreak ignora la política por completo', () {
      // Esta es la separación que nos permite ser generosos con la racha
      // sin mentir en el IMR. Duolingo no puede permitírselo porque su
      // racha ES su única métrica; Elena tiene una honesta debajo.
      final history = [
        _real('2026-07-27'),
        _real('2026-07-28'),
        _descansoConSuelo('2026-07-29'),
        _real('2026-07-30'),
      ];

      // La racha visible cuenta 4; la real, la que alimenta la tendencia
      // de adherencia y el IMR longitudinal, cuenta 1.
      expect(
        StreakEngine.computeCurrentStreakWithFreezes(
          history,
          asOf: DateTime(2026, 7, 30),
          restPolicy: policy,
        ).currentStreak,
        4,
      );
      expect(
        StreakEngine.computeCurrentStreak(
          history,
          asOf: DateTime(2026, 7, 30),
        ),
        1,
      );
    });
  });
}
