// SPEC-261.4: repositorio del documento de sesión (metadatos + plan).

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/alcohol/data/mappers/consumption_session_mapper.dart';
import 'package:elena_app/src/features/alcohol/data/sources/consumption_session_data_source.dart';
import 'package:elena_app/src/features/alcohol/data/sources/firestore_consumption_session_v1_source.dart';
import 'package:elena_app/src/features/alcohol/domain/consumption_session.dart';

abstract class ConsumptionSessionRepository {
  /// Stream de los metadatos de la sesión (null si no hay ocasión activa).
  Stream<ConsumptionSession?> watch(String userId);

  /// Persiste (sobrescribe) los metadatos de la sesión.
  Future<void> save(String userId, ConsumptionSession session);

  /// Borra la sesión persistida (al cerrar el protocolo).
  Future<void> clear(String userId);
}

class ConsumptionSessionRepositoryImpl implements ConsumptionSessionRepository {
  final ConsumptionSessionDataSource _source;
  final ConsumptionSessionMapper _mapper;

  ConsumptionSessionRepositoryImpl({
    required ConsumptionSessionDataSource source,
    ConsumptionSessionMapper mapper = const ConsumptionSessionMapper(),
  })  : _source = source,
        _mapper = mapper;

  @override
  Stream<ConsumptionSession?> watch(String userId) {
    return _source
        .watch(userId)
        .map((map) => map == null ? null : _mapper.fromMap(map));
  }

  @override
  Future<void> save(String userId, ConsumptionSession session) async {
    await _source.save(userId: userId, data: _mapper.toMap(session));
  }

  @override
  Future<void> clear(String userId) async {
    await _source.clear(userId);
  }
}

/// SPEC-261.4: provider único del repositorio de sesión.
final consumptionSessionRepositoryProvider =
    Provider<ConsumptionSessionRepository>((ref) {
  return ConsumptionSessionRepositoryImpl(
    source: FirestoreConsumptionSessionV1Source(),
  );
});
