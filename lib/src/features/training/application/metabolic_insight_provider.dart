import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Ensure AsyncValue is visible
import '../../fasting/presentation/providers/fasting_provider.dart';
import '../../fasting/domain/fasting_session.dart';
import '../../glucose/presentation/providers/glucose_provider.dart';
import '../../glucose/domain/glucose_model.dart';

part 'metabolic_insight_provider.g.dart';

class MetabolicInsight {
  final String message;
  final IconData icon;
  final Color color;
  final Color backgroundColor;

  MetabolicInsight({
    required this.message,
    required this.icon,
    required this.color,
    required this.backgroundColor,
  });
}

@riverpod
MetabolicInsight? metabolicInsight(MetabolicInsightRef ref) {
  // 1. Check Glucose (Priority: High)
  final AsyncValue<List<GlucoseLog>> glucoseState = ref.watch(filteredGlucoseProvider);

  if (glucoseState.hasValue && glucoseState.value != null && glucoseState.value!.isNotEmpty) {
    // Sort by timestamp descending just to be safe
    final logs = List.of(glucoseState.value!);
    logs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    
    final latestLog = logs.first;
    final hoursSinceLog = DateTime.now().difference(latestLog.timestamp).inHours;

    // Only relevant if log is very fresh (e.g., < 3 hours)
    if (hoursSinceLog < 3 && latestLog.value > 140) {
      return MetabolicInsight(
        message: "Pico de Glucosa Detectado (${latestLog.value.toInt()} mg/dL). \nSe sugiere una sesión de HIIT para activar receptores GLUT4 y estabilizar glicemia.",
        icon: Icons.bolt,
        color: Colors.orange.shade800,
        backgroundColor: Colors.orange.shade50,
      );
    }
  }

  // 2. Check Fasting (Priority: Medium)
  final AsyncValue<FastingSession?> fastingState = ref.watch(activeFastProvider);
  
  if (fastingState.hasValue && fastingState.value != null) {
    final session = fastingState.value!;
    final hoursFast = DateTime.now().difference(session.startTime).inHours;

    if (!session.isCompleted && hoursFast >= 14) {
      return MetabolicInsight(
        message: "Ayuno Profundo detectado ($hoursFast h). \nTu cuerpo está usando grasa como combustible. Mantén la intensidad en Zona 2 para maximizar la oxidación de lípidos.",
        icon: Icons.local_fire_department,
        color: Colors.blue.shade800,
        backgroundColor: Colors.blue.shade50,
      );
    }
  }

  return null;
}
