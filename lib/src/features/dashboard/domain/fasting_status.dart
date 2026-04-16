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
  final String fastingProtocol; // ej: "16:8", "18:6"
  
  // --- PROACTIVIDAD: ALERTA DE VENTANA CRÍTICA ---
  final bool nearSleepWarning; 

  // --- ESTADOS DE CONFIRMACIÓN MANUAL ---
  final bool isWaitingForFastingEnd;
  final bool isWaitingForFeedingEnd;
  final bool isSaving;

  FastingState({
    this.startTime,
    this.duration = Duration.zero,
    this.phase = FastingPhase.none,
    this.circadianPhase = "Iniciando...",
    this.timeUntilLock = Duration.zero,
    this.isActive = false,
    this.fastingProtocol = "16:8",
    this.nearSleepWarning = false, 
    this.isWaitingForFastingEnd = false,
    this.isWaitingForFeedingEnd = false,
    this.isSaving = false,
  });

  factory FastingState.initial() => FastingState();

  /// --- LÓGICA DE PROGRESO Y TARGET ---
  
  int get targetHours {
    final cleanProtocol = fastingProtocol.contains(':') 
        ? fastingProtocol.split(':').first 
        : "16";
    return int.tryParse(cleanProtocol) ?? 16;
  }

  double get progressPercentage {
    if (!isActive || targetHours == 0) return 0.0;
    final double percent = duration.inSeconds / (targetHours * 3600);
    return percent.clamp(0.0, 1.0);
  }

  static FastingPhase determinePhase(Duration duration) {
    final hours = duration.inHours;
    if (hours < 12) return FastingPhase.postAbsorption;
    if (hours < 18) return FastingPhase.transition;
    if (hours < 24) return FastingPhase.fatBurning;
    if (hours < 48) return FastingPhase.autophagy;
    return FastingPhase.survival;
  }

  String get metabolicMilestone {
    switch (phase) {
      case FastingPhase.none: return "Estado Anabólico";
      case FastingPhase.postAbsorption: return "Descenso de Insulina";
      case FastingPhase.transition: return "Inicio de Cetogénesis";
      case FastingPhase.fatBurning: return "Quema de Grasa";
      case FastingPhase.autophagy: return "Autofagia Activa";
      case FastingPhase.survival: return "Regeneración Celular";
    }
  }

  /// COMUNICACIÓN SEMÁNTICA DE ALERTA
  String? get metabolicAlert {
    if (nearSleepWarning && !isActive) {
      return "CIERRE DE VENTANA OBLIGATORIO: < 3H PARA REPARACIÓN";
    }
    return null;
  }

  String get nextMilestoneLabel {
    if (isActive) {
      if (duration.inHours < 12) return "SIGUIENTE ETAPA: DESCENSO DE INSULINA (12H)";
      if (duration.inHours < 18) return "SIGUIENTE ETAPA: QUEMA DE GRASA (18H)";
      if (duration.inHours < 24) return "SIGUIENTE ETAPA: AUTOFAGIA (24H)";
      return "FASE DE REGENERACIÓN PROFUNDA";
    } else {
      return nearSleepWarning ? "ATENCIÓN: RIESGO DE INSULINA NOCTURNA" : "META: INICIAR AYUNO";
    }
  }

  Duration get timeRemainingForNextMilestone {
    if (isActive) {
      if (duration.inHours < 12) return const Duration(hours: 12) - duration;
      if (duration.inHours < 18) return const Duration(hours: 18) - duration;
      if (duration.inHours < 24) return const Duration(hours: 24) - duration;
      return Duration.zero;
    } else {
      final remaining = const Duration(hours: 8) - duration;
      return remaining.isNegative ? Duration.zero : remaining;
    }
  }

  FastingState copyWith({
    DateTime? startTime, 
    Duration? duration, 
    FastingPhase? phase, 
    String? circadianPhase,
    Duration? timeUntilLock,
    bool? isActive,
    String? fastingProtocol,
    bool? nearSleepWarning,
    bool? isWaitingForFastingEnd,
    bool? isWaitingForFeedingEnd,
    bool? isSaving,
  }) {
    return FastingState(
      startTime: startTime ?? this.startTime,
      duration: duration ?? this.duration,
      phase: phase ?? this.phase,
      circadianPhase: circadianPhase ?? this.circadianPhase,
      timeUntilLock: timeUntilLock ?? this.timeUntilLock,
      isActive: isActive ?? this.isActive,
      fastingProtocol: fastingProtocol ?? this.fastingProtocol,
      nearSleepWarning: nearSleepWarning ?? this.nearSleepWarning,
      isWaitingForFastingEnd: isWaitingForFastingEnd ?? this.isWaitingForFastingEnd,
      isWaitingForFeedingEnd: isWaitingForFeedingEnd ?? this.isWaitingForFeedingEnd,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}