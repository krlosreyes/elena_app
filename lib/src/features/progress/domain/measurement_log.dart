import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeasurementLog {
  final String id;
  final DateTime date;
  final double weight;
  final double? waistCircumference;
  final double? neckCircumference;
  final double? hipCircumference;
  final int? energyLevel; // 1-10
  final double? bodyFatPercentage;
  final double? muscleMassPercentage;

  MeasurementLog({
    required this.id,
    required this.date,
    required this.weight,
    this.waistCircumference,
    this.neckCircumference,
    this.hipCircumference,
    this.energyLevel,
    this.bodyFatPercentage,
    this.muscleMassPercentage,
  });

  // Factory to create from Firestore
  factory MeasurementLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MeasurementLog(
      id: doc.id,
      date: (data['date'] as Timestamp).toDate(),
      weight: (data['weight'] as num).toDouble(),
      waistCircumference: (data['waistCircumference'] as num?)?.toDouble(),
      neckCircumference: (data['neckCircumference'] as num?)?.toDouble(),
      hipCircumference: (data['hipCircumference'] as num?)?.toDouble(),
      energyLevel: data['energyLevel'] as int?,
      bodyFatPercentage: (data['bodyFatPercentage'] as num?)?.toDouble(),
      muscleMassPercentage: (data['muscleMassPercentage'] as num?)?.toDouble(),
    );
  }

  // To JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'date': Timestamp.fromDate(date),
      'weight': weight,
      'waistCircumference': waistCircumference,
      'neckCircumference': neckCircumference,
      'hipCircumference': hipCircumference,
      'energyLevel': energyLevel,
      'bodyFatPercentage': bodyFatPercentage,
      'muscleMassPercentage': muscleMassPercentage,
    };
  }

  // Calculated Getters

  // BMI = weight (kg) / (height (m) ^ 2)
  double calculateBmi(double heightInMeters) {
    if (heightInMeters <= 0) return 0.0;
    return weight / (heightInMeters * heightInMeters);
  }

  // Waist-to-Height Ratio = waist (cm) / height (cm)
  double? calculateWaistToHeightRatio(double heightInCm) {
    if (waistCircumference == null || heightInCm <= 0) return null;
    return waistCircumference! / heightInCm;
  }

  // Static: Calculate Body Fat (US Navy Formula)
  static double? calculateBodyFat({
    required double heightCm,
    required double waistCm,
    required double neckCm,
    double? hipCm,
    required bool isMale,
  }) {
    if (heightCm <= 0 || waistCm <= 0 || neckCm <= 0) return null;

    try {
      if (isMale) {
        // Male: 495 / (1.0324 - 0.19077 * log10(waist-neck) + 0.15456 * log10(height)) - 450
        return 495 /
                (1.0324 -
                    0.19077 * (log(waistCm - neckCm) / ln10) +
                    0.15456 * (log(heightCm) / ln10)) -
            450;
      } else {
        // Female: 495 / (1.29579 - 0.35004 * log10(waist+hip-neck) + 0.22100 * log10(height)) - 450
        if (hipCm == null) return null;
        return 495 /
                (1.29579 -
                    0.35004 * (log(waistCm + hipCm - neckCm) / ln10) +
                    0.22100 * (log(heightCm) / ln10)) -
            450;
      }
    } catch (e) {
      return null;
    }
  }
}
