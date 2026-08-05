// SPEC-264: tests de los anillos (5 pilares del día).

import 'package:elena_app/src/features/challenges/domain/challenge_rings.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromEntry mapea los 5 pilares y cuenta los cerrados', () {
    const e = StreakEntry(
      date: '2026-08-01',
      fastingCompleted: true,
      sleepCompleted: true,
      hydrationCompleted: true,
      exerciseLogged: false,
      nutritionLogged: false,
      imrScore: 70,
    );
    final rings = ChallengeRings.fromEntry(e);
    expect(rings.ayuno, isTrue);
    expect(rings.sueno, isTrue);
    expect(rings.hidratacion, isTrue);
    expect(rings.ejercicio, isFalse);
    expect(rings.nutricion, isFalse);
    expect(rings.closedCount, 3);
  });

  test('round-trip toMap/fromMap', () {
    const rings = ChallengeRings(
      ayuno: true,
      ejercicio: true,
      nutricion: false,
      sueno: true,
      hidratacion: false,
    );
    final back = ChallengeRings.fromMap(rings.toMap());
    expect(back, rings);
    expect(back.closedCount, 3);
  });

  test('fromMap tolera null y campos ausentes', () {
    expect(ChallengeRings.fromMap(null), ChallengeRings.empty);
    expect(ChallengeRings.fromMap(const {}).closedCount, 0);
  });
}
