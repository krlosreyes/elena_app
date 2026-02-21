import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../authentication/data/auth_repository.dart';
import '../../plan/domain/health_plan.dart';
import '../domain/user_model.dart';
import '../../../core/exceptions/exceptions.dart';

part 'user_repository.g.dart';

class UserRepository {
  final FirebaseFirestore _firestore;

  UserRepository(this._firestore);

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

    await _usersCollection.doc(user.uid).set(userJson, SetOptions(merge: true));
  }

  /// Recupera los datos de un usuario por su UID.
  Future<UserModel?> getUser(String uid) async {
    final snapshot = await _usersCollection.doc(uid).get();
    if (snapshot.exists && snapshot.data() != null) {
      // Freezed generated fromJson handles standard types. 
      // Firestore Timestamps might need conversion if direct mapping fails, 
      // but json_serializable usually handles basic types. 
      // Si hay Timestamp, json_serializable standard puede fallar sin converters.
      // Ajuste: agregaremos lógica manual para timestamps si es necesario, 
      // pero por ahora confiamos en que freezed/json_serializable maneje DateTime.
      // Nota: Firestore devuelve Timestamp, Dart espera DateTime.
      // json_serializable tiene soporte básico, pero a veces requiere configuración.
      // Para asegurar, convertimos los Timestamps a DateTime en un mapa intermedio si falla.
      try {
        final data = snapshot.data()!;
        // Pequeño hack para asegurar compatibilidad de Timestamps si json_serializable no tiene los converters configurados
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['updatedAt'] is Timestamp) {
          data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['birthDate'] is Timestamp) {
           data['birthDate'] = (data['birthDate'] as Timestamp).toDate().toIso8601String();
        } else if (data['birthDate'] is String) {
           // Ya es string, ok.
        }

        return UserModel.fromJson(data);
      } catch (e) {
        print('Error deserializando User: $e');
        return null; // O lanzar excepción según el caso
      }
    }
    return null;
  }

  /// Stream del usuario para cambios en tiempo real
  Stream<UserModel?> watchUser(String uid) {
    return _usersCollection.doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
         final data = snapshot.data()!;
         // Misma lógica de conversión temporal
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['updatedAt'] is Timestamp) {
          data['updatedAt'] = (data['updatedAt'] as Timestamp).toDate().toIso8601String();
        }
        if (data['birthDate'] is Timestamp) {
           data['birthDate'] = (data['birthDate'] as Timestamp).toDate().toIso8601String();
        }
        return UserModel.fromJson(data);
      }
      return null;
    });
  }
  // Guardar Plan de Salud
  Future<void> saveHealthPlan(String uid, HealthPlan plan) async {
    try {
      await _usersCollection
          .doc(uid)
          .collection('plans')
          .add(plan.toJson());
    } catch (e) {
      throw UnknownException();
    }
  }
}

@Riverpod(keepAlive: true)
UserRepository userRepository(Ref ref) {
  return UserRepository(FirebaseFirestore.instance);
}

@riverpod
Future<UserModel?> user(Ref ref, String uid) {
  return ref.watch(userRepositoryProvider).getUser(uid);
}

@riverpod
Stream<UserModel?> userStream(Ref ref, String uid) {
  return ref.watch(userRepositoryProvider).watchUser(uid);
}

@riverpod
Stream<UserModel?> currentUser(Ref ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(userRepositoryProvider).watchUser(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (err, stack) => Stream.value(null),
  );
}
