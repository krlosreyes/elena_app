import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; // IMPORTACIÓN NECESARIA PARA debugPrint
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

/// Proveedor global para el repositorio de usuarios
final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

class UserRepository {
  UserRepository();

  FirebaseFirestore get _firestore => FirebaseFirestore.instance;

  /// Colección principal de usuarios
  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Escucha cambios en tiempo real con manejo de errores para Web
  Stream<UserModel?> watchUser(String userId) {
    return _usersCollection.doc(userId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserModel.fromJson(snapshot.data()!);
      }
      return null;
    }).handleError((error) {
      // Ahora debugPrint funcionará correctamente
      debugPrint("⚠️ Firestore Stream Error: $error");
      return null; 
    });
  }

  /// Recupera el perfil del usuario (One-time get)
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

  /// Guarda o actualiza el perfil del usuario
  Future<void> saveUser(UserModel user) async {
    try {
      await _usersCollection.doc(user.id.isEmpty ? null : user.id).set(
        user.toJson(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint("❌ Error saveUser: $e");
      throw Exception("Error al persistir usuario");
    }
  }
}