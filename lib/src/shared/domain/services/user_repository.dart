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

  // SPEC-50.4: lógica de intervalos de ayuno extraída a
  // FastingIntervalRepository (lib/src/features/dashboard/data/
  // fasting_interval_repository_impl.dart). Notifiers consumen
  // `fastingIntervalRepositoryProvider`. La operación atómica
  // close-and-create vive en el data source para preservar
  // consistencia transaccional.
}