import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../fasting/application/fasting_controller.dart';
import '../domain/metabolic_phase.dart'; // <--- IMPORT CRÍTICO

// ─────────────────────────────────────────────────────────────────────────────
// METABOLIC PHASE PROVIDER — El Reloj Maestro de Elena
// ─────────────────────────────────────────────────────────────────────────────

final metabolicPhaseProvider = Provider<MetabolicPhase>((ref) {
  final now = DateTime.now();
  final hour = now.hour;
  final minute = now.minute;
  final timeAsDouble = hour + (minute / 60);
  
  final fastingState = ref.watch(fastingControllerProvider).valueOrNull;
  final fastingHours = fastingState?.elapsed.inHours ?? 0;

  // 1. PRIORIDAD: ESTADOS DE AYUNO (Fisiología sobre Horario)
  // Según "El Mapa Cronológico del Ayuno"
  if (fastingHours >= 18 && fastingHours < 24) return MetabolicPhase.fatBurning;
  if (fastingHours >= 12 && fastingHours < 18) return MetabolicPhase.metabolicSwitch;

  // 2. PRIORIDAD: CICLO CIRCADIANO (Ritmo Evolutivo)
  // Según "El Cronómetro Biológico"
  
  // Fenómeno del Amanecer (Cortisol/Glucosa endógena)
  if (timeAsDouble >= 4 && timeAsDouble < 9) return MetabolicPhase.dawnPhenomenon;
  
  // Pico Cognitivo (IQ máximo/Enfoque)
  if (timeAsDouble >= 9 && timeAsDouble < 12) return MetabolicPhase.cognitivePeak;
  
  // Ventana de Poder (Pico térmico y motor)
  if (timeAsDouble >= 15 && timeAsDouble < 18) return MetabolicPhase.powerWindow;
  
  // Bloqueo Intestinal y Reparación (Melatonina activa)
  if (timeAsDouble >= 22.5 || timeAsDouble < 4) return MetabolicPhase.digestiveLock;

  return MetabolicPhase.neutral;
});