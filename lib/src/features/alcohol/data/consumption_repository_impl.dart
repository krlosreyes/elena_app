// SPEC-261: implementación concreta del ConsumptionRepository.
//
// Espejo de HydrationRepositoryImpl (SPEC-50.1): stream mapeado, sin cap
// fijo (stream abierto cuando no se pasa `until`), writes con auto-id.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/alcohol/data/mappers/drink_event_mapper.dart';
import 'package:elena_app/src/features/alcohol/data/sources/consumption_data_source.dart';
import 'package:elena_app/src/features/alcohol/data/sources/firestore_consumption_v1_source.dart';
import 'package:elena_app/src/features/alcohol/domain/consumption_repository.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_event.dart';

class ConsumptionRepositoryImpl implements ConsumptionRepository {
  final ConsumptionDataSource _source;
  final DrinkEventMapper _mapper;

  ConsumptionRepositoryImpl({
    required ConsumptionDataSource source,
    DrinkEventMapper mapper = const DrinkEventMapper(),
  })  : _source = source,
        _mapper = mapper;

  @override
  Stream<List<DrinkEvent>> watchSince(
    String userId,
    DateTime since, {
    DateTime? until,
  }) {
    return _source
        .streamSince(userId: userId, startOfDay: since, endOfDay: until)
        .map((maps) => maps.map(_mapper.fromMap).toList());
  }

  @override
  Future<void> add(String userId, DrinkEvent event) async {
    final data = _mapper.toMap(event);
    await _source.append(userId: userId, data: data);
  }

  @override
  Future<void> removeLast(String userId, DateTime since) async {
    await _source.deleteLatest(userId: userId, since: since);
  }
}

/// SPEC-261: provider único del ConsumptionRepository.
final consumptionRepositoryProvider = Provider<ConsumptionRepository>((ref) {
  return ConsumptionRepositoryImpl(
    source: FirestoreConsumptionV1Source(),
  );
});
