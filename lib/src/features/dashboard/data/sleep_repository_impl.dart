// SPEC-50: implementación concreta del SleepRepository.
//
// Orquesta DataSource (storage) + Mapper (translation). Separa la
// lógica "qué leer/escribir" (source) de "cómo se ve en el dominio"
// (mapper). Ambos son inyectables — tests pueden usar fakes sin
// Firestore real.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/dashboard/data/mappers/sleep_log_mapper.dart';
import 'package:elena_app/src/features/dashboard/data/sources/firestore_sleep_v1_source.dart';
import 'package:elena_app/src/features/dashboard/data/sources/sleep_data_source.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_repository.dart';

class SleepRepositoryImpl implements SleepRepository {
  final SleepDataSource _source;
  final SleepLogMapper _mapper;

  SleepRepositoryImpl({
    required SleepDataSource source,
    SleepLogMapper mapper = const SleepLogMapper(),
  })  : _source = source,
        _mapper = mapper;

  @override
  Stream<SleepLog?> watchLatest(String userId) {
    return _source.streamLatest(userId).map((map) {
      if (map == null) return null;
      // El source inyecta `__docId`; el resto del map es el body.
      final docId = map['__docId'] as String? ?? '';
      final body = Map<String, dynamic>.from(map)..remove('__docId');
      try {
        return _mapper.fromMap(body, docId: docId);
      } catch (_) {
        // Si un doc viejo está corrupto o malformado, NO crasheamos
        // toda la app — emitimos null y dejamos que el siguiente
        // snapshot intente de nuevo. La validación falló se loguea
        // arriba (en el mapper) si fuera el caso.
        return null;
      }
    });
  }

  @override
  Stream<List<SleepLog>> watchRecent(String userId, {int limit = 7}) {
    return _source
        .streamRecent(userId: userId, limit: limit)
        .map((maps) {
      final out = <SleepLog>[];
      for (final map in maps) {
        final docId = map['__docId'] as String? ?? '';
        final body = Map<String, dynamic>.from(map)..remove('__docId');
        try {
          out.add(_mapper.fromMap(body, docId: docId));
        } catch (_) {
          // Docs corruptos se descartan en silencio (mismo patrón que
          // watchLatest). Si toda la lista llega corrupta, devolvemos
          // lista vacía y el widget cae a empty state.
        }
      }
      return out;
    });
  }

  // 17-jul: lectura puntual por id — ver comentario en el contrato.
  @override
  Future<SleepLog?> getById(String userId, String docId) async {
    final map = await _source.fetchById(userId: userId, docId: docId);
    if (map == null) return null;
    final resolvedDocId = map['__docId'] as String? ?? docId;
    final body = Map<String, dynamic>.from(map)..remove('__docId');
    try {
      return _mapper.fromMap(body, docId: resolvedDocId);
    } catch (_) {
      // Mismo criterio que watchLatest/watchRecent: doc corrupto → null,
      // no crashear. El caller (guard "manual gana") trata esto igual
      // que "no existe" — conservador: si no podemos confirmar que hay
      // un manual válido, no bloqueamos el import automático.
      return null;
    }
  }

  @override
  Future<void> save(String userId, SleepLog log) async {
    final data = _mapper.toMap(log);
    await _source.persist(userId: userId, docId: log.id, data: data);
  }

  @override
  Future<void> delete(String userId, String logId) async {
    await _source.deleteDoc(userId: userId, docId: logId);
  }
}

// ─────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────

/// SPEC-50: provider único del SleepRepository. Notifiers consumen
/// `ref.read(sleepRepositoryProvider)` en lugar de `userRepositoryProvider`
/// para todo lo relacionado a sueño.
final sleepRepositoryProvider = Provider<SleepRepository>((ref) {
  return SleepRepositoryImpl(
    source: FirestoreSleepV1Source(),
  );
});
