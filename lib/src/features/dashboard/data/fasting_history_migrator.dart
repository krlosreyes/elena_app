// SPEC-222 (2026-06-14): migración one-shot de la colección plana
// `fasting_history/{docId}` (path original SPEC-50.4) a la subcolección
// `users/{uid}/fasting_history/{docId}` (path introducido en SPEC-217).
//
// CONTEXTO: SPEC-217 cambió el path de lectura/escritura sin ejecutar la
// migración de datos existentes, dejando los historiales previos inaccesibles
// y produciendo "Sin datos" en todas las pantallas de análisis de Ayuno.
//
// GARANTÍAS:
//  - Idempotente: la clave Firestore `spec217_fasting_migrated` en
//    users/{uid}/app_state/migrations impide que corra más de una vez
//    por usuario en CUALQUIER dispositivo (SPEC-228: cross-device guard).
//  - No destructiva: solo COPIA — NO borra la colección plana. El borrado
//    es responsabilidad de SPEC-217 inc5 (post-launch, una vez confirmada
//    la integridad de la subcolección en producción).
//  - Tolerante a fallos: si el batch falla, NO marca la migración como hecha
//    → se reintentará en el próximo arranque hasta que tenga éxito.
//  - Segura offline: si Firestore devuelve error de red, el try/catch lo
//    captura y el reintento automático en el siguiente arranque aplica.
//
// LLAMADA: FastingNotifier._init() cuando el usuario hace login.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/core/data/app_state_repository.dart';
import 'package:elena_app/src/core/services/app_logger.dart';

class FastingHistoryMigrator {
  final FirebaseFirestore _firestore;
  final AppStateRepository _appState;

  FastingHistoryMigrator({
    FirebaseFirestore? firestore,
    required AppStateRepository appState,
  }) : _firestore = firestore ?? FirebaseFirestore.instance,
       _appState = appState;

  static const String _kMigrationKey = 'spec217_fasting_migrated';

  /// Corre la migración si aún no se completó para este uid.
  /// Guard key en Firestore — funciona igual en iOS, Android y Web.
  /// No lanza — los errores se registran y se dejan para el próximo intento.
  Future<void> migrateIfNeeded(String uid) async {
    if (await _appState.getMigrationFlag(uid, _kMigrationKey)) return;

    // SEC-07: uid truncado, nunca completo en logs.
    AppLogger.debug(
        '[SPEC-222] Iniciando migración fasting_history → subcollección uid=${AppLogger.truncateUid(uid)}');

    try {
      // FB-12 (auditoría independiente 2026-07-11): la lectura ya no trae
      // todos los docs del usuario en un único .get() sin límite — se pagina
      // en páginas de 450 vía startAfterDocument para acotar memoria/latencia
      // en usuarios con miles de ciclos históricos. Destino: subcolección
      // aislada por uid (nuevo path SPEC-217).
      const pageSize = 450;
      final subCol = _firestore
          .collection('users')
          .doc(uid)
          .collection('fasting_history');

      int totalMigrated = 0;
      DocumentSnapshot<Map<String, dynamic>>? lastDoc;
      var batchNumber = 0;

      while (true) {
        Query<Map<String, dynamic>> query = _firestore
            .collection('fasting_history')
            .where('userId', isEqualTo: uid)
            .limit(pageSize);
        if (lastDoc != null) {
          query = query.startAfterDocument(lastDoc);
        }

        final page = await query.get(const GetOptions(source: Source.server));
        if (page.docs.isEmpty) break;

        batchNumber++;
        final batch = _firestore.batch();
        for (final doc in page.docs) {
          // set() es idempotente: si ya existe (migración parcial previa),
          // sobreescribe con los mismos datos — sin efecto neto.
          batch.set(subCol.doc(doc.id), doc.data());
        }
        await batch.commit();
        totalMigrated += page.docs.length;
        AppLogger.debug(
            '[SPEC-222] Página $batchNumber commiteada (${page.docs.length} docs).');

        lastDoc = page.docs.last;
        if (page.docs.length < pageSize) break; // última página
      }

      if (totalMigrated == 0) {
        AppLogger.debug('[SPEC-222] Sin datos en colección plana — migración trivial completada.');
      } else {
        AppLogger.debug('[SPEC-222] Migración completada — $totalMigrated docs copiados.');
      }

      // Solo marcar como hecho si TODAS las páginas tuvieron éxito.
      await _appState.setMigrationFlag(uid, _kMigrationKey);
    } catch (e, st) {
      // No relanzar — el fallo se reintentará en el próximo arranque.
      AppLogger.warning('[SPEC-222] Error en migración (se reintentará): $e\n$st', e);
    }
  }
}
