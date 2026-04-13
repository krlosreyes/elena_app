import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/features/auth/domain/auth_repository.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Stream<UserModel?> get authStateChanges => _auth.authStateChanges().asyncMap((user) async {
    if (user == null) return null;
    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (doc.exists) {
      return UserModel.fromJson(doc.data()!);
    }
    return null;
  });

  @override
  Future<UserModel> signUpWithEmail({
    required String email,
    required String password,
    required String name,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      
      final newUser = UserModel(
        id: credential.user!.uid,
        name: name,
        age: 0,
        gender: 'M',
        weight: 0.0,
        height: 0,
        profile: CircadianProfile(
          wakeUpTime: DateTime.now(),
          sleepTime: DateTime.now(),
          firstMealGoal: DateTime.now(),
          lastMealGoal: DateTime.now(),
        ),
      );

      await _firestore.collection('users').doc(newUser.id).set(newUser.toJson());
      return newUser;
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<UserModel> signInWithEmail({required String email, required String password}) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email, 
        password: password
      );
      final doc = await _firestore.collection('users').doc(credential.user!.uid).get();
      if (!doc.exists) throw Exception("Perfil no encontrado.");
      return UserModel.fromJson(doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  @override
  Future<void> signOut() => _auth.signOut();

  @override
  Future<void> sendPasswordResetEmail(String email) => _auth.sendPasswordResetEmail(email: email);

  @override
  Future<bool> isUserOnboarded(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data();
      return (data?['age'] ?? 0) > 0 && (data?['weight'] ?? 0) > 0;
    }
    return false;
  }

  // IMPLEMENTACIÓN REAL DE ELIMINACIÓN
  @override
  Future<void> deleteAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final uid = user.uid;

      // 1. Borrar rastro en Firestore
      await _firestore.collection('users').doc(uid).delete();

      // 2. Borrar de Auth
      await user.delete();
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        throw Exception("Seguridad: Por favor re-inicia sesión antes de eliminar tu cuenta.");
      }
      throw _handleAuthException(e);
    } catch (e) {
      throw Exception("Error técnico al eliminar cuenta.");
    }
  }

  Exception _handleAuthException(FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password': return Exception('Contraseña débil.');
      case 'email-already-in-use': return Exception('Email ya registrado.');
      case 'user-not-found':
      case 'wrong-password': return Exception('Credenciales incorrectas.');
      default: return Exception('Error crítico de autenticación.');
    }
  }
}