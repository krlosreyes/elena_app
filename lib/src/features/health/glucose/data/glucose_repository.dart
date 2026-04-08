import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/health/glucose/domain/glucose_model.dart';

class GlucoseRepository {
  final FirebaseFirestore _firestore;

  GlucoseRepository(this._firestore);

  // STATELESS: UID is passed as argument
  Future<void> addLog({required String uid, required GlucoseLog log}) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('glucose_logs')
          .add(log.toMap());
    } catch (e) {
      throw Exception('Error adding glucose log: $e');
    }
  }

  Stream<List<GlucoseLog>> getGlucoseLogs({
    required String uid,
    required DateTime startDate,
  }) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('glucose_logs')
        .where('timestamp',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => GlucoseLog.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<GlucoseLog?> getLatestGlucoseLog(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('glucose_logs')
        .orderBy('timestamp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return GlucoseLog.fromMap(
            snapshot.docs.first.data(), snapshot.docs.first.id);
      }
      return null;
    });
  }
}

final glucoseRepositoryProvider = Provider<GlucoseRepository>((ref) {
  return GlucoseRepository(FirebaseFirestore.instance);
});
