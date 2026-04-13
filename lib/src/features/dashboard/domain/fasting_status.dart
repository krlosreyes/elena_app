     import 'package:flutter/material.dart';

/// Fases biológicas extendidas según el mapa cronológico del ayuno real
enum FastingPhase {
  none,            // Estado inicial/Alimentación
  postAbsorption, // 0-12h: Descenso de insulina
  transition,     // 12-18h: Gluconeogénesis
  fatBurning,     // 18-24h: Cetosis nutricional
  autophagy,      // 24-48h: Reciclaje celular
  survival        // 48h+: Conservación profunda
}

class FastingState {
  final DateTime? startTime;
  final Duration duration;
  final FastingPhase phase;
  final String circadianPhase;
  final Duration timeUntilLock;
  final bool isActive;

  FastingState({
    this.startTime,
    this.duration = Duration.zero,
    this.phase = FastingPhase.none,
    this.circadianPhase = "Iniciando...",
    this.timeUntilLock = Duration.zero,
    this.isActive = false,
  });

  factory FastingState.initial() => FastingState();

  /// Determina la fase biológica exacta basándose en la duración transcurrida
  static FastingPhase determinePhase(Duration duration) {
    final hours = duration.inHours;
    if (hours < 12) return FastingPhase.postAbsorption;
    if (hours < 18) return FastingPhase.transition;
    if (hours < 24) return FastingPhase.fatBurning;
    if (hours < 48) return FastingPhase.autophagy;
    return FastingPhase.survival;
  }

  /// NUEVO: Lógica Proactiva de Hitos Metabólicos
  /// Devuelve el nombre del próximo beneficio biológico
  String get nextMilestoneLabel {
    if (isActive) {
      if (duration.inHours < 12) return "PARA DESCENSO DE INSULINA";
      if (duration.inHours < 18) return "PARA QUEMA DE GRASA";
      if (duration.inHours < 24) return "PARA AUTOFAGIA";
      return "EN REGENERACIÓN PROFUNDA";
    } else {
      return "PARA CIERRE DE VENTANA";
    }
  }

  /// NUEVO: Tiempo restante para el siguiente objetivo
  /// Basado en umbrales técnicos: 12h, 18h, 24h y Ventana de 8h
  Duration get timeRemainingForNextMilestone {
    if (isActive) {
      if (duration.inHours < 12) return const Duration(hours: 12) - duration;
      if (duration.inHours < 18) return const Duration(hours: 18) - duration;
      if (duration.inHours < 24) return const Duration(hours: 24) - duration;
      return Duration.zero;
    } else {
      // Asumimos ventana de 8 horas para el cálculo proactivo
      final remaining = const Duration(hours: 8) - duration;
      return remaining.isNegative ? Duration.zero : remaining;
    }
  }

  String get metabolicMilestone {
    switch (phase) {
      case FastingPhase.none: return "Estado Anabólico";
      case FastingPhase.postAbsorption: return "Descenso de Glucemia e Insulina";
      case FastingPhase.transition: return "Inicio de Cetogénesis";
      case FastingPhase.fatBurning: return "Quema de Grasa Optimizada";
      case FastingPhase.autophagy: return "Reciclaje Proteico (Autofagia)";
      case FastingPhase.survival: return "Regeneración de Células Madre";
    }
  }

  FastingState copyWith({
    DateTime? startTime, 
    Duration? duration, 
    FastingPhase? phase, 
    String? circadianPhase,
    Duration? timeUntilLock,
    bool? isActive
  }) {
    return FastingState(
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      phase: phase ?? this.phase,
      circadianPhase: circadianPhase ?? this.circadianPhase,
      timeUntilLock: timeUntilLock ?? this.timeUntilLock,
      isActive: isActive ?? this.isActive,
    );
  }
}