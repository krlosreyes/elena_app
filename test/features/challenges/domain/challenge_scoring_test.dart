// SPEC-263: tests del cálculo de la competencia (puro).

import 'dart:math';

import 'package:elena_app/src/features/challenges/domain/challenge_score.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_scoring.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:flutter_test/flutter_test.dart';

StreakEntry _entry(String date, {required bool qualifies}) => StreakEntry(
      date: date,
      // Califica: ayuno+sueño+hidratación (3 pilares con ancla).
      fastingCompleted: qualifies,
      sleepCompleted: qualifies,
      hydrationCompleted: true,
      exerciseLogged: false,
      nutritionLogged: false,
      imrScore: qualifies ? 70 : 40,
    );

void main() {
  test('dateKey formatea yyyy-MM-dd', () {
    expect(ChallengeScoring.dateKey(DateTime(2026, 8, 1)), '2026-08-01');
    expect(ChallengeScoring.dateKey(DateTime(2026, 12, 25)), '2026-12-25');
  });

  test('consistencyPoints cuenta días que califican en el rango', () {
    final history = [
      _entry('2026-07-31', qualifies: true), // fuera del rango
      _entry('2026-08-01', qualifies: true), // ✓
      _entry('2026-08-02', qualifies: false), // en rango pero no califica
      _entry('2026-08-03', qualifies: true), // ✓
      _entry('2026-09-05', qualifies: true), // fuera del rango
    ];
    final pts = ChallengeScoring.consistencyPoints(
      history,
      startKey: '2026-08-01',
      endKey: '2026-08-31',
    );
    expect(pts, 2);
  });

  test('leaderboard ordena por puntos y desempata por nombre', () {
    final board = ChallengeScoring.leaderboard(const [
      ChallengeScore(uid: 'a', displayName: 'Ana', points: 3),
      ChallengeScore(uid: 'b', displayName: 'Bruno', points: 5),
      ChallengeScore(uid: 'c', displayName: 'Carla', points: 5),
    ]);
    expect(board.map((s) => s.uid).toList(), ['b', 'c', 'a']);
    expect(ChallengeScoring.winner(board)!.uid, 'b');
  });

  test('winner de lista vacía es null', () {
    expect(ChallengeScoring.winner(const []), isNull);
  });

  test('código de invitación: longitud, alfabeto seguro y determinismo', () {
    final code = ChallengeScoring.generateInviteCode(random: Random(42));
    expect(code.length, 6);
    for (final ch in code.split('')) {
      expect('ABCDEFGHJKLMNPQRSTUVWXYZ23456789'.contains(ch), isTrue,
          reason: 'char inseguro: $ch');
    }
    // Mismo seed → mismo código (determinístico para tests).
    expect(ChallengeScoring.generateInviteCode(random: Random(42)), code);
  });
}
