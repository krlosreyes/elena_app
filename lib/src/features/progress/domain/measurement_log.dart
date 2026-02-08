import 'package:cloud_firestore/cloud_firestore.dart';

class MeasurementLog {
  final String id;
  final DateTime date;
  final double weight;
  final double? waistCircumference;
  final int? energyLevel; // 1-10

  MeasurementLog({
    required this.id,
    required this.date,
    required this.weight,
    this.waistCircumference,
    this.energyLevel,
  });

  // Factory to create from Firestore
  factory MeasurementLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeasurementLog(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      weight: (data['weight'] as num).toDouble(),
      waistCircumference: (data['waistCircumference'] as num?)?.toDouble(),
      energyLevel: data['energyLevel'] as int?,
    );
  }

  // To JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'waistCircumference': waistCircumference,
      'energyLevel': energyLevel,
    };
  }

  // Calculated Getters

  // BMI = weight (kg) / (height (m) ^ 2)
  // Note: We need the user's height. For now, we'll calculate it if height is provided externally,
  // or we can add height to the log if it changes, but usually height is in User Profile.
  // For the model itself, maybe we just return the calculation method.
  double calculateBmi(double heightInMeters) {
    if (heightInMeters <= 0) return 0.0;
    return weight / (heightInMeters * heightInMeters);
  }

  // Waist-to-Height Ratio = waist (cm) / height (cm)
  double? calculateWaistToHeightRatio(double heightInCm) {
    if (waistCircumference == null || heightInCm <= 0) return null;
    return waistCircumference! / heightInCm;
  }
}
