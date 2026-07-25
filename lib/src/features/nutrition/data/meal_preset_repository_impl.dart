// "Mis platos frecuentes" (25-jul-2026) — implementación Firestore.
// Colección: users/{uid}/meal_presets/{presetId}. Mismo patrón delgado
// que BadgeRepositoryImpl (SPEC-badges 2026-07-15): sin mapper/source
// separados — el repositorio traduce directo a/desde el modelo, porque
// no hay lógica de ventana temporal ni de fuente intercambiable que
// justifique las capas extra que sí tiene NutritionRepository.
//
// Persistencia (garantía pedida por Carlos): `savePreset`/`deletePreset`
// escriben directo a Firestore (colección real, no memoria). El
// notifier de aplicación (`meal_preset_notifier.dart`) hace update
// optimista en el estado local ANTES del roundtrip — mismo patrón
// offline-first que el resto del proyecto — pero la escritura real
// SIEMPRE se dispara (`unawaited(...).catchError(...)`), nunca se
// omite. El stream `watchPresets` es la fuente de verdad a mediano
// plazo y reconcilia cualquier discrepancia cuando llega el snapshot.
//
// Reglas de seguridad: NO se agregó una regla específica para
// `meal_presets` en firestore.rules — la regla catch-all
// `match /users/{userId}/{allPaths=**}` (ownership + límite de tamaño)
// ya cubre cualquier subcolección nueva que no esté en la lista de
// exclusión (metabolic_cycles, imr_history, badges, glucose_readings).
// `meal_presets` NO está en esa lista, así que create/update/delete ya
// funcionan para el dueño desde el primer commit — verificado leyendo
// firestore.rules antes de escribir este archivo, no asumido.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/nutrition/domain/meal_preset.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_preset_repository.dart';

class MealPresetRepositoryImpl implements MealPresetRepository {
  MealPresetRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> _collection(String userId) =>
      _firestore.collection('users').doc(userId).collection('meal_presets');

  @override
  Stream<List<MealPreset>> watchPresets(String userId) {
    // orderBy de un solo campo — no requiere índice compuesto (SPEC-145
    // §3.4, checklist de indexes verificado: Firestore auto-indexa
    // campos individuales, solo las queries con where+orderBy en campos
    // distintos necesitan índice compuesto explícito).
    return _collection(userId)
        .orderBy('lastUsedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) {
            try {
              return MealPreset.fromJson(Map<String, dynamic>.from(doc.data()));
            } catch (_) {
              // Doc corrupto: se salta en vez de tumbar toda la lista
              // (mismo criterio que BadgeRepositoryImpl.watchEarned).
              return null;
            }
          })
          .whereType<MealPreset>()
          .toList(growable: false);
    });
  }

  @override
  Future<void> savePreset(String userId, MealPreset preset) async {
    await _collection(userId)
        .doc(preset.id)
        .set(preset.toJson(), SetOptions(merge: true));
  }

  @override
  Future<void> deletePreset(String userId, String presetId) async {
    await _collection(userId).doc(presetId).delete();
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────

final mealPresetRepositoryProvider = Provider<MealPresetRepository>((ref) {
  return MealPresetRepositoryImpl();
});
