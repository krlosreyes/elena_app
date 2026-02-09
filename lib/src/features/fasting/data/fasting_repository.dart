import 'package:cloud_firestore/cloud_firestore.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/fasting_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FastingRepository {
  final FirebaseFirestore _firestore;

  FastingRepository(this._firestore);

  Future<void> saveCompletedFast(String uid, FastingSession session) async {
    print('🔥 Intentando guardar ayuno en Firestore...');
    
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('fasting_history') 
          .add(session.toJson());
          
      print('✅ Ayuno guardado correctamente en Firestore.');
    } catch (e) {
      print('❌ Error al guardar ayuno en Firestore: $e');
      rethrow;
    }
  }

  Stream<List<FastingSession>> getHistoryStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('fasting_history')
        .orderBy('startTime', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => FastingSession.fromJson(doc.data()))
            .toList());
  }

  // Active Fast Stream (by UID)
  Stream<FastingSession?> getActiveFastStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('fasting_history') 
        .where('isCompleted', isEqualTo: false) 
        .limit(1)
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return FastingSession.fromJson(snapshot.docs.first.data());
        });
  }
}

final fastingRepositoryProvider = Provider<FastingRepository>((ref) {
  return FastingRepository(FirebaseFirestore.instance);
});
