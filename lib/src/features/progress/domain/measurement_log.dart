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
  final double? visceralFat;

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
    this.visceralFat,
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
      visceralFat: (data['visceralFat'] as num?)?.toDouble(),
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
      'visceralFat': visceralFat,
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
    required double? waistCm,
    required double? neckCm,
    double? hipCm,
    required bool isMale,
  }) {
    if (heightCm <= 0 ||
        waistCm == null ||
        neckCm == null ||
        waistCm <= 0 ||
        neckCm <= 0) {
      return null;
    }

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

  // Estimate Visceral Fat if missing
  static double? estimateVisceralFat({
    required double waistCm,
    required bool isMale,
  }) {
    if (waistCm <= 0) return null;
    // Simple heuristic placeholder
    // Men > 102cm, Women > 88cm -> High Risk (approx 15)
    // Else -> Normal (approx 8)
    if (isMale) {
      return waistCm > 102 ? 15.0 : 8.0;
    } else {
      return waistCm > 88 ? 15.0 : 8.0;
    }
  }

  MeasurementLog copyWith({
    String? id,
    DateTime? date,
    double? weight,
    double? waistCircumference,
    double? neckCircumference,
    double? hipCircumference,
    int? energyLevel,
    double? bodyFatPercentage,
    double? muscleMassPercentage,
    double? visceralFat,
  }) {
    return MeasurementLog(
      id: id ?? this.id,
      date: date ?? this.date,
      weight: weight ?? this.weight,
      waistCircumference: waistCircumference ?? this.waistCircumference,
      neckCircumference: neckCircumference ?? this.neckCircumference,
      hipCircumference: hipCircumference ?? this.hipCircumference,
      energyLevel: energyLevel ?? this.energyLevel,
      bodyFatPercentage: bodyFatPercentage ?? this.bodyFatPercentage,
      muscleMassPercentage: muscleMassPercentage ?? this.muscleMassPercentage,
      visceralFat: visceralFat ?? this.visceralFat,
    );
  }
}
