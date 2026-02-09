import 'package:cloud_firestore/cloud_firestore.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/fasting_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FastingRepository {
  final FirebaseFirestore _firestore;

  FastingRepository(this._firestore);

  Future<void> startFast(String uid, FastingSession session) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('fasting_history')
          .add(session.toJson());
      print('✅ Ayuno iniciado guardado en Firestore.');
    } catch (e) {
      print('❌ Error al iniciar ayuno en Firestore: $e');
      rethrow;
    }
  }

  Future<void> saveCompletedFast(String uid, FastingSession session) async {
    print('🔥 Intentando guardar/actualizar ayuno en Firestore...');
    
    try {
      final colRef = _firestore.collection('users').doc(uid).collection('fasting_history');
      
      // Buscar si hay un ayuno activo para cerrarlo
      final activeSnapshot = await colRef
          .where('isCompleted', isEqualTo: false)
          .limit(1)
          .get();

      if (activeSnapshot.docs.isNotEmpty) {
        // ACTUALIZAR el existente
        final docId = activeSnapshot.docs.first.id;
        await colRef.doc(docId).update(session.toJson());
        print('✅ Ayuno existente actualizado a completado.');
      } else {
        // Si no existe (ej: ayuno manual retroactivo), CREAR uno nuevo
         await colRef.add(session.toJson());
         print('✅ Ayuno completado (nuevo) guardado en Firestore.');
      }

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
