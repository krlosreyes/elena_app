// SPEC-50.5: implementación concreta del UserProfileRepository.
//
// Cierra la descomposición del UserRepository monolítico. Reemplaza
// directamente al `userRepositoryProvider` previo — este archivo
// expone `userProfileRepositoryProvider` como reemplazo nominal.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/shared/data/mappers/user_profile_mapper.dart';
import 'package:elena_app/src/shared/data/sources/firestore_user_profile_v1_source.dart';
import 'package:elena_app/src/shared/data/sources/user_profile_data_source.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/domain/repositories/user_profile_repository.dart';

class UserProfileRepositoryImpl implements UserProfileRepository {
  final UserProfileDataSource _source;
  final UserProfileMapper _mapper;

  UserProfileRepositoryImpl({
    required UserProfileDataSource source,
    UserProfileMapper mapper = const UserProfileMapper(),
  })  : _source = source,
        _mapper = mapper;

  @override
  Stream<UserModel?> watchProfile(String userId) {
    return _source.streamProfile(userId).map((map) {
      if (map == null) return null;
      try {
        return _mapper.fromMap(map);
      } catch (_) {
        // Doc corrupto: emitimos null en lugar de caer la app.
        return null;
      }
    });
  }

  @override
  Future<void> saveProfile(UserModel user) async {
    final data = _mapper.toMap(user);
    await _source.saveProfile(userId: user.id, data: data);
  }

  @override
  Future<void> updateWeeklyAdherence(String userId, double adherence) async {
    await _source.updateProfileFields(
      userId: userId,
      updates: {'weeklyAdherence': adherence},
    );
  }

  @override
  Future<void> saveProtocolAdjustment(
    String userId,
    Map<String, dynamic> adjustment,
  ) async {
    await _source.appendProtocolAdjustment(
      userId: userId,
      adjustment: adjustment,
    );
  }

  @override
  Future<void> applyProtocolAdjustment({
    required String userId,
    String? newFastingProtocol,
    int? newExerciseGoal,
  }) async {
    final updates = <String, dynamic>{};
    if (newFastingProtocol != null) {
      updates['fastingProtocol'] = newFastingProtocol;
    }
    if (newExerciseGoal != null) {
      updates['exerciseGoalMinutes'] = newExerciseGoal;
    }
    if (updates.isEmpty) return;
    await _source.updateProfileFields(userId: userId, updates: updates);
  }

  // SPEC-82: dotted-path para tocar solo `imr.current` y opcionalmente
  // `imr.history`. Firestore acepta keys con `.` en `update()` como
  // path nested. No usar `set` porque pisaría `imr.history` y otros
  // subcampos del bloque imr.
  @override
  Future<void> updateCurrentImr(
    String userId,
    Map<String, dynamic> imrCurrent,
  ) async {
    await _source.updateProfileFields(
      userId: userId,
      updates: {'imr.current': imrCurrent},
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────

/// Reemplazo nominal del antiguo `userRepositoryProvider`. Ningún
/// caller debería seguir usando `userRepositoryProvider` después de
/// esta SPEC.
final userProfileRepositoryProvider = Provider<UserProfileRepository>((ref) {
  return UserProfileRepositoryImpl(
    source: FirestoreUserProfileV1Source(),
  );
});
