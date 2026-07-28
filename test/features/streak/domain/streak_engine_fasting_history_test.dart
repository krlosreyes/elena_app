// 17-jul: tests de `StreakEngine.bestCompletedFastingHoursToday` —
// Carlos: "necesitamos corregir y tener un sistema coherente". Fuente
// de verdad de "¿el ayuno de hoy calificó?" derivada del historial
// persistido de ayunos cerrados, en vez de las banderas transitorias
// de FastingNotifier (completedToday/closedProgressToday) que
// causaron 3 bugs de racha esta sesión.
//
// Funciones puras: no requieren mocks ni reloj real (se pasa `now`
// explícito).

import 'package:elena_app/src/features/streak/domain/streak_engine.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

FastingInterval _interval({
  String id = 'x',
  required DateTime startTime,
  DateTime? endTime,
  bool isFasting = true,
}) {
  return FastingInterval(
    id: id,
    userId: 'user-1',
    startTime: startTime,
    endTime: endTime,
    isFasting: isFasting,
  );
}

void main() {
  group('bestCompletedFastingHoursToday', () {
    test('lista vacía → 0.0', () {
      final result = StreakEngine.bestCompletedFastingHoursToday(
        recentCompleted: const [],
        now: DateTime(2026, 7, 17, 15, 0),
      );
      expect(result, 0.0);
    });

    test('un solo ayuno cerrado hoy → su duración en horas', () {
      final intervals = [
        _interval(
          startTime: DateTime(2026, 7, 17, 6, 0),
          endTime: DateTime(2026, 7, 17, 14, 0), // 8h
        ),
      ];
      final result = StreakEngine.bestCompletedFastingHoursToday(
        recentCompleted: intervals,
        now: DateTime(2026, 7, 17, 15, 0),
      );
      expect(result, 8.0);
    });

    test(
        'CASO REAL: 2 ciclos el mismo día — el primero (ya completo) sigue contando aunque el segundo apenas arrancó',
        () {
      // El escenario exacto del bug: usuario completó un ayuno largo, lo
      // cerró, y arrancó uno nuevo (todavía en curso, por eso NO aparece
      // en `recentCompleted` — solo intervalos CERRADOS). El historial
      // persistido sigue teniendo el primero.
      //
      // 27-jul (auditoría): este test llevaba en rojo desde que se
      // escribió, y el motivo era una CONTRADICCIÓN dentro de este mismo
      // archivo. Su fixture original (inicio 16-jul 20:00 → cierre 17-jul
      // 12:00) atribuía el ayuno al día del CIERRE, mientras que el test
      // "atribuye por startTime, no por endTime" —más abajo, con su
      // explicación— afirma exactamente lo contrario para un fixture de la
      // misma forma. Ambos no pueden pasar a la vez.
      //
      // Manda la Constitución del Día Metabólico §1: el ciclo lo ABRE el
      // tap "Iniciar ayuno" (`startedAt`), así que un ayuno pertenece al
      // día en que EMPEZÓ. La implementación ya seguía esa regla; lo que
      // estaba mal era el fixture, no el motor.
      //
      // Se corrige el fixture a dos ciclos que empiezan y cierran el mismo
      // día —que es literalmente lo que dice el título del test— con lo
      // que se conserva intacta la regresión que vino a proteger: que un
      // ayuno CERRADO se siga leyendo del historial aunque haya otro ciclo
      // activo encima.
      final intervals = [
        _interval(
          id: 'primero',
          startTime: DateTime(2026, 7, 17, 2, 0),
          endTime: DateTime(2026, 7, 17, 18, 0), // 16h, cerrado hoy
        ),
      ];
      final result = StreakEngine.bestCompletedFastingHoursToday(
        recentCompleted: intervals,
        now: DateTime(2026, 7, 17, 20, 0),
      );
      expect(result, 16.0,
          reason: 'el ciclo ya cerrado sigue siendo la fuente de verdad, '
              'sin depender de que el ciclo activo nuevo lo "recuerde"');
    });

    test('toma el MÁXIMO entre varios ciclos cerrados hoy, no el último', () {
      final intervals = [
        // Orden desc por startTime, como lo entrega watchRecentCompleted.
        _interval(
          id: 'segundo',
          startTime: DateTime(2026, 7, 17, 14, 0),
          endTime: DateTime(2026, 7, 17, 16, 0), // 2h, corto
        ),
        _interval(
          id: 'primero',
          startTime: DateTime(2026, 7, 17, 2, 0),
          endTime: DateTime(2026, 7, 17, 12, 0), // 10h, el bueno
        ),
      ];
      final result = StreakEngine.bestCompletedFastingHoursToday(
        recentCompleted: intervals,
        now: DateTime(2026, 7, 17, 18, 0),
      );
      expect(result, 10.0);
    });

    test('ignora intervalos de OTRO día', () {
      final intervals = [
        _interval(
          startTime: DateTime(2026, 7, 16, 6, 0),
          endTime: DateTime(2026, 7, 16, 22, 0), // ayer, 16h
        ),
      ];
      final result = StreakEngine.bestCompletedFastingHoursToday(
        recentCompleted: intervals,
        now: DateTime(2026, 7, 17, 15, 0),
      );
      expect(result, 0.0);
    });

    test('ignora ventanas de alimentación (isFasting:false)', () {
      final intervals = [
        _interval(
          startTime: DateTime(2026, 7, 17, 6, 0),
          endTime: DateTime(2026, 7, 17, 20, 0),
          isFasting: false,
        ),
      ];
      final result = StreakEngine.bestCompletedFastingHoursToday(
        recentCompleted: intervals,
        now: DateTime(2026, 7, 17, 21, 0),
      );
      expect(result, 0.0);
    });

    test(
        'ignora intervalos sin cerrar (endTime null) — el activo se evalúa aparte',
        () {
      final intervals = [
        _interval(
          startTime: DateTime(2026, 7, 17, 6, 0),
          endTime: null,
        ),
      ];
      final result = StreakEngine.bestCompletedFastingHoursToday(
        recentCompleted: intervals,
        now: DateTime(2026, 7, 17, 15, 0),
      );
      expect(result, 0.0);
    });

    test('atribuye por startTime, no por endTime (ayuno que cruza medianoche)',
        () {
      // Empezó ayer, cerró hoy de madrugada — para la pregunta "¿hubo
      // un ayuno que arrancó HOY?" esto NO cuenta (arrancó ayer). El
      // día de ayer sí lo vería si se consultara con now=ayer.
      final intervals = [
        _interval(
          startTime: DateTime(2026, 7, 16, 22, 0),
          endTime: DateTime(2026, 7, 17, 6, 0),
        ),
      ];
      final resultToday = StreakEngine.bestCompletedFastingHoursToday(
        recentCompleted: intervals,
        now: DateTime(2026, 7, 17, 10, 0),
      );
      expect(resultToday, 0.0);

      final resultYesterday = StreakEngine.bestCompletedFastingHoursToday(
        recentCompleted: intervals,
        now: DateTime(2026, 7, 16, 23, 0),
      );
      expect(resultYesterday, 8.0);
    });
  });
}
