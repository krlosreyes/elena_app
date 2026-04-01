import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/fasting/application/fasting_controller.dart';
import '../../features/glucose/application/glucose_provider.dart';
import '../../features/health/data/health_repository.dart';
import '../../features/profile/application/user_controller.dart';
import '../../domain/logic/elena_brain.dart';
import '../../features/fasting/domain/meal_milestone_calculator.dart';
import 'package:elena_app/src/shared/domain/models/metabolic_milestone.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_model.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import '../../features/training/application/movement_controller.dart';
import '../../features/health/domain/daily_log.dart';
import '../../features/sleep/application/sleep_controller.dart';

/// ✅ METABOLIC CONTEXT
class MetabolicContext {
  final FastingState? fastingStatus;
  final GlucoseLog? lastGlucoseReading;
  final double hydrationLevel; // In glasses (1 glass = 250ml)
  final UserModel? profile;
  final DateTime? lastHydrationReminder;
  final bool isInsistentMode;
  final ExerciseState? movementStatus;
  final double sleepMinutes;
  final double nutritionScore; // % based on meals logged vs expected
  final int actualMeals; // Number of meals logged today
  final int expectedMeals; // Total meals planned for this protocol
  final double totalIED;
  final bool isWindowClosing;
  final double lastSleepScore;

  // Convenience Getters
  bool get isFasting => fastingStatus?.isFasting ?? true;
  bool get isFeeding => fastingStatus?.isFeeding ?? false;

  // Real-time Estimated Biometrics (from ElenaBrain)
  final double estimatedGlucose;
  final double estimatedKetones;

  // Geometry for 24h Circle
  final List<MetabolicMilestone> mealMilestones;
  final List<MetabolicMilestone> physiologicalMilestones;

  final double protocolFastingProgress; // 0.66 for 16:8
  final double startHour; // 0-24.0 (Actual or Onboarding fallback)
  final double currentTotalProgress; // Total elapsed / 24h

  MetabolicContext({
    this.fastingStatus,
    this.lastGlucoseReading,
    this.hydrationLevel = 0.0,
    this.profile,
    this.estimatedGlucose = 0.0,
    this.estimatedKetones = 0.0,
    this.mealMilestones = const [],
    this.physiologicalMilestones = const [],
    this.protocolFastingProgress = 0.5,
    this.currentTotalProgress = 0.0,
    this.startHour = 20.0, // Default 8 PM
    this.lastHydrationReminder,
    this.isInsistentMode = false,
    this.movementStatus,
    this.sleepMinutes = 0.0,
    this.nutritionScore = 0.0,
    this.actualMeals = 0,
    this.expectedMeals = 1,
    this.totalIED = 0.0,
    this.isWindowClosing = false,
    this.lastSleepScore = 0.0,
  });

  bool get isLoading => profile == null || fastingStatus == null;
}

/// ✅ ELENA METABOLIC HUB (Manual Orchestrator)
///
/// Manual refactor to avoid build_runner permission issues.
class MetabolicHub extends Notifier<MetabolicContext> {
  Timer? _hydrationTimer;
  DateTime? _lastReminder;
  bool _isInsistent = false;
  int _lastKnownWater = -1;

  @override
  MetabolicContext build() {
    final profile = ref.watch(currentUserStreamProvider).valueOrNull;
    final fastingStatus = ref.watch(fastingControllerProvider).valueOrNull;
    final latestGlucose = ref.watch(latestGlucoseLogProvider).valueOrNull;
    final movementStatus = ref.watch(exerciseProvider);

    // 1. Biometría en tiempo real
    double estimatedG = 100.0;
    double estimatedK = 0.2;
    double hoursFasted = 0.0;

    if (fastingStatus != null && fastingStatus.isFasting) {
      hoursFasted = fastingStatus.elapsed.inMinutes / 60.0;
      estimatedG = ElenaBrain.estimateGlucose(hoursFasted);
      estimatedK = ElenaBrain.estimateKetones(hoursFasted);
    }

    // 2. Hidratación
    double hydration = 0.0;
    DailyLog? todayLog;
    if (profile != null) {
      todayLog = ref.watch(todayLogProvider(profile.uid)).valueOrNull;
      hydration = (todayLog?.waterGlasses ?? 0).toDouble();

      // Update hydration loop state
      final water = todayLog?.waterGlasses ?? 0;
      if (_lastKnownWater != -1 && water > _lastKnownWater) {
        _lastReminder = DateTime.now();
        _isInsistent = false;
      }
      _lastKnownWater = water;
    }

    // Gestion de Timer de Hidratación
    ref.onDispose(() => _hydrationTimer?.cancel());
    _hydrationTimer ??=
        Timer.periodic(const Duration(minutes: 1), (_) => _checkHydration());

    // 3. Geometría (Sincronizada con el reloj real 24h)
    final int plannedFastingHours = fastingStatus?.plannedHours ?? 16;
    final String protocolStr =
        "$plannedFastingHours:${24 - plannedFastingHours}";
    final double protocolFastingProgress = plannedFastingHours / 24.0;

    // Cálculo de la hora de inicio (Prioridad: Tiempo real > Onboarding > Fallback 20:00)
    double startHour = 20.0;
    final st = fastingStatus?.startTime;
    if (st != null) {
      startHour = st.hour + (st.minute / 60.0);
    } else if (profile?.usualLastMealTime != null &&
        profile!.usualLastMealTime!.isNotEmpty) {
      final mealTime = profile.usualLastMealTime ?? '20:00';
      final parts = mealTime.split(':');
      if (parts.length == 2) {
        startHour = (double.tryParse(parts[0]) ?? 20.0) +
            ((double.tryParse(parts[1]) ?? 0.0) / 60.0);
      }
    }

    // 4. Hitos de Comida (DINÁMICOS) - Se adaptan al momento real de ruptura
    // Offset absoluto de la ruptura del ayuno respecto a la hora de inicio
    double offsetToFeedingStart =
        protocolFastingProgress * 24.0; // Default: fin del protocolo

    if (fastingStatus != null && fastingStatus.isFeeding) {
      // Si ya rompió, usamos el tiempo REAL que duró el ayuno
      final startTime = fastingStatus.startTime;
      final feedingStartTime = fastingStatus.feedingStartTime;
      if (startTime != null && feedingStartTime != null) {
        final actualFastingDuration = feedingStartTime.difference(startTime);
        offsetToFeedingStart = actualFastingDuration.inSeconds / 3600.0;
      }
    }

    final List<double> mealOffsets =
        MealMilestoneCalculator.calculateOffsets(protocolStr);
    final List<MetabolicMilestone> mealMilestones = [];

    for (int i = 0; i < mealOffsets.length; i++) {
      final double relativeToFeeding = mealOffsets[i];
      final double absoluteOffset = offsetToFeedingStart + relativeToFeeding;
      final double elapsed = (fastingStatus?.elapsed.inMinutes ?? 0) / 60.0;
      final bool isReached = elapsed >= absoluteOffset;

      mealMilestones.add(_createMilestone(
        'COMIDA ${i + 1}',
        Icons.restaurant,
        absoluteOffset,
        startHour,
        isReached: isReached,
      ));
    }

    // 5. Hitos Fisiológicos (Fijados al inicio del ayuno)
    final double elapsedHours = (fastingStatus?.elapsed.inMinutes ?? 0) / 60.0;
    final List<MetabolicMilestone> physiologicalMilestones = [
      _createMilestone('DIGESTIÓN', Icons.timer, 0.0, startHour,
          isReached: elapsedHours >= 0.0),
      _createMilestone('NIVEL AZÚCAR ↓', Icons.bloodtype, 3.0, startHour,
          isReached: elapsedHours >= 3.0),
      _createMilestone('ESTABILIZACIÓN', Icons.balance, 9.0, startHour,
          isReached: elapsedHours >= 9.0),
      _createMilestone(
          'QUEMA DE GRASA', Icons.local_fire_department, 11.0, startHour,
          isReached: elapsedHours >= 11.0),
      _createMilestone('CETOSIS', Icons.whatshot, 14.0, startHour,
          isReached: elapsedHours >= 14.0),
      _createMilestone('AUTOFAGIA', Icons.autorenew, 16.0, startHour,
          isReached: elapsedHours >= 16.0),
    ];

    // 6. Sueño y MTI (Requiere Perfil)
    double sleepMins = 0.0;
    double mti = 0.0;
    double nutritionScore = 0.0;

    int actualMealsVal = 0;
    int expectedMealsVal = mealOffsets.length;

    if (profile != null) {
      final uid = profile.uid;
      final dailyLog = ref.watch(todayLogProvider(uid)).valueOrNull;
      sleepMins = (dailyLog?.sleepMinutes ?? 0).toDouble();

      // 7. Cálculo del IED (Índice de Ejecución Diaria)
      // Definido como el promedio simple de los 5 pilares (0-100%)

      // Pilar 1: Ayuno
      final fastingScore = (fastingStatus != null && fastingStatus.isFeeding)
          ? 100.0
          : (fastingStatus?.fastingPercent ?? 0.0).clamp(0, 100.0).toDouble();

      // Pilar 2: Nutrición (basado en comidas registradas vs esperadas)
      final int expMeals = mealOffsets.length;
      final int actMeals = dailyLog?.mealEntries.length ?? 0;
      nutritionScore =
          expMeals > 0 ? (actMeals / expMeals).clamp(0, 1.0) * 100 : 0.0;

      // Pilar 3: Ejercicio
      final double exerciseGoal = 30.0; // Sincronizado con UI (30 min = 100%)
      final exerciseScore =
          ((dailyLog?.exerciseMinutes ?? 0) / exerciseGoal * 100)
              .clamp(0, 100)
              .toDouble();

      // Pilar 4: Sueño
      final double sleepGoal = 8.0 * 60.0; // 8 horas en minutos
      final sleepScore = (sleepMins / sleepGoal * 100).clamp(0, 100).toDouble();

      // Pilar 5: Hidratación
      final double hydrationGoal =
          (profile.currentWeightKg / 7).roundToDouble().clamp(1.0, 100.0);
      final double hydrationScore =
          (hydration / hydrationGoal * 100).clamp(0, 100).toDouble();

      mti = (fastingScore +
              nutritionScore +
              exerciseScore +
              sleepScore +
              hydrationScore) /
          5.0;

      // Asignamos variables locales para el constructor
      actualMealsVal = actMeals;
      expectedMealsVal = expMeals;
    }

    final sleepStatus = ref.watch(sleepStatusProvider).valueOrNull;

    return MetabolicContext(
      profile: profile,
      fastingStatus: fastingStatus,
      lastGlucoseReading: latestGlucose,
      hydrationLevel: hydration,
      estimatedGlucose: estimatedG,
      estimatedKetones: estimatedK,
      mealMilestones: mealMilestones,
      physiologicalMilestones: physiologicalMilestones,
      protocolFastingProgress: protocolFastingProgress,
      currentTotalProgress: hoursFasted / 24.0,
      startHour: startHour,
      lastHydrationReminder: _lastReminder,
      isInsistentMode: _isInsistent,
      movementStatus: movementStatus,
      sleepMinutes: sleepMins,
      nutritionScore: nutritionScore,
      actualMeals: actualMealsVal,
      expectedMeals: expectedMealsVal,
      totalIED: mti,
      isWindowClosing: fastingStatus?.isWindowClosing ?? false,
      lastSleepScore: sleepStatus?.lastSleepScore ?? 0.0,
    );
  }

  void _checkHydration() {
    final profile = ref.read(currentUserStreamProvider).valueOrNull;
    if (profile == null) return;

    final now = DateTime.now();

    // 1. Regla de Oro: No molestar durante el sueño
    if (ElenaBrain.isSleepWindow(profile, now)) return;

    // 2. Cálculo de tiempo desde último recordatorio
    final last = _lastReminder ?? now.subtract(const Duration(minutes: 31));
    final diff = now.difference(last);
    final threshold = _isInsistent ? 5 : 30;

    if (diff.inMinutes >= threshold) {
      _triggerReminder(profile);
    }
  }

  void _triggerReminder(UserModel profile) {
    _lastReminder = DateTime.now();

    // Mensajería Dinámica basada en Glucosa Estimada
    final fastingStatus = ref.read(fastingControllerProvider).valueOrNull;
    double hoursFasted = 0.0;
    if (fastingStatus != null && fastingStatus.isFasting) {
      hoursFasted = fastingStatus.elapsed.inMinutes / 60.0;
    }
    final estimatedG = ElenaBrain.estimateGlucose(hoursFasted);

    NotificationService.scheduleHydrationReminder(
      Duration.zero,
      body:
          "Tu glucosa está en ${estimatedG.toStringAsFixed(1)}, un vaso de agua ayudará a mantener tu volemia estable. ¿Lo tomaste?",
    );

    // Forzamos rebuild para que el Hub actualice las flags de UI
    ref.notifyListeners();
  }

  /// Método interactivo para respuesta rápida (250ml)
  Future<void> addWater() async {
    final profile = ref.read(currentUserStreamProvider).valueOrNull;
    if (profile == null) return;

    await ref.read(healthRepositoryProvider).logHydration(profile.uid, 1);
    _lastReminder = DateTime.now();
    _isInsistent = false;
    _lastKnownWater++;
    debugPrint("💧 Hidratación rápida registrada (250ml)");
  }

  /// Método interactivo para responder NO (Modo Insistente)
  void postponeHydration() {
    _isInsistent = true;
    _lastReminder = DateTime.now();
    // Re-programamos alerta para dentro de 5 minutos
    _checkHydration();
  }

  MetabolicMilestone _createMilestone(
      String label, IconData iconType, double offsetFromStart, double startHour,
      {bool isReached = false}) {
    final double absoluteHour = (startHour + offsetFromStart) % 24.0;
    final double angle = (absoluteHour * 2 * math.pi / 24.0) - (math.pi / 2.0);

    return MetabolicMilestone(
      label: label,
      angle: angle,
      isReached: isReached,
      icon: iconType,
      hour: offsetFromStart,
      absoluteHour: absoluteHour,
    );
  }
}

final metabolicHubProvider =
    NotifierProvider<MetabolicHub, MetabolicContext>(MetabolicHub.new);
