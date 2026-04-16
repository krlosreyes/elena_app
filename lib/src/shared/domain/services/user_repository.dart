import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';
import 'package:elena_app/src/features/dashboard/domain/hydration_log.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  return UserRepository();
});

class UserRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _usersCollection =>
      _firestore.collection('users');

  CollectionReference<Map<String, dynamic>> get _historyCollection =>
      _firestore.collection('fasting_history');

  // --- MÉTODOS DE USUARIO ---

  Stream<UserModel?> watchUser(String userId) {
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
    });
  }

  Future<void> saveUser(UserModel user) async {
    try {
      final docId = user.id.isEmpty ? 'carlos_01' : user.id;
      await _usersCollection.doc(docId).set(
        user.toJson(),
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint("❌ Error saveUser: $e");
      throw Exception("Fallo en sincronización metabólica");
    }
  }

  // --- LÓGICA DE SUEÑO (PILAR: RECUPERACIÓN) ---

  Future<void> saveSleepLog(String userId, SleepLog log) async {
    try {
      await _usersCollection
          .doc(userId)
          .collection('sleep_history')
          .doc(log.id)
          .set({
        'fellAsleep': Timestamp.fromDate(log.fellAsleep),
        'wokeUp': Timestamp.fromDate(log.wokeUp),
        'lastMealTime': Timestamp.fromDate(log.lastMealTime),
        'durationMinutes': log.duration.inMinutes,
        'metabolicGapMinutes': log.metabolicGap.inMinutes,
        'recoveryStatus': log.recoveryStatus,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint("🌙 Registro de sueño guardado: ${log.id}");
    } catch (e) {
      debugPrint("❌ Error en saveSleepLog: $e");
      throw Exception("Fallo al guardar registro de sueño");
    }
  }

  // --- LÓGICA DE HIDRATACIÓN (PILAR: SOLVENTE METABÓLICO) ---

  Future<void> saveHydrationLog(String userId, HydrationLog log) async {
    try {
      await _usersCollection
          .doc(userId)
          .collection('hydration_history')
          .add({
        'amount': log.amountInLiters,
        'timestamp': Timestamp.fromDate(log.timestamp),
        'type': log.type,
        'serverAt': FieldValue.serverTimestamp(),
      });
      debugPrint("💧 Registro de hidratación sincronizado: ${log.amountInLiters}L");
    } catch (e) {
      debugPrint("❌ Error en saveHydrationLog: $e");
      throw Exception("Error de persistencia en hidratación");
    }
  }

  // --- LÓGICA DE HISTORIAL (EL MOTOR DE LAS COORDENADAS) ---

  Stream<FastingInterval?> watchLastInterval(String userId) {
    return _historyCollection
        .where('userId', isEqualTo: userId)
        .orderBy('startTime', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return FastingInterval.fromJson(snapshot.docs.first.data());
      }
      return null;
    });
  }

  /// Inicia un nuevo hito metabólico respetando fechas manuales para pruebas.
  Future<void> startNewInterval(String userId, bool isFasting, {DateTime? startTime}) async {
    final effectiveTime = startTime ?? DateTime.now();
    final batch = _firestore.batch();

    try {
      // 1. Buscamos CUALQUIER intervalo abierto para cerrarlo con el effectiveTime
      // Esto evita solapamientos si estás forzando fechas pasadas
      final activeQuery = await _historyCollection
          .where('userId', isEqualTo: userId)
          .where('endTime', isNull: true)
          .get();

      for (var doc in activeQuery.docs) {
        batch.update(doc.reference, {
          'endTime': Timestamp.fromDate(effectiveTime),
        });
      }

      // 2. Creamos el nuevo hito (Ayuno o Ventana)
      final newDocRef = _historyCollection.doc();
      final newInterval = FastingInterval(
        id: newDocRef.id,
        userId: userId,
        startTime: effectiveTime,
        isFasting: isFasting,
      );

      batch.set(newDocRef, newInterval.toJson());
      
      await batch.commit();
      debugPrint("🚀 Sincronización manual: ${isFasting ? 'AYUNO' : 'VENTANA'} desde ${effectiveTime.toString()}");
    } catch (e) {
      debugPrint("❌ Error en startNewInterval: $e");
      rethrow;
    }
  }
}