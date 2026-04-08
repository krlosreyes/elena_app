import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/nutrition_plan.dart';
import '../../domain/entities/metabolic_nutrition_plan.dart';
import '../../domain/entities/metabolic_profile.dart'; // Added
import '../../domain/entities/nutrition_strategy.dart'; // Added
import '../../../../shared/domain/models/user_model.dart'; // Added for Gender
import '../../domain/repositories/nutrition_repository.dart';

class NutritionRepositoryImpl implements NutritionRepository {
  final FirebaseFirestore _firestore;

  NutritionRepositoryImpl(this._firestore);

  // ─────────────────────────────────────────────────────────────────────────
  // LEGACY (preserved, no breaking changes)
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveNutritionPlan(NutritionPlan plan) async {
    await _firestore
        .collection('users')
        .doc(plan.userId)
        .collection('nutrition')
        .doc('current_legacy')
        .set(plan.toJson());
  }

  @override
  Future<NutritionPlan?> getCurrentPlan(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('nutrition')
        .doc('current_legacy')
        .get();

    if (!doc.exists || doc.data() == null) return null;
    try {
      return NutritionPlan.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('❌ Error parsing legacy NutritionPlan: $e');
      return null;
    }
  }

  @override
  Stream<NutritionPlan?> watchCurrentPlan(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('nutrition')
        .doc('current_legacy')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      try {
        return NutritionPlan.fromJson(doc.data()!);
      } catch (e) {
        debugPrint('❌ Error parsing legacy NutritionPlan stream: $e');
        return null;
      }
    });
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NEW METABOLIC ENGINE
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Future<void> saveMetabolicPlan(
      String userId, MetabolicNutritionPlan plan) async {
    try {
      final data = plan.toFirestoreMap();

      // Save as current (active singleton)
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('nutrition')
          .doc('current_metabolic')
          .set(data);

      // Also archive in history for progress tracking
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('nutrition_history')
          .doc(plan.id)
          .set(data);

      debugPrint('✅ Plan metabólico guardado: ${plan.strategy.name} '
          '| ${plan.totalCalories} kcal '
          '| P:${plan.proteinGrams}g F:${plan.fatGrams}g C:${plan.carbsGrams}g');
    } catch (e) {
      debugPrint('❌ Error guardando plan metabólico: $e');
      rethrow;
    }
  }

  @override
  Stream<MetabolicNutritionPlan?> watchMetabolicPlan(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('nutrition')
        .doc('current_metabolic')
        .snapshots()
        .map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      try {
        return _planFromFirestore(doc.data()!);
      } catch (e) {
        debugPrint('❌ Error parseando plan metabólico: $e');
        return null;
      }
    });
  }

  @override
  Future<List<MetabolicNutritionPlan>> getPlanHistory(
    String userId, {
    int limit = 10,
  }) async {
    try {
      final query = await _firestore
          .collection('users')
          .doc(userId)
          .collection('nutrition_history')
          .orderBy('calculated_at', descending: true)
          .limit(limit)
          .get();

      return query.docs
          .map((doc) {
            try {
              return _planFromFirestore(doc.data());
            } catch (e) {
              debugPrint('⚠️ Skipping malformed history doc: $e');
              return null;
            }
          })
          .whereType<MetabolicNutritionPlan>()
          .toList();
    } catch (e) {
      debugPrint('❌ Error obteniendo historial de planes: $e');
      return [];
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PARSER — Firestore → MetabolicNutritionPlan
  // ─────────────────────────────────────────────────────────────────────────

  MetabolicNutritionPlan _planFromFirestore(Map<String, dynamic> data) {
    // Parse meals
    final rawMeals = data['meals'] as List<dynamic>? ?? [];
    final meals = rawMeals
        .map((m) => _mealFromMap(m as Map<String, dynamic>))
        .toList();

    // Parse profile snapshot (lightweight, for display only)
    final snap = data['profile_snapshot'] as Map<String, dynamic>? ?? {};

    // Reconstruct a lightweight display-only profile
    // Full profile is re-built on next generatePlan() call from live user data
    final profile = _lightweightProfileFromSnapshot(snap, data);
    final strategy = _strategyFromName(data['strategy_name'] as String? ?? '');

    return MetabolicNutritionPlan(
      id: data['id'] as String? ?? '',
      userId: data['user_id'] as String? ?? '',
      calculatedAt: _parseTimestamp(data['calculated_at']),
      algorithmVersion:
          data['algorithm_version'] as String? ?? '2.0.0-metabolic',
      profile: profile,
      strategy: strategy,
      isTrainingDay: data['is_training_day'] as bool? ?? false,
      totalCalories: data['total_calories'] as int? ?? 0,
      proteinGrams: data['protein_grams'] as int? ?? 0,
      fatGrams: data['fat_grams'] as int? ?? 0,
      carbsGrams: data['carbs_grams'] as int? ?? 0,
      meals: meals,
      caloricDeficitPercent:
          (data['caloric_deficit_percent'] as num?)?.toDouble() ?? 0.0,
      metabolicNotes:
          (data['metabolic_notes'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  PlannedMeal _mealFromMap(Map<String, dynamic> m) {
    return PlannedMeal(
      index: m['index'] as int? ?? 0,
      label: m['label'] as String? ?? '',
      calories: m['calories'] as int? ?? 0,
      proteinG: m['protein_g'] as int? ?? 0,
      fatG: m['fat_g'] as int? ?? 0,
      carbsG: m['carbs_g'] as int? ?? 0,
      timingNote: m['timing_note'] as String? ?? '',
      priority: MealPriority.values.firstWhere(
        (e) => e.name == (m['priority'] as String? ?? 'primary'),
        orElse: () => MealPriority.primary,
      ),
    );
  }

  /// Deserializes a stored snapshot back to a read-only MetabolicProfile.
  /// NOTE: This is for *display only*. Real calculations always use live data.
  MetabolicProfile _lightweightProfileFromSnapshot(
    Map<String, dynamic> snap,
    Map<String, dynamic> data,
  ) {
    final bf = (snap['body_fat_percent'] as num?)?.toDouble() ?? 20.0;
    final lean = (snap['lean_mass_kg'] as num?)?.toDouble() ?? 60.0;
    final bmr = (snap['bmr'] as num?)?.toDouble() ?? 1500.0;
    final tdee = (snap['tdee'] as num?)?.toDouble() ?? 2000.0;

    final insulinName = snap['insulin_sensitivity'] as String? ?? 'normal';
    final flexName = snap['metabolic_flexibility'] as String? ?? 'medium';
    final adaptName = snap['adaptation_state'] as String? ?? 'normal';
    final fastingName = snap['fasting_protocol'] as String? ?? 'none';
    final goalName = data['goal'] as String? ?? 'maintenance';

    return MetabolicProfile(
      totalWeightKg: lean / (1 - bf / 100),
      bodyFatPercent: bf,
      leanMassKg: lean,
      fatMassKg: (lean / (1 - bf / 100)) - lean,
      bmr: bmr,
      tdee: tdee,
      activityMultiplier: tdee / bmr,
      bmi: 0.0, // Not stored in snapshot
      whtr: 0.0,
      whr: 0.0,
      insulinSensitivity: InsulinSensitivity.values.firstWhere(
        (e) => e.name == insulinName,
        orElse: () => InsulinSensitivity.normal,
      ),
      metabolicFlexibility: MetabolicFlexibility.values.firstWhere(
        (e) => e.name == flexName,
        orElse: () => MetabolicFlexibility.medium,
      ),
      adaptationState: AdaptationState.values.firstWhere(
        (e) => e.name == adaptName,
        orElse: () => AdaptationState.normal,
      ),
      hasMetabolicRisk: false,
      hasHormonalRisk: false,
      age: 30,
      gender: Gender.female,
      goal: MetabolicGoal.values.firstWhere(
        (e) => e.name == goalName,
        orElse: () => MetabolicGoal.maintenance,
      ),
      dailyExerciseGoalMinutes: 30,
      fastingContext: FastingContext(
        protocol: FastingProtocol.values.firstWhere(
          (e) => e.name == fastingName,
          orElse: () => FastingProtocol.none,
        ),
        fastingWindowHours: 16,
        feedingWindowHours: 8,
        experience: FastingExperience.beginner,
        trainingTiming: TrainingTiming.fed,
      ),
    );
  }

  NutritionStrategy _strategyFromName(String name) {
    if (name.contains('Agresiva') || name.contains('Agresivo')) {
      return AggressiveFatLossStrategy();
    }
    if (name.contains('Insulínico') || name.contains('Reset')) {
      return InsulinResetStrategy();
    }
    if (name.contains('Recomposición')) return RecompositionStrategy();
    if (name.contains('Muscular')) return MuscleGainStrategy();
    return MaintenanceStrategy();
  }

  DateTime _parseTimestamp(dynamic val) {
    if (val is Timestamp) return val.toDate();
    if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
    return DateTime.now();
  }
}
