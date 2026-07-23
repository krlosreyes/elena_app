// Módulo "Tu Glucosa" — implementación Firestore (propuesta §8/§9).
//
// Schema:
//   users/{uid}/glucose_readings/{readingId} — colección de eventos
//     históricos, un documento por lectura (a diferencia de
//     exercise_meta/profile que es un documento único — acá cada
//     lectura es un evento, más parecido a fasting_history).
//   users/{uid}/glucose_meta/protocol — documento único con el estado
//     del protocolo, mismo patrón que exercise_meta/profile.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/glucose/domain/glucose_protocol_state.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_reading.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_repository.dart';

class GlucoseRepositoryImpl implements GlucoseRepository {
  final FirebaseFirestore _firestore;

  GlucoseRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _readingsCol(String userId) =>
      _firestore.collection('users').doc(userId).collection('glucose_readings');

  DocumentReference<Map<String, dynamic>> _protocolDoc(String userId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection('glucose_meta')
          .doc('protocol');

  @override
  Future<String> saveReading(String userId, GlucoseReading reading) async {
    final doc = await _readingsCol(userId).add(reading.toMap());
    return doc.id;
  }

  @override
  Future<List<GlucoseReading>> fetchReadings(
    String userId, {
    int days = 90,
  }) async {
    final since = DateTime.now().subtract(Duration(days: days));
    final snap = await _readingsCol(userId)
        .where('measuredAt', isGreaterThanOrEqualTo: since.toIso8601String())
        .orderBy('measuredAt', descending: true)
        .get();
    return snap.docs
        .map((d) => GlucoseReading.fromMap(d.id, d.data()))
        .toList();
  }

  @override
  Stream<List<GlucoseReading>> watchReadings(
    String userId, {
    int days = 90,
  }) {
    final since = DateTime.now().subtract(Duration(days: days));
    return _readingsCol(userId)
        .where('measuredAt', isGreaterThanOrEqualTo: since.toIso8601String())
        .orderBy('measuredAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => GlucoseReading.fromMap(d.id, d.data()))
            .toList());
  }

  @override
  Future<GlucoseProtocolState?> fetchProtocolState(String userId) async {
    final snap = await _protocolDoc(userId).get();
    final data = snap.data();
    if (data == null) return null;
    return GlucoseProtocolState.fromMap(data);
  }

  @override
  Future<void> saveProtocolState(
    String userId,
    GlucoseProtocolState state,
  ) async {
    await _protocolDoc(userId).set(state.toMap(), SetOptions(merge: true));
  }

  @override
  Stream<GlucoseProtocolState?> watchProtocolState(String userId) {
    return _protocolDoc(userId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return null;
      return GlucoseProtocolState.fromMap(data);
    });
  }
}

final glucoseRepositoryProvider = Provider<GlucoseRepository>((ref) {
  return GlucoseRepositoryImpl();
});
