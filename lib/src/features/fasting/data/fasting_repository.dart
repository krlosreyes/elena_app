import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/fasting_session.dart';

// Provider para el repositorio de ayuno
final fastingRepositoryProvider = Provider<FastingRepository>((ref) {
  return FastingRepository(FirebaseFirestore.instance);
});

// Provider para el historial de ayuno en un rango de días
final fastingHistoryRangeProvider =
    StreamProvider.family<List<FastingSession>, ({String uid, int days})>(
        (ref, arg) {
  final repository = ref.watch(fastingRepositoryProvider);
  return repository.watchFastingHistory(arg.uid, arg.days);
});

class FastingRepository {
  final FirebaseFirestore _firestore;

  FastingRepository(this._firestore);

  /// Helper para convertir documentos de Firestore a FastingSession
  FastingSession _sessionFromFirestore(Map<String, dynamic> data) {
    final map = Map<String, dynamic>.from(data);

    // Conversión de Timestamps a String ISO (que Freezed/JsonSerializable entiende)
    // Soportar tanto snake_case (nuevo) como camelCase (viejo)
    final dynamic rawStart = map['start_time'] ?? map['startTime'];
    if (rawStart != null && rawStart is Timestamp) {
      map['startTime'] = rawStart.toDate().toIso8601String();
    }
    
    final dynamic rawEnd = map['end_time'] ?? map['endTime'];
    if (rawEnd != null && rawEnd is Timestamp) {
      map['endTime'] = rawEnd.toDate().toIso8601String();
    }

    // Mapeo de nombres si difieren (para JSON parser de FastingSession)
    if (map['target_hours'] != null) {
      map['plannedDurationHours'] = map['target_hours'];
    } else if (map['targetHours'] != null) {
      map['plannedDurationHours'] = map['targetHours'];
    }

    if (map['is_completed'] != null) {
      map['isCompleted'] = map['is_completed'];
    }

    return FastingSession.fromJson(map);
  }

  /// Obtiene el estado metabólico actual del usuario (Ayuno vs Alimentación)
  Future<Map<String, dynamic>?> getCurrentMetabolicState(String uid) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(uid)
          .collection('current_status')
          .doc('metabolic_state')
          .get();
      return doc.data();
    } catch (e) {
      debugPrint("❌ Error obteniendo estado metabólico: $e");
      return null;
    }
  }

  /// Actualiza el estado metabólico de forma atómica.
  Future<void> updateMetabolicState({
    required String uid,
    required String phase,
    DateTime? startTime,
    DateTime? feedingStartTime,
    int? targetHours,
    int? originalTargetHours,
    bool? isActive,
    bool? hasCompletedConfirmationShown,
    bool? hasInitialMealBeenLogged,
    bool? hasFeedingEndDialogShown,
    bool? isContinuingPastGoal,
  }) async {
    try {
      final updates = <String, dynamic>{
        'current_phase': phase,
        'last_updated': FieldValue.serverTimestamp(),
      };

      if (startTime != null) {
        updates['start_time'] = startTime;
      }
      if (originalTargetHours != null) {
        updates['original_target_hours'] = originalTargetHours;
      }
      if (feedingStartTime != null) {
        updates['feeding_start_time'] = feedingStartTime;
      }
      if (targetHours != null) {
        updates['target_hours'] = targetHours;
      }
      if (isActive != null) {
        updates['is_active'] = isActive;
      }
      if (hasCompletedConfirmationShown != null) {
        updates['has_completed_confirmation_shown'] =
            hasCompletedConfirmationShown;
      }
      if (isContinuingPastGoal != null) {
        updates['is_continuing_past_goal'] = isContinuingPastGoal;
      }
      if (hasInitialMealBeenLogged != null) {
        updates['has_initial_meal_been_logged'] = hasInitialMealBeenLogged;
      }
      if (hasFeedingEndDialogShown != null) {
        updates['has_feeding_end_dialog_shown'] = hasFeedingEndDialogShown;
      }

      await _firestore
          .collection('users')
          .doc(uid)
          .collection('current_status')
          .doc('metabolic_state')
          .set(updates, SetOptions(merge: true));
    } catch (e) {
      debugPrint("❌ Error actualizando estado metabólico: $e");
    }
  }

  /// Marca que la primera comida de la ventana ha sido registrada.
  Future<void> markInitialMealLogged(String uid) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('current_status')
          .doc('metabolic_state')
          .update({
        'has_initial_meal_been_logged': true,
        'last_updated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint("❌ Error marcando primera comida registrada: $e");
    }
  }

  /// Crea una nueva sesión de ayuno (Alias para compatibilidad)
  Future<void> startFast(String uid, FastingSession session) async {
    await createFastingSession(
      uid: uid,
      startTime: session.startTime,
      targetHours: session.plannedDurationHours,
    );
  }

  /// Finaliza una sesión (Alias para compatibilidad)
  Future<void> saveCompletedFast(String uid, FastingSession session) async {
    final activeSessionId = await getActiveSessionId(uid);

    if (activeSessionId != null) {
      final actualDuration = session.endTime!.difference(session.startTime);
      final actualHours = actualDuration.inSeconds / 3600;

      await completeFastingSession(
        uid: uid,
        sessionId: activeSessionId,
        endTime: session.endTime!,
        actualHours: actualHours,
      );
      return;
    }

    // FALLBACK: Si no hay doc activo, creamos el completado directamente
    final actualHours =
        session.endTime!.difference(session.startTime).inSeconds / 3600;
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('fasting_history')
        .add({
      'uid': uid,
      'start_time': session.startTime,
      'end_time': session.endTime,
      'target_hours': session.plannedDurationHours,
      'actual_hours': actualHours,
      'is_completed': true,
      'created_at': FieldValue.serverTimestamp(),
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  /// Obtiene el ID de la sesión de ayuno activa más reciente.
  Future<String?> getActiveSessionId(String uid) async {
    final query = await _firestore
        .collection('users')
        .doc(uid)
        .collection('fasting_history')
        .where('is_completed', isEqualTo: false)
        .limit(5)
        .get();

    if (query.docs.isEmpty) return null;

    final docs = query.docs
        .where((d) =>
            d.data().containsKey('start_time') ||
            d.data().containsKey('startTime'))
        .toList();

    if (docs.isEmpty) return null;

    docs.sort((a, b) {
      final aRaw = a.data()['start_time'] ?? a.data()['startTime'];
      final bRaw = b.data()['start_time'] ?? b.data()['startTime'];
      final aTime = (aRaw as Timestamp?)?.seconds ?? 0;
      final bTime = (bRaw as Timestamp?)?.seconds ?? 0;
      return bTime.compareTo(aTime);
    });

    return docs.first.id;
  }

  /// Ejecuta una transición atómica para finalizar el ayuno.
  Future<void> performEndFastingBatch({
    required String uid,
    required DateTime endTime,
    required DateTime startTime,
    required int targetHours,
  }) async {
    final batch = _firestore.batch();

    // 1. Referencia al estado metabólico
    final statusRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('current_status')
        .doc('metabolic_state');

    batch.set(
        statusRef,
        {
          'current_phase': 'IS_FEEDING',
          'last_updated': FieldValue.serverTimestamp(),
          'start_time': startTime,
          'feeding_start_time': endTime,
          'target_hours': targetHours,
          'is_active': false,
          'has_completed_confirmation_shown': true,
          'is_continuing_past_goal': false,
          'has_initial_meal_been_logged': false,
          'has_feeding_end_dialog_shown': false,
        },
        SetOptions(merge: true));

    // 2. Referencia al historial
    final activeSessionId = await getActiveSessionId(uid);
    final actualHours = endTime.difference(startTime).inSeconds / 3600;

    if (activeSessionId != null) {
      final sessionRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('fasting_history')
          .doc(activeSessionId);

      batch.update(sessionRef, {
        'end_time': endTime,
        'actual_hours': actualHours,
        'is_completed': true,
        'last_updated': FieldValue.serverTimestamp(),
      });
    } else {
      // Fallback: Crear nueva sesión completada
      final newSessionRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('fasting_history')
          .doc();

      batch.set(newSessionRef, {
        'uid': uid,
        'start_time': startTime,
        'end_time': endTime,
        'target_hours': targetHours,
        'actual_hours': actualHours,
        'is_completed': true,
        'created_at': FieldValue.serverTimestamp(),
        'last_updated': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Limpia sesiones antiguas que hayan quedado en isCompleted: false por error.
  Future<void> forceCleanupOldActiveSessions(String uid) async {
    try {
      final threshold = DateTime.now().subtract(const Duration(hours: 72));
      final query = await _firestore
          .collection('users')
          .doc(uid)
          .collection('fasting_history')
          .where('is_completed', isEqualTo: false)
          .where('start_time', isLessThan: threshold)
          .get();

      final batch = _firestore.batch();
      for (var doc in query.docs) {
        batch.update(doc.reference, {
          'is_completed': true,
          'end_time': FieldValue.serverTimestamp(),
          'cancelled': true,
          'last_updated': FieldValue.serverTimestamp(),
        });
      }
      await batch.commit();
      // debugPrint("🧹 Limpieza de sesiones huérfanas completada."); (Silenciado)
    } catch (e) {
      debugPrint("⚠️ Error en forceCleanupOldActiveSessions: $e");
    }
  }

  /// Crea una nueva sesión de ayuno en el histórico.
  Future<String> createFastingSession({
    required String uid,
    required DateTime startTime,
    required int targetHours,
  }) async {
    final docRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('fasting_history')
        .doc();

    await docRef.set({
      'id': docRef.id,
      'uid': uid,
      'start_time': startTime,
      'target_hours': targetHours,
      'is_completed': false,
      'created_at': FieldValue.serverTimestamp(),
    });

    return docRef.id;
  }

  /// Finaliza una sesión de ayuno existente.
  Future<void> completeFastingSession({
    required String uid,
    required String sessionId,
    required DateTime endTime,
    required double actualHours,
  }) async {
    await _firestore
        .collection('users')
        .doc(uid)
        .collection('fasting_history')
        .doc(sessionId)
        .update({
      'end_time': endTime,
      'actual_hours': actualHours,
      'is_completed': true,
      'last_updated': FieldValue.serverTimestamp(),
    });
  }

  /// Escucha el historial de ayuno en un rango de días.
  Stream<List<FastingSession>> watchFastingHistory(String uid, int days) {
    final threshold = DateTime.now().subtract(Duration(days: days));
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('fasting_history')
        .where('start_time', isGreaterThanOrEqualTo: threshold)
        .orderBy('start_time', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => _sessionFromFirestore(doc.data()))
          .where((session) => session.isCompleted)
          .toList();
    });
  }

  /// Escucha en tiempo real el estado metabólico actual.
  Stream<Map<String, dynamic>?> getMetabolicStateStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('current_status')
        .doc('metabolic_state')
        .snapshots()
        .map((snapshot) => snapshot.data());
  }

  /// Método de compatibilidad para obtener la sesión activa como FastingSession.
  Stream<FastingSession?> getActiveFastStream(String uid) {
    return getMetabolicStateStream(uid).map((data) {
      if (data == null || data['current_phase'] != 'IS_FASTING') return null;

      return FastingSession(
        uid: uid,
        startTime:
            (data['start_time'] as Timestamp?)?.toDate() ?? DateTime.now(),
        plannedDurationHours: data['target_hours'] ?? 16,
        isCompleted: false,
      );
    });
  }

  /// Método de compatibilidad para obtener todo el historial (último año).
  Stream<List<FastingSession>> getHistoryStream(String uid) {
    return watchFastingHistory(uid, 365);
  }
}
