// SPEC-270 — Implementación Firestore del intake dietético.
//
// Documento único: users/{uid}/nutritionProfile/intake. Mismo patrón
// delgado que MealPresetRepositoryImpl (sin mapper/source separados —
// no hay ventana temporal ni fuente intercambiable que justifique las
// capas extra que sí tiene NutritionRepository).
//
// Reglas de seguridad: NO se agregó regla específica. La catch-all
// `match /users/{userId}/{allPaths=**}` de firestore.rules (ownership +
// límite de tamaño) cubre cualquier subcolección que NO esté en la lista
// de exclusión (metabolic_cycles, imr_history, badges, glucose_readings).
// 'nutritionProfile' NO está en esa lista → create/update/delete ya
// funcionan para el dueño desde el primer commit — verificado leyendo
// firestore.rules (líneas 236-244) antes de escribir este archivo, no
// asumido.
//
// Persistencia offline-first: `saveIntake` hace `set(merge)` directo; el
// notifier (nutrition_intake_notifier.dart) actualiza estado optimista
// ANTES del roundtrip y nunca hace `await` en el camino principal.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_intake_repository.dart';

class NutritionIntakeRepositoryImpl implements NutritionIntakeRepository {
  NutritionIntakeRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _collection = 'nutritionProfile';
  static const String _docId = 'intake';

  DocumentReference<Map<String, dynamic>> _doc(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection(_collection)
      .doc(_docId);

  NutritionIntake? _parse(DocumentSnapshot<Map<String, dynamic>> snap) {
    if (!snap.exists) return null;
    final data = snap.data();
    if (data == null) return null;
    try {
      return NutritionIntake.fromJson(Map<String, dynamic>.from(data));
    } catch (_) {
      // Documento corrupto: se trata como "no hay intake" en vez de
      // tumbar el stream (mismo criterio permisivo del resto del pilar).
      return null;
    }
  }

  @override
  Stream<NutritionIntake?> watchIntake(String userId) =>
      _doc(userId).snapshots().map(_parse);

  @override
  Future<NutritionIntake?> getIntake(String userId) async {
    final snap = await _doc(userId).get();
    return _parse(snap);
  }

  @override
  Future<void> saveIntake(String userId, NutritionIntake intake) async {
    await _doc(userId).set(intake.toJson(), SetOptions(merge: true));
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────

final nutritionIntakeRepositoryProvider =
    Provider<NutritionIntakeRepository>((ref) {
  return NutritionIntakeRepositoryImpl();
});
