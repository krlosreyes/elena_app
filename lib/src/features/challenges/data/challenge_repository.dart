// SPEC-263: repositorio de retos. Traduce entre dominio y la fuente Firestore.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/challenges/data/mappers/challenge_mapper.dart';
import 'package:elena_app/src/features/challenges/data/mappers/challenge_score_mapper.dart';
import 'package:elena_app/src/features/challenges/data/sources/challenge_data_source.dart';
import 'package:elena_app/src/features/challenges/data/sources/firestore_challenge_v1_source.dart';
import 'package:elena_app/src/features/challenges/domain/challenge.dart';
import 'package:elena_app/src/features/challenges/domain/challenge_score.dart';

abstract class ChallengeRepository {
  Stream<List<Challenge>> watchMyChallenges(String userId);
  Stream<Challenge?> watchChallenge(String code);
  Stream<List<ChallengeScore>> watchScores(String code);

  Future<void> create(Challenge challenge);
  Future<void> join(String code, List<String> memberIds);
  Future<void> publishScore(String code, ChallengeScore score);
  Future<void> leave(String code, String uid);
  Future<void> delete(String code);
}

class ChallengeRepositoryImpl implements ChallengeRepository {
  final ChallengeDataSource _source;
  final ChallengeMapper _mapper;
  final ChallengeScoreMapper _scoreMapper;

  ChallengeRepositoryImpl({
    required ChallengeDataSource source,
    ChallengeMapper mapper = const ChallengeMapper(),
    ChallengeScoreMapper scoreMapper = const ChallengeScoreMapper(),
  })  : _source = source,
        _mapper = mapper,
        _scoreMapper = scoreMapper;

  @override
  Stream<List<Challenge>> watchMyChallenges(String userId) =>
      _source.watchMyChallenges(userId).map((list) => list
          .map((m) => _mapper.fromMap(m['code'] as String? ?? '', m))
          .toList());

  @override
  Stream<Challenge?> watchChallenge(String code) => _source
      .watchChallenge(code)
      .map((m) => m == null ? null : _mapper.fromMap(code, m));

  @override
  Stream<List<ChallengeScore>> watchScores(String code) => _source
      .watchScores(code)
      .map((list) => list.map(_scoreMapper.fromMap).toList());

  @override
  Future<void> create(Challenge challenge) =>
      _source.createChallenge(challenge.code, _mapper.toMap(challenge));

  @override
  Future<void> join(String code, List<String> memberIds) =>
      _source.joinChallenge(code, memberIds);

  @override
  Future<void> publishScore(String code, ChallengeScore score) =>
      _source.publishScore(code, score.uid, _scoreMapper.toMap(score));

  @override
  Future<void> leave(String code, String uid) => _source.removeScore(code, uid);

  @override
  Future<void> delete(String code) => _source.deleteChallenge(code);
}

final challengeRepositoryProvider = Provider<ChallengeRepository>((ref) {
  return ChallengeRepositoryImpl(source: FirestoreChallengeV1Source());
});
