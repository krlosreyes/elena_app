import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_log.dart';
import 'package:elena_app/src/features/exercise/application/exercise_intensity_validator.dart';
import 'package:elena_app/src/core/orchestrator/orchestrator_provider.dart';

/// Provider del notifier de intensidad de ejercicio
final exerciseIntensityNotifierProvider =
    StateNotifierProvider<ExerciseIntensityNotifier, ExerciseIntensityState?>((ref) {
  return ExerciseIntensityNotifier(ref: ref);
});

/// Selector: Obtener recomendación actual
final exerciseIntensityRecommendationProvider =
    StateProvider.autoDispose<ExerciseIntensityRecommendation?>((ref) {
  return ref.watch(exerciseIntensityNotifierProvider)?.currentRecommendation;
});

/// Selector: Obtener validaciones pendientes
final exerciseValidationWarningsProvider =
    StateProvider.autoDispose<List<String>>((ref) {
  return ref.watch(exerciseIntensityNotifierProvider)?.recentWarnings ?? [];
});

/// Selector: Obtener carga metabólica actual
final currentMetabolicLoadProvider =
    StateProvider.autoDispose<double>((ref) {
  return ref.watch(exerciseIntensityNotifierProvider)?.currentMetabolicLoad ?? 0;
});

/// Estado del notifier de intensidad
class ExerciseIntensityState {
  final ExerciseIntensityRecommendation? currentRecommendation;
  final List<ExerciseLog> todayLogs;
  final double totalMetabolicLoad;
  final List<String> recentWarnings;
  final bool isCalculating;

  ExerciseIntensityState({
    this.currentRecommendation,
    this.todayLogs = const [],
    this.totalMetabolicLoad = 0,
    this.recentWarnings = const [],
    this.isCalculating = false,
  });

  ExerciseIntensityState copyWith({
    ExerciseIntensityRecommendation? currentRecommendation,
    List<ExerciseLog>? todayLogs,
    double? totalMetabolicLoad,
    List<String>? recentWarnings,
    bool? isCalculating,
  }) {
    return ExerciseIntensityState(
      currentRecommendation: currentRecommendation ?? this.currentRecommendation,
      todayLogs: todayLogs ?? this.todayLogs,
      totalMetabolicLoad: totalMetabolicLoad ?? this.totalMetabolicLoad,
      recentWarnings: recentWarnings ?? this.recentWarnings,
      isCalculating: isCalculating ?? this.isCalculating,
    );
  }

  double get currentMetabolicLoad => totalMetabolicLoad;
}

/// Recomendación de intensidad
class ExerciseIntensityRecommendation {
  final int recommendedIntensityPercent;
  final String exerciseType;
  final String reasoning;
  final DateTime generatedAt;

  ExerciseIntensityRecommendation({
    required this.recommendedIntensityPercent,
    required this.exerciseType,
    required this.reasoning,
    required this.generatedAt,
  });
}

/// Notifier para gestionar intensidad de ejercicio
/// SPEC-37: Intensidad de Ejercicio
class ExerciseIntensityNotifier extends StateNotifier<ExerciseIntensityState?> {
  final Ref _ref;

  ExerciseIntensityNotifier({required Ref ref})
      : _ref = ref,
        super(ExerciseIntensityState()) {
    _initializeTracking();
  }

  void _initializeTracking() {
    // NOTA: No escuchamos orchestratorStateProvider aquí para evitar circular dependency.
    // En su lugar, el UI puede llamar selectivamente a getRecommendation() cuando sea necesario.
    // O usar un selector: ref.watch(orchestratorStateProvider.select(...))
  }

  /// Genera una recomendación reactiva basada en el estado metabólico
  void _generateRecommendation() {
    final orchestratorState = _ref.read(orchestratorProvider);
    final metabolicState = _ref.read(metabolicStateProvider);
    
    final (recommendedIntensity, exerciseType, reasoning) =
        ExerciseIntensityValidator.recommendOptimalIntensity(
      currentFastingPhase: orchestratorState.fastingPhase,
      currentCircadianPhase: orchestratorState.circadianPhase,
      sleepQuality: metabolicState.sleepQuality,
    );

    final recommendation = ExerciseIntensityRecommendation(
      recommendedIntensityPercent: recommendedIntensity,
      exerciseType: exerciseType,
      reasoning: reasoning,
      generatedAt: DateTime.now(),
    );

    debugPrint(
        '💪 SPEC-37: Recomendación actualizada: $exerciseType ${recommendedIntensity}% - $reasoning');

    state = state?.copyWith(currentRecommendation: recommendation);
  }

  /// Valida intensidad propuesta y retorna validación + advertencias
  (bool isSafe, String? warning) validateIntensity({
    required int intensityPercent,
    required int durationMinutes,
  }) {
    // Validar sensatez
    final sanityError = ExerciseIntensityValidator.validateIntensitySanity(
      intensityPercent: intensityPercent,
      durationMinutes: durationMinutes,
    );
    final orchestratorState = _ref.read(orchestratorProvider);
    final metabolicState = _ref.read(metabolicStateProvider);
    
    // Obtener validación metabólica
    final (isSafe, warning) =
        ExerciseIntensityValidator.validateIntensityAgainstMetabolicState(
      intensityPercent: intensityPercent,
      currentFastingPhase: orchestratorState.fastingPhase,
      currentCircadianPhase: orchestratorState.circadianPhase,
      sleepQuality: metabolicState.sleepQuality,
      durationMinutes: durationMinutes,
    );

    if (warning != null) {
      final warnings = <String>[...(state?.recentWarnings ?? []), warning];
      state = state?.copyWith(recentWarnings: warnings);
      debugPrint('⚠️  SPEC-37: $warning');
    }

    return (isSafe, warning);
  }

  /// Registra un ejercicio con intensidad
  /// RF-37-01: Registra int intensityPercent, String exerciseType, etc.
  /// RF-37-04: Calcula carga metabólica
  void registerExerciseWithIntensity({
    required ExerciseLog baseLog,
    required int intensityPercent,
    required String exerciseType,
    required int estimatedHeartRate,
  }) {
    // Calcular carga metabólica
    final metabolicLoad = ExerciseIntensityValidator.calculateMetabolicLoad(
      intensityPercent: intensityPercent,
      durationMinutes: baseLog.durationMinutes,
    );

    // Validar
    final (isSafe, warning) = validateIntensity(
      intensityPercent: intensityPercent,
      durationMinutes: baseLog.durationMinutes,
    );

    // Crear log mejorado con intensidad
    final enhancedLog = baseLog.copyWith(
      intensityPercent: intensityPercent,
      exerciseType: exerciseType,
      estimatedHeartRate: estimatedHeartRate,
      metabolicLoad: metabolicLoad,
      safetyValidated: isSafe,
      validationWarning: warning,
    );

    // Agregar a estado
    final newLogs = <ExerciseLog>[...(state?.todayLogs ?? []), enhancedLog];
    final totalLoad = newLogs.fold<double>(
        0, (sum, log) => sum + (log.metabolicLoad ?? 0));

    state = state?.copyWith(
      todayLogs: newLogs,
      totalMetabolicLoad: totalLoad,
    );

    debugPrint(
        '💪 SPEC-37: Ejercicio registrado: $exerciseType ${intensityPercent}% × ${baseLog.durationMinutes}min = ${metabolicLoad.toStringAsFixed(2)} carga metabólica');
  }

  /// Registra feedback post-ejercicio
  /// RF-37-05: Cómo se sintió el usuario (1-10)
  void recordExerciseFeedback({
    required int logIndex,
    required int perceptionScore,
    String? notes,
  }) {
    if (logIndex < 0 || logIndex >= (state?.todayLogs.length ?? 0)) {
      return;
    }

    final log = state!.todayLogs[logIndex];
    final updatedLog = log.copyWith(
      userPerceptionScore: perceptionScore,
      userNotes: notes,
    );

    final newLogs = [...state!.todayLogs];
    newLogs[logIndex] = updatedLog;

    state = state!.copyWith(todayLogs: newLogs);

    debugPrint(
        '📊 SPEC-37-05: Feedback registrado. Percepción: $perceptionScore/10');
  }

  /// Obtiene recomendación actual
  ExerciseIntensityRecommendation? getRecommendation() {
    return state?.currentRecommendation;
  }

  /// Obtiene carga metabólica total del día
  double getTotalMetabolicLoad() {
    return state?.totalMetabolicLoad ?? 0;
  }

  /// Obtiene registros del día
  List<ExerciseLog> getTodayLogs() {
    return state?.todayLogs ?? [];
  }

  /// Limpia advertencias recientes
  void clearWarnings() {
    state = state?.copyWith(recentWarnings: []);
  }

  /// Verifica compatibilidad de ejercicio propuesto con estado de ayuno
  bool isCompatibleWithCurrentFasting({
    required int intensityPercent,
    required int durationMinutes,
  }) {
    final orchestratorState = _ref.read(orchestratorProvider);

    return ExerciseIntensityValidator.isCompatibleWithCurrentFasting(
      fastingPhase: orchestratorState.fastingPhase,
      intensityPercent: intensityPercent,
      durationMinutes: durationMinutes,
    );
  }

  /// Obtiene multiplicador de seguridad para ejercicio
  double getSafetyMultiplier() {
    final orchestratorState = _ref.read(orchestratorProvider);

    return ExerciseIntensityValidator.getExerciseSafetyMultiplier(
      orchestratorState.fastingPhase,
    );
  }
}
