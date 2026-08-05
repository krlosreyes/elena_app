// SPEC-263: tests del modelo de reto.

import 'package:elena_app/src/features/challenges/domain/challenge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const c = Challenge(
    code: 'ABC234',
    name: 'Reto de agosto',
    ownerId: 'u1',
    ownerName: 'Carlos',
    startDateKey: '2026-08-01',
    endDateKey: '2026-08-31',
    memberIds: ['u1', 'u2'],
  );

  test('estado según la fecha', () {
    expect(c.statusOn('2026-07-15'), ChallengeStatus.upcoming);
    expect(c.statusOn('2026-08-01'), ChallengeStatus.active); // borde inicio
    expect(c.statusOn('2026-08-15'), ChallengeStatus.active);
    expect(c.statusOn('2026-08-31'), ChallengeStatus.active); // borde fin
    expect(c.statusOn('2026-09-01'), ChallengeStatus.ended);
  });

  test('membresía y conteo', () {
    expect(c.isMember('u2'), isTrue);
    expect(c.isMember('u9'), isFalse);
    expect(c.memberCount, 2);
  });

  test('copyWith agrega miembro sin mutar', () {
    final c2 = c.copyWith(memberIds: [...c.memberIds, 'u3']);
    expect(c2.memberCount, 3);
    expect(c.memberCount, 2); // original intacto
  });
}
