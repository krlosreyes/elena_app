import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_logger.dart';

part 'daily_log_service.g.dart';

/// 🏗️ DAILY LOG SERVICE - Centralizado para Clean Architecture
///
/// Reemplaza queries dispersas en widgets para daily logs.
class DailyLogService {
  final FirebaseFirestore _firestore;

  DailyLogService(this._firestore);

  /// ✅ TASK 2.2.1: Obtener log diario del usuario
  Future<Map<String, dynamic>?> getDailyLog(String userId, String date) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_logs')
          .doc(date)
          .get();

      if (!doc.exists) return null;
      return doc.data();
    } catch (e) {
      AppLogger.error('Error obteniendo daily log: $e');
      rethrow;
    }
  }

  /// ✅ TASK 2.2.2: Limpiar todos los logs del usuario para una fecha
  Future<void> clearDailyLogForDate(String userId, String date) async {
    try {
      AppLogger.logDatabaseEvent('daily_logs', 'clear for date $date');

      // 1. Eliminar subcollección
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_logs')
          .where('date', isEqualTo: date)
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      // 2. Eliminar documento principal
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_logs')
          .doc(date)
          .delete();

      AppLogger.info('Daily log para $date eliminado exitosamente');
    } catch (e) {
      AppLogger.error('Error limpiando daily log: $e');
      rethrow;
    }
  }

  /// ✅ TASK 2.2.3: Stream de logs diarios para un período
  Stream<List<Map<String, dynamic>>> watchDailyLogs(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) {
    try {
      return _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_logs')
          .where('date', isGreaterThanOrEqualTo: startDate.toIso8601String())
          .where('date', isLessThanOrEqualTo: endDate.toIso8601String())
          .snapshots()
          .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
    } catch (e) {
      AppLogger.error('Error escuchando daily logs: $e');
      rethrow;
    }
  }

  /// ✅ TASK 2.2.4: Guardar/actualizar daily log
  Future<void> saveDailyLog(
    String userId,
    String date,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('daily_logs')
          .doc(date)
          .set(data, SetOptions(merge: true));

      AppLogger.logDatabaseEvent('daily_logs', 'save/update');
    } catch (e) {
      AppLogger.error('Error guardando daily log: $e');
      rethrow;
    }
  }
}

/// 📱 Riverpod Provider para DailyLogService
@riverpod
DailyLogService dailyLogService(DailyLogServiceRef ref) {
  return DailyLogService(FirebaseFirestore.instance);
}
