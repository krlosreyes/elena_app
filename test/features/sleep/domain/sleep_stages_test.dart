// SPEC-301 — SleepStages: value object de las etapas de sueño.

import 'package:elena_app/src/features/sleep/domain/sleep_stages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('asleepMinutes suma profundo+ligero+REM (sin despierto)', () {
    const s = SleepStages(
        deepMinutes: 90, lightMinutes: 240, remMinutes: 90, awakeMinutes: 20);
    expect(s.asleepMinutes, 420);
    expect(s.totalMinutes, 440);
  });

  test('fracciones respecto al sueño real', () {
    const s = SleepStages(deepMinutes: 100, lightMinutes: 200, remMinutes: 100);
    expect(s.deepFraction, closeTo(0.25, 1e-9));
    expect(s.remFraction, closeTo(0.25, 1e-9));
    expect(s.lightFraction, closeTo(0.5, 1e-9));
  });

  test('hasData: solo despierto no cuenta', () {
    expect(const SleepStages(awakeMinutes: 30).hasData, isFalse);
    expect(const SleepStages(deepMinutes: 1).hasData, isTrue);
  });

  test('fromHealthMap: mapa vacío/sin etapas → null', () {
    expect(SleepStages.fromHealthMap(null), isNull);
    expect(SleepStages.fromHealthMap(const {}), isNull);
    expect(SleepStages.fromHealthMap(const {'awake': 30}), isNull);
  });

  test('fromHealthMap: con etapas construye el VO', () {
    final s = SleepStages.fromHealthMap(const {'deep': 90, 'rem': 80});
    expect(s, isNotNull);
    expect(s!.deepMinutes, 90);
    expect(s.remMinutes, 80);
  });

  test('round-trip toMap/fromMap (omite ceros)', () {
    const s = SleepStages(deepMinutes: 90, lightMinutes: 240, remMinutes: 90);
    final map = s.toMap();
    expect(map.containsKey('awake'), isFalse);
    expect(SleepStages.fromMap(map), s);
  });
}
