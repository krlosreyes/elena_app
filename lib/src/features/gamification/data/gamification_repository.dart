// SPEC-262: repositorio del wallet de gamificación.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/gamification/data/mappers/gamification_mapper.dart';
import 'package:elena_app/src/features/gamification/data/sources/firestore_gamification_v1_source.dart';
import 'package:elena_app/src/features/gamification/data/sources/gamification_data_source.dart';
import 'package:elena_app/src/features/gamification/domain/gamification_state.dart';

abstract class GamificationRepository {
  /// Stream del estado (null si el usuario aún no tiene wallet).
  Stream<GamificationState?> watch(String userId);

  /// Persiste el estado (offline-first: el caller no debe await bloqueante).
  Future<void> save(String userId, GamificationState state);
}

class GamificationRepositoryImpl implements GamificationRepository {
  final GamificationDataSource _source;
  final GamificationMapper _mapper;

  GamificationRepositoryImpl({
    required GamificationDataSource source,
    GamificationMapper mapper = const GamificationMapper(),
  })  : _source = source,
        _mapper = mapper;

  @override
  Stream<GamificationState?> watch(String userId) => _source
      .watch(userId)
      .map((map) => map == null ? null : _mapper.fromMap(map));

  @override
  Future<void> save(String userId, GamificationState state) =>
      _source.save(userId: userId, data: _mapper.toMap(state));
}

final gamificationRepositoryProvider = Provider<GamificationRepository>((ref) {
  return GamificationRepositoryImpl(
    source: FirestoreGamificationV1Source(),
  );
});
