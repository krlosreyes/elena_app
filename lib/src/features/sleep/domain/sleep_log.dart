import 'package:flutter/material.dart';

class SleepLog {
  final String id;
  final DateTime fellAsleep; 
  final DateTime wokeUp;     
  final DateTime lastMealTime;    

  SleepLog({
    required this.id,
    required this.fellAsleep,
    required this.wokeUp,
    required this.lastMealTime,
  });

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

  /// Semántica para el usuario: Transforma datos en información
  String get recoveryStatus {
    final hours = metabolicGap.inHours;
    if (hours >= 3) return "REPARACIÓN PROFUNDA";
    if (hours >= 2) return "REPARACIÓN INTERRUMPIDA";
    return "DIGESTIÓN ACTIVA";
  }

  String get gapDescription => "Cenaste ${metabolicGap.inHours}h antes de dormir";
}