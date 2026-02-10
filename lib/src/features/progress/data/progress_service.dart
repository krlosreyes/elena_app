import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/measurement_log.dart';

class ProgressService {
  final FirebaseFirestore _firestore;

  ProgressService(this._firestore);

  // Collection Reference
  CollectionReference<MeasurementLog> _measurementsRef(String uid) => _firestore
      .collection('users')
      .doc(uid)
      .collection('measurements')
      .withConverter<MeasurementLog>(
        fromFirestore: (doc, _) => MeasurementLog.fromFirestore(doc),
        toFirestore: (log, _) => log.toJson(),
      );

  // Add Measurement
  Future<void> addMeasurement(String uid, {
    required double weight,
    double? waistCircumference,
    int? energyLevel,
    DateTime? date, // Optional date for retroactive logging
  }) async {
    final log = MeasurementLog(
      id: '', // Will be generated
      date: date ?? DateTime.now(),
      weight: weight,
      waistCircumference: waistCircumference,
      energyLevel: energyLevel,
    );
    
    // Use standard add to let Firestore generate ID
    await _measurementsRef(uid).add(log);
  }

  // Get History Stream
  Stream<List<MeasurementLog>> getHistory(String uid) {
    return _measurementsRef(uid)
        .orderBy('date', descending: false) // Oldest first for charts
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get Latest Measurement
  Future<MeasurementLog?> getLatest(String uid) async {
    final snapshot = await _measurementsRef(uid)
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }

  // Delete Measurement
  Future<void> deleteMeasurement(String uid, String measurementId) async {
    await _measurementsRef(uid).doc(measurementId).delete();
  }

  // Update Measurement
  Future<void> updateMeasurement(String uid, MeasurementLog log) async {
    if (log.id.isEmpty) return; // Should not happen for existing logs
    await _measurementsRef(uid).doc(log.id).set(log);
  }
}

// Providers
final progressServiceProvider = Provider<ProgressService>((ref) {
  return ProgressService(FirebaseFirestore.instance);
});

// Reactive Provider that watches Auth State
final userMeasurementsProvider = StreamProvider.autoDispose<List<MeasurementLog>>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) {
    return const Stream.empty();
  }
  final service = ref.watch(progressServiceProvider);
  return service.getHistory(user.uid);
});
