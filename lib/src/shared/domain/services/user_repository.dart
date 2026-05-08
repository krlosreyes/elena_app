import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

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
        } catch (e, stackTrace) {
          AppLogger.error('Error parseando UserModel', e, stackTrace);
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
    } catch (e, stackTrace) {
      AppLogger.error('Error saveUser', e, stackTrace);
      throw Exception("Fallo en sincronización metabólica");
    }
  }

  // SPEC-50: lógica de sueño extraída a SleepRepository
  // (lib/src/features/dashboard/data/sleep_repository_impl.dart).
  // Notifiers consumen `sleepRepositoryProvider` en lugar de los
  // métodos que vivían aquí.

  // SPEC-50.1: lógica de hidratación extraída a HydrationRepository
  // (lib/src/features/dashboard/data/hydration_repository_impl.dart).
  // Notifiers consumen `hydrationRepositoryProvider`.

  // SPEC-50.2: lógica de ejercicio extraída a ExerciseRepository
  // (lib/src/features/exercise/data/exercise_repository_impl.dart).
  // Notifiers consumen `exerciseRepositoryProvider`.

  // SPEC-50.3: lógica del historial de racha extraída a StreakRepository
  // (lib/src/features/streak/data/streak_repository_impl.dart).
  // Notifiers consumen `streakRepositoryProvider`. Las operaciones de
  // configuración del usuario (weeklyAdherence, protocol adjustments)
  // que vivían bajo "racha" se quedan abajo — su dominio real es
  // perfil de usuario, no streak. SPEC-50.5 las moverá al
  // UserProfileRepository final.

  // --- PERFIL DEL USUARIO: configuración y adherencia agregada ---

  /// Actualiza el ratio de adherencia semanal en el perfil del usuario.
  Future<void> updateWeeklyAdherence(String userId, double adherence) async {
    try {
      await _usersCollection.doc(userId).update({
        'weeklyAdherence': adherence,
      });
      AppLogger.debug('Adherencia semanal actualizada: $adherence');
    } catch (e, stackTrace) {
      AppLogger.error('Error al actualizar adherencia', e, stackTrace);
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
      AppLogger.debug('Ajuste de protocolo registrado en historial.');
    } catch (e, stackTrace) {
      AppLogger.error('Error al registrar ajuste', e, stackTrace);
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
        AppLogger.debug('Protocolo actualizado en perfil: $updates');
      }
    } catch (e, stackTrace) {
      AppLogger.error('Error al aplicar protocolo', e, stackTrace);
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
      AppLogger.debug(
        'Sincronización manual: ${isFasting ? 'AYUNO' : 'VENTANA'} '
        'desde ${effectiveTime.toString()}',
      );
    } catch (e, stackTrace) {
      AppLogger.error('Error en startNewInterval', e, stackTrace);
      rethrow;
    }
  }
}