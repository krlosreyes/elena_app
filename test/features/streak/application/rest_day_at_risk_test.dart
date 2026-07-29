// El día de descanso no se avisa como riesgo (28-jul-2026).
//
// QUÉ IMPIDE ESTE TEST
// --------------------
// `StreakAtRiskBanner` aparece de tarde/noche cuando el día todavía no
// calificó y hay racha en juego. Sin el chequeo de descanso, el usuario
// que declaró el sábado para descansar recibiría el sábado por la noche
// un aviso de que su racha está en peligro — meterle prisa justo el día
// que él mismo apartó para no tener prisa.
//
// Es la versión más nítida del problema que este trabajo viene a
// arreglar: tratar el plan del usuario como un fallo. Por eso tiene test
// propio y no queda solo como un `if` en el provider.
//
// El provider real depende de `streakProvider` (que arrastra Firestore y
// los 5 pilares) y de `DateTime.now()`, así que la regla se extrajo a
// `shouldWarnStreakAtRisk`, que es pura. Estos tests ejecutan LITERALMENTE
// el mismo código que la app: si alguien cambia la regla, fallan.
//
// La alternativa —reimplementar las guardas aquí— habría dejado un test
// que fotografía el comportamiento en vez de exigirlo, y que seguiría en
// verde con el provider roto. Ya nos pasó cinco veces en este repo.

import 'package:elena_app/src/features/streak/application/streak_notifier.dart';
import 'package:elena_app/src/features/streak/domain/rest_day_policy.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:flutter_test/flutter_test.dart';

/// Día sin nada registrado: no califica.
StreakEntry _vacio(String date) => StreakEntry(
      date: date,
      fastingCompleted: false,
      sleepCompleted: false,
      hydrationCompleted: false,
      exerciseLogged: false,
      nutritionLogged: false,
      imrScore: 0,
    );

/// Día completo: califica.
StreakEntry _completo(String date) => StreakEntry(
      date: date,
      fastingCompleted: true,
      sleepCompleted: true,
      hydrationCompleted: true,
      exerciseLogged: true,
      nutritionLogged: true,
      imrScore: 80,
    );

bool _seAvisa(StreakState state, {required int hora}) =>
    shouldWarnStreakAtRisk(state, hour: hora);

void main() {
  // 2026-08-01 es sábado (ISO 6).
  const sabado = '2026-08-01';
  const viernes = '2026-07-31';
  const descansaSabados = RestDayPolicy(weeklyRestWeekday: 6);

  group('el aviso de riesgo respeta el día de descanso', () {
    test('un viernes flojo por la noche SÍ avisa', () {
      final state = StreakState(
        currentStreak: 5,
        todayEntry: _vacio(viernes),
        restPolicy: descansaSabados,
      );
      expect(_seAvisa(state, hora: 20), isTrue);
    });

    test('el sábado declarado NO avisa, aunque sea de noche y esté vacío', () {
      final state = StreakState(
        currentStreak: 5,
        todayEntry: _vacio(sabado),
        restPolicy: descansaSabados,
      );
      expect(_seAvisa(state, hora: 23), isFalse,
          reason: 'meterle prisa el día que él mismo apartó para descansar '
              'es tratar su plan como un fallo');
    });

    test('sin política configurada, el sábado avisa como cualquier día', () {
      final state = StreakState(
        currentStreak: 5,
        todayEntry: _vacio(sabado),
      );
      expect(_seAvisa(state, hora: 20), isTrue,
          reason: 'el descanso es opt-in: sin configurar, el comportamiento '
              'debe ser idéntico al de antes de que existiera');
    });

    test('antes de las 18:00 no avisa, con o sin descanso', () {
      final state = StreakState(
        currentStreak: 5,
        todayEntry: _vacio(viernes),
        restPolicy: descansaSabados,
      );
      expect(_seAvisa(state, hora: 14), isFalse);
    });

    test('con reserva disponible tampoco avisa (regla previa, intacta)', () {
      final state = StreakState(
        currentStreak: 5,
        freezesAvailable: 1,
        todayEntry: _vacio(viernes),
        restPolicy: descansaSabados,
      );
      expect(_seAvisa(state, hora: 22), isFalse);
    });

    test('sin racha activa no hay nada que avisar', () {
      final state = StreakState(
        currentStreak: 0,
        todayEntry: _vacio(viernes),
        restPolicy: descansaSabados,
      );
      expect(_seAvisa(state, hora: 22), isFalse);
    });

    test('si el día ya calificó no avisa, sea descanso o no', () {
      final state = StreakState(
        currentStreak: 5,
        todayEntry: _completo(sabado),
        restPolicy: descansaSabados,
      );
      expect(_seAvisa(state, hora: 22), isFalse);
    });
  });

  group('StreakState expone el descanso sin que la UI calcule semanas', () {
    test('isRestDayToday responde por la política vigente', () {
      const state = StreakState(restPolicy: descansaSabados);
      expect(state.isRestDayToday(sabado), isTrue);
      expect(state.isRestDayToday(viernes), isFalse);
    });

    test('el estado por defecto no tiene descanso ni lo inventa', () {
      const state = StreakState();
      expect(state.restPolicy, RestDayPolicy.disabled);
      expect(state.restPolicy.isEnabled, isFalse);
      expect(state.streakRestDays, 0);
      expect(state.nextRestDate, isNull);
      expect(state.isRestDayToday(sabado), isFalse);
    });

    test('copyWith puede limpiar nextRestDate al desactivar el descanso', () {
      // Sin `clearNextRestDate`, el patrón `x ?? this.x` haría imposible
      // volver a null: el usuario quitaría su día de descanso y la UI
      // seguiría anunciando el próximo.
      const conDescanso = StreakState(nextRestDate: sabado);
      final sinDescanso = conDescanso.copyWith(clearNextRestDate: true);
      expect(sinDescanso.nextRestDate, isNull);
    });
  });
}
