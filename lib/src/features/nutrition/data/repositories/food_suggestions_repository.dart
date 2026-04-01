import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/food_suggestion.dart';

// Bump this version string whenever seeds change to force a Firestore reseed.
const _seedVersion = 'v2-charlie-preferences';

// ─────────────────────────────────────────────────────────────
// 🌱 SEED DATA — 12 meals aligned to Charlie's preference profile
//    (Pollo 🥩 · Huevo 🍳 · Pescado 🐟 · Aguacate 🥑 · Res 🥩)
//    Target: 48y, prediabetes — low GI, high protein, healthy fats
// ─────────────────────────────────────────────────────────────
final _seeds = <Map<String, dynamic>>[
  // ── RUPTURA (romper ayuno después del periodo de ayuno) ──────
  {
    'food_id': 'fs_001',
    'name': 'Huevos Revueltos con Aguacate',
    'tags': ['Ruptura suave', 'Grasas saludables', 'Low GI', 'Prediabetes'],
    // 2 huevos (140g) + ½ aguacate (75g)
    'macros': {'p': 18, 'c': 6, 'g': 28, 'kcal': 370},
    'category': 'Ruptura', 'preferences_match': true,
  },
  {
    'food_id': 'fs_002',
    'name': 'Salmón con Aguacate y Pepino',
    'tags': ['Omega-3', 'Ruptura cetogénica', 'Anti-inflamatorio'],
    // 100g salmón + ½ aguacate
    'macros': {'p': 25, 'c': 5, 'g': 30, 'kcal': 390},
    'category': 'Ruptura', 'preferences_match': true,
  },
  {
    'food_id': 'fs_003',
    'name': 'Huevo Pochado con Papa al Vapor',
    'tags': ['Carbohidrato complejo', 'Post-ayuno', 'Energía sostenida'],
    // 2 huevos (140g) + 150g papa al vapor
    'macros': {'p': 16, 'c': 28, 'g': 12, 'kcal': 340},
    'category': 'Ruptura', 'preferences_match': true,
  },
  // ── COMIDA PRINCIPAL ─────────────────────────────────────────
  {
    'food_id': 'fs_004',
    'name': 'Bowl de Pollo y Aguacate',
    'tags': ['Alta proteína', 'Grasas saludables', 'Low GI'],
    // 150g pollo + ½ aguacate + verduras
    'macros': {'p': 42, 'c': 12, 'g': 22, 'kcal': 430},
    'category': 'Principal', 'preferences_match': true,
  },
  {
    'food_id': 'fs_005',
    'name': 'Filete de Res con Brócoli al Vapor',
    'tags': ['Alta proteína', 'Hierro', 'Low carb'],
    // 150g res magra + 200g brócoli
    'macros': {'p': 38, 'c': 10, 'g': 16, 'kcal': 360},
    'category': 'Principal', 'preferences_match': true,
  },
  {
    'food_id': 'fs_006',
    'name': 'Salmón al Horno con Espárragos',
    'tags': ['Omega-3', 'Anti-inflamatorio', 'Cetogénico'],
    // 150g salmón + 150g espárragos + aceite oliva
    'macros': {'p': 37, 'c': 8, 'g': 28, 'kcal': 440},
    'category': 'Principal', 'preferences_match': true,
  },
  {
    'food_id': 'fs_007',
    'name': 'Pollo a la Plancha con Papa al Vapor',
    'tags': ['Alta proteína', 'Carbohidrato complejo', 'Balanceado'],
    // 150g pollo + 150g papa
    'macros': {'p': 40, 'c': 28, 'g': 10, 'kcal': 380},
    'category': 'Principal', 'preferences_match': true,
  },
  {
    'food_id': 'fs_008',
    'name': 'Res Salteada con Aguacate y Verduras',
    'tags': ['Hierro', 'Grasas saludables', 'Anti-inflamatorio'],
    // 150g res magra + ½ aguacate + vegetales
    'macros': {'p': 36, 'c': 14, 'g': 30, 'kcal': 480},
    'category': 'Principal', 'preferences_match': true,
  },
  {
    'food_id': 'fs_009',
    'name': 'Ensalada de Atún con Aguacate',
    'tags': ['Omega-3', 'Proteína magra', 'Low GI', 'Prediabetes'],
    // 150g atún + ½ aguacate + vegetales
    'macros': {'p': 32, 'c': 8, 'g': 22, 'kcal': 360},
    'category': 'Principal', 'preferences_match': true,
  },
  // ── SNACK ────────────────────────────────────────────────────
  {
    'food_id': 'fs_010',
    'name': 'Huevo Duro con Aceite de Oliva',
    'tags': ['Proteína rápida', 'Snack metabólico', 'Low carb'],
    // 2 huevos duros + 1 cdita aceite oliva
    'macros': {'p': 14, 'c': 1, 'g': 16, 'kcal': 220},
    'category': 'Snack', 'preferences_match': true,
  },
  {
    'food_id': 'fs_011',
    'name': 'Aguacate con Atún al Natural',
    'tags': ['Omega-3', 'Grasas saludables', 'Snack proteico'],
    // ½ aguacate + 80g atún
    'macros': {'p': 16, 'c': 7, 'g': 20, 'kcal': 280},
    'category': 'Snack', 'preferences_match': true,
  },
  {
    'food_id': 'fs_012',
    'name': 'Fruta de Temporada con Huevo',
    'tags': ['Antioxidantes', 'Fibra', 'Post-entrenamiento'],
    // 1 manzana/pera + 1 huevo duro
    'macros': {'p': 8, 'c': 28, 'g': 6, 'kcal': 210},
    'category': 'Snack', 'preferences_match': true,
  },
];

// ─────────────────────────────────────────────────────────────
// REPOSITORY
// ─────────────────────────────────────────────────────────────
class FoodSuggestionsRepository {
  final FirebaseFirestore _db;

  FoodSuggestionsRepository(this._db);

  // Global collection (shared, not per-user)
  CollectionReference<Map<String, dynamic>> get _col =>
      _db.collection('user_food_suggestions');

  // ── Seed / reseed (version-gated upsert) ────────────────────
  /// Uses a meta-document `_meta/seed_version` to detect stale seeds.
  /// On version mismatch, runs a full batch upsert WITHOUT touching
  /// existing `last_shown` values → rotation history is preserved.
  Future<void> seedIfEmpty() async {
    try {
      final metaRef = _db.collection('user_food_suggestions').doc('_meta');
      final meta = await metaRef.get();
      final currentVersion = meta.data()?['version'] as String? ?? '';

      if (currentVersion == _seedVersion) return; // already up-to-date

      debugPrint('🌱 FoodSuggestions: Reseeding [$_seedVersion]...');
      final batch = _db.batch();

      for (final seed in _seeds) {
        final id = seed['food_id'] as String;
        // SetOptions(merge: true) preserves last_shown if already set
        batch.set(
            _col.doc(id),
            {
              ...seed,
              'last_shown': null, // only written on first create
            },
            SetOptions(merge: false)); // full write on reseed for fresh data
      }

      // Write version marker
      batch.set(metaRef, {'version': _seedVersion});

      await batch.commit();
      debugPrint(
          '✅ FoodSuggestions: Seeded ${_seeds.length} items [$_seedVersion]');
    } catch (e) {
      debugPrint('❌ FoodSuggestions Seed Error: $e');
    }
  }

  // ── Rotation algorithm ───────────────────────────────────────
  /// Returns 3 daily suggestions using LRU rotation:
  /// Filter → sort by last_shown asc → pick randomly from top-10
  Future<List<FoodSuggestion>> getDailySuggestions() async {
    await seedIfEmpty();

    try {
      // Get all preference-match items, skip _meta doc
      // ordered by last_shown asc (nulls first = never shown = highest priority)
      final query = await _col
          .where('preferences_match', isEqualTo: true)
          .orderBy('last_shown', descending: false)
          .limit(10)
          .get();

      if (query.docs.isEmpty) return [];

      // Exclude meta document if it slips through
      final allItems = query.docs
          .where((d) => d.id != '_meta')
          .map((d) => FoodSuggestion.fromFirestore(d))
          .toList();

      // Randomly pick 3 from the 10 oldest
      final rng = Random();
      final selected = <FoodSuggestion>[];
      final pool = List<FoodSuggestion>.from(allItems);
      final count = pool.length.clamp(0, 3);
      for (int i = 0; i < count; i++) {
        final idx = rng.nextInt(pool.length);
        selected.add(pool.removeAt(idx));
      }

      // Update last_shown for the 3 chosen (fire-and-forget)
      _updateLastShown(selected.map((s) => s.foodId).toList());

      return selected;
    } catch (e) {
      debugPrint('❌ getDailySuggestions Error: $e');
      return [];
    }
  }

  void _updateLastShown(List<String> ids) {
    final batch = _db.batch();
    for (final id in ids) {
      batch.update(_col.doc(id), {
        'last_shown': FieldValue.serverTimestamp(),
      });
    }
    batch
        .commit()
        .catchError((e) => debugPrint('⚠️ last_shown update error: $e'));
  }

  // ── Add suggestion to daily_logs ────────────────────────────
  Future<void> addToDaily({
    required String uid,
    required FoodSuggestion suggestion,
  }) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dailyRef =
        _db.collection('users').doc(uid).collection('daily_logs').doc(today);

    final entry = {
      'id': suggestion.foodId,
      'name': suggestion.name,
      'type': suggestion.category.label.toLowerCase(),
      'calories': suggestion.macros.kcal,
      'protein': suggestion.macros.protein,
      'carbs': suggestion.macros.carbs,
      'fats': suggestion.macros.fat,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _db.runTransaction((tx) async {
      final snap = await tx.get(dailyRef);
      final existing = snap.exists && snap.data() != null
          ? Map<String, dynamic>.from(snap.data()!)
          : <String, dynamic>{};

      final meals =
          List<Map<String, dynamic>>.from(existing['mealEntries'] ?? []);
      meals.add(entry);

      final newCal = ((existing['calories'] as num?) ?? 0).toInt() +
          suggestion.macros.kcal;
      final newProt = ((existing['proteinGrams'] as num?) ?? 0).toInt() +
          suggestion.macros.protein;
      final newCarb = ((existing['carbsGrams'] as num?) ?? 0).toInt() +
          suggestion.macros.carbs;
      final newFat =
          ((existing['fatGrams'] as num?) ?? 0).toInt() + suggestion.macros.fat;

      tx.set(
          dailyRef,
          {
            ...existing,
            'id': today,
            'mealEntries': meals,
            'calories': newCal,
            'proteinGrams': newProt,
            'carbsGrams': newCarb,
            'fatGrams': newFat,
          },
          SetOptions(merge: true));
    });
  }
}

// ─────────────────────────────────────────────────────────────
// PROVIDER
// ─────────────────────────────────────────────────────────────
final foodSuggestionsRepositoryProvider =
    Provider<FoodSuggestionsRepository>((ref) {
  return FoodSuggestionsRepository(FirebaseFirestore.instance);
});

/// StreamProvider that fetches rotated suggestions once per screen mount.
/// Returns a fresh list daily via FutureProvider to allow re-fetch on hot
/// restart without hammering Firestore with a stream.
final dailySuggestionsProvider =
    FutureProvider.autoDispose<List<FoodSuggestion>>((ref) async {
  final repo = ref.watch(foodSuggestionsRepositoryProvider);
  return repo.getDailySuggestions();
});
