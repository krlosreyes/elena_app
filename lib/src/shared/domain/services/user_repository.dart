import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ajuste a la colección raíz según tu arquitectura de Ecosistema
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Escucha en tiempo real (Crítico para el IMR Score dinámico)
  Stream<UserModel?> watchUser(String userId) {
    // Usamos el ID específico 'carlos_01' que ya tienes en nam5
    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        try {
          return UserModel.fromJson(snapshot.data()!);
        } catch (e) {
          debugPrint("❌ Error parseando UserModel: $e");
          return null;
        }
      }
      return null;
    }).handleError((error) {
      debugPrint("⚠️ Firestore Stream Error: $error");
      return null; 
    });
  }

  /// Recupera el perfil (Útil para inicializaciones rápidas)
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _usersCollection.doc(userId).get();
      if (doc.exists && doc.data() != null) {
        return UserModel.fromJson(doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint("❌ Error getUser: $e");
      return null;
    }
  }

  /// Guarda el perfil y asegura la persistencia del metabolismo
  Future<void> saveUser(UserModel user) async {
    try {
      // Si el ID viene vacío, Firestore generará uno, pero preferimos carlos_01 para el MVP
      final docId = user.id.isEmpty ? 'carlos_01' : user.id;
      
      await _usersCollection.doc(docId).set(
        user.toJson(),
        SetOptions(merge: true),
      );
      debugPrint("✅ Usuario ${user.name} sincronizado en nam5");
    } catch (e) {
      debugPrint("❌ Error saveUser: $e");
      throw Exception("Fallo en sincronización metabólica");
    }
  }
}