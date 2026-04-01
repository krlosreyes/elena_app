import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/features/health/data/health_repository.dart';
import '../../authentication/application/auth_controller.dart';
import '../../../core/providers/metabolic_hub_provider.dart';
import 'package:elena_app/src/features/profile/application/user_controller.dart';

final dashboardTabIndexProvider = StateProvider<int>((ref) => 0);

/// 🧊 GUARDIÁN DE REGISTRO: Rastrea el último hito de comida disparado automáticamente
final lastAutomatedMealIndexProvider = StateProvider<int>((ref) => -1);

final dailyComplianceScoreProvider = Provider<double>((ref) {
  final user = ref.watch(authControllerProvider.notifier).currentUser;
  if (user == null) return 0.0;

  final dailyLogAsync = ref.watch(todayLogProvider(user.uid));

  return dailyLogAsync.when(
    data: (log) {
      if (log == null) return 0.0;

      // 1. Ayuno (Simulando meta de 16h si no hay plan específico)
      double fastingHours = 0;
      if (log.fastingStartTime != null && log.fastingEndTime != null) {
        fastingHours =
            log.fastingEndTime!.difference(log.fastingStartTime!).inMinutes /
                60.0;
      }
      final fastingGoal = 16.0;
      final fastingProgress = (fastingHours / fastingGoal).clamp(0.0, 1.0);

      // 2. Ejercicio
      final exerciseMinutes = log.exerciseMinutes;
      final exerciseGoal = 30; // Default
      final exerciseProgress = (exerciseMinutes / exerciseGoal).clamp(0.0, 1.0);

      // 3. Hidratación
      final hydrationCount = log.waterGlasses;
      final hydrationGoal = 8;
      final hydrationProgress =
          (hydrationCount / hydrationGoal).clamp(0.0, 1.0);

      // 4. Sueño
      final sleepHours = log.sleepMinutes / 60.0;
      final sleepGoal = 8.0;
      final sleepProgress = (sleepHours / sleepGoal).clamp(0.0, 1.0);

      // 5. Alimentación (Proteína)
      final proteinGrams = log.proteinGrams;
      final proteinGoal = 75;
      final proteinProgress = (proteinGrams / proteinGoal).clamp(0.0, 1.0);

      final totalProgress = (fastingProgress +
              exerciseProgress +
              hydrationProgress +
              sleepProgress +
              proteinProgress) /
          5;
      return totalProgress * 100;
    },
    loading: () => 0.0,
    error: (_, __) => 0.0,
  );
});

final dailyMotivationalPhraseProvider = Provider<String>((ref) {
  final score = ref.watch(dailyComplianceScoreProvider);

  // Mensajes basados en Score General (Breves y Concisos - Máx 4 palabras)
  final mtiScore = ref.watch(metabolicHubProvider).totalIED;
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  final waist = user?.waistCircumferenceCm ?? 95.0;

  if (score < 30) {
    return "Tu MTI de ${mtiScore.toStringAsFixed(1)} es el umbral de tu cambio. Vamos por el 70.";
  } else if (score < 60) {
    return "Cada minuto de ayuno es un respiro para tu páncreas. Estabilidad celular en proceso.";
  } else if (score < 85) {
    return "${waist.toStringAsFixed(0)} cm de cintura es solo un número de partida. Hoy reducimos milímetros.";
  } else {
    return "Metamorfosis Real activa. Tu eficiencia metabólica está en niveles de élite.";
  }
});

/// 🥩 STRICT MEAL COUNT: Consulta directa a Firestore para verificación de seguridad
final strictMealCountProvider =
    StreamProvider.autoDispose.family<int, String>((ref, uid) {
  final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
  return FirebaseFirestore.instance
      .collection('users')
      .doc(uid)
      .collection('daily_logs')
      .where('date', isEqualTo: todayId)
      .where('type', isEqualTo: 'meal')
      .snapshots()
      .map((snapshot) {
    for (var doc in snapshot.docs) {
      debugPrint('🧪 Elena DEBUG: ID DE COMIDA ENCONTRADA: ${doc.id}');
    }
    return snapshot.docs.length;
  });
});
