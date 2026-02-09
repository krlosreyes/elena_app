import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/measurement_log.dart';

class ProgressService {
  final FirebaseFirestore _firestore;
  final String uid;

  ProgressService(this._firestore, this.uid);

  // Collection Reference
  CollectionReference<MeasurementLog> get _measurementsRef => _firestore
      .collection('users')
      .doc(uid)
      .collection('measurements')
      .withConverter<MeasurementLog>(
        fromFirestore: (doc, _) => MeasurementLog.fromFirestore(doc),
        toFirestore: (log, _) => log.toJson(),
      );

  // Add Measurement
  Future<void> addMeasurement({
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
    await _measurementsRef.add(log);
  }

  // Get History Stream
  Stream<List<MeasurementLog>> getHistory() {
    return _measurementsRef
        .orderBy('date', descending: false) // Oldest first for charts
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  // Get Latest Measurement
  Future<MeasurementLog?> getLatest() async {
    final snapshot = await _measurementsRef
        .orderBy('date', descending: true)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.data();
    }
    return null;
  }
}

// Providers
final progressServiceProvider = Provider<ProgressService>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) throw Exception('User not authenticated');
  return ProgressService(FirebaseFirestore.instance, user.uid);
});

final measurementHistoryProvider = StreamProvider<List<MeasurementLog>>((ref) {
  final service = ref.watch(progressServiceProvider);
  return service.getHistory();
});
