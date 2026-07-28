// 18-jul ("Día Metabólico: dos sistemas de día en paralelo" — hallazgo
// central de la auditoría de persistencia/coherencia): tests del parámetro
// `asOf` en `computeCurrentStreak`/`computeCurrentStreakWithFreezes`.
//
// Contexto del bug que este parámetro corrige: un StreakEntry.date ahora se
// ancla al día en que el CICLO METABÓLICO abrió (`StreakNotifier._todayKey`,
// ver comentario allí), no al reloj. Un ayuno extendido que cruza medianoche
// (o varias) sigue escribiendo a la MISMA entrada mientras el ciclo esté
// abierto. Pero `computeCurrentStreak`/`computeCurrentStreakWithFreezes`
// tienen su propio chequeo de "¿la entrada más reciente es de hoy o de
// ayer?" para decidir si la racha sigue viva — si ese chequeo sigue usando
// el reloj real en vez del mismo ancla que usó el notifier para escribir la
// entrada, un ciclo abierto que empezó hace >24h de reloj (pero sigue
// siendo "hoy" en términos de día metabólico) se vería como "racha vieja"
// y se descartaría por error.
//
// `asOf` resuelve esto: el caller (StreakNotifier) pasa el mismo
// `cycle.startedAt` que usó para escribir la entrada. Estos tests simulan
// la carrera exacta comparando el resultado CON `asOf` correcto (el ancla
// del ciclo) contra el resultado que se obtendría si el motor siguiera
// comparando contra el reloj real — reproduciendo determinísticamente el
// bug que el parámetro corrige, sin depender de `DateTime.now()` real.
//
// Funciones puras: no requieren mocks ni reloj real.

import 'package:elena_app/src/features/streak/domain/streak_engine.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:flutter_test/flutter_test.dart';

StreakEntry _qualifying(String date) => StreakEntry(
      date: date,
      fastingCompleted: true,
      sleepCompleted: true,
      hydrationCompleted: true,
      exerciseLogged: false,
      nutritionLogged: false,
      imrScore: 70,
    );

void main() {
  group('computeCurrentStreak — asOf ancla al día metabólico', () {
    test(
        'ciclo abierto que empezó lunes sigue contando el martes '
        '(ayuno extendido cruzando medianoche, dentro del límite de 28h)', () {
      // Racha de 3 días metabólicos: sáb, dom, lun (lun = el ciclo que
      // sigue abierto — el usuario inició su ayuno el lunes a las 23:50 y
      // sigue ayunando el martes de madrugada, sin haber cerrado ventana).
      final history = [
        _qualifying('2026-07-11'), // sábado
        _qualifying('2026-07-12'), // domingo
        _qualifying('2026-07-13'), // lunes — el ciclo AÚN abierto
      ];

      // El ciclo abrió lunes 23:50. "Ahora" real son las 02:00 del martes
      // (~2h10 después) — el mismo ancla que StreakNotifier._todayAnchor
      // usaría: cycle.startedAt, NO DateTime.now().
      final cycleStartedAt = DateTime(2026, 7, 13, 23, 50);

      final streak = StreakEngine.computeCurrentStreak(
        history,
        asOf: cycleStartedAt,
      );

      // Los 3 días cuentan — el ciclo del lunes sigue siendo "hoy" para
      // efectos de racha mientras esté abierto.
      expect(streak, 3);
    });

    test(
        'el MISMO historial se rompería si el motor comparara contra el '
        'reloj real en vez del ancla del ciclo (reproduce el bug de fondo)',
        () {
      final history = [
        _qualifying('2026-07-11'),
        _qualifying('2026-07-12'),
        _qualifying('2026-07-13'), // lunes — el ciclo AÚN abierto
      ];

      // Simulamos qué pasaría si, en vez de pasar el ancla del ciclo, se
      // pasara el reloj real en el instante en que corre `_evaluateToday()`
      // durante la madrugada del martes — exactamente el comportamiento
      // ANTERIOR a este fix (asOf ausente → DateTime.now() interno).
      final realWallClockNow = DateTime(2026, 7, 15, 2, 0); // miércoles!
      // (Ayuno de protocolo largo/OMAD que arrancó el lunes 23:50 y sigue
      // abierto ~26h después, todavía dentro del límite absoluto de ~28h
      // de METABOLIC_DAY_CONSTITUTION.md §3 — un caso real, no de laboratorio.)

      final streakWithWallClock = StreakEngine.computeCurrentStreak(
        history,
        asOf: realWallClockNow,
      );

      // Con el reloj real, "hoy"=miércoles y "ayer"=martes — ninguno
      // coincide con la entrada más reciente (lunes 13) → la racha se
      // descarta por completo, aunque el ciclo del lunes sigue vivo y
      // acumulando. Este es el bug que `_todayAnchor` (cycle-aware)
      // evita en producción al pasar SIEMPRE el ancla del ciclo, nunca
      // el reloj real, mientras haya un ciclo abierto.
      expect(streakWithWallClock, 0);
    });

    test(
        'sin asOf (default), preserva el comportamiento previo basado en '
        'DateTime.now() real — no rompe a computeAdherenceTrend', () {
      final today = DateTime.now();
      final todayKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final history = [_qualifying(todayKey)];

      // Llamada sin `asOf` — mismo call site que `computeAdherenceTrend`
      // sigue usando internamente.
      final streak = StreakEngine.computeCurrentStreak(history);

      expect(streak, 1);
    });
  });

  group('computeCurrentStreakWithFreezes — asOf ancla al día metabólico', () {
    test(
        'ciclo abierto que empezó ayer (por el ancla del ciclo) sigue '
        'protegiendo la racha visible al usuario', () {
      final history = [
        _qualifying('2026-07-11'),
        _qualifying('2026-07-12'),
        _qualifying('2026-07-13'),
      ];
      final cycleStartedAt = DateTime(2026, 7, 13, 23, 50);

      final result = StreakEngine.computeCurrentStreakWithFreezes(
        history,
        asOf: cycleStartedAt,
      );

      expect(result.currentStreak, 3);
    });

    test('sin asOf, preserva el comportamiento previo', () {
      final today = DateTime.now();
      final todayKey =
          '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final history = [_qualifying(todayKey)];

      final result = StreakEngine.computeCurrentStreakWithFreezes(history);

      expect(result.currentStreak, 1);
    });
  });
}
