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

    AppLogger.debug('[SPEC-222] Iniciando migración fasting_history → subcollección uid=$uid');

    try {
      // Leer todos los docs de la colección PLANA del usuario.
      final flatSnap = await _firestore
          .collection('fasting_history')
          .where('userId', isEqualTo: uid)
          .get(const GetOptions(source: Source.server));

      if (flatSnap.docs.isEmpty) {
        // Nada que migrar (cuenta nueva o ya limpia). Marcar como hecho.
        AppLogger.debug('[SPEC-222] Sin datos en colección plana — migración trivial completada.');
        await _appState.setMigrationFlag(uid, _kMigrationKey);
        return;
      }

      AppLogger.debug('[SPEC-222] Migrando ${flatSnap.docs.length} docs...');

      // Destino: subcolección aislada por uid (nuevo path SPEC-217).
      final subCol = _firestore
          .collection('users')
          .doc(uid)
          .collection('fasting_history');

      // Firestore batch tiene límite de 500 ops; 2000 docs → 4 batches máx.
      const batchSize = 450;
      final docs = flatSnap.docs;

      for (var i = 0; i < docs.length; i += batchSize) {
        final chunk = docs.sublist(i, (i + batchSize).clamp(0, docs.length));
        final batch = _firestore.batch();
        for (final doc in chunk) {
          // set() es idempotente: si ya existe (migración parcial previa),
          // sobreescribe con los mismos datos — sin efecto neto.
          batch.set(subCol.doc(doc.id), doc.data());
        }
        await batch.commit();
        AppLogger.debug('[SPEC-222] Batch ${i ~/ batchSize + 1} commiteado (${chunk.length} docs).');
      }

      // Solo marcar como hecho si TODOS los batches tuvieron éxito.
      await _appState.setMigrationFlag(uid, _kMigrationKey);
      AppLogger.debug('[SPEC-222] Migración completada — ${docs.length} docs copiados.');
    } catch (e, st) {
      // No relanzar — el fallo se reintentará en el próximo arranque.
      AppLogger.warning('[SPEC-222] Error en migración (se reintentará): $e\n$st', e);
    }
  }
}
