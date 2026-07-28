// 17-jul: tests de `StreakEngine.reconcileTodayWithLocal` — Carlos:
// "llevaba 2, cerré el día, me devolvió a uno". Ver comentario extenso
// en la función. Reproduce la carrera exacta: un snapshot de Firestore
// de HOY llega desactualizado (fastingCompleted:false) justo cuando ya
// habíamos calculado fastingCompleted:true en memoria, y sin
// reconciliar eso descalifica el día y tira la racha hacia atrás.
//
// Funciones puras: no requieren mocks ni reloj.

import 'package:elena_app/src/features/streak/domain/streak_engine.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:flutter_test/flutter_test.dart';

StreakEntry _entry({
  required String date,
  bool fastingCompleted = false,
  bool sleepCompleted = false,
  bool hydrationCompleted = false,
  bool exerciseLogged = false,
  bool nutritionLogged = false,
  double? fastingMagnitude,
}) {
  return StreakEntry(
    date: date,
    fastingCompleted: fastingCompleted,
    sleepCompleted: sleepCompleted,
    hydrationCompleted: hydrationCompleted,
    exerciseLogged: exerciseLogged,
    nutritionLogged: nutritionLogged,
    imrScore: 0,
    fastingMagnitude: fastingMagnitude,
  );
}

void main() {
  const today = '2026-07-17';
  const yesterday = '2026-07-16';
  const dayBefore = '2026-07-15';

  group('reconcileTodayWithLocal', () {
    test('local sin fastingCompleted → history se devuelve tal cual', () {
      final local = _entry(date: today, sleepCompleted: true);
      final history = [_entry(date: today, sleepCompleted: true)];

      final result = StreakEngine.reconcileTodayWithLocal(
        history: history,
        localToday: local,
        todayKey: today,
      );

      expect(identical(result, history), isTrue);
    });

    test('local es de otro día (stale) → history se devuelve tal cual', () {
      final local = _entry(date: yesterday, fastingCompleted: true);
      final history = [_entry(date: today, fastingCompleted: false)];

      final result = StreakEngine.reconcileTodayWithLocal(
        history: history,
        localToday: local,
        todayKey: today,
      );

      expect(identical(result, history), isTrue);
    });

    test(
        'localToday null → history se devuelve tal cual (primer rebuild de la sesión)',
        () {
      final history = [_entry(date: today, fastingCompleted: false)];

      final result = StreakEngine.reconcileTodayWithLocal(
        history: history,
        localToday: null,
        todayKey: today,
      );

      expect(identical(result, history), isTrue);
    });

    test(
        'snapshot ya coincide (fastingCompleted:true) → history se devuelve tal cual',
        () {
      final local = _entry(date: today, fastingCompleted: true);
      final history = [_entry(date: today, fastingCompleted: true)];

      final result = StreakEngine.reconcileTodayWithLocal(
        history: history,
        localToday: local,
        todayKey: today,
      );

      expect(identical(result, history), isTrue);
    });

    test(
        'CASO REAL: snapshot desactualizado (fastingCompleted:false) se corrige a true',
        () {
      // El ack del primer ayuno llegó desordenado — el snapshot todavía
      // trae fastingCompleted:false aunque en memoria ya sabíamos que
      // el usuario completó el ayuno hoy más temprano.
      final local = _entry(
        date: today,
        fastingCompleted: true,
        fastingMagnitude: 1.1,
        sleepCompleted: true,
      );
      final staleFromFirestore = _entry(
        date: today,
        fastingCompleted: false,
        sleepCompleted: true,
      );
      final history = [staleFromFirestore, _entry(date: yesterday)];

      final result = StreakEngine.reconcileTodayWithLocal(
        history: history,
        localToday: local,
        todayKey: today,
      );

      final patchedToday = result.firstWhere((e) => e.date == today);
      expect(patchedToday.fastingCompleted, isTrue);
      expect(patchedToday.fastingMagnitude, 1.1);
      // El resto de los pilares de la foto de Firestore se preserva —
      // no reconciliamos sleep/hidratación/ejercicio/nutrición.
      expect(patchedToday.sleepCompleted, isTrue);
    });

    test('HOY ausente del snapshot (doc recién creado) → se inyecta localToday',
        () {
      final local = _entry(date: today, fastingCompleted: true);
      final history = [_entry(date: yesterday, fastingCompleted: true)];

      final result = StreakEngine.reconcileTodayWithLocal(
        history: history,
        localToday: local,
        todayKey: today,
      );

      expect(result.any((e) => e.date == today && e.fastingCompleted), isTrue);
      expect(result.length, 2);
    });

    test(
        'no toca pilares "vivos": una eliminación real de hidratación no se enmascara',
        () {
      // El local tenía hydrationCompleted:true de un momento anterior,
      // pero el usuario borró vasos de agua y el snapshot real ahora
      // trae false — esto NO debe revertirse (a diferencia de fasting,
      // hidratación es deliberadamente "viva", SPEC-242).
      final local = _entry(
        date: today,
        fastingCompleted: true,
        hydrationCompleted: true,
      );
      final afterDeletion = _entry(
        date: today,
        fastingCompleted: false, // aún no llegó el ack de fasting tampoco
        hydrationCompleted: false, // eliminación real y reciente
      );
      final history = [afterDeletion];

      final result = StreakEngine.reconcileTodayWithLocal(
        history: history,
        localToday: local,
        todayKey: today,
      );

      final patched = result.firstWhere((e) => e.date == today);
      expect(patched.fastingCompleted, isTrue,
          reason: 'fasting es monotónico dentro del día — se corrige');
      expect(patched.hydrationCompleted, isFalse,
          reason:
              'hidratación es "viva" — la eliminación real del usuario se respeta');
    });
  });

  group('CASO REAL end-to-end: racha 2 → 1 al reabrir un segundo ayuno', () {
    test(
        'sin reconciliar: el snapshot desactualizado de HOY tira la racha de 2 a 1',
        () {
      // Racha esperada: hoy + ayer, ambos calificando (>=3 pilares con
      // ancla). El día-antes-de-ayer NO califica (para aislar el caso).
      final rawHistoryStale = [
        _entry(
          date: today,
          fastingCompleted: false, // snapshot desactualizado
          sleepCompleted: true,
          hydrationCompleted: true,
        ),
        _entry(
          date: yesterday,
          fastingCompleted: true,
          sleepCompleted: true,
          hydrationCompleted: true,
        ),
        _entry(date: dayBefore), // no califica, corta la cadena de todos modos
      ];

      // SIN reconciliar (comportamiento previo al fix): hoy solo tiene
      // sleep+hydration = 2 pilares → no califica → la racha cuenta
      // solo ayer = 1. Esto reproduce el bug reportado.
      //
      // 27-jul (auditoría): se pasa `asOf` explícito. El test se escribió
      // el 17-jul con fechas fijas y sin `asOf` —parámetro que el motor
      // todavía no tenía—, así que `computeCurrentStreakWithFreezes` caía
      // en `DateTime.now()`. Desde el 18-jul '2026-07-17' dejó de ser hoy
      // y la cadena se cortaba en el primer día ausente: el test devolvía
      // 0 y llevaba diez días en rojo sin que fuera un bug del motor.
      final freezeStateBuggy = StreakEngine.computeCurrentStreakWithFreezes(
        rawHistoryStale,
        asOf: DateTime.parse('$today 12:00:00'),
      );
      expect(freezeStateBuggy.currentStreak, 1);
    });

    test(
        'CON reconciliar: la racha se mantiene en 2 (o sube a 3 si hoy ya calificaba)',
        () {
      final local = _entry(
        date: today,
        fastingCompleted: true,
        fastingMagnitude: 1.05,
        sleepCompleted: true,
        hydrationCompleted: true,
      );
      final rawHistoryStale = [
        _entry(
          date: today,
          fastingCompleted: false, // mismo snapshot desactualizado
          sleepCompleted: true,
          hydrationCompleted: true,
        ),
        _entry(
          date: yesterday,
          fastingCompleted: true,
          sleepCompleted: true,
          hydrationCompleted: true,
        ),
        _entry(date: dayBefore),
      ];

      final reconciled = StreakEngine.reconcileTodayWithLocal(
        history: rawHistoryStale,
        localToday: local,
        todayKey: today,
      );
      // 27-jul: mismo motivo que el test anterior — `asOf` explícito para
      // que el fixture no dependa del día en que se corre la suite.
      final freezeStateFixed = StreakEngine.computeCurrentStreakWithFreezes(
        reconciled,
        asOf: DateTime.parse('$today 12:00:00'),
      );

      expect(freezeStateFixed.currentStreak, 2,
          reason:
              'hoy (3 pilares con ancla, corregido) + ayer — el bug reportado por Carlos ya no ocurre');
    });
  });
}
