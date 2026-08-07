// SPEC-271 — Implementación Firestore de la Minuta Diaria.
//
// Colección: users/{uid}/mealPlans/{yyyy-MM-dd} (un documento por día).
// Mismo patrón delgado que NutritionIntakeRepositoryImpl / MealPreset.
//
// Reglas de seguridad: NO se agregó regla específica. La catch-all
// `match /users/{userId}/{allPaths=**}` (ownership + límite de tamaño)
// cubre 'mealPlans' porque NO está en la lista de exclusión
// (metabolic_cycles, imr_history, badges, glucose_readings) — verificado
// leyendo firestore.rules, no asumido. Índices: no se requieren; las
// lecturas son por id de documento (la fecha), sin where+orderBy.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan_repository.dart';

class MealPlanRepositoryImpl implements MealPlanRepository {
  MealPlanRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'mealPlans';

  DocumentReference<Map<String, dynamic>> _doc(String userId, String dateId) =>
      _firestore
          .collection('users')
          .doc(userId)
          .collection(_collection)
          .doc(dateId);

  MealPlan? _parse(DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    try {
      return MealPlan.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      // Documento corrupto: se trata como "no hay plan" (mismo criterio
      // permisivo del resto del pilar).
      return null;
    }
  }

  @override
  Stream<MealPlan?> watchPlan(String userId, String dateId) =>
      _doc(userId, dateId).snapshots().map(_parse);

  @override
  Future<MealPlan?> getPlan(String userId, String dateId) async {
    final snap = await _doc(userId, dateId).get();
    return _parse(snap);
  }

  @override
  Future<void> savePlan(String userId, MealPlan plan) async {
    await _doc(userId, plan.date).set(plan.toJson(), SetOptions(merge: true));
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────

final mealPlanRepositoryProvider = Provider<MealPlanRepository>((ref) {
  return MealPlanRepositoryImpl();
});
