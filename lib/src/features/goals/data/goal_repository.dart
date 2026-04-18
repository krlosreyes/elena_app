// SPEC-14: Objetivos del Usuario
// Repositorio de persistencia Firestore para los objetivos.
// Guarda los goals como campo 'goals' dentro del documento existente users/{uid}.
// Usa SetOptions(merge: true) para no sobreescribir otros campos del usuario.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';

class GoalRepository {
  const GoalRepository(this._firestore);

  final FirebaseFirestore _firestore;

  DocumentReference<Map<String, dynamic>> _userDoc(String userId) =>
      _firestore.collection('users').doc(userId);

  // ─── Escritura ────────────────────────────────────────────────────────────

  /// Persiste el mapa completo de goals para el usuario.
  /// Usa merge para no tocar el resto de campos de UserModel.
  Future<void> saveGoals(
    String userId,
    Map<GoalType, UserGoal> goals,
  ) async {
    final Map<String, dynamic> serialized = {
      for (final entry in goals.entries)
        entry.key.name: entry.value.toJson(),
    };

    await _userDoc(userId).set(
      {'goals': serialized},
      SetOptions(merge: true),
    );
  }

  // ─── Lectura ──────────────────────────────────────────────────────────────

  /// Stream que emite el mapa de goals cada vez que cambia en Firestore.
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
      } catch (_) {}
    }
    return result;
  }
}

// ─── Provider ────────────────────────────────────────────────────────────────

final goalRepositoryProvider = Provider<GoalRepository>((ref) {
  return GoalRepository(FirebaseFirestore.instance);
});
