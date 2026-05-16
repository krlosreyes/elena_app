import 'package:flutter/material.dart';

import 'package:elena_app/src/core/errors/validation_error.dart';

/// Registro de un ciclo de sueño individual.
///
/// SPEC-69: amplía el modelo con campos opcionales para una métrica
/// multidimensional de calidad. Logs anteriores (sin estos campos)
/// siguen siendo válidos — el calculador degrada graciosamente.
class SleepLog {
  final String id;
  final DateTime fellAsleep;
  final DateTime wokeUp;
  final DateTime lastMealTime;

  // ── SPEC-69: dimensiones opcionales ─────────────────────────────────────

  /// Latencia: minutos entre acostarse e iniciar el sueño.
  /// Valor saludable: < 20 min. > 30 min sugiere ansiedad/insomnio.
  /// `null` si no se midió.
  final int? sleepLatencyMinutes;

  /// Número de despertares conscientes durante la noche.
  /// 0-1 es normal; ≥ 3 indica fragmentación. `null` si no se midió.
  final int? nightAwakenings;

  /// Calidad subjetiva 1-5 (1 = muy pobre, 5 = excelente).
  /// `null` si el usuario no la registró.
  final int? subjectiveQuality;

  SleepLog({
    required this.id,
    required this.fellAsleep,
    required this.wokeUp,
    required this.lastMealTime,
    this.sleepLatencyMinutes,
    this.nightAwakenings,
    this.subjectiveQuality,
  }) {
    // SPEC-62: errores tipados. Caller puede pattern-match sobre
    // ValidationError sin parsear strings de mensaje.
    if (sleepLatencyMinutes != null && sleepLatencyMinutes! < 0) {
      throw NegativeValue(
        field: 'sleepLatencyMinutes',
        value: sleepLatencyMinutes!,
      );
    }
    if (nightAwakenings != null && nightAwakenings! < 0) {
      throw NegativeValue(
        field: 'nightAwakenings',
        value: nightAwakenings!,
      );
    }
    if (subjectiveQuality != null) {
      if (subjectiveQuality! < 1 || subjectiveQuality! > 5) {
        throw OutOfRange(
          field: 'subjectiveQuality',
          value: subjectiveQuality!,
          min: 1,
          max: 5,
        );
      }
    }
  }

  /// Duración real: Maneja correctamente el cruce de medianoche
  Duration get duration {
    DateTime end = wokeUp;
    if (end.isBefore(fellAsleep)) {
      end = end.add(const Duration(days: 1));
    }
    return end.difference(fellAsleep);
  }

  /// Brecha metabólica: Tiempo entre la última comida y el sueño
  Duration get metabolicGap {
    if (fellAsleep.isBefore(lastMealTime)) return Duration.zero;
    return fellAsleep.difference(lastMealTime);
  }

  /// Semántica de salud: Diagnóstico para el usuario
  String get recoveryStatus {
    final hours = metabolicGap.inHours;
    if (hours >= 3) return "REPARACIÓN PROFUNDA";
    if (hours >= 2) return "REPARACIÓN INTERRUMPIDA";
    return "DIGESTIÓN ACTIVA";
  }

  String get gapDescription =>
      "Cenaste ${metabolicGap.inHours}h antes de dormir";
}
