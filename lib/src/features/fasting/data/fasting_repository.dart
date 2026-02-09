import 'package:cloud_firestore/cloud_firestore.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/fasting_session.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class FastingRepository {
  final FirebaseFirestore _firestore;
  final String? uid;

  FastingRepository(this._firestore, this.uid);

  Future<void> saveCompletedFast(FastingSession session) async {
    print('🔥 Intentando guardar ayuno en Firestore...');
    
    if (uid == null) {
        print('❌ Error: Usuario no autenticado. No se puede guardar ayuno.');
        return;
    }

    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('fasting_history') // 'fasts' or 'fasting_history'? Request said 'users/{uid}/fasts', check existing usage/request. Request said "Verificar la ruta de colección: users/{uid}/fasts". 
          // Wait, Prompt says: "Verificar la ruta de colección: users/{uid}/fasts". 
          // Previous controller code used 'fasting_history'. I will use 'fasts' as requested in the specific instructions.
          .add(session.toJson());
          
      print('✅ Ayuno guardado correctamente en Firestore.');
    } catch (e) {
      print('❌ Error al guardar ayuno en Firestore: $e');
      rethrow;
    }
  }
}

final fastingRepositoryProvider = Provider<FastingRepository>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  return FastingRepository(FirebaseFirestore.instance, user?.uid);
});
