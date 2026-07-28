// SPEC-257 §3.1 / RF-257-VERIFICACION: tests de días de ayuno programados
// para el nivel Novato (12:12/14:10).

import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/features/streak/domain/fasting_schedule.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('FastingSchedule.isNovatoTier', () {
    test('12:12 y 14:10 son Novato', () {
      expect(FastingSchedule.isNovatoTier('12:12'), isTrue);
      expect(FastingSchedule.isNovatoTier('14:10'), isTrue);
    });

    test('16:8 en adelante NO es Novato', () {
      expect(FastingSchedule.isNovatoTier('16:8'), isFalse);
      expect(FastingSchedule.isNovatoTier('18:6'), isFalse);
      expect(FastingSchedule.isNovatoTier('20:4'), isFalse);
      expect(FastingSchedule.isNovatoTier('22:2'), isFalse);
      expect(FastingSchedule.isNovatoTier('OMAD'), isFalse);
      expect(FastingSchedule.isNovatoTier('Ninguno'), isFalse);
    });
  });

  group('FastingSchedule.effectiveDaysPerWeek', () {
    test('sin goal activo → default (3)', () {
      expect(FastingSchedule.effectiveDaysPerWeek(const {}), 3);
    });

    test('goal inactivo → default (3), se ignora el valor', () {
      final goals = {
        GoalType.fastingDaysPerWeek: UserGoal(
          type: GoalType.fastingDaysPerWeek,
          targetValue: 4,
          startValue: 0,
          isActive: false,
          createdAt: DateTime(2026, 1, 1),
        ),
      };
      expect(FastingSchedule.effectiveDaysPerWeek(goals), 3);
    });

    test('goal activo dentro de rango [2,4] → se respeta tal cual', () {
      final goals = {
        GoalType.fastingDaysPerWeek: UserGoal(
          type: GoalType.fastingDaysPerWeek,
          targetValue: 2,
          startValue: 0,
          createdAt: DateTime(2026, 1, 1),
        ),
      };
      expect(FastingSchedule.effectiveDaysPerWeek(goals), 2);
    });

    // RF-257-VERIFICACION: antes un valor fuera de rango se IGNORABA del
    // todo y caía al default (3) — el usuario veía "5" persistido en
    // Perfil pero el ring se comportaba como si hubiera puesto 3. Ahora
    // se recorta (clamp) al borde más cercano, respetando la intención.
    test('goal activo por ENCIMA del rango (5) → se recorta a 4, no se ignora',
        () {
      final goals = {
        GoalType.fastingDaysPerWeek: UserGoal(
          type: GoalType.fastingDaysPerWeek,
          targetValue: 5,
          startValue: 0,
          createdAt: DateTime(2026, 1, 1),
        ),
      };
      expect(FastingSchedule.effectiveDaysPerWeek(goals), 4);
    });

    test('goal activo por DEBAJO del rango (1) → se recorta a 2', () {
      final goals = {
        GoalType.fastingDaysPerWeek: UserGoal(
          type: GoalType.fastingDaysPerWeek,
          targetValue: 1,
          startValue: 0,
          createdAt: DateTime(2026, 1, 1),
        ),
      };
      expect(FastingSchedule.effectiveDaysPerWeek(goals), 2);
    });
  });

  group('FastingSchedule.defaultWeekdays', () {
    test('N=2 → martes/viernes (ejemplo primario de Suárez)', () {
      expect(
        FastingSchedule.defaultWeekdays(2),
        [DateTime.tuesday, DateTime.friday],
      );
    });

    test('N=3 → lunes/miércoles/viernes, no consecutivos', () {
      expect(
        FastingSchedule.defaultWeekdays(3),
        [DateTime.monday, DateTime.wednesday, DateTime.friday],
      );
    });

    test('N=4 → lunes/martes/jueves/viernes', () {
      expect(
        FastingSchedule.defaultWeekdays(4),
        [DateTime.monday, DateTime.tuesday, DateTime.thursday, DateTime.friday],
      );
    });
  });

  group('FastingSchedule.isRestDay', () {
    test(
        'protocolo no-Novato → nunca es día de descanso, aunque no esté programado',
        () {
      // Domingo 2026-01-04, día no programado — pero 16:8 es ventana diaria.
      final sunday = DateTime(2026, 1, 4);
      expect(
        FastingSchedule.isRestDay(
          date: sunday,
          protocol: '16:8',
          goals: const {},
        ),
        isFalse,
      );
    });

    test('Novato, default 3 días (L/M/V) → martes es descanso', () {
      final tuesday = DateTime(2026, 1, 6); // 2026-01-06 es martes
      expect(tuesday.weekday, DateTime.tuesday);
      expect(
        FastingSchedule.isRestDay(
          date: tuesday,
          protocol: '12:12',
          goals: const {},
        ),
        isTrue,
      );
    });

    test('Novato, default 3 días (L/M/V) → lunes NO es descanso', () {
      final monday = DateTime(2026, 1, 5);
      expect(monday.weekday, DateTime.monday);
      expect(
        FastingSchedule.isRestDay(
          date: monday,
          protocol: '14:10',
          goals: const {},
        ),
        isFalse,
      );
    });
  });
}
