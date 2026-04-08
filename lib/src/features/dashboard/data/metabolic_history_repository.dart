import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MetabolicHistoryRepository {
  final FirebaseFirestore _firestore;

  MetabolicHistoryRepository(this._firestore);

  Stream<List<Map<String, dynamic>>> watchWeeklyHistory(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('metabolic_history')
        .orderBy('timestamp', descending: true)
        .limit(7)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => doc.data()).toList().reversed.toList();
    });
  }

  Future<void> saveDailyScore(String userId, double score) async {
    final dateId = DateTime.now().toIso8601String().split('T')[0];
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('metabolic_history')
        .doc(dateId)
        .set({
      'score': score,
      'day': _getWeekdayInitial(DateTime.now().weekday),
      'timestamp': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _getWeekdayInitial(int day) {
    const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
    return days[day - 1];
  }
}

// Provider con instancia directa para evitar el error de firebase_providers.dart
final metabolicHistoryRepositoryProvider = Provider((ref) {
  return MetabolicHistoryRepository(FirebaseFirestore.instance);
});