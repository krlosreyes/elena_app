import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/health_plan.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/domain/models/user_food_preferences.dart';
import '../../../core/exceptions/exceptions.dart';

class UserRepository {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  UserRepository(this._firestore, this._firebaseAuth);

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  /// Guarda o actualiza los datos del usuario en Firestore.
  /// Usa merge: true para no sobrescribir campos no enviados si fuera el caso,
  /// aunque aquí enviamos el objeto completo.
  Future<void> saveUser(UserModel user) async {
    // Convertimos a JSON y aseguramos que updatedAt sea el momento actual
    final userJson = user.toJson();
    userJson['updatedAt'] = FieldValue.serverTimestamp();

    // Si createdAt es nulo (nuevo usuario), lo seteamos
    if (user.createdAt == null) {
      userJson['createdAt'] = FieldValue.serverTimestamp();
    }

    debugPrint('💾 Repo: Guardando usuario ${user.uid} en Firestore...');
    await _usersCollection.doc(user.uid).set(userJson, SetOptions(merge: true));
  }

  /// Recupera el usuario actual sincronamente (si existe en auth)
  UserModel? getCurrentUserSync() {
    // Nota: El repo es stateless, esto es solo una ayuda
    // En una implementación real, se podría cachear el último user visto
    return null;
  }

  /// Recupera los datos de un usuario por su UID.
  Future<UserModel?> getUser([String? uid]) async {
    final targetUid = uid ?? _firebaseAuth.currentUser?.uid;
    if (targetUid == null) return null;

    try {
      final doc = await _usersCollection.doc(targetUid).get();
      if (!doc.exists || doc.data() == null) return null;
      return UserModel.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('Error deserializando User ($targetUid): $e');
      return null;
    }
  }

  /// Stream del usuario para cambios en tiempo real
  Stream<UserModel?> watchUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        try {
          return UserModel.fromJson(snapshot.data()!);
        } catch (e, stackTrace) {
          debugPrint('❌ UserRepository: Error mapeando UserModel ($uid) -> $e');
          debugPrint(stackTrace.toString());
          rethrow;
        }
      }
      return null;
    });
  }

  // Guardar Plan de Salud
  Future<void> saveHealthPlan(String uid, HealthPlan plan) async {
    try {
      await _usersCollection.doc(uid).collection('plans').add(plan.toJson());
    } catch (e) {
      throw UnknownException();
    }
  }

  /// Recupera el plan activo del usuario en tiempo real.
  Stream<Map<String, dynamic>?> userActivePlanStream(String uid) {
    return _usersCollection
        .doc(uid)
        .collection('plans')
        .doc('current')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return snapshot.data();
      }
      return null;
    });
  }

  /// Actualiza campos específicos de un usuario.
  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    final updateData = Map<String, dynamic>.from(data);
    updateData['updatedAt'] = FieldValue.serverTimestamp();
    await _usersCollection.doc(uid).update(updateData);
  }

  /// Registra una nueva entrada de medidas corporales y actualiza el usuario.
  Future<void> saveBodyLog(String uid, Map<String, double> metrics) async {
    final logData = Map<String, dynamic>.from(metrics);
    logData['userId'] = uid;
    logData['date'] = FieldValue.serverTimestamp();

    // 1. Guardar en el histórico
    await _usersCollection.doc(uid).collection('body_logs').add(logData);

    // 2. Actualizar el documento principal del usuario para sincronización inmediata
    final userUpdates = <String, dynamic>{
      'waistCircumferenceCm': metrics['cintura'],
      'hipCircumferenceCm': metrics['cadera'],
      'neckCircumferenceCm': metrics['cuello'],
      'currentWeightKg': metrics['peso'],
      'estimated_fat_percentage': metrics['grasa'],
      'estimated_muscle_percentage': metrics['musculo'],
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _usersCollection.doc(uid).update(userUpdates);
  }

  /// Stream del historial de medidas corporales (últimos 2 docs)
  Stream<List<Map<String, dynamic>>> bodyLogsStream(String uid) {
    return _usersCollection
        .doc(uid)
        .collection('body_logs')
        .orderBy('date', descending: true)
        .limit(2)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  /// Registra el momento de la primera comida del día (romper ayuno).
  Future<void> recordFirstMeal(String uid, String option, DateTime time) async {
    await _usersCollection.doc(uid).update({
      'lastFirstMealTime': Timestamp.fromDate(time),
      'lastBreakingFastOption': option,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream de los datos "crudos" del usuario.
  Stream<Map<String, dynamic>?> watchUserRaw(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      return snapshot.data();
    });
  }

  /// Guarda las preferencias alimentarias del usuario.
  Future<void> saveUserFoodPreferences(
      String uid, UserFoodPreferences prefs) async {
    debugPrint('Repo: Guardando preferencias para $uid a Firestore...');
    try {
      await _usersCollection
          .doc(uid)
          .collection('user_food_preferences')
          .doc('current')
          .set(prefs.toJson());
      debugPrint('Repo: Guardado exitoso en Firebase.');
    } catch (e) {
      debugPrint('Repo: Error fatal guardando preferencias: $e');
      rethrow;
    }
  }

  /// Recupera las preferencias alimentarias del usuario.
  Future<UserFoodPreferences> getUserFoodPreferences(String uid) async {
    final snapshot = await _usersCollection
        .doc(uid)
        .collection('user_food_preferences')
        .doc('current')
        .get();

    if (snapshot.exists && snapshot.data() != null) {
      return UserFoodPreferences.fromJson(snapshot.data()!);
    }
    return UserFoodPreferences.empty();
  }

  /// Watch preferences in real-time.
  Stream<UserFoodPreferences> watchUserFoodPreferences(String uid) {
    return _usersCollection
        .doc(uid)
        .collection('user_food_preferences')
        .doc('current')
        .snapshots()
        .map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return UserFoodPreferences.fromJson(snapshot.data()!);
      }
      return UserFoodPreferences.empty();
    });
  }

  /// Elimina completamente los datos del usuario de Firestore.
  /// Paraleliza el borrado de subcolecciones para mayor eficiencia.
  Future<void> deleteUser(String uid) async {
    final userDoc = _usersCollection.doc(uid);

    // 1. Borrar subcolecciones conocidas
    final subcollections = [
          'plans',
          'user_food_preferences',
          'daily_logs',
          'current_status',
          'fasting_history',
          'meals',
          'nutrition',
          'workouts',
          'sleep_logs',
          'measurements',
        ];

    await Future.wait(subcollections.map((sub) async {
      try {
        final snapshot = await userDoc.collection(sub).get().timeout(
              const Duration(seconds: 5),
              onTimeout: () =>
                  throw Exception('Timeout reading subcollection $sub'),
            );

        final deleteOps = snapshot.docs.map((doc) => doc.reference.delete());
        await Future.wait(deleteOps);
      } catch (e) {
        debugPrint('⚠️ Error limpiando subcolección $sub para $uid: $e');
        // Continuamos para intentar borrar el documento principal al menos
      }
    }));

    // 2. Borrar el documento principal
    debugPrint('🗑️ Repo: Borrando documento principal users/$uid');
    await userDoc.delete();
  }
}

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository(FirebaseFirestore.instance, FirebaseAuth.instance);
});

// currentUserStreamProvider movido a user_controller.dart para consistencia arquitectónica

final userFutureProvider =
    FutureProvider.family.autoDispose<UserModel?, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).getUser(uid);
});

final userStreamProvider =
    StreamProvider.family.autoDispose<UserModel?, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).watchUser(uid);
});

final userFoodPreferencesProvider =
    StreamProvider.family.autoDispose<UserFoodPreferences, String>((ref, uid) {
  return ref.watch(userRepositoryProvider).watchUserFoodPreferences(uid);
});
