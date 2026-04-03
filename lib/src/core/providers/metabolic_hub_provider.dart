import 'dart:async';
import 'dart:math' as math;

import 'package:elena_app/src/core/health/providers/health_snapshot_provider.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:elena_app/src/features/dashboard/application/dashboard_adapter.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_model.dart';
import 'package:elena_app/src/shared/domain/models/metabolic_milestone.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/fasting/application/fasting_controller.dart';
import '../../features/fasting/domain/meal_milestone_calculator.dart';
import '../../features/glucose/application/glucose_provider.dart';
import '../../features/health/data/health_repository.dart';
import '../../features/health/domain/daily_log.dart';
import '../../features/profile/application/user_controller.dart';
import '../../features/sleep/application/sleep_controller.dart';
import '../../features/training/application/movement_controller.dart';

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
    // Moved to DecisionEngine in Phase 3
    // This legacy hub is now a thin adapter over the unified health snapshot.
    final profile = ref.watch(currentUserStreamProvider).valueOrNull;
    final fastingStatus = ref.watch(fastingControllerProvider).valueOrNull;
    final latestGlucose = ref.watch(latestGlucoseLogProvider).valueOrNull;
    final movementStatus = ref.watch(exerciseProvider);
    final snapshotData = ref.watch(healthSnapshotProvider).valueOrNull;
    final dashboardSnapshot = snapshotData != null
        ? const DashboardAdapter()
            .adapt(snapshotData.state, decision: snapshotData.decision)
        : null;

    // 1. Biometría en tiempo real
    double estimatedG = dashboardSnapshot?.metabolic.estimatedGlucose ?? 100.0;
    double estimatedK = dashboardSnapshot?.metabolic.estimatedKetones ?? 0.2;
    double hoursFasted = 0.0;

    if (fastingStatus != null && fastingStatus.isFasting) {
      hoursFasted = fastingStatus.elapsed.inMinutes / 60.0;
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

    final parts = protocolStr.split(':');
    final fastingHours =
        parts.length == 2 ? (int.tryParse(parts[0]) ?? 16) : 16;
    final feedingWindowVal = 24.0 - fastingHours.toDouble();

    final List<double> mealOffsets = MealMilestoneCalculator.calculateOffsets(
      protocolStr,
      numberOfMeals: (profile?.numberOfMeals == 2 && feedingWindowVal > 8.0)
          ? null
          : profile?.numberOfMeals,
    );
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
    double mti = dashboardSnapshot?.compliance.totalIED ?? 0.0;
    double nutritionScore = dashboardSnapshot?.compliance.nutritionScore ?? 0.0;

    int actualMealsVal = dashboardSnapshot?.compliance.mealsLogged ?? 0;
    int expectedMealsVal =
        dashboardSnapshot?.compliance.mealsExpected ?? mealOffsets.length;

    if (profile != null) {
      final uid = profile.uid;
      final dailyLog = ref.watch(todayLogProvider(uid)).valueOrNull;
      sleepMins = (dailyLog?.sleepMinutes ?? 0).toDouble();

      // Moved to DecisionEngine in Phase 3
      // IED and compliance scores now come from HealthOrchestrator + DashboardAdapter.
      if (dashboardSnapshot == null) {
        final int expMeals = mealOffsets.length;
        final int actMeals = dailyLog?.mealEntries.length ?? 0;
        actualMealsVal = actMeals;
        expectedMealsVal = expMeals;
      }
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
    final now = DateTime.now();
    // TODO: Remove in Phase 4 cleanup
    // Legacy reminder cadence retained for backward compatibility.

    // 2. Cálculo de tiempo desde último recordatorio
    final last = _lastReminder ?? now.subtract(const Duration(minutes: 31));
    final diff = now.difference(last);
    final threshold = _isInsistent ? 5 : 30;

    if (diff.inMinutes >= threshold) {
      _triggerReminder();
    }
  }

  void _triggerReminder() {
    _lastReminder = DateTime.now();

    final snapshotData = ref.read(healthSnapshotProvider).valueOrNull;
    final estimatedG =
        snapshotData?.state.metabolicProfile.estimatedCurrentGlucose ?? 95.0;

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
