import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../science/metabolic_engine.dart';

/// Provee la CircadianPhase actual y se actualiza cada minuto.
/// AutoDispose para liberar el timer cuando no hay listeners.
final circadianPhaseProvider =
    StreamProvider.autoDispose<CircadianPhase>((ref) {
  StreamController<CircadianPhase>? controller;
  Timer? timer;

  controller = StreamController<CircadianPhase>();
  controller.add(MetabolicEngine.getCurrentCircadianPhase());

  timer = Timer.periodic(const Duration(minutes: 1), (_) {
    controller?.add(
      MetabolicEngine.getCurrentCircadianPhase(),
    );
  });

  ref.onDispose(() {
    timer?.cancel();
    controller?.close();
  });

  return controller.stream;
});

/// Provee el label de ventana biológica actual para mostrar en UI.
/// Derivado de circadianPhaseProvider — no recalcula lógica.
final circadianWindowLabelProvider = Provider.autoDispose<String>((ref) {
  final phase = ref.watch(circadianPhaseProvider).value ??
      MetabolicEngine.getCurrentCircadianPhase();

  return switch (phase) {
    CircadianPhase.morningSensitivity => 'VENTANA COGNITIVA · PICO DE CLARIDAD',
    CircadianPhase.afternoonDip => 'VENTANA NEUROMOTORA · FUERZA Y CARDIO',
    CircadianPhase.melatoninRise => 'CIERRE DIGESTIVO · REPARACIÓN PRÓXIMA',
    CircadianPhase.deepSleep => 'REPARACIÓN CELULAR · SUEÑO PROFUNDO',
  };
});

/// Provee el color asociado a la ventana circadiana actual.
final circadianPhaseColorProvider = Provider.autoDispose<int>((ref) {
  final phase = ref.watch(circadianPhaseProvider).value ??
      MetabolicEngine.getCurrentCircadianPhase();

  return switch (phase) {
    CircadianPhase.morningSensitivity => 0xFFFFD600, // Amarillo — cortisol
    CircadianPhase.afternoonDip => 0xFFFF6B35, // Naranja — motor físico
    CircadianPhase.melatoninRise => 0xFF9C27B0, // Púrpura — melatonina
    CircadianPhase.deepSleep => 0xFF1A237E, // Azul profundo — sueño
  };
});
