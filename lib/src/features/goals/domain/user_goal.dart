// SPEC-14: Objetivos del Usuario
// Modelo de datos para los objetivos personales del usuario.
// Sistema independiente de UserModel — persiste en Firestore bajo users/{uid}
// como campo 'goals' (Map). No requiere build_runner.

import 'package:flutter/material.dart';

// ─── Tipos de objetivo (uno por pilar + composición corporal) ─────────────────

enum GoalType {
  weightTarget,         // Pilar: Composición Corporal — kg objetivo
  bodyFatTarget,        // Pilar: Composición Corporal — % grasa objetivo
  fastingDaysPerWeek,   // Pilar: Ayuno — días por semana con protocolo completo
  exerciseMinPerDay,    // Pilar: Ejercicio — minutos diarios de actividad
  sleepHoursPerNight,   // Pilar: Sueño — horas de sueño por noche
  hydrationLitersPerDay,// Pilar: Hidratación — litros diarios
}

// ─── Modelo principal ─────────────────────────────────────────────────────────

class UserGoal {
  final GoalType type;

  /// Valor que el usuario quiere alcanzar.
  final double targetValue;

  /// Valor registrado al momento de crear el objetivo (línea de base).
  final double startValue;

  /// Si el objetivo está activo y se muestra en el dashboard.
  final bool isActive;

  /// Fecha de creación del objetivo.
  final DateTime createdAt;

  /// Fecha límite opcional.
  final DateTime? deadline;

  const UserGoal({
    required this.type,
    required this.targetValue,
    required this.startValue,
    this.isActive = true,
    required this.createdAt,
    this.deadline,
  });

  // ─── Metadata de presentación ───────────────────────────────────────────────

  String get label {
    switch (type) {
      case GoalType.weightTarget:          return 'Peso Objetivo';
      case GoalType.bodyFatTarget:         return 'Grasa Corporal';
      case GoalType.fastingDaysPerWeek:    return 'Días de Ayuno';
      case GoalType.exerciseMinPerDay:     return 'Ejercicio Diario';
      case GoalType.sleepHoursPerNight:    return 'Sueño';
      case GoalType.hydrationLitersPerDay: return 'Hidratación';
    }
  }

  String get unit {
    switch (type) {
      case GoalType.weightTarget:          return 'kg';
      case GoalType.bodyFatTarget:         return '%';
      case GoalType.fastingDaysPerWeek:    return 'días/sem';
      case GoalType.exerciseMinPerDay:     return 'min/día';
      case GoalType.sleepHoursPerNight:    return 'h/noche';
      case GoalType.hydrationLitersPerDay: return 'L/día';
    }
  }

  String get emoji {
    switch (type) {
      case GoalType.weightTarget:          return '⚖️';
      case GoalType.bodyFatTarget:         return '🔥';
      case GoalType.fastingDaysPerWeek:    return '⏱️';
      case GoalType.exerciseMinPerDay:     return '💪';
      case GoalType.sleepHoursPerNight:    return '🌙';
      case GoalType.hydrationLitersPerDay: return '💧';
    }
  }

  /// Rango deslizable mínimo para el slider de setup.
  double get sliderMin {
    switch (type) {
      case GoalType.weightTarget:          return 40.0;
      case GoalType.bodyFatTarget:         return 5.0;
      case GoalType.fastingDaysPerWeek:    return 1.0;
      case GoalType.exerciseMinPerDay:     return 15.0;
      case GoalType.sleepHoursPerNight:    return 5.0;
      case GoalType.hydrationLitersPerDay: return 1.0;
    }
  }

  /// Rango deslizable máximo para el slider de setup.
  double get sliderMax {
    switch (type) {
      case GoalType.weightTarget:          return 150.0;
      case GoalType.bodyFatTarget:         return 45.0;
      case GoalType.fastingDaysPerWeek:    return 7.0;
      case GoalType.exerciseMinPerDay:     return 120.0;
      case GoalType.sleepHoursPerNight:    return 10.0;
      case GoalType.hydrationLitersPerDay: return 4.0;
    }
  }

  int get sliderDivisions {
    switch (type) {
      case GoalType.weightTarget:          return 220; // 40–150 paso 0.5 → 110*2=220
      case GoalType.bodyFatTarget:         return 40;  // 5–45 paso 1
      case GoalType.fastingDaysPerWeek:    return 6;   // 1–7
      case GoalType.exerciseMinPerDay:     return 21;  // 15–120 paso 5 → 105/5=21
      case GoalType.sleepHoursPerNight:    return 10;  // 5–10 paso 0.5 → 5/0.5=10
      case GoalType.hydrationLitersPerDay: return 12;  // 1–4 paso 0.25 → 3/0.25=12
    }
  }

  Color get pillarColor {
    switch (type) {
      case GoalType.weightTarget:
      case GoalType.bodyFatTarget:         return const Color(0xFF1ABC9C);
      case GoalType.fastingDaysPerWeek:    return const Color(0xFFF39C12);
      case GoalType.exerciseMinPerDay:     return const Color(0xFF3498DB);
      case GoalType.sleepHoursPerNight:    return const Color(0xFF9B59B6);
      case GoalType.hydrationLitersPerDay: return const Color(0xFF27AE60);
    }
  }

  /// true = el objetivo es "reducir" (peso, grasa). false = "aumentar".
  bool get isReductionGoal {
    return type == GoalType.weightTarget || type == GoalType.bodyFatTarget;
  }

  /// Progreso normalizado 0.0–1.0 dado un valor actual.
  /// Para objetivos de reducción: 0 = en start, 1 = en target.
  double progress(double currentValue) {
    if (startValue == targetValue) return 1.0;
    if (isReductionGoal) {
      // Queremos bajar: de startValue a targetValue (startValue > targetValue)
      final double total = startValue - targetValue;
      final double done  = startValue - currentValue;
      return (done / total).clamp(0.0, 1.0);
    } else {
      // Queremos subir: de startValue a targetValue
      final double total = targetValue - startValue;
      final double done  = currentValue - startValue;
      return (done / total).clamp(0.0, 1.0);
    }
  }

  // ─── Serialización manual (sin Freezed / build_runner) ─────────────────────

  Map<String, dynamic> toJson() => {
    'type':        type.name,
    'targetValue': targetValue,
    'startValue':  startValue,
    'isActive':    isActive,
    'createdAt':   createdAt.toIso8601String(),
    'deadline':    deadline?.toIso8601String(),
  };

  factory UserGoal.fromJson(Map<String, dynamic> json) {
    return UserGoal(
      type:        GoalType.values.firstWhere((e) => e.name == json['type']),
      targetValue: (json['targetValue'] as num).toDouble(),
      startValue:  (json['startValue']  as num).toDouble(),
      isActive:    json['isActive'] as bool? ?? true,
      createdAt:   DateTime.parse(json['createdAt'] as String),
      deadline:    json['deadline'] != null
                       ? DateTime.parse(json['deadline'] as String)
                       : null,
    );
  }

  UserGoal copyWith({
    double?   targetValue,
    double?   startValue,
    bool?     isActive,
    DateTime? deadline,
  }) {
    return UserGoal(
      type:        type,
      targetValue: targetValue ?? this.targetValue,
      startValue:  startValue  ?? this.startValue,
      isActive:    isActive    ?? this.isActive,
      createdAt:   createdAt,
      deadline:    deadline ?? this.deadline,
    );
  }
}
