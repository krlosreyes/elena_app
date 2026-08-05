// SPEC-263: round-trip de los mappers (dominio <-> Map de Firestore).

import 'package:elena_app/src/features/challenges/data/mappers/challenge_mapper.dart';
import 'package:elena_app/src/features/challenges/data/mappers/challenge_score_mapper.dart';
import 'package:elena_app/src/features/challenges/domain/challenge.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_score.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const challengeMapper = ChallengeMapper();
  const scoreMapper = ChallengeScoreMapper();

  test('Challenge: toMap no incluye el code; fromMap lo reinyecta', () {
    const c = Challenge(
      code: 'ABC234',
      name: 'Reto de agosto',
      ownerId: 'u1',
      ownerName: 'Carlos',
      startDateKey: '2026-08-01',
      endDateKey: '2026-08-31',
      memberIds: ['u1', 'u2'],
    );
    final map = challengeMapper.toMap(c);
    expect(map.containsKey('code'), isFalse);

    final back = challengeMapper.fromMap('ABC234', map);
    expect(back.code, 'ABC234');
    expect(back.name, c.name);
    expect(back.ownerId, c.ownerId);
    expect(back.memberIds, c.memberIds);
    expect(back.startDateKey, c.startDateKey);
    expect(back.endDateKey, c.endDateKey);
  });

  test('Challenge.fromMap tolera memberIds ausente', () {
    final back = challengeMapper.fromMap('X', {'name': 'n', 'ownerId': 'o'});
    expect(back.memberIds, isEmpty);
  });

  test('ChallengeScore: round-trip', () {
    const s =
        ChallengeScore(uid: 'u1', displayName: 'Carlos', points: 12);
    final back = scoreMapper.fromMap(scoreMapper.toMap(s));
    expect(back.uid, 'u1');
    expect(back.displayName, 'Carlos');
    expect(back.points, 12);
  });

  test('ChallengeScore.fromMap usa defaults seguros', () {
    final back = scoreMapper.fromMap(const {});
    expect(back.uid, '');
    expect(back.displayName, 'Usuario');
    expect(back.points, 0);
  });
}
