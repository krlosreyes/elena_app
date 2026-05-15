// SPEC-50.4: implementación Firestore v1 del FastingIntervalDataSource.
//
// Schema legacy: colección flat `fasting_history/{docId}` con `userId`
// como campo del doc. Distinto del resto de pilares que usan
// `users/{uid}/...`. Decisión histórica preservada — esta SPEC envuelve
// el schema, no lo migra.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/dashboard/data/sources/fasting_interval_data_source.dart';

class FirestoreFastingIntervalV1Source implements FastingIntervalDataSource {
  final FirebaseFirestore _firestore;

  FirestoreFastingIntervalV1Source({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('fasting_history');

  @override
  Stream<Map<String, dynamic>?> streamLatest(String userId) {
    // SPEC-99: "más reciente" no es "startTime mayor" — es "intervalo
    // abierto si hay uno; si no, el último cerrado".
    //
    // Antes ordenábamos sólo por startTime descending y limit 1. Si el
    // usuario corregía la hora de inicio del ayuno HACIA ATRÁS (caso
    // común con SPEC-97), su `startTime` quedaba menor al de otros
    // docs históricos y el snapshot devolvía un doc cerrado viejo —
    // el listener marcaba `isActive=false` y abría ventana de comida
    // fantasma.
    //
    // Solución: traemos los últimos 5 docs por startTime y en cliente
    // priorizamos el primero que esté abierto (endTime==null). Si
    // ninguno está abierto, devolvemos el más reciente por startTime.
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .limit(5)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;

      // SPEC-100: prioridad explícita entre abiertos.
      // (a) Ayuno abierto (isFasting=true, endTime=null) — gana siempre.
      // (b) Si no hay ayuno abierto, cualquier otro abierto (ventana
      //     de comida en curso, en data sana).
      // (c) Si no hay nada abierto, el más reciente cerrado.
      //
      // Esto blinda el caso de data corrupta donde haya un ayuno y
      // una ventana fantasma simultáneamente abiertos: gana el ayuno
      // y el listener pinta el state correcto.
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data['endTime'] == null && data['isFasting'] == true) {
          return data;
        }
      }
      for (final doc in snap.docs) {
        if (doc.data()['endTime'] == null) {
          return doc.data();
        }
      }
      return snap.docs.first.data();
    });
  }

  @override
  Stream<Map<String, dynamic>?> streamLastCompletedFasting(String userId) {
    // SPEC-101 / SPEC-113.bugfix: último ayuno cerrado (endTime != null,
    // isFasting=true).
    //
    // ANTES: combinábamos where('userId') + where('isFasting') +
    // orderBy('endTime', desc). Requiere un índice compuesto que
    // probablemente NO está desplegado en Firebase, así que la query
    // fallaba con `failed-precondition` y el stream nunca emitía →
    // el satélite Ayuno caía a 0% al reabrir la app.
    //
    // AHORA: usamos solo where('userId') + orderBy('startTime', desc)
    // — el mismo índice que `streamLatest` ya consume — y filtramos
    // client-side los docs cerrados de tipo ayuno. Sin índices nuevos.
    return _collection
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .limit(20)
        .snapshots()
        .map((snap) {
      if (snap.docs.isEmpty) return null;
      Map<String, dynamic>? best;
      DateTime? bestEnd;
      for (final doc in snap.docs) {
        final data = doc.data();
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
  Future<void> updateOpenIntervalStartTime({
    required String userId,
    required DateTime newStartTime,
    bool? isFastingFilter,
  }) async {
    // SPEC-97 + SPEC-100: buscamos intervalos abiertos del usuario y
    // les mutamos el startTime. Si `isFastingFilter` está presente,
    // solo afectamos docs con ese tipo (evita pisar ventanas fantasma
    // cuando se corrige un ayuno).
    Query<Map<String, dynamic>> q = _collection
        .where('userId', isEqualTo: userId)
        .where('endTime', isNull: true);
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
    final batch = _firestore.batch();

    // 1. Buscar todos los abiertos para cerrarlos.
    final openQuery = await _collection
        .where('userId', isEqualTo: userId)
        .where('endTime', isNull: true)
        .get();

    for (final doc in openQuery.docs) {
      batch.update(doc.reference, {
        'endTime': Timestamp.fromDate(closeAt),
      });
    }

    // 2. Crear el nuevo (id auto-generado).
    final newDocRef = _collection.doc();
    final data = buildNewData(newDocRef.id);
    batch.set(newDocRef, data);

    await batch.commit();
    return newDocRef.id;
  }
}
