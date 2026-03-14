import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/progress_service.dart';
import '../domain/measurement_log.dart';
import '../../authentication/application/auth_controller.dart';


class ProgressController extends StateNotifier<void> {
  final ProgressService _service;
  final Ref _ref; // Necesitamos el ref para leer otros providers

  ProgressController(this._service, this._ref) : super(null);

  Future<void> addMeasurement(String uid, {
    required double weight,
    double? waistCircumference,
    int? energyLevel,
    DateTime? date,
  }) async {
    await _service.addMeasurement(
      uid,
      weight: weight,
      waistCircumference: waistCircumference,
      energyLevel: energyLevel,
      date: date,
    );
    
    // TODO: Re-calcular IMX tras registrar la medida mediante un trigger global
  }

  Future<MeasurementLog?> getLatest(String uid) {
    return _service.getLatest(uid);
  }

  Future<void> deleteMeasurement(String uid, String measurementId) {
    return _service.deleteMeasurement(uid, measurementId);
  }

  Future<void> updateMeasurement(String uid, MeasurementLog log) {
    return _service.updateMeasurement(uid, log);
  }
}

final progressControllerProvider =
    StateNotifierProvider<ProgressController, void>((ref) {
  return ProgressController(ref.watch(progressServiceProvider), ref);
});

/// Reactive stream of all measurements for the currently authenticated user.
final userMeasurementsStreamProvider =
    StreamProvider.autoDispose<List<MeasurementLog>>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  
  return authState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.watch(progressServiceProvider).getHistory(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => const Stream.empty(),
  );
});
