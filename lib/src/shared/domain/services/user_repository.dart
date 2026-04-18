import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/dashboard/domain/sleep_log.dart';
import 'package:elena_app/src/features/dashboard/domain/hydration_log.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';

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
      if (user.id.isEmpty) throw Exception("UserID vacío — no se puede guardar");
      final docId = user.id;
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

  Stream<SleepLog?> watchLatestSleep(String userId) {
    return _usersCollection
        .doc(userId)
        .collection('sleep_history')
        .orderBy('wokeUp', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final data = snapshot.docs.first.data();
      return SleepLog(
        id: snapshot.docs.first.id,
        fellAsleep: (data['fellAsleep'] as Timestamp).toDate(),
        wokeUp: (data['wokeUp'] as Timestamp).toDate(),
        lastMealTime: (data['lastMealTime'] as Timestamp).toDate(),
      );
    });
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

  Stream<double> watchTodayHydration(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    return _usersCollection
        .doc(userId)
        .collection('hydration_history')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .snapshots()
        .map((snapshot) {
      double total = 0.0;
      for (var doc in snapshot.docs) {
        total += (doc.data()['amount'] as num).toDouble();
      }
      return total;
    });
  }

  // --- LÓGICA DE EJERCICIO (PILAR: ACTIVIDAD FÍSICA) ---

  Future<void> saveExerciseLog(String userId, ExerciseLog log) async {
    try {
      await _usersCollection
          .doc(userId)
          .collection('exercise_history')
          .doc(log.id)
          .set({
        'id': log.id,
        'userId': log.userId,
        'durationMinutes': log.durationMinutes,
        'activityType': log.activityType,
        'timestamp': Timestamp.fromDate(log.timestamp),
        'intensityMultiplier': log.intensityMultiplier,
        'createdAt': FieldValue.serverTimestamp(),
      });
      debugPrint("💪 Registro de ejercicio guardado: ${log.durationMinutes} min");
    } catch (e) {
      debugPrint("❌ Error en saveExerciseLog: $e");
      throw Exception("Fallo al guardar registro de ejercicio");
    }
  }

  Stream<int> watchTodayExercise(String userId) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    
    return _usersCollection
        .doc(userId)
        .collection('exercise_history')
        .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
        .snapshots()
        .map((snapshot) {
      int totalMinutes = 0;
      for (var doc in snapshot.docs) {
        final data = doc.data();
        totalMinutes += (data['durationMinutes'] as num).toInt();
      }
      return totalMinutes;
    });
  }

  // --- LÓGICA DE RACHAS (SPEC-06) ---

  /// Guarda o actualiza el registro de cumplimiento diario.
  /// Usa el campo [date] ('yyyy-MM-dd') como clave de documento.
  Future<void> saveStreakEntry(String userId, StreakEntry entry) async {
    try {
      await _usersCollection
          .doc(userId)
          .collection('streak_history')
          .doc(entry.date)
          .set(entry.toJson(), SetOptions(merge: true));
      debugPrint('🔥 StreakEntry guardado: ${entry.date} — ${entry.pillarsCompleted}/5');
    } catch (e) {
      debugPrint('❌ Error en saveStreakEntry: $e');
      throw Exception('Fallo al guardar racha');
    }
  }

  /// Stream de los últimos 30 días de historial de racha, ordenados por fecha desc.
  Stream<List<StreakEntry>> watchStreakHistory(String userId) {
    final cutoff = DateTime.now().subtract(const Duration(days: 30));
    final cutoffKey =
        '${cutoff.year.toString().padLeft(4, '0')}-'
        '${cutoff.month.toString().padLeft(2, '0')}-'
        '${cutoff.day.toString().padLeft(2, '0')}';

    return _usersCollection
        .doc(userId)
        .collection('streak_history')
        .where('date', isGreaterThanOrEqualTo: cutoffKey)
        .orderBy('date', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StreakEntry.fromJson(doc.data()))
            .toList());
  }

  /// Actualiza el ratio de adherencia semanal en el perfil del usuario.
  Future<void> updateWeeklyAdherence(String userId, double adherence) async {
    try {
      await _usersCollection.doc(userId).update({
        'weeklyAdherence': adherence,
      });
      debugPrint('📈 Adherencia semanal actualizada: $adherence');
    } catch (e) {
      debugPrint('❌ Error al actualizar adherencia: $e');
    }
  }

  /// Registra una sugerencia de protocolo en el historial.
  Future<void> saveProtocolAdjustment(String userId, Map<String, dynamic> adjustment) async {
    try {
      await _usersCollection
          .doc(userId)
          .collection('protocol_adjustments')
          .add({
        ...adjustment,
        'timestamp': FieldValue.serverTimestamp(),
      });
      debugPrint('📝 Ajuste de protocolo registrado en historial.');
    } catch (e) {
      debugPrint('❌ Error al registrar ajuste: $e');
    }
  }

  /// Aplica el cambio de protocolo físicamente en el perfil.
  Future<void> applyProtocolAdjustment(String userId, {
    String? newFastingProtocol,
    int? newExerciseGoal,
  }) async {
    try {
      final Map<String, dynamic> updates = {};
      if (newFastingProtocol != null) updates['fastingProtocol'] = newFastingProtocol;
      if (newExerciseGoal != null) updates['exerciseGoalMinutes'] = newExerciseGoal;

      if (updates.isNotEmpty) {
        await _usersCollection.doc(userId).update(updates);
        debugPrint('✅ Protocolo actualizado en perfil: $updates');
      }
    } catch (e) {
      debugPrint('❌ Error al aplicar protocolo: $e');
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