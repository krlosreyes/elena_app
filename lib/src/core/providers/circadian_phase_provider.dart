import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../science/metabolic_engine.dart';

/// Flujo de actualización del ritmo circadiano cada minuto.
final circadianPhaseProvider = StreamProvider.autoDispose<CircadianPhase>((ref) {
  final controller = StreamController<CircadianPhase>();
  
  // Emisión inicial inmediata
  controller.add(MetabolicEngine.getCurrentCircadianPhase());

  final timer = Timer.periodic(const Duration(minutes: 1), (_) {
    if (!controller.isClosed) {
      controller.add(MetabolicEngine.getCurrentCircadianPhase());
    }
  });

  ref.onDispose(() {
    timer.cancel();
    controller.close();
  });

  return controller.stream;
});

/// Label dinámico para la UI basado en las 8 fases del Cronómetro Biológico.
final circadianWindowLabelProvider = Provider.autoDispose<String>((ref) {
  final phase = ref.watch(circadianPhaseProvider).value ?? 
                MetabolicEngine.getCurrentCircadianPhase();

  return switch (phase) {
    CircadianPhase.morningActivation => 'OLA DE ALERTA · CORTISOL Y LUZ SOLAR',
    CircadianPhase.testosteronePeak => 'PICO HORMONAL · MÁXIMA TESTOSTERONA',
    CircadianPhase.cognitivePeak => 'PICO COGNITIVO · IQ Y TRABAJO PROFUNDO',
    CircadianPhase.afternoonDip => 'DESCANSÓ METABÓLICO · BAJA NATURAL',
    CircadianPhase.neuromotorWindow => 'VENTANA MOTORA · FUERZA Y REFLEJOS',
    CircadianPhase.thermalDecompression => 'DESCOMPRESIÓN TÉRMICA · CIERRE DIGESTIVO',
    CircadianPhase.melatoninRise => 'OLA DE SUEÑO · REPARACIÓN CELULAR',
    CircadianPhase.digestiveLock => 'BLOQUEO INTESTINAL · REPARACIÓN PROFUNDA',
  };
});

/// Colores hexadecimales alineados con la fisiología de cada fase.
final circadianPhaseColorProvider = Provider.autoDispose<int>((ref) {
  final phase = ref.watch(circadianPhaseProvider).value ?? 
                MetabolicEngine.getCurrentCircadianPhase();

  return switch (phase) {
    CircadianPhase.morningActivation => 0xFFFFD600, // Amarillo Cortisol
    CircadianPhase.testosteronePeak => 0xFF00E676,  // Verde Testo
    CircadianPhase.cognitivePeak => 0xFF00B0FF,     // Azul IQ
    CircadianPhase.afternoonDip => 0xFF9E9E9E,      // Gris Dip
    CircadianPhase.neuromotorWindow => 0xFFFF6D00,  // Naranja Motor
    CircadianPhase.thermalDecompression => 0xFFD50000, // Rojo Térmico
    CircadianPhase.melatoninRise => 0xFF6200EA,     // Púrpura Melatonina
    CircadianPhase.digestiveLock => 0xFF1A237E,     // Azul Profundo
  };
});