// SPEC-95: tests puros del value object `EatingWindowState`.

import 'package:elena_app/src/features/dashboard/domain/eating_window_state.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter_test/flutter_test.dart';

UserModel _user({
  String protocol = '16:8',
  DateTime? firstMealGoal,
}) {
  return UserModel(
    id: 'u',
    age: 30,
    gender: 'M',
    weight: 75,
    height: 175,
    fastingProtocol: protocol,
    profile: CircadianProfile(
      wakeUpTime: DateTime(2026, 5, 14, 6, 0),
      sleepTime: DateTime(2026, 5, 14, 22, 0),
      firstMealGoal: firstMealGoal,
    ),
  );
}

FastingInterval _interval({
  required DateTime startTime,
  required bool isFasting,
}) {
  return FastingInterval(
    id: 'i',
    userId: 'u',
    startTime: startTime,
    isFasting: isFasting,
  );
}

void main() {
  group('EatingWindowState — duración por protocolo', () {
    test('protocolo 18:6 → ventana de 6h', () {
      final now = DateTime(2026, 5, 14, 15, 0);
      final state = EatingWindowState.compute(
        lastInterval: _interval(
          startTime: DateTime(2026, 5, 14, 13, 0),
          isFasting: false,
        ),
        user: _user(protocol: '18:6'),
        now: now,
      );
      expect(state.windowDurationHours, 6);
      expect(state.windowStart, DateTime(2026, 5, 14, 13, 0));
      expect(state.windowEnd, DateTime(2026, 5, 14, 19, 0));
    });

    test('protocolo 20:4 → ventana de 4h', () {
      final now = DateTime(2026, 5, 14, 20, 0);
      final state = EatingWindowState.compute(
        lastInterval: _interval(
          startTime: DateTime(2026, 5, 14, 17, 0),
          isFasting: false,
        ),
        user: _user(protocol: '20:4'),
        now: now,
      );
      expect(state.windowDurationHours, 4);
      expect(state.windowEnd, DateTime(2026, 5, 14, 21, 0));
    });

    test('protocolo 16:8 → ventana de 8h', () {
      final state = EatingWindowState.compute(
        lastInterval: _interval(
          startTime: DateTime(2026, 5, 14, 12, 0),
          isFasting: false,
        ),
        user: _user(protocol: '16:8'),
        now: DateTime(2026, 5, 14, 14, 0),
      );
      expect(state.windowDurationHours, 8);
    });

    test('protocolo "Ninguno" → ventana de 14h (default sensible)', () {
      final state = EatingWindowState.compute(
        lastInterval: null,
        user: _user(
          protocol: 'Ninguno',
          firstMealGoal: DateTime(2026, 5, 14, 8, 0),
        ),
        now: DateTime(2026, 5, 14, 12, 0),
      );
      expect(state.windowDurationHours, 14);
      expect(state.windowEnd, DateTime(2026, 5, 14, 22, 0));
    });
  });

  group('EatingWindowState — status y progreso', () {
    test('now dentro de ventana → withinWindow + progreso correcto', () {
      // protocolo 18:6, abrió 13:00, cierra 19:00. now=15:00.
      // 2h transcurridas de 6h = 33.3%
      final state = EatingWindowState.compute(
        lastInterval: _interval(
          startTime: DateTime(2026, 5, 14, 13, 0),
          isFasting: false,
        ),
        user: _user(protocol: '18:6'),
        now: DateTime(2026, 5, 14, 15, 0),
      );
      expect(state.status, EatingWindowStatus.withinWindow);
      expect(state.progressPercent, closeTo(2 / 6, 0.001));
    });

    test('now antes de ventana → beforeWindow + progreso 0', () {
      // Ventana abre a las 13:00, ahora son las 11:00.
      // En este caso, lastInterval marca 13:00 pero now es anterior →
      // el state lo trata como "antes de la ventana".
      final state = EatingWindowState.compute(
        lastInterval: _interval(
          startTime: DateTime(2026, 5, 14, 13, 0),
          isFasting: false,
        ),
        user: _user(protocol: '18:6'),
        now: DateTime(2026, 5, 14, 11, 0),
      );
      expect(state.status, EatingWindowStatus.beforeWindow);
      expect(state.progressPercent, 0.0);
    });

    test('now después de ventana → afterWindow + progreso clamp 1', () {
      // 18:6 con windowEnd 19:00, now=21:00.
      final state = EatingWindowState.compute(
        lastInterval: _interval(
          startTime: DateTime(2026, 5, 14, 13, 0),
          isFasting: false,
        ),
        user: _user(protocol: '18:6'),
        now: DateTime(2026, 5, 14, 21, 0),
      );
      expect(state.status, EatingWindowStatus.afterWindow);
      expect(state.progressPercent, 1.0);
    });
  });

  group('EatingWindowState — fallbacks', () {
    test('sin lastInterval, con firstMealGoal → windowStart = goal de hoy',
        () {
      final state = EatingWindowState.compute(
        lastInterval: null,
        user: _user(
          protocol: '16:8',
          firstMealGoal: DateTime(2026, 5, 14, 9, 30),
        ),
        now: DateTime(2026, 5, 14, 12, 0),
      );
      expect(state.windowStart, DateTime(2026, 5, 14, 9, 30));
      expect(state.windowEnd, DateTime(2026, 5, 14, 17, 30));
      expect(state.status, EatingWindowStatus.withinWindow);
    });

    test('sin lastInterval, sin firstMealGoal → fallback 08:00', () {
      final state = EatingWindowState.compute(
        lastInterval: null,
        user: _user(protocol: '16:8'),
        now: DateTime(2026, 5, 14, 12, 0),
      );
      expect(state.windowStart, DateTime(2026, 5, 14, 8, 0));
      expect(state.windowEnd, DateTime(2026, 5, 14, 16, 0));
    });

    test('lastInterval con isFasting=true → status unknown', () {
      // Si hay ayuno activo, este state no debería usarse.
      final state = EatingWindowState.compute(
        lastInterval: _interval(
          startTime: DateTime(2026, 5, 14, 10, 0),
          isFasting: true,
        ),
        user: _user(protocol: '18:6'),
        now: DateTime(2026, 5, 14, 15, 0),
      );
      expect(state.status, EatingWindowStatus.unknown);
      expect(state.progressPercent, 0.0);
    });

    test('lastInterval muy viejo (>24h) → cae a fallback', () {
      // lastInterval de hace 3 días. No es confiable.
      final state = EatingWindowState.compute(
        lastInterval: _interval(
          startTime: DateTime(2026, 5, 11, 13, 0),
          isFasting: false,
        ),
        user: _user(
          protocol: '16:8',
          firstMealGoal: DateTime(2026, 5, 14, 9, 0),
        ),
        now: DateTime(2026, 5, 14, 12, 0),
      );
      expect(state.windowStart, DateTime(2026, 5, 14, 9, 0));
    });
  });
}
