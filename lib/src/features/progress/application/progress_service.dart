import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/services/app_logger.dart';
import '../data/progress_service.dart' as old_service;
import '../domain/measurement_log.dart';

part 'progress_service.g.dart';

/// 🏗️ PROGRESS SERVICE - Centraliza operaciones de progreso y medidas
///
/// Reemplaza queries dispersas en widgets.
/// Proporciona interfaz limpia y testeable para:
/// - Registrar mediciones (peso, perímetros, etc.)
/// - Obtener historial de mediciones
/// - Calcular estadísticas de progreso
class ProgressService {
  final old_service.ProgressService _service;

  ProgressService(this._service);

  /// ✅ Registrar nueva medición
  Future<void> addMeasurement({
    required String uid,
    required double weight,
    double? waistCircumference,
    double? neckCircumference,
    double? hipCircumference,
    int? energyLevel,
    double? bodyFatPercentage,
    double? muscleMassPercentage,
    double? visceralFat,
    DateTime? date,
  }) async {
    try {
      AppLogger.debug('Registrando medición: ${weight}kg');

      final log = MeasurementLog(
        id: '', // Firestore lo genera
        date: date ?? DateTime.now(),
        weight: weight,
        waistCircumference: waistCircumference,
        neckCircumference: neckCircumference,
        hipCircumference: hipCircumference,
        energyLevel: energyLevel,
        bodyFatPercentage: bodyFatPercentage,
        muscleMassPercentage: muscleMassPercentage,
        visceralFat: visceralFat,
      );

      await _service.addFullMeasurement(uid, log);
      AppLogger.info('Medición registrada exitosamente');
    } catch (e) {
      AppLogger.error('Error registrando medición: $e');
      rethrow;
    }
  }

  /// ✅ Obtener historial de mediciones
  Future<List<MeasurementLog>> getHistory(
    String uid, {
    int limit = 30,
  }) async {
    try {
      AppLogger.debug('Obteniendo historial de mediciones');
      final measurements = await _service.getHistory(uid).first;
      // Ordenar por fecha descendente (más reciente primero) y limitar
      measurements.sort((a, b) => b.date.compareTo(a.date));
      return measurements.take(limit).toList();
    } catch (e) {
      AppLogger.error('Error obteniendo historial: $e');
      rethrow;
    }
  }

  /// ✅ Ver stream en tiempo real de mediciones
  Stream<List<MeasurementLog>> watchHistory(String uid) {
    try {
      AppLogger.debug('Observando historial de mediciones');
      return _service.getHistory(uid);
    } catch (e) {
      AppLogger.error('Error observando historial: $e');
      rethrow;
    }
  }

  /// ✅ Obtener última medición
  Future<MeasurementLog?> getLatest(String uid) async {
    try {
      AppLogger.debug('Obteniendo última medición');
      return await _service.getLatest(uid);
    } catch (e) {
      AppLogger.error('Error obteniendo última medición: $e');
      return null;
    }
  }

  /// ✅ Calcular progreso de peso
  /// Retorna cambio en kg (negativo = pérdida de peso)
  Future<double?> calculateWeightProgress(
    String uid, {
    int days = 30,
  }) async {
    try {
      AppLogger.debug('Calculando progreso de peso');
      final measurements = await getHistory(uid, limit: days);

      if (measurements.length < 2) {
        AppLogger.debug('No hay suficientes mediciones para calcular progreso');
        return null;
      }

      // Primera medición (más antigua) vs última (más reciente)
      final firstWeight = measurements.last.weight;
      final lastWeight = measurements.first.weight;
      final change = lastWeight - firstWeight;

      AppLogger.debug(
        'Weight progress: ${change > 0 ? '+' : ''}${change.toStringAsFixed(1)}kg',
      );
      return change;
    } catch (e) {
      AppLogger.error('Error calculando progreso de peso: $e');
      return null;
    }
  }

  /// ✅ Calcular estadísticas de mediciones
  Future<Map<String, double>> getMeasurementStats(
    String uid, {
    int days = 30,
  }) async {
    try {
      AppLogger.debug('Calculando estadísticas de mediciones');
      final measurements = await getHistory(uid, limit: days);

      if (measurements.isEmpty) {
        return {'avgWeight': 0, 'minWeight': 0, 'maxWeight': 0};
      }

      final weights = measurements.map((m) => m.weight).toList();
      final avgWeight = weights.reduce((a, b) => a + b) / weights.length;
      final minWeight = weights.reduce((a, b) => a < b ? a : b);
      final maxWeight = weights.reduce((a, b) => a > b ? a : b);

      final stats = {
        'avgWeight': avgWeight,
        'minWeight': minWeight,
        'maxWeight': maxWeight,
        'countMeasurements': measurements.length.toDouble(),
      };

      AppLogger.debug('Measurement stats: $stats');
      return stats;
    } catch (e) {
      AppLogger.error('Error calculando estadísticas: $e');
      return {'avgWeight': 0, 'minWeight': 0, 'maxWeight': 0};
    }
  }

  /// ✅ Calcular índice de masa corporal (BMI)
  /// Necesita peso (kg) y altura (m)
  double? calculateBMI({
    required double weight,
    required double heightMeters,
  }) {
    try {
      if (heightMeters <= 0) return null;
      final bmi = weight / (heightMeters * heightMeters);
      AppLogger.debug('BMI calculated: ${bmi.toStringAsFixed(1)}');
      return bmi;
    } catch (e) {
      AppLogger.error('Error calculando BMI: $e');
      return null;
    }
  }

  /// ✅ Eliminar una medición
  Future<void> deleteMeasurement(String uid, String measurementId) async {
    try {
      AppLogger.debug('Eliminando medición: $measurementId');
      await _service.deleteMeasurement(uid, measurementId);
      AppLogger.info('Medición eliminada exitosamente');
    } catch (e) {
      AppLogger.error('Error eliminando medición: $e');
      rethrow;
    }
  }
}

// ========== RIVERPOD PROVIDERS ==========

/// 🔌 ProgressService provider (singleton)
@riverpod
ProgressService progressService(Ref ref) {
  final oldService = old_service.ProgressService(FirebaseFirestore.instance);
  return ProgressService(oldService);
}

/// 🔌 Latest measurement provider
@riverpod
Future<MeasurementLog?> latestMeasurement(Ref ref, String uid) async {
  final service = ref.watch(progressServiceProvider);
  return await service.getLatest(uid);
}

/// 🔌 Measurement history provider
@riverpod
Future<List<MeasurementLog>> measurementHistory(
  Ref ref,
  String uid, {
  int days = 30,
}) async {
  final service = ref.watch(progressServiceProvider);
  return await service.getHistory(uid, limit: days);
}

/// 🔌 Weight progress provider
@riverpod
Future<double?> weightProgress(
  Ref ref,
  String uid, {
  int days = 30,
}) async {
  final service = ref.watch(progressServiceProvider);
  return await service.calculateWeightProgress(uid, days: days);
}

/// 🔌 Measurement statistics provider
@riverpod
Future<Map<String, double>> measurementStats(
  Ref ref,
  String uid, {
  int days = 30,
}) async {
  final service = ref.watch(progressServiceProvider);
  return await service.getMeasurementStats(uid, days: days);
}

/// 🔌 Watch measurement history (stream)
@riverpod
Stream<List<MeasurementLog>> watchMeasurements(Ref ref, String uid) {
  final service = ref.watch(progressServiceProvider);
  return service.watchHistory(uid);
}
