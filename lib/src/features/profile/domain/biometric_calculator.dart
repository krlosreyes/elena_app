import 'dart:math' as math;

import 'package:elena_app/src/shared/domain/models/user_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BIOMETRIC CALCULATOR — Pure Domain Logic
// No side effects. No Flutter dependencies. No Riverpod.
// ─────────────────────────────────────────────────────────────────────────────

enum IMRRiskLevel { red, yellow, green }

class BiometricResult {
  final double bmi;
  final double bodyFatPercentage;
  final double leanBodyMassKg;
  final IMRRiskLevel imrRiskLevel;
  final double waistToHeightRatio;
  final String riskDescription;

  BiometricResult({
    required this.bmi,
    required this.bodyFatPercentage,
    required this.leanBodyMassKg,
    required this.imrRiskLevel,
    required this.waistToHeightRatio,
    required this.riskDescription,
  });

  /// Get IMR risk color (hex string)
  String getIMRColor() {
    switch (imrRiskLevel) {
      case IMRRiskLevel.red:
        return '#FF4D4D'; // Elena High Risk Red
      case IMRRiskLevel.yellow:
        return '#FFD700'; // Metabolic Warning Yellow
      case IMRRiskLevel.green:
        return '#00FF9C'; // Deepmind Metabolic Green
    }
  }
}

class BiometricCalculator {
  // ──────────────────────────────────────────────────────────────────────────
  // PUBLIC CALCULATION METHODS
  // ──────────────────────────────────────────────────────────────────────────

  /// Calculate BMI (Body Mass Index)
  /// Formula: weight(kg) / (height(m))^2
  ///
  /// Classification:
  /// - Underweight: < 18.5
  /// - Normal: 18.5 - 24.9
  /// - Overweight: 25.0 - 29.9
  /// - Obese: >= 30.0
  static double calculateBMI({
    required double weightKg,
    required double heightCm,
  }) {
    if (heightCm <= 0 || weightKg <= 0) {
      throw ArgumentError('Weight and height must be positive values');
    }

    final heightM = heightCm / 100.0;
    final bmi = weightKg / (heightM * heightM);

    return double.parse(bmi.toStringAsFixed(2));
  }

  /// Calculate Body Fat Percentage using US Navy Formula
  /// This formula is non-invasive and highly accurate for most populations
  ///
  /// For Men: BF% = 495 / (1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(height)) - 450
  /// For Women: BF% = 495 / (1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(height)) - 450
  ///
  /// Parameters:
  /// - waistCm: Waist circumference at navel level
  /// - neckCm: Neck circumference (below larynx)
  /// - hipCm: Hip circumference (widest point, only for women)
  /// - heightCm: Height in centimeters
  /// - gender: Gender (affects formula)
  static double calculateBodyFat({
    required double waistCm,
    required double neckCm,
    required double? hipCm,
    required double heightCm,
    required Gender gender,
  }) {
    if (waistCm <= 0 || neckCm <= 0 || heightCm <= 0) {
      throw ArgumentError('Measurements must be positive values');
    }

    // Validate measurements are logical
    if (neckCm >= waistCm) {
      throw ArgumentError(
          'Neck circumference cannot be >= waist circumference');
    }

    if (gender == Gender.female && (hipCm == null || hipCm <= 0)) {
      throw ArgumentError(
          'Hip circumference is required for female calculations');
    }

    double bodyFatPercentage;

    if (gender == Gender.male) {
      // Men: BF% = 495 / (1.0324 - 0.19077 * log10(waist - neck) + 0.15456 * log10(height)) - 450
      final waistMinusNeck = waistCm - neckCm;
      final log10WaistMinusNeck = math.log(waistMinusNeck) / math.ln10;
      final log10Height = math.log(heightCm) / math.ln10;

      final denominator =
          1.0324 - (0.19077 * log10WaistMinusNeck) + (0.15456 * log10Height);

      bodyFatPercentage = (495 / denominator) - 450;
    } else {
      // Women: BF% = 495 / (1.29579 - 0.35004 * log10(waist + hip - neck) + 0.22100 * log10(height)) - 450
      final waistPlusHipMinusNeck = waistCm + hipCm! - neckCm;
      final log10WaistPlusHipMinusNeck =
          math.log(waistPlusHipMinusNeck) / math.ln10;
      final log10Height = math.log(heightCm) / math.ln10;

      final denominator = 1.29579 -
          (0.35004 * log10WaistPlusHipMinusNeck) +
          (0.22100 * log10Height);

      bodyFatPercentage = (495 / denominator) - 450;
    }

    // Clamp to realistic range (0-60%)
    bodyFatPercentage = math.max(2.0, math.min(60.0, bodyFatPercentage));

    return double.parse(bodyFatPercentage.toStringAsFixed(2));
  }

  /// Calculate Metabolic Risk using Waist Circumference
  /// Returns IMRRiskLevel based on gender and waist measurement
  ///
  /// Risk Classification (WHO):
  /// Men:
  ///   - Red (High Risk): > 94 cm
  ///   - Yellow (Increased Risk): 80-94 cm
  ///   - Green (Healthy): < 80 cm
  /// Women:
  ///   - Red (High Risk): > 80 cm
  ///   - Yellow (Increased Risk): 70-80 cm
  ///   - Green (Healthy): < 70 cm
  static IMRRiskLevel calculateIMR({
    required double waistCm,
    required Gender gender,
  }) {
    if (waistCm <= 0) {
      throw ArgumentError('Waist circumference must be positive');
    }

    if (gender == Gender.male) {
      if (waistCm > 94) {
        return IMRRiskLevel.red;
      } else if (waistCm >= 80) {
        return IMRRiskLevel.yellow;
      } else {
        return IMRRiskLevel.green;
      }
    } else {
      if (waistCm > 80) {
        return IMRRiskLevel.red;
      } else if (waistCm >= 70) {
        return IMRRiskLevel.yellow;
      } else {
        return IMRRiskLevel.green;
      }
    }
  }

  /// Calculate Lean Body Mass
  /// Formula: LBM = Weight * (1 - (Body Fat % / 100))
  static double calculateLeanBodyMass({
    required double weightKg,
    required double bodyFatPercentage,
  }) {
    if (weightKg <= 0 || bodyFatPercentage < 0) {
      throw ArgumentError('Invalid weight or body fat percentage');
    }

    final lbm = weightKg * (1.0 - (bodyFatPercentage / 100.0));
    return double.parse(lbm.toStringAsFixed(2));
  }

  /// Calculate Waist-to-Height Ratio
  /// Formula: Waist (cm) / Height (cm)
  ///
  /// Classification:
  /// - Healthy: < 0.5
  /// - At Risk: 0.5 - 0.59
  /// - High Risk: >= 0.6
  static double calculateWaistToHeightRatio({
    required double waistCm,
    required double heightCm,
  }) {
    if (waistCm <= 0 || heightCm <= 0) {
      throw ArgumentError('Measurements must be positive values');
    }

    final ratio = waistCm / heightCm;
    return double.parse(ratio.toStringAsFixed(3));
  }

  // ──────────────────────────────────────────────────────────────────────────
  // COMPOSITE CALCULATION — Full Biometric Profile
  // ──────────────────────────────────────────────────────────────────────────

  /// Generate complete biometric profile from user measurements
  static BiometricResult generateProfile({
    required UserModel user,
  }) {
    // Validate required measurements
    if (user.currentWeightKg <= 0 || user.heightCm <= 0) {
      throw ArgumentError('Weight and height are required');
    }

    final bmi = calculateBMI(
      weightKg: user.currentWeightKg,
      heightCm: user.heightCm,
    );

    // Body fat calculation requires waist and neck measurements
    double bodyFatPercentage = 0.0;
    if (user.waistCircumferenceCm != null && user.neckCircumferenceCm != null) {
      bodyFatPercentage = calculateBodyFat(
        waistCm: user.waistCircumferenceCm!,
        neckCm: user.neckCircumferenceCm!,
        hipCm: user.hipCircumferenceCm,
        heightCm: user.heightCm,
        gender: user.gender,
      );
    }

    // Calculate LBM
    final lbm = calculateLeanBodyMass(
      weightKg: user.currentWeightKg,
      bodyFatPercentage: bodyFatPercentage,
    );

    // Waist-to-Height Ratio
    final waistToHeightRatio = user.waistCircumferenceCm != null
        ? calculateWaistToHeightRatio(
            waistCm: user.waistCircumferenceCm!,
            heightCm: user.heightCm,
          )
        : 0.0;

    // IMR Risk Level
    IMRRiskLevel riskLevel = IMRRiskLevel.green;
    if (user.waistCircumferenceCm != null) {
      riskLevel = calculateIMR(
        waistCm: user.waistCircumferenceCm!,
        gender: user.gender,
      );
    }

    // Generate risk description
    final riskDescription = _generateRiskDescription(
      riskLevel: riskLevel,
      waistCm: user.waistCircumferenceCm,
      gender: user.gender,
    );

    return BiometricResult(
      bmi: bmi,
      bodyFatPercentage: bodyFatPercentage,
      leanBodyMassKg: lbm,
      imrRiskLevel: riskLevel,
      waistToHeightRatio: waistToHeightRatio,
      riskDescription: riskDescription,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // PRIVATE HELPERS
  // ──────────────────────────────────────────────────────────────────────────

  static String _generateRiskDescription({
    required IMRRiskLevel riskLevel,
    required double? waistCm,
    required Gender gender,
  }) {
    if (waistCm == null) {
      return 'Medidas de perímetro no registradas';
    }

    final threshold = gender == Gender.male ? 94.0 : 80.0;

    switch (riskLevel) {
      case IMRRiskLevel.red:
        return 'Alto riesgo metabólico. Circunferencia de cintura de $waistCm cm (> $threshold cm)';
      case IMRRiskLevel.yellow:
        return 'Riesgo metabólico moderado. Considere reducir circunferencia de cintura a < $threshold cm';
      case IMRRiskLevel.green:
        return 'Nivel de riesgo metabólico saludable. Continúe monitoreando.';
    }
  }

  /// Get BMI classification text
  static String getBMIClassification(double bmi) {
    if (bmi < 18.5) {
      return 'Bajo peso';
    } else if (bmi < 25.0) {
      return 'Peso normal';
    } else if (bmi < 30.0) {
      return 'Sobrepeso';
    } else {
      return 'Obeso';
    }
  }

  /// Get BMI classification color (hex value as string)
  static String getBMIColorHex(double bmi) {
    if (bmi < 18.5) {
      return '#4444FF'; // Blue
    } else if (bmi < 25.0) {
      return '#39FF14'; // Green
    } else if (bmi < 30.0) {
      return '#FFD700'; // Yellow
    } else {
      return '#FF4444'; // Red
    }
  }

  /// Get body fat classification
  static String getBodyFatClassification({
    required double percentage,
    required Gender gender,
  }) {
    if (gender == Gender.male) {
      if (percentage < 10) return 'Muy bajo';
      if (percentage < 14) return 'Bajo (Atlético)';
      if (percentage < 18) return 'Normal-Bajo';
      if (percentage < 25) return 'Normal';
      return 'Alto';
    } else {
      if (percentage < 14) return 'Muy bajo';
      if (percentage < 18) return 'Bajo (Atlético)';
      if (percentage < 24) return 'Normal-Bajo';
      if (percentage < 32) return 'Normal';
      return 'Alto';
    }
  }
}
