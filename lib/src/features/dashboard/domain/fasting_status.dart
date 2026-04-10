/// Fases biológicas extendidas según el mapa cronológico del ayuno
enum FastingPhase {
  postAbsorption, // 0-12h
  transition,     // 12-18h
  fatBurning,     // 18-24h
  autophagy,      // 24-48h
  survival        // 72h+
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
    this.phase = FastingPhase.postAbsorption,
    this.circadianPhase = "Iniciando...",
    this.timeUntilLock = Duration.zero,
    this.isActive = false,
  });

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