import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../features/authentication/data/auth_repository.dart';
import '../../../features/health/data/health_repository.dart';
import '../domain/user_engagement_profile.dart';

final engagementRepositoryProvider = Provider<EngagementRepository>((ref) {
  return EngagementRepository(FirebaseFirestore.instance);
});

class EngagementRepository {
  final FirebaseFirestore _firestore;
  static const _docId = 'engagement_profile';

  EngagementRepository(this._firestore);

  DocumentReference<Map<String, dynamic>> _ref(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('current_status')
      .doc(_docId);

  /// Carga el perfil persistido. Retorna null si no existe aún.
  Future<UserEngagementProfile?> load(String uid) async {
    try {
      final doc = await _ref(uid).get();
      if (!doc.exists || doc.data() == null) return null;
      return _fromMap(doc.data()!);
    } catch (e) {
      debugPrint('❌ EngagementRepository.load: $e');
      return null;
    }
  }

  /// Persiste el perfil calculado. Usa merge para no sobreescribir
  /// campos no relacionados si los hubiera.
  Future<void> save(String uid, UserEngagementProfile profile) async {
    try {
      await _ref(uid).set(_toMap(profile), SetOptions(merge: true));
    } catch (e) {
      debugPrint('❌ EngagementRepository.save: $e');
    }
  }

  /// Stream para escuchar cambios en tiempo real (opcional, para UI reactiva).
  Stream<UserEngagementProfile?> watch(String uid) {
    return _ref(uid).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return _fromMap(doc.data()!);
    });
  }

  Map<String, dynamic> _toMap(UserEngagementProfile p) => {
    'current_streak': p.currentStreak,
    'longest_streak': p.longestStreak,
    'total_actions_completed': p.totalActionsCompleted,
    'adherence_score': p.adherenceScore,
    'motivation_level': p.motivationLevel,
    'last_active': p.lastActive,
    'missed_days': p.missedDays,
    'completed_actions_by_type': p.completedActionsByType,
    'last_updated': FieldValue.serverTimestamp(),
  };

  UserEngagementProfile _fromMap(Map<String, dynamic> map) {
    DateTime lastActive;
    final rawLastActive = map['last_active'];
    if (rawLastActive is Timestamp) {
      lastActive = rawLastActive.toDate();
    } else {
      lastActive = DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }

    Map<String, int> completedByType = {};
    final rawByType = map['completed_actions_by_type'];
    if (rawByType is Map) {
      completedByType = rawByType.map(
        (k, v) => MapEntry(k.toString(), (v as num).toInt()),
      );
    }

    return UserEngagementProfile(
      currentStreak: (map['current_streak'] as num?)?.toInt() ?? 0,
      longestStreak: (map['longest_streak'] as num?)?.toInt() ?? 0,
      totalActionsCompleted:
          (map['total_actions_completed'] as num?)?.toInt() ?? 0,
      adherenceScore: (map['adherence_score'] as num?)?.toDouble() ?? 0.5,
      motivationLevel: (map['motivation_level'] as num?)?.toDouble() ?? 0.5,
      lastActive: lastActive,
      missedDays: (map['missed_days'] as num?)?.toInt() ?? 0,
      completedActionsByType: completedByType,
    );
  }
}

/// Stream reactivo de la racha actual del usuario autenticado.
/// Calcula días consecutivos (hasta hoy) con imrScore > 0 desde daily_logs.
/// Misma lógica que ProgressData.fromLogs para garantizar coherencia.
final streakStreamProvider = StreamProvider.autoDispose<int>((ref) {
  final user = ref.watch(authStateChangesProvider).valueOrNull;
  if (user == null) return Stream.value(0);

  final repo = ref.read(healthRepositoryProvider);
  return repo.watchLogsHistory(user.uid, 30).map((logs) {
    final now = DateTime.now();
    int streak = 0;
    final sortedDesc = [...logs]..sort((a, b) => b.id.compareTo(a.id));
    for (int i = 0; i < sortedDesc.length; i++) {
      final expectedDate = now.subtract(Duration(days: i));
      final expectedId = DateFormat('yyyy-MM-dd').format(expectedDate);
      if (i < sortedDesc.length &&
          sortedDesc[i].id == expectedId &&
          sortedDesc[i].imrScore > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  });
});
