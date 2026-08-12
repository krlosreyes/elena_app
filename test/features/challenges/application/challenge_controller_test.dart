// SPEC-263: tests del controlador de retos con repo en memoria (sin Firebase).

import 'package:elena_app/src/features/challenges/application/challenge_controller.dart';
import 'package:elena_app/src/features/challenges/application/challenge_providers.dart';
import 'package:elena_app/src/features/challenges/data/challenge_repository.dart';
import 'package:elena_app/src/features/challenges/domain/challenge.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_score.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Repo en memoria: guarda retos y puntajes en mapas.
class _FakeChallengeRepository implements ChallengeRepository {
  final Map<String, Challenge> challenges = {};
  final Map<String, Map<String, ChallengeScore>> scores = {};

  @override
  Future<void> create(Challenge challenge) async {
    challenges[challenge.code] = challenge;
  }

  @override
  Future<void> join(String code, List<String> memberIds) async {
    challenges[code] = challenges[code]!.copyWith(memberIds: memberIds);
  }

  @override
  Future<void> publishScore(String code, ChallengeScore score) async {
    (scores[code] ??= {})[score.uid] = score;
  }

  @override
  Future<void> leave(String code, String uid) async {
    scores[code]?.remove(uid);
  }

  @override
  Future<void> delete(String code) async {
    challenges.remove(code);
    scores.remove(code);
  }

  @override
  Stream<Challenge?> watchChallenge(String code) =>
      Stream.value(challenges[code]);

  @override
  Stream<List<Challenge>> watchMyChallenges(String userId) => Stream.value(
        challenges.values.where((c) => c.isMember(userId)).toList(),
      );

  @override
  Stream<List<ChallengeScore>> watchScores(String code) =>
      Stream.value((scores[code] ?? {}).values.toList());
}

StreakEntry _entry(String date, {required bool qualifies}) => StreakEntry(
      date: date,
      fastingCompleted: qualifies,
      sleepCompleted: qualifies,
      hydrationCompleted: true,
      exerciseLogged: false,
      nutritionLogged: false,
      imrScore: qualifies ? 70 : 40,
    );

UserModel _carlos() => UserModel(
      id: 'u1',
      name: 'Carlos',
      age: 30,
      gender: 'male',
      weight: 80,
      height: 175,
      profile: CircadianProfile(
        wakeUpTime: DateTime(2026, 1, 1, 7),
        sleepTime: DateTime(2026, 1, 1, 23),
      ),
    );

ProviderContainer _container(_FakeChallengeRepository repo) {
  final history = [
    _entry('2026-08-01', qualifies: true),
    _entry('2026-08-02', qualifies: true),
    _entry('2026-08-03', qualifies: false),
    _entry('2026-08-04', qualifies: true),
  ];
  return ProviderContainer(overrides: [
    currentUserStreamProvider.overrideWith(
      (ref) => Stream<UserModel?>.value(_carlos()),
    ),
    challengeRepositoryProvider.overrideWithValue(repo),
    challengeStreakHistoryProvider.overrideWithValue(history),
    // El grafo de retos alcanza fastingProvider (vía streak); su `_init`
    // escucha dos streams de Firebase. Los overrideamos con streams vacíos
    // para que el FastingNotifier real se construya sin Firebase, como
    // promete la cabecera del test.
    lastFastingIntervalProvider.overrideWith((ref) => Stream.empty()),
    lastCompletedFastingProvider.overrideWith((ref) => Stream.empty()),
  ]);
}

void main() {
  test('crear un reto: soy dueño, único miembro, y publica mi puntaje real',
      () async {
    final repo = _FakeChallengeRepository();
    final c = _container(repo);
    addTearDown(c.dispose);
    // Prime el stream del usuario para que valueOrNull ya tenga el valor.
    await c.read(currentUserStreamProvider.future);

    final challenge = await c.read(challengeControllerProvider).createChallenge(
          name: 'Reto de agosto',
          startDateKey: '2026-08-01',
          endDateKey: '2026-08-31',
        );

    expect(challenge.ownerId, 'u1');
    expect(challenge.memberIds, ['u1']);
    expect(challenge.code.length, 6);
    expect(repo.challenges[challenge.code], isNotNull);
    // SPEC-264 puntos por pilar: 01→3, 02→3, 03→1, 04→3 = 10.
    expect(repo.scores[challenge.code]!['u1']!.points, 10);
    expect(repo.scores[challenge.code]!['u1']!.displayName, 'Carlos');
  });

  test('crear con nombre vacío es rechazado', () async {
    final repo = _FakeChallengeRepository();
    final c = _container(repo);
    addTearDown(c.dispose);
    // Prime el stream del usuario para que valueOrNull ya tenga el valor.
    await c.read(currentUserStreamProvider.future);
    await expectLater(
      c.read(challengeControllerProvider).createChallenge(
            name: '   ',
            startDateKey: '2026-08-01',
            endDateKey: '2026-08-31',
          ),
      throwsA(isA<ChallengeException>()),
    );
  });

  test('unirse por código agrega al usuario y publica su puntaje', () async {
    final repo = _FakeChallengeRepository();
    // Un reto preexistente creado por otra persona.
    repo.challenges['ABC234'] = const Challenge(
      code: 'ABC234',
      name: 'Reto ajeno',
      ownerId: 'owner',
      ownerName: 'Ana',
      startDateKey: '2026-08-01',
      endDateKey: '2026-08-31',
      memberIds: ['owner'],
    );
    final c = _container(repo);
    addTearDown(c.dispose);
    // Prime el stream del usuario para que valueOrNull ya tenga el valor.
    await c.read(currentUserStreamProvider.future);

    final joined =
        await c.read(challengeControllerProvider).joinByCode('abc234');

    expect(joined.memberIds, containsAll(['owner', 'u1']));
    expect(repo.challenges['ABC234']!.isMember('u1'), isTrue);
    expect(repo.scores['ABC234']!['u1']!.points, 10);
  });

  test('unirse a un código inexistente lanza error legible', () async {
    final repo = _FakeChallengeRepository();
    final c = _container(repo);
    addTearDown(c.dispose);
    // Prime el stream del usuario para que valueOrNull ya tenga el valor.
    await c.read(currentUserStreamProvider.future);
    await expectLater(
      c.read(challengeControllerProvider).joinByCode('ZZZZZZ'),
      throwsA(isA<ChallengeException>()),
    );
  });

  test('unirse cuando ya soy miembro no falla (republica)', () async {
    final repo = _FakeChallengeRepository();
    repo.challenges['ABC234'] = const Challenge(
      code: 'ABC234',
      name: 'Reto',
      ownerId: 'u1',
      ownerName: 'Carlos',
      startDateKey: '2026-08-01',
      endDateKey: '2026-08-31',
      memberIds: ['u1'],
    );
    final c = _container(repo);
    addTearDown(c.dispose);
    // Prime el stream del usuario para que valueOrNull ya tenga el valor.
    await c.read(currentUserStreamProvider.future);

    final r = await c.read(challengeControllerProvider).joinByCode('ABC234');
    expect(r.memberIds, ['u1']);
    expect(repo.scores['ABC234']!['u1']!.points, 10);
  });
}
