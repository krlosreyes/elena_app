// SPEC-264: repositorio de zumbidos.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/challenges/data/mappers/nudge_mapper.dart';
import 'package:elena_app/src/features/challenges/data/sources/firestore_nudge_v1_source.dart';
import 'package:elena_app/src/features/challenges/data/sources/nudge_data_source.dart';
import 'package:elena_app/src/features/challenges/domain/nudge.dart';

abstract class NudgeRepository {
  Future<void> send(String code, Nudge nudge);
  Stream<List<Nudge>> watchForRecipient(String code, String uid);
}

class NudgeRepositoryImpl implements NudgeRepository {
  final NudgeDataSource _source;
  final NudgeMapper _mapper;

  NudgeRepositoryImpl({
    required NudgeDataSource source,
    NudgeMapper mapper = const NudgeMapper(),
  })  : _source = source,
        _mapper = mapper;

  @override
  Future<void> send(String code, Nudge nudge) =>
      _source.send(code, _mapper.toMap(nudge));

  @override
  Stream<List<Nudge>> watchForRecipient(String code, String uid) => _source
      .watchForRecipient(code, uid)
      .map((list) => list.map(_mapper.fromMap).toList());
}

final nudgeRepositoryProvider = Provider<NudgeRepository>((ref) {
  return NudgeRepositoryImpl(source: FirestoreNudgeV1Source());
});
