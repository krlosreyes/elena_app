// SPEC-14: Objetivos del Usuario
// Repositorio de persistencia Firestore para los objetivos.
// Guarda los goals como campo 'goals' dentro del documento existente users/{uid}.
// Usa SetOptions(merge: true) para no sobreescribir otros campos del usuario.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/goals/domain/goal_repository.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';

// ARCH-05 (auditoría 2026-07-11): implementación Firestore del contrato
// `GoalRepository` (domain/goal_repository.dart). Renombrada a `Impl`
// porque el único sitio que instanciaba la clase concreta era el
// provider de este mismo archivo — seguro de renombrar sin tocar otros
// consumidores (verificado con grep, ver informe de la tarea).
class GoalRepositoryImpl implements GoalRepository {
  const GoalRepositoryImpl(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _firestore.collection('users').doc(userId);

  // ─── Escritura ────────────────────────────────────────────────────────────

  /// Persiste el mapa completo de goals para el usuario.
  /// Usa merge para no tocar el resto de campos de UserModel.
  @override
  Future<void> saveGoals(
    String userId,
    Map<GoalType, UserGoal> goals,
  ) async {
    final Map<String, dynamic> serialized = {
      for (final entry in goals.entries) entry.key.name: entry.value.toJson(),
    };

    await _userDoc(userId).set(
      {'goals': serialized},
      SetOptions(merge: true),
    );
  }

  // ─── Lectura ──────────────────────────────────────────────────────────────

  /// Stream que emite el mapa de goals cada vez que cambia en Firestore.
  @override
  Stream<Map<GoalType, UserGoal>> watchGoals(String userId) {
    return _userDoc(userId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return {};

      final rawGoals = data['goals'] as Map<String, dynamic>?;
      if (rawGoals == null) return {};

      final Map<GoalType, UserGoal> result = {};
      for (final entry in rawGoals.entries) {
        try {
          final goal = UserGoal.fromJson(entry.value as Map<String, dynamic>);
          result[goal.type] = goal;
        } catch (_) {
          // Ignorar entradas corruptas
        }
      }
      return result;
    });
  }

  /// Lee los goals una sola vez (útil para inicialización).
  @override
  Future<Map<GoalType, UserGoal>> fetchGoals(String userId) async {
    final snap = await _userDoc(userId).get();
    final data = snap.data();
    if (data == null) return {};

    final rawGoals = data['goals'] as Map<String, dynamic>?;
    if (rawGoals == null) return {};

    final Map<GoalType, UserGoal> result = {};
    for (final entry in rawGoals.entries) {
      try {
        final goal = UserGoal.fromJson(entry.value as Map<String, dynamic>);
        result[goal.type] = goal;
      } catch (e) {
        // SPEC-237 BUG-C: catch vacío silenciaba parse errors de goals.
        // Si Firestore tiene un doc con schema antiguo o campo desconocido,
        // ahora queda traza para diagnóstico. El goal se omite pero no se
        // rompe la carga del resto.
        AppLogger.warning('[GoalRepository] goal inválido key=${entry.key}: $e');
      }
    }
    return result;
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepositoryImpl(FirebaseFirestore.instance);
});
