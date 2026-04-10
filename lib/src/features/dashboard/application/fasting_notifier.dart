import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/rules/circadian_rules.dart';

/// Fases biológicas extendidas según el mapa cronológico del ayuno
enum FastingPhase {
  postAbsorption, // 0-12h: Digestión activa. Estado base.
  transition,     // 12-18h: Agotamiento de glucógeno. Cambio de combustible.
  fatBurning,     // 18-24h: Cetosis temprana. Quema de grasa activa.
  autophagy,      // 24-48h: Renovación celular profunda.
  survival        // 72h+: Restricción del sistema por seguridad.
}

class FastingState {
  final DateTime? startTime;
  final Duration duration;
  final FastingPhase phase;
  final String circadianPhase; // Fase según el reloj maestro (Cortisol, Melatonina, etc)
  final Duration timeUntilLock; // Tiempo restante hasta el bloqueo intestinal (22:30)
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

class FastingNotifier extends StateNotifier<FastingState> {
  Timer? _timer;

  FastingNotifier() : super(FastingState());

  /// Inicia el cronómetro metabólico
  void startFasting() {
    final now = DateTime.now();
    state = state.copyWith(
      startTime: now, 
      isActive: true,
      circadianPhase: CircadianRules.getPhaseName(now),
      timeUntilLock: CircadianRules.timeUntilLock(now),
    );
    _tick();
    // Actualizamos cada segundo para la fluidez de la UI del Dashboard
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  /// Detiene el proceso y resetea el estado
  void stopFasting() {
    _timer?.cancel();
    state = FastingState();
  }

  void _tick() {
    final now = DateTime.now();
    
    // Si no está ayunando, aún actualizamos la fase circadiana y el bloqueo
    if (!state.isActive) {
      state = state.copyWith(
        circadianPhase: CircadianRules.getPhaseName(now),
        timeUntilLock: CircadianRules.timeUntilLock(now),
      );
      return;
    }

    if (state.startTime == null) return;
    
    final duration = now.difference(state.startTime!);
    state = state.copyWith(
      duration: duration,
      phase: _calculateFastingPhase(duration),
      circadianPhase: CircadianRules.getPhaseName(now),
      timeUntilLock: CircadianRules.timeUntilLock(now),
    );
  }

  /// Lógica de fases basada en el Mapa Cronológico de ElenaApp
  FastingPhase _calculateFastingPhase(Duration d) {
    final hours = d.inHours;
    if (hours < 12) return FastingPhase.postAbsorption;
    if (hours < 18) return FastingPhase.transition;
    if (hours < 24) return FastingPhase.fatBurning;
    if (hours < 72) return FastingPhase.autophagy;
    return FastingPhase.survival;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final fastingProvider = StateNotifierProvider<FastingNotifier, FastingState>((ref) {
  return FastingNotifier();
});