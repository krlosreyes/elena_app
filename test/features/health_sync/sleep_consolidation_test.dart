// 2026-11-04 (auditoría Apple Salud): consolidación de sueño por noche.

import 'package:elena_app/src/features/health_sync/application/health_sync_service.dart';
import 'package:elena_app/src/features/health_sync/domain/health_metric.dart';
import 'package:elena_app/src/features/health_sync/domain/health_sample.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_log.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_stages.dart';
import 'package:flutter_test/flutter_test.dart';

HealthSample _s(String stage, DateTime start, DateTime end,
        {String source = 'Apple Watch'}) =>
    HealthSample(
      metric: HealthMetric.sleepSession,
      value: end.difference(start).inMinutes.toDouble(),
      start: start,
      end: end,
      sourceName: source,
      uuid: '$stage-${start.toIso8601String()}',
      sleepStage: stage,
    );

DateTime _t(int day, int h, [int m = 0]) => DateTime(2026, 11, day, h, m);

void main() {
  test('despierto antes de dormir y al levantarse NO estira la noche', () {
    final nights = consolidateSleepByNight([
      _s('awake', _t(3, 22, 30), _t(3, 23, 10)), // en cama sin dormir
      _s('light', _t(3, 23, 10), _t(4, 2)),
      _s('deep', _t(4, 2), _t(4, 3)),
      _s('rem', _t(4, 3), _t(4, 5, 30)),
      _s('awake', _t(4, 5, 30), _t(4, 7)), // ya despierto
    ]);
    expect(nights.length, 1);
    final n = nights.single;
    expect(n.start, _t(3, 23, 10));
    expect(n.end, _t(4, 5, 30));
    expect(n.value, 380); // 6 h 20 min
    expect(n.sleepStages, {'light': 170, 'deep': 60, 'rem': 150});
  });

  test('despierto DENTRO de la noche se descuenta del tiempo dormido', () {
    final n = consolidateSleepByNight([
      _s('light', _t(3, 23), _t(4, 2)),
      _s('awake', _t(4, 2), _t(4, 2, 40)),
      _s('light', _t(4, 2, 40), _t(4, 6)),
    ]).single;
    expect(n.sleepStages?['awake'], 40);
    expect(n.value, 7 * 60 - 40);

    final log = SleepLog(
      id: 'x',
      fellAsleep: n.start,
      wokeUp: n.end,
      lastMealTime: _t(3, 20),
      stages: SleepStages.fromHealthMap(n.sleepStages),
    );
    expect(log.duration, const Duration(hours: 6, minutes: 20));
  });

  test('iPhone + Watch reportando lo mismo no se cuenta dos veces', () {
    final n = consolidateSleepByNight([
      _s('asleep', _t(3, 23), _t(4, 6), source: 'iPhone'),
      _s('light', _t(3, 23), _t(4, 3)),
      _s('light', _t(4, 2), _t(4, 6)), // se solapa con la anterior
    ]).single;
    expect(n.value, 7 * 60);
    expect(n.sleepStages?['light'], 7 * 60);
  });

  test('una siesta separada por más de 2 h es otra sesión', () {
    final nights = consolidateSleepByNight([
      _s('asleep', _t(3, 23), _t(4, 6)),
      _s('asleep', _t(4, 14), _t(4, 14, 40)),
    ]);
    expect(nights.length, 2);
  });

  test('solo despierto → no hay sesión', () {
    expect(
      consolidateSleepByNight([_s('awake', _t(4, 6), _t(4, 7))]),
      isEmpty,
    );
  });

  test('unionMinutes', () {
    expect(unionMinutes([(_t(1, 1), _t(1, 2)), (_t(1, 1, 30), _t(1, 3))]), 120);
    expect(unionMinutes([(_t(1, 1), _t(1, 2)), (_t(1, 4), _t(1, 5))]), 120);
    expect(unionMinutes(const []), 0);
  });
}
