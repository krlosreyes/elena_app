import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_logger.dart';
import '../data/repositories/sleep_repository_impl.dart';
import '../domain/entities/sleep_log.dart';
import '../domain/repositories/sleep_repository.dart';

part 'sleep_service.g.dart';

/// 🏗️ SLEEP SERVICE - Centraliza operaciones de sueño
///
/// Reemplaza queries dispersas en widgets.
/// Proporciona interfaz limpia y testeable para:
/// - Registrar sesiones de sueño
/// - Obtener historial de sueño
/// - Calcular calidad y estadísticas de sueño
class SleepService {
  final SleepRepository _repository;

  SleepService(this._repository);

  /// ✅ Registrar sesión de sueño
  Future<void> logSleep({
    required SleepLog log,
  }) async {
    try {
      AppLogger.debug(
        'Registrando sueño: ${log.hours}h',
      );
      await _repository.saveSleepLog(log);
      AppLogger.info('Sesión de sueño registrada exitosamente');
    } catch (e) {
      AppLogger.error('Error registrando sueño: $e');
      rethrow;
    }
  }

  /// ✅ Obtener logs recientes de sueño
  Future<List<SleepLog>> getRecentSleep(
    String uid, {
    int limit = 7,
  }) async {
    try {
      AppLogger.debug('Obteniendo últimos $limit registros de sueño');
      return await _repository.getRecentSleepLogs(uid, limit: limit);
    } catch (e) {
      AppLogger.error('Error obteniendo sueño reciente: $e');
      rethrow;
    }
  }

  /// ✅ Calcular calidad de sueño (0-100)
  ///
  /// Moved to DecisionEngine in Phase 3
  /// This method remains as a simple helper for legacy callers.
  int calculateSleepQuality(double hours) {
    final normalized = (hours / 8.0 * 100).clamp(0.0, 100.0);
    return normalized.round();
  }

  /// ✅ Calcular promedio de sueño
  Future<double> getAverageSleep(
    String uid, {
    int limit = 7,
  }) async {
    try {
      final logs = await getRecentSleep(uid, limit: limit);
      if (logs.isEmpty) return 0;

      final totalHours = logs.fold<double>(
        0,
        (accumulated, log) => accumulated + log.hours,
      );

      final average = totalHours / logs.length;
      AppLogger.debug('Average sleep: ${average.toStringAsFixed(1)}h');
      return average;
    } catch (e) {
      AppLogger.error('Error calculando promedio: $e');
      return 0;
    }
  }

  /// ✅ Stream en tiempo real de sueño reciente
  Stream<List<SleepLog>> watchRecentSleep(
    String uid, {
    int limit = 7,
  }) {
    try {
      return _repository.watchRecentSleepLogs(uid, limit: limit);
    } catch (e) {
      AppLogger.error('Error watching sleep: $e');
      rethrow;
    }
  }
}

/// 📱 Riverpod Providers para SleepService
///
/// Proporcionan acceso singleton a SleepService en toda la app

@riverpod
SleepRepository sleepRepository(Ref ref) {
  return SleepRepositoryImpl(FirebaseFirestore.instance);
}

@riverpod
SleepService sleepService(Ref ref) {
  final repository = ref.watch(sleepRepositoryProvider);
  return SleepService(repository);
}

/// ✅ Provider para sueño reciente
@riverpod
Future<List<SleepLog>> recentSleep(Ref ref, String uid, {int limit = 7}) async {
  final service = ref.watch(sleepServiceProvider);
  return await service.getRecentSleep(uid, limit: limit);
}

/// ✅ Stream provider para sueño en tiempo real
@riverpod
Stream<List<SleepLog>> sleepStream(Ref ref, String uid, {int limit = 7}) {
  final service = ref.watch(sleepServiceProvider);
  return service.watchRecentSleep(uid, limit: limit);
}

/// ✅ Provider para promedio de sueño
@riverpod
Future<double> averageSleep(Ref ref, String uid, {int limit = 7}) async {
  final service = ref.watch(sleepServiceProvider);
  return await service.getAverageSleep(uid, limit: limit);
}
