import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  Future<void> addMeasurement(
    String uid, {
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

  // Add Full Auto Measurement from Object directly
  Future<void> addFullMeasurement(String uid, MeasurementLog log) async {
    await _measurementsRef(uid).add(log);
  }

  // Update Profile Stats directly from Measurement logic
  Future<void> updateProfileDerivedStats(String uid,
      {required double weight,
      double? waist,
      double? neck,
      double? hip}) async {
    final Map<String, dynamic> updates = {
      'currentWeightKg': weight,
    };
    if (waist != null) updates['waistCircumferenceCm'] = waist;
    if (neck != null) updates['neckCircumferenceCm'] = neck;
    if (hip != null) updates['hipCircumferenceCm'] = hip;

    await _firestore.collection('users').doc(uid).update(updates);
  }
}

// Providers
final progressServiceProvider = Provider<ProgressService>((ref) {
  return ProgressService(FirebaseFirestore.instance);
});
