import 'package:flutter/material.dart';

class CircadianRules {
  static const int intestinalLockHour = 22;
  static const int intestinalLockMinute = 30;

  // Aseguramos que sean métodos estáticos
  static String getPhaseName(DateTime time) {
    int hour = time.hour;
    if (hour >= 6 && hour < 9) return "Activación (Cortisol)";
    if (hour >= 9 && hour < 13) return "Pico Cognitivo";
    if (hour >= 13 && hour < 17) return "Eficiencia Neuromotora";
    if (hour >= 17 && hour < 21) return "Máxima Fuerza";
    return "Reparación y Autofagia";
  }

  static Duration timeUntilLock(DateTime now) {
    DateTime lock = DateTime(now.year, now.month, now.day, intestinalLockHour, intestinalLockMinute);
    if (now.isAfter(lock)) return Duration.zero;
    return lock.difference(now);
  }
}