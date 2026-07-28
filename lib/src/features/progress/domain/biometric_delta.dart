// SPEC-143: BiometricDelta — value object que representa un cambio
// propuesto en los campos biométricos del usuario.
//
// Se consume desde BiometricHistoryService antes de escribir, para
// determinar si el cambio es significativo (vale la pena versionar)
// o es ruido del sensor (HealthKit sync con variaciones < threshold).
//
// Es Dart puro — sin Flutter, sin Riverpod, sin Freezed (consistente
// con el patrón de biometric_checkin.dart).

import 'package:elena_app/src/shared/domain/models/user_model.dart';

/// Cambio propuesto en los campos biométricos. Todos los campos son
/// opcionales — un delta puede tocar solo peso, solo cintura, varios
/// a la vez, etc.
class BiometricDelta {
  /// Nuevo peso en kg.
  final double? weight;

  /// Nueva circunferencia de cintura en cm.
  final double? waistCircumference;

  /// Nueva circunferencia de cuello en cm.
  final double? neckCircumference;

  /// Nuevo porcentaje de grasa corporal.
  final double? bodyFatPercentage;

  /// Nuevo flag de medición estimada (vs medición real con cinta).
  final bool? isMeasurementEstimated;

  const BiometricDelta({
    this.weight,
    this.waistCircumference,
    this.neckCircumference,
    this.bodyFatPercentage,
    this.isMeasurementEstimated,
  });

  /// True si AL MENOS UN campo del delta excede el threshold de cambio
  /// significativo respecto al baseline. Si es false, el llamador puede
  /// descartar el delta como ruido (típicamente HealthKit sync).
  ///
  /// Thresholds — SPEC-143 §RF-143-08:
  /// - Peso: 0.5% relativo (0.4 kg en 75 kg dispara)
  /// - Cintura: 0.5% relativo (0.45 cm en 90 cm dispara)
  /// - Cuello: 1.0% relativo (las mediciones manuales son más ruidosas)
  /// - BodyFat: 0.5 puntos porcentuales absolutos (el % es volátil)
  /// - isMeasurementEstimated: cualquier toggle es significativo
  ///
  /// Para HealthKit/HC sync usar threshold conservador (false negative
  /// preferible a false positive — un cambio real pequeño se capta en
  /// el próximo sync). Para edits manuales del usuario, considerar
  /// siempre significativo (el usuario explícitamente lo cambió).
  bool isSignificant({required UserModel baseline}) {
    if (isMeasurementEstimated != null &&
        isMeasurementEstimated != baseline.isMeasurementEstimated) {
      return true;
    }

    if (weight != null &&
        _relativeDeltaExceeds(weight!, baseline.weight, 0.005)) {
      return true;
    }

    final baseWaist = baseline.waistCircumference;
    if (waistCircumference != null &&
        baseWaist != null &&
        _relativeDeltaExceeds(waistCircumference!, baseWaist, 0.005)) {
      return true;
    }

    final baseNeck = baseline.neckCircumference;
    if (neckCircumference != null &&
        baseNeck != null &&
        _relativeDeltaExceeds(neckCircumference!, baseNeck, 0.010)) {
      return true;
    }

    final baseBf = baseline.bodyFatPercentage;
    if (bodyFatPercentage != null &&
        baseBf != null &&
        (bodyFatPercentage! - baseBf).abs() >= 0.5) {
      return true;
    }

    // Caso especial: el baseline tiene un campo null y el delta lo aporta.
    // Esto es siempre significativo — el usuario está completando datos
    // que antes no tenía.
    if (waistCircumference != null && baseWaist == null) return true;
    if (neckCircumference != null && baseNeck == null) return true;
    if (bodyFatPercentage != null && baseBf == null) return true;

    return false;
  }

  /// True si el delta no aporta ningún cambio (todos los campos null).
  bool get isEmpty =>
      weight == null &&
      waistCircumference == null &&
      neckCircumference == null &&
      bodyFatPercentage == null &&
      isMeasurementEstimated == null;

  /// Mapa con SOLO los campos que cambian respecto al baseline.
  /// Útil para construir el `previousValues` audit en biometric_history.
  /// Devuelve los valores PREVIOS de los campos que el delta modifica.
  Map<String, dynamic> previousValuesAgainst(UserModel baseline) {
    final out = <String, dynamic>{};
    if (weight != null && weight != baseline.weight) {
      out['weight'] = baseline.weight;
    }
    if (waistCircumference != null &&
        waistCircumference != baseline.waistCircumference) {
      out['waistCircumference'] = baseline.waistCircumference;
    }
    if (neckCircumference != null &&
        neckCircumference != baseline.neckCircumference) {
      out['neckCircumference'] = baseline.neckCircumference;
    }
    if (bodyFatPercentage != null &&
        bodyFatPercentage != baseline.bodyFatPercentage) {
      out['bodyFatPercentage'] = baseline.bodyFatPercentage;
    }
    return out;
  }

  /// Aplica el delta sobre un UserModel y devuelve una copia con los
  /// campos del delta sobrescritos. Si el delta no toca un campo, el
  /// valor del baseline se preserva.
  UserModel applyTo(UserModel baseline) {
    return baseline.copyWith(
      weight: weight ?? baseline.weight,
      waistCircumference: waistCircumference ?? baseline.waistCircumference,
      neckCircumference: neckCircumference ?? baseline.neckCircumference,
      bodyFatPercentage: bodyFatPercentage ?? baseline.bodyFatPercentage,
      isMeasurementEstimated:
          isMeasurementEstimated ?? baseline.isMeasurementEstimated,
    );
  }

  // ─── Helpers privados ──────────────────────────────────────────────────────

  /// True si |a - b| / b > threshold. Si b es 0 o negativo, retorna true
  /// para evitar división por cero (cualquier cambio desde 0 es significativo).
  static bool _relativeDeltaExceeds(double a, double b, double threshold) {
    if (b <= 0) return a > 0;
    return (a - b).abs() / b > threshold;
  }

  @override
  String toString() =>
      'BiometricDelta(weight: $weight, waist: $waistCircumference, '
      'neck: $neckCircumference, bodyFat: $bodyFatPercentage, '
      'estimated: $isMeasurementEstimated)';
}

/// Fuentes posibles de un cambio biométrico. SPEC-143 §RF-143-02.
///
/// Se persiste como String en `biometric_history.source` para que docs
/// legacy (sin esta info) sigan siendo leíbles como null.
class BiometricSource {
  static const String profileEdit = 'profile_edit';
  static const String checkinSheet = 'checkin_sheet';
  static const String healthkitSync = 'healthkit_sync';
  static const String bodyFatRecompute = 'bodyfat_recompute';
  static const String onboardingBaseline = 'onboarding_baseline';
  static const String spec143Backfill = 'spec_143_backfill';

  /// Todas las fuentes válidas. Útil para validación en tests/CI.
  static const Set<String> all = {
    profileEdit,
    checkinSheet,
    healthkitSync,
    bodyFatRecompute,
    onboardingBaseline,
    spec143Backfill,
  };

  BiometricSource._();
}
