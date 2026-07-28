// SPEC-50: implementación concreta del SleepRepository.
//
// Orquesta DataSource (storage) + Mapper (translation). Separa la
// lógica "qué leer/escribir" (source) de "cómo se ve en el dominio"
// (mapper). Ambos son inyectables — tests pueden usar fakes sin
// Firestore real.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/sleep/data/mappers/sleep_log_mapper.dart';
import 'package:elena_app/src/features/sleep/data/sources/firestore_sleep_v1_source.dart';
import 'package:elena_app/src/features/sleep/data/sources/sleep_data_source.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_log.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_quality_classifier.dart';
import 'package:elena_app/src/features/sleep/domain/sleep_repository.dart';

class SleepRepositoryImpl implements SleepRepository {
  final SleepDataSource _source;
  final SleepLogMapper _mapper;

  SleepRepositoryImpl({
    required SleepDataSource source,
    SleepLogMapper mapper = const SleepLogMapper(),
  })  : _source = source,
        _mapper = mapper;

  /// 17-jul (bulletproofing, Carlos: "el anillo de sueño no muestra el
  /// dato correcto"): ventana de documentos recientes que evaluamos
  /// para resolver "cuál es el sueño vigente". No usamos `streamLatest`
  /// del source (que es literalmente "el doc con wokeUp más tardío",
  /// SIN importar su origen) porque eso deja a cualquier documento
  /// automático viejo con un wokeUp posterior al del registro real del
  /// usuario ganando PARA SIEMPRE — incluyendo datos que ya quedaron
  /// mal escritos en Firestore ANTES del guard "manual gana" agregado a
  /// `HealthImportService`. Ese guard solo previene escrituras futuras;
  /// no repara lo que ya existe. 10 alcanza sobrado para cubrir varias
  /// noches de historial reciente, incluyendo duplicados.
  static const int _kLatestResolutionWindow = 10;

  @override
  Stream<SleepLog?> watchLatest(String userId) {
    // Resolvemos "el sueño vigente" a partir de la ventana reciente en
    // vez de confiar ciegamente en un solo doc — ver `_resolveLatest`.
    // Esta resolución corre en cada emisión del stream (lectura), así
    // que autorepara datos viejos corruptos sin necesitar migrar
    // Firestore.
    return watchRecent(userId, limit: _kLatestResolutionWindow)
        .map(_resolveLatest);
  }

  /// Agrupa [recent] por noche de atribución (mismo criterio que
  /// `SleepNotifier._attributionDocId`: día del punto medio del
  /// intervalo `[fellAsleep, wokeUp]`) y devuelve el sueño vigente de
  /// la noche MÁS RECIENTE.
  ///
  /// Dentro de esa noche, un registro MANUAL (`id` empieza con
  /// `sleep_` — el mismo prefijo que usan `confirmManualWakeUp` y
  /// `saveManualSleep`) gana sobre cualquier registro automático
  /// (`hk_*` de HealthKit/Health Connect, `sh_*` de Samsung Health) de
  /// esa misma noche, sin importar cuál tenga el `wokeUp` más tardío.
  /// Si no hay manual, gana el automático con `wokeUp` más tardío
  /// dentro de la noche (comportamiento previo, sin cambios).
  ///
  /// `null` si [recent] está vacía.
  static SleepLog? _resolveLatest(List<SleepLog> recent) {
    if (recent.isEmpty) {
      AppLogger.debug('[SleepRepositoryImpl] watchLatest: ventana vacía');
      return null;
    }

    // 17-jul (Carlos: "solo tenemos en cuenta el sueño nocturno y de
    // calidad"): descartamos siestas y fragmentos ANTES de agrupar por
    // noche. Sin esto, una siesta vespertina comparte noche de
    // atribución con el sueño real y, al no haber manual, gana por
    // tener `wokeUp` más tardío — ver SleepQualityClassifier para el
    // caso completo. Esta resolución alimenta también Score del día e
    // IMR (ambos leen `sleep.lastLog`), así que el filtro los protege
    // a los tres por cascada.
    final qualified =
        recent.where(SleepQualityClassifier.isNocturnalQualitySleep).toList();
    if (qualified.isEmpty) {
      AppLogger.debug(
        '[SleepRepositoryImpl] watchLatest: ${recent.length} docs en '
        'ventana, ninguno nocturno-de-calidad (solo siestas/fragmentos)',
      );
      return null;
    }

    final byNight = <String, List<SleepLog>>{};
    for (final log in qualified) {
      final night = DayBoundaryResolver.attributionDayKey(
        start: log.fellAsleep,
        end: log.wokeUp,
      );
      byNight.putIfAbsent(night, () => []).add(log);
    }

    // Claves en formato YYYYMMDD — comparación de string coincide con
    // orden cronológico, no hace falta parsear a DateTime.
    final latestNight =
        byNight.keys.reduce((a, b) => a.compareTo(b) >= 0 ? a : b);
    final candidates = byNight[latestNight]!;

    SleepLog? manual;
    SleepLog? bestAuto;
    for (final log in candidates) {
      final isManual = log.id.startsWith('sleep_');
      if (isManual) {
        if (manual == null || log.wokeUp.isAfter(manual.wokeUp)) {
          manual = log;
        }
      } else {
        if (bestAuto == null || log.wokeUp.isAfter(bestAuto.wokeUp)) {
          bestAuto = log;
        }
      }
    }

    final resolved = manual ?? bestAuto;
    // 17-jul (diagnóstico, Carlos: "el anillo muestra cero"): visibilidad
    // de qué ventana llegó y qué se resolvió — si `resolved` es null acá
    // a pesar de que `recent` no estaba vacío, es un bug de esta función
    // (no debería pasar: todo grupo no vacío produce manual o bestAuto).
    AppLogger.debug(
      '[SleepRepositoryImpl] watchLatest: ${recent.length} docs en '
      'ventana, noche más reciente=$latestNight '
      '(${candidates.length} candidatos), resuelto=${resolved?.id}',
    );
    return resolved;
  }

  @override
  Stream<List<SleepLog>> watchRecent(String userId, {int limit = 7}) {
    return _source.streamRecent(userId: userId, limit: limit).map((maps) {
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
