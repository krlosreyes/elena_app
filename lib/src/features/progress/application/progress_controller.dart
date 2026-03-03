import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/progress_service.dart';
import '../domain/measurement_log.dart';
import '../../authentication/application/auth_controller.dart';

part 'progress_controller.g.dart';

@riverpod
class ProgressController extends _$ProgressController {
  @override
  void build() {}

  Future<void> addMeasurement(String uid, {
    required double weight,
    double? waistCircumference,
    int? energyLevel,
    DateTime? date,
  }) {
    return ref.read(progressServiceProvider).addMeasurement(
      uid,
      weight: weight,
      waistCircumference: waistCircumference,
      energyLevel: energyLevel,
      date: date,
    );
  }

  Future<MeasurementLog?> getLatest(String uid) {
    return ref.read(progressServiceProvider).getLatest(uid);
  }

  Future<void> deleteMeasurement(String uid, String measurementId) {
    return ref.read(progressServiceProvider).deleteMeasurement(uid, measurementId);
  }

  Future<void> updateMeasurement(String uid, MeasurementLog log) {
    return ref.read(progressServiceProvider).updateMeasurement(uid, log);
  }
}

@riverpod
Stream<List<MeasurementLog>> userMeasurementsStream(Ref ref) {
  final user = ref.watch(authControllerProvider.notifier).currentUser;
  if (user == null) {
    return const Stream.empty();
  }
  return ref.read(progressServiceProvider).getHistory(user.uid);
}
