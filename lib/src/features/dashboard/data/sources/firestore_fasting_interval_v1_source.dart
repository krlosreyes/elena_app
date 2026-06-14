// SPEC-50.4: implementación Firestore del FastingIntervalDataSource.
//
// SPEC-217 (2026-06-14): migración de colección plana `fasting_history/{docId}`
// a subcolección `users/{uid}/fasting_history/{docId}`.
//
// Antes:  _db.collection('fasting_history') + .where('userId', isEqualTo: uid)
// Ahora:  _db.collection('users').doc(uid).collection('fasting_history')
//
// La subcolección está aislada por uid → no se necesita el filtro por userId.
// El campo `userId` sigue escribiéndose en el documento (vía FastingInterval.toJson)
// por retrocompatibilidad durante el período de transición (inc2/inc5 de SPEC-217).
// Eliminarlo es deuda post-migración confirmada.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/dashboard/data/sources/fasting_interval_data_source.dart';

class FirestoreFastingIntervalV1Source implements FastingIntervalDataSource {
  final FirebaseFirestore _firestore;

  FirestoreFastingIntervalV1Source({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // SPEC-217: subcolección por uid — aislamiento garantizado por path.
  CollectionReference<Map<String, dynamic>> _col(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('fasting_history');

  @override
  Stream<Map<String, dynamic>?> streamLatest(String userId) {
    // SPEC-99: "más reciente" no es "startTime mayor" — es "intervalo
    // abierto si hay uno; si no, el último cerrado".
    //
    // Traemos los últimos 5 docs por startTime y en cliente priorizamos
    // el primero que esté abierto (endTime==null). Si ninguno está
    // abierto, devolvemos el más reciente por startTime.
    return _col(userId)
        .orderBy('startTime', descending: true)
        .limit(5)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;

      // SPEC-100: prioridad explícita entre abiertos.
      // (a) Ayuno abierto (isFasting=true, endTime=null) — gana siempre.
      // (b) Si no hay ayuno abierto, cualquier otro abierto (ventana de comida).
      // (c) Si no hay nada abierto, el más reciente cerrado.
      for (final doc in snap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        if (data['endTime'] == null && data['isFasting'] == true) {
          return data;
        }
      }
      for (final doc in snap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        if (data['endTime'] == null) {
          return data;
        }
      }
      return Map<String, dynamic>.from(snap.docs.first.data());
    });
  }

  @override
  Stream<Map<String, dynamic>?> streamLastCompletedFasting(String userId) {
    // SPEC-101 / SPEC-113.bugfix: último ayuno cerrado (endTime != null,
    // isFasting=true). Sin índice compuesto — filtramos client-side.
    return _col(userId)
        .orderBy('startTime', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      Map<String, dynamic>? best;
      DateTime? bestEnd;
      for (final doc in snap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        if (data['isFasting'] != true) continue;
        final endTimeRaw = data['endTime'];
        if (endTimeRaw == null) continue;
        final endTime = endTimeRaw is Timestamp
            ? endTimeRaw.toDate()
            : (endTimeRaw is DateTime ? endTimeRaw : null);
        if (endTime == null) continue;
        if (bestEnd == null || endTime.isAfter(bestEnd)) {
          best = data;
          bestEnd = endTime;
        }
      }
      return best;
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> streamRecentCompleted(
    String userId, {
    int limit = 365,
  }) {
    // SPEC-162 (2026-06-02): últimos N ayunos cerrados (isFasting=true,
    // endTime != null), ordenados por startTime desc. Filtro client-side.
    return _col(userId)
        .orderBy('startTime', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) {
      final out = <Map<String, dynamic>>[];
      for (final doc in snap.docs) {
        final data = Map<String, dynamic>.from(doc.data());
        if (data['isFasting'] != true) continue;
        if (data['endTime'] == null) continue;
        out.add(data);
      }
      return out;
    });
  }

  @override
  Future<void> updateOpenIntervalStartTime({
    required String userId,
    required DateTime newStartTime,
    bool? isFastingFilter,
  }) async {
    // SPEC-97 + SPEC-100: buscar intervalos abiertos y mutar startTime.
    Query<Map<String, dynamic>> q =
        _col(userId).where('endTime', isNull: true);
    if (isFastingFilter != null) {
      q = q.where('isFasting', isEqualTo: isFastingFilter);
    }
    final openQuery = await q.get();

    if (openQuery.docs.isEmpty) {
      throw StateError(
        'No hay intervalo abierto que corregir (userId=$userId, '
        'isFastingFilter=$isFastingFilter).',
      );
    }

    final batch = _firestore.batch();
    for (final doc in openQuery.docs) {
      batch.update(doc.reference, {
        'startTime': Timestamp.fromDate(newStartTime),
      });
    }
    await batch.commit();
  }

  @override
  Future<String> closeAllOpenAndCreate({
    required String userId,
    required DateTime closeAt,
    required Map<String, dynamic> Function(String newDocId) buildNewData,
  }) async {
    final col = _col(userId);
    final batch = _firestore.batch();

    // 1. Cerrar todos los abiertos.
    final openQuery = await col.where('endTime', isNull: true).get();
    for (final doc in openQuery.docs) {
      batch.update(doc.reference, {
        'endTime': Timestamp.fromDate(closeAt),
      });
    }

    // 2. Crear el nuevo (id auto-generado en la subcolección del uid).
    final newDocRef = col.doc();
    final data = buildNewData(newDocRef.id);
    batch.set(newDocRef, data);

    await batch.commit();
    return newDocRef.id;
  }
}
