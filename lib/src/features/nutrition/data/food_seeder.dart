import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ═════════════════════════════════════════════════════════════════════════════
// FOOD SEEDER — Master Metabolic Database Population
// Strict 4-Node JSON Architecture for Firestore
// ═════════════════════════════════════════════════════════════════════════════

class FoodSeeder {
  static const String _masterFoodCollection = 'master_food_db';

  /// ═══════════════════════════════════════════════════════════════════════════
  /// 🗑️ DATABASE ADMINISTRATOR: Delete all documents from master_food_db
  /// Used to purge duplicate entries and ensure clean slate before re-seeding
  /// ═══════════════════════════════════════════════════════════════════════════
  static Future<void> deleteAllFoods() async {
    print('[DBA] 🗑️ PURGING: Fetching all documents from master_food_db...');

    try {
      final batch = FirebaseFirestore.instance.batch();
      int deleteCount = 0;
      const maxBatchSize = 500;

      // Fetch all document IDs in master_food_db
      final snapshot = await FirebaseFirestore.instance
          .collection(_masterFoodCollection)
          .get();

      print('[DBA] Found ${snapshot.docs.length} documents to delete');

      // Queue deletions in batch (max 500 per batch)
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        deleteCount++;

        // If batch reaches max size, commit and start new one
        if (deleteCount % maxBatchSize == 0) {
          await batch.commit();
          print('[DBA] 📦 Batch deleted $deleteCount documents');
        }
      }

      // Commit remaining deletions
      if (deleteCount > 0 && deleteCount % maxBatchSize != 0) {
        await batch.commit();
      }

      print('[DBA] ✅ PURGE COMPLETE! Deleted $deleteCount documents');
      print('[DBA] master_food_db is now empty. Ready for re-injection.');
    } catch (e) {
      print('[DBA] ❌ Error in deleteAllFoods: $e');
      debugPrint('[DBA] $e');
      rethrow;
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// 🔄 DEDUPLICATION: Consolidate all food datasets into clean Map by ID
  /// Ensures exactly one unique entry per food ID (last one wins)
  /// ═══════════════════════════════════════════════════════════════════════════
  static Map<String, Map<String, dynamic>> _buildCleanDataset() {
    print('[DBA] 🧹 DEDUPLICATION: Building clean dataset...');

    final cleanDataset = <String, Map<String, dynamic>>{};

    // Collect all food lists
    final allFoods = <Map<String, dynamic>>[
      ..._getCompleteFoodList(),
      ..._getGrasasHealthyFatsList(),
      ..._getProteinsCompleteList(),
      ..._getVegetablesCompleteList(),
      ..._getCarbsCompleteList(),
    ];

    print('[DBA] 📊 Total food items collected: ${allFoods.length}');

    // Build clean map with ID as key (last duplicate wins)
    for (final food in allFoods) {
      try {
        final id = food['metadata']['id'] as String;

        if (cleanDataset.containsKey(id)) {
          print('[DBA] ⚠️  DUPLICATE found: $id - Using latest entry');
        }

        cleanDataset[id] = food;
      } catch (e) {
        print('[DBA] ❌ Error processing food item: $e');
      }
    }

    final uniqueCount = cleanDataset.length;
    final duplicateCount = allFoods.length - uniqueCount;

    print('[DBA] 📈 DEDUPLICATION RESULTS:');
    print('[DBA]   Total collected: ${allFoods.length}');
    print('[DBA]   Unique entries: $uniqueCount');
    print('[DBA]   Duplicates removed: $duplicateCount');

    return cleanDataset;
  }

  /// Seed the master_food_db collection with 25+ verified foods (4-Node structure)
  /// Auto-checks if empty to prevent duplicates
  static Future<void> seedDatabase() async {
    print('[SEEDER] Starting Master Metabolic Database population...');

    try {
      // Check if collection already has data
      final countSnapshot = await FirebaseFirestore.instance
          .collection(_masterFoodCollection)
          .count()
          .get();

      final docCount = countSnapshot.count ?? 0;
      if (docCount > 0) {
        print(
          '⚠️ [SEEDER] Database already has data ($docCount documents). Skipping.',
        );
        return;
      }

      print('[SEEDER] Database is empty. Beginning injection of 25+ foods...');

      // Get the complete food list
      final foods = _getCompleteFoodList();
      print('[SEEDER] Injecting ${foods.length} verified foods...');

      // Inject each food
      for (final foodDoc in foods) {
        try {
          final id = foodDoc['metadata']['id'] as String;
          final name = foodDoc['metadata']['name'] as String;

          await FirebaseFirestore.instance
              .collection(_masterFoodCollection)
              .doc(id)
              .set(foodDoc);

          print('✅ [SEEDER] Food "$name" injected successfully');
        } catch (e) {
          print('❌ [SEEDER] Error injecting food: $e');
          debugPrint('[SEEDER] $e');
        }
      }

      print('[SEEDER] ✅ Master Metabolic Database population complete!');

      // Now seed the new Grasas Saludables collection
      print('[SEEDER] ▶️ Starting Grasas Saludables injection...');
      await seedGrasasHealthyFats();

      // Now seed the 30 Proteínas collection
      print('[SEEDER] ▶️ Starting Proteínas injection...');
      await seedProteinsComplete();

      // Now seed the 15 Vegetales collection
      print('[SEEDER] ▶️ Starting Vegetales injection...');
      await seedVegetablesComplete();

      // Now seed the 15 Carbohidratos collection
      print('[SEEDER] ▶️ Starting Carbohidratos injection...');
      await seedCarbsComplete();
    } catch (e) {
      print('[SEEDER] ❌ Error in seedDatabase: $e');
      debugPrint('[SEEDER] $e');
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// 🔄 CLEAN & RESEED: Complete cleanup with deduplication
  /// 1. Purges all existing documents from master_food_db
  /// 2. Deduplicates all food datasets (ID-based map)
  /// 3. Re-injects unique documents only
  /// ═══════════════════════════════════════════════════════════════════════════
  static Future<void> cleanAndReseed() async {
    print('[DBA] ╔══════════════════════════════════════════════════════╗');
    print('[DBA] ║  CLEAN & RESEED: Complete Database Maintenance       ║');
    print('[DBA] ╚══════════════════════════════════════════════════════╝');

    try {
      // STEP 1: DELETE ALL DOCUMENTS
      print('[DBA] STEP 1/3: Purging existing documents...');
      await deleteAllFoods();

      // STEP 2: BUILD CLEAN DATASET
      print('[DBA] STEP 2/3: Building clean, deduplicated dataset...');
      final cleanDataset = _buildCleanDataset();

      // STEP 3: RE-INJECT CLEAN DATA
      print('[DBA] STEP 3/3: Re-injecting clean data...');
      await _injectCleanDataset(cleanDataset);

      print('[DBA] ✅ CLEAN & RESEED COMPLETE!');
      print(
        '[DBA] Database now has exactly ${cleanDataset.length} unique foods',
      );
      print('[DBA] ✅ No duplicates, no orphaned entries');
    } catch (e) {
      print('[DBA] ❌ Error in cleanAndReseed: $e');
      debugPrint('[DBA] $e');
      rethrow;
    }
  }

  /// Re-inject clean dataset into Firestore using WriteBatch
  static Future<void> _injectCleanDataset(
    Map<String, Map<String, dynamic>> cleanDataset,
  ) async {
    print(
      '[DBA] 💉 INJECTION: Re-injecting ${cleanDataset.length} unique documents...',
    );

    try {
      final batch = FirebaseFirestore.instance.batch();
      int batchCount = 0;
      int totalCount = 0;
      const maxBatchSize = 500;

      for (final entry in cleanDataset.entries) {
        final id = entry.key;
        final foodData = entry.value;

        try {
          final name = foodData['metadata']['name'] as String;
          final category = foodData['metadata']['category'] as String;

          final docRef = FirebaseFirestore.instance
              .collection(_masterFoodCollection)
              .doc(id);

          // ✅ Inject with SetOptions(merge: false) for clean creation
          batch.set(docRef, foodData);

          batchCount++;
          totalCount++;
          print('[DBA] ✅ Queued "$name" (ID: $id, Category: $category)');

          if (batchCount >= maxBatchSize) {
            await batch.commit();
            print(
              '[DBA] 📦 Batch committed ($batchCount docs). Total: $totalCount',
            );
            batchCount = 0;
          }
        } catch (e) {
          print('[DBA] ❌ Error processing document "$id": $e');
        }
      }

      // Commit final batch
      if (batchCount > 0) {
        await batch.commit();
        print(
          '[DBA] 📦 Final batch committed ($batchCount docs). Total: $totalCount',
        );
      }

      print(
        '[DBA] ✅ INJECTION COMPLETE! $totalCount documents successfully stored',
      );
    } catch (e) {
      print('[DBA] ❌ Error in _injectCleanDataset: $e');
      debugPrint('[DBA] $e');
      rethrow;
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// 🔄 FORCED RE-SEED: Ignores document count check and OVERWRITES all 105 docs
  /// Uses WriteBatch + SetOptions(merge: true) to update all documents
  /// This ensures 'metadata.category' is correctly set in every document
  /// ═══════════════════════════════════════════════════════════════════════════
  static Future<void> forcedReSeed() async {
    print(
      '[FORCED RE-SEED] 🚨 Starting FORCED RE-SEED - WILL OVERWRITE ALL DOCUMENTS',
    );
    print(
      '[FORCED RE-SEED] This will update all 105 documents with correct metadata structure...',
    );

    try {
      final batch = FirebaseFirestore.instance.batch();
      int batchCount = 0;
      int totalCount = 0;
      const maxBatchSize = 500;

      // Collect ALL food items from all data methods
      final allFoods = <Map<String, dynamic>>[
        ..._getCompleteFoodList(), // ~37 Proteinas from initial list
        ..._getGrasasHealthyFatsList(), // ~24 Grasas
        ..._getProteinsCompleteList(), // ~30+ Proteinas (may overlap, will merge)
        ..._getVegetablesCompleteList(), // ~21 Vegetales
        ..._getCarbsCompleteList(), // ~23 Carbohidratos
      ];

      print(
        '[FORCED RE-SEED] Processing ${allFoods.length} food items for OVERWRITE...',
      );

      for (final foodItem in allFoods) {
        String itemId = 'unknown';
        try {
          final id = foodItem['metadata']['id'] as String;
          itemId = id;
          final name = foodItem['metadata']['name'] as String;
          final category = foodItem['metadata']['category'] as String;

          final docRef = FirebaseFirestore.instance
              .collection(_masterFoodCollection)
              .doc(id);

          // ✅ SetOptions(merge: true) ensures we OVERWRITE with correct structure
          batch.set(docRef, foodItem, SetOptions(merge: true));

          batchCount++;
          totalCount++;
          print('[FORCED RE-SEED] ✅ Queued "$name" (Category: $category)');

          if (batchCount >= maxBatchSize) {
            await batch.commit();
            print(
              '[FORCED RE-SEED] 📦 Batch committed ($batchCount items). Running total: $totalCount',
            );
            batchCount = 0;
          }
        } catch (e) {
          print('[FORCED RE-SEED] ❌ Error processing "$itemId": $e');
          debugPrint('[FORCED RE-SEED] $e');
        }
      }

      // Commit final batch
      if (batchCount > 0) {
        await batch.commit();
        print('[FORCED RE-SEED] 📦 Final batch committed ($batchCount items)');
      }

      print(
        '[FORCED RE-SEED] ✅ COMPLETE! All $totalCount documents OVERWRITTEN successfully',
      );
      print(
        '[FORCED RE-SEED] ✅ All documents now have correct metadata.category structure',
      );
    } catch (e) {
      print('[FORCED RE-SEED] ❌ Error in forcedReSeed: $e');
      debugPrint('[FORCED RE-SEED] $e');
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// OVERWRITE all 105 documents with plain-text categories (NO EMOJIS)
  /// Uses WriteBatch + SetOptions(merge: true) for atomic updates
  /// ═══════════════════════════════════════════════════════════════════════════
  static Future<void> runMasterSeeding() async {
    print(
      '[MASTER SEEDING] 🔄 Beginning OVERWRITE of all 105 documents with plain-text categories...',
    );

    try {
      final batch = FirebaseFirestore.instance.batch();
      int batchCount = 0;
      int totalCount = 0;
      const maxBatchSize = 500;

      // Get all food items (37 Proteinas + 24 Grasas + 21 Vegetales + 23 Carbohidratos)
      final allFoods = <Map<String, dynamic>>[
        ..._getCompleteFoodList(),
        ..._getGrasasHealthyFatsList(),
        ..._getProteinsCompleteList(),
        ..._getVegetablesCompleteList(),
        ..._getCarbsCompleteList(),
      ];

      print(
        '[MASTER SEEDING] Processing ${allFoods.length} food items for OVERWRITE...',
      );

      for (final foodItem in allFoods) {
        try {
          final id = foodItem['metadata']['id'] as String;
          final category = foodItem['metadata']['category'] as String;

          final docRef = FirebaseFirestore.instance
              .collection(_masterFoodCollection)
              .doc(id);

          // SetOptions(merge: true) ensures we OVERWRITE only the category field
          batch.set(docRef, foodItem, SetOptions(merge: true));

          batchCount++;
          totalCount++;

          if (batchCount >= maxBatchSize) {
            await batch.commit();
            print(
              '[MASTER SEEDING] ✅ Batch committed ($batchCount items). Total: $totalCount',
            );
            batchCount = 0;
          }
        } catch (e) {
          print('[MASTER SEEDING] ❌ Error preparing item: $e');
          debugPrint('[MASTER SEEDING] $e');
        }
      }

      // Commit final batch
      if (batchCount > 0) {
        await batch.commit();
        print(
          '[MASTER SEEDING] ✅ Final batch committed ($batchCount items). Total: $totalCount',
        );
      }

      print(
        '[MASTER SEEDING] ✅ COMPLETE! All $totalCount documents overwritten with plain-text categories',
      );
    } catch (e) {
      print('[MASTER SEEDING] ❌ Error in runMasterSeeding: $e');
      debugPrint('[MASTER SEEDING] $e');
    }
  }

  /// Seed 20 Healthy Fats ('Grasas Saludables') using WriteBatch for atomicity
  static Future<void> seedGrasasHealthyFats() async {
    print(
      '[GRASAS SEEDER] Beginning atomic WriteBatch injection of 20 Grasas Saludables...',
    );

    try {
      final grasasList = _getGrasasHealthyFatsList();
      final batch = FirebaseFirestore.instance.batch();

      int successCount = 0;

      for (final grasaDoc in grasasList) {
        try {
          final id = grasaDoc['metadata']['id'] as String;
          final name = grasaDoc['metadata']['name'] as String;

          final docRef = FirebaseFirestore.instance
              .collection('master_food_db')
              .doc(id);

          // Check if document already exists
          final docSnapshot = await docRef.get();

          if (!docSnapshot.exists) {
            batch.set(docRef, grasaDoc);
            successCount++;
            print('✅ [GRASAS] Queued "$name" for atomic write');
          } else {
            print('⚠️ [GRASAS] "$name" already exists. Skipping.');
          }
        } catch (e) {
          print('❌ [GRASAS] Error preparing "$e" for batch: $e');
          debugPrint('[GRASAS] $e');
        }
      }

      // Commit the batch
      if (successCount > 0) {
        await batch.commit();
        print(
          '[GRASAS] ✅ WriteBatch committed! $successCount Grasas Saludables injected atomically.',
        );
      } else {
        print(
          '[GRASAS] ℹ️ No new Grasas to inject (all exist or were skipped).',
        );
      }
    } catch (e) {
      print('[GRASAS] ❌ Error in seedGrasasHealthyFats: $e');
      debugPrint('[GRASAS] $e');
    }
  }

  /// Seed 30 Complete Proteins using WriteBatch for atomicity
  static Future<void> seedProteinsComplete() async {
    print(
      '[PROTEINS SEEDER] Beginning atomic WriteBatch injection of 30 Proteínas 🍗...',
    );

    try {
      final proteinsList = _getProteinsCompleteList();
      final batch = FirebaseFirestore.instance.batch();

      int successCount = 0;

      for (final proteinDoc in proteinsList) {
        try {
          final id = proteinDoc['metadata']['id'] as String;
          final name = proteinDoc['metadata']['name'] as String;

          final docRef = FirebaseFirestore.instance
              .collection('master_food_db')
              .doc(id);

          final docSnapshot = await docRef.get();

          if (!docSnapshot.exists) {
            batch.set(docRef, proteinDoc);
            successCount++;
            print('✅ [PROTEINS] Queued "$name" for atomic write');
          } else {
            print('⚠️ [PROTEINS] "$name" already exists. Skipping.');
          }
        } catch (e) {
          print('❌ [PROTEINS] Error preparing for batch: $e');
          debugPrint('[PROTEINS] $e');
        }
      }

      if (successCount > 0) {
        await batch.commit();
        print(
          '[PROTEINS] ✅ WriteBatch committed! $successCount Proteínas injected atomically.',
        );
      } else {
        print(
          '[PROTEINS] ℹ️ No new Proteínas to inject (all exist or were skipped).',
        );
      }
    } catch (e) {
      print('[PROTEINS] ❌ Error in seedProteinsComplete: $e');
      debugPrint('[PROTEINS] $e');
    }
  }

  /// Get 25+ verified foods with strict 4-Node structure
  static List<Map<String, dynamic>> _getCompleteFoodList() {
    return [
      // ═════════════════════════════════════════════════════════════════════════
      // PROTEINS (High IMR 9-10): Clean protein sources for muscle preservation
      // ═════════════════════════════════════════════════════════════════════════
      {
        'metadata': {
          'id': 'sardinas-atlanticas',
          'name': 'Sardinas (Atlánticas)',
          'nameLowercase': 'sardinas (atlánticas)',
          'category': 'Proteinas',
          'tags': ['sardina', 'pez', 'omega-3', 'calcio'],
        },
        'content': {
          'calories': 208.0,
          'proteins': 22.0,
          'fats': 12.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Omega-3 y Calcio puro para sarcopenia',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },

      {
        'metadata': {
          'id': 'pechuga-pollo',
          'name': 'Pechuga de Pollo',
          'nameLowercase': 'pechuga de pollo',
          'category': 'Proteinas',
          'tags': ['pollo', 'pechuga', 'proteína', 'limpia'],
        },
        'content': {
          'calories': 165.0,
          'proteins': 31.0,
          'fats': 3.6,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Proteína limpia sin grasa saturada',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },

      {
        'metadata': {
          'id': 'huevo-entero',
          'name': 'Huevo Entero',
          'nameLowercase': 'huevo entero',
          'category': 'Proteinas',
          'tags': ['huevo', 'colina', 'completo', 'nutriente-denso'],
        },
        'content': {
          'calories': 155.0,
          'proteins': 13.0,
          'fats': 11.0,
          'net_carbs': 1.1,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Proteína completa + Colina para cerebro',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },

      {
        'metadata': {
          'id': 'pata-de-res',
          'name': 'Pata de Res',
          'nameLowercase': 'pata de res',
          'category': 'Proteinas',
          'tags': ['res', 'colágeno', 'rojo', 'hierro'],
        },
        'content': {
          'calories': 128.0,
          'proteins': 18.0,
          'fats': 5.0,
          'net_carbs': 0.5,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Colágeno para reparación de tejidos',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },

      {
        'metadata': {
          'id': 'muslo-pollo',
          'name': 'Muslo de Pollo',
          'nameLowercase': 'muslo de pollo',
          'category': 'Proteinas',
          'tags': ['pollo', 'muslo', 'hierro', 'vitamina-b12'],
        },
        'content': {
          'calories': 169.0,
          'proteins': 20.0,
          'fats': 9.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Proteína con hierro y B12',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },

      {
        'metadata': {
          'id': 'salmon-cocido',
          'name': 'Salmón (Cocido)',
          'nameLowercase': 'salmón (cocido)',
          'category': 'Proteinas',
          'tags': ['salmón', 'pescado', 'omega-3', 'cocido'],
        },
        'content': {
          'calories': 208.0,
          'proteins': 25.0,
          'fats': 13.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Omega-3 premium y astaxantina',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },

      // ═════════════════════════════════════════════════════════════════════════
      // FATS (IMR 10): Healthy fats for hormone synthesis
      // ═════════════════════════════════════════════════════════════════════════
      {
        'metadata': {
          'id': 'aguacate',
          'name': 'Aguacate',
          'nameLowercase': 'aguacate',
          'category': 'Grasas',
          'tags': ['aguacate', 'potasio', 'grasa-saludable', 'monoinsaturada'],
        },
        'content': {
          'calories': 160.0,
          'proteins': 2.0,
          'fats': 15.0,
          'net_carbs': 2.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Grasa monoinsaturada + potasio alto',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },

      {
        'metadata': {
          'id': 'aceite-oliva-virgen',
          'name': 'Aceite de Oliva (Virgen Extra)',
          'nameLowercase': 'aceite de oliva (virgen extra)',
          'category': 'Grasas',
          'tags': ['aceite', 'oliva', 'polifenoles', 'virgen-extra'],
        },
        'content': {
          'calories': 884.0,
          'proteins': 0.0,
          'fats': 92.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Polifenoles anti-oxidantes máximos',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },

      {
        'metadata': {
          'id': 'nueces',
          'name': 'Nueces',
          'nameLowercase': 'nueces',
          'category': 'Grasas',
          'tags': ['nueces', 'fruto-seco', 'omega-3', 'cruda'],
        },
        'content': {
          'calories': 654.0,
          'proteins': 9.0,
          'fats': 65.0,
          'net_carbs': 14.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip': 'Omega-3 vegetal y antioxidantes',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },

      {
        'metadata': {
          'id': 'cafe-negro',
          'name': 'Café Negro',
          'nameLowercase': 'café negro',
          'category': 'Grasas',
          'tags': ['café', 'negro', 'cero-calorías', 'energía'],
        },
        'content': {
          'calories': 0.0,
          'proteins': 0.2,
          'fats': 0.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Energía pura sin calorías ni azúcar',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },

      // ═════════════════════════════════════════════════════════════════════════
      // VEGETABLES (IMR 9-10): Low glycemic, high micronutrients
      // ═════════════════════════════════════════════════════════════════════════
      {
        'metadata': {
          'id': 'zucchini',
          'name': 'Zucchini',
          'nameLowercase': 'zucchini',
          'category': 'Vegetales',
          'tags': ['zucchini', 'calabacín', 'bajo-gi', 'verde'],
        },
        'content': {
          'calories': 17.0,
          'proteins': 1.2,
          'fats': 0.3,
          'net_carbs': 3.1,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Bajo índice glucémico, perfecto para opciones',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },

      {
        'metadata': {
          'id': 'pimentón-rojo',
          'name': 'Pimentón Rojo',
          'nameLowercase': 'pimentón rojo',
          'category': 'Vegetales',
          'tags': ['pimentón', 'vitamina-c', 'capsaicina', 'rojo'],
        },
        'content': {
          'calories': 31.0,
          'proteins': 1.0,
          'fats': 0.3,
          'net_carbs': 6.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Vitamina C masiva y capsaicina thermogénica',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },

      {
        'metadata': {
          'id': 'apio',
          'name': 'Apio',
          'nameLowercase': 'apio',
          'category': 'Vegetales',
          'tags': ['apio', 'diurético', 'antiinflamatorio', 'verde'],
        },
        'content': {
          'calories': 16.0,
          'proteins': 0.7,
          'fats': 0.2,
          'net_carbs': 3.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Diurético natural y antiinflamatorio',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },

      {
        'metadata': {
          'id': 'cebolla',
          'name': 'Cebolla',
          'nameLowercase': 'cebolla',
          'category': 'Vegetales',
          'tags': ['cebolla', 'quercetina', 'inmune', 'blanca'],
        },
        'content': {
          'calories': 40.0,
          'proteins': 1.1,
          'fats': 0.1,
          'net_carbs': 9.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip': 'Quercetina para sistema inmunológico',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Moderado'},
      },

      {
        'metadata': {
          'id': 'brocoli',
          'name': 'Brócoli',
          'nameLowercase': 'brócoli',
          'category': 'Vegetales',
          'tags': ['brócoli', 'sulforafano', 'verde', 'crucífero'],
        },
        'content': {
          'calories': 34.0,
          'proteins': 2.8,
          'fats': 0.4,
          'net_carbs': 6.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Sulforafano anti-inflamatorio poderoso',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },

      {
        'metadata': {
          'id': 'espinaca',
          'name': 'Espinaca',
          'nameLowercase': 'espinaca',
          'category': 'Vegetales',
          'tags': ['espinaca', 'hierro', 'verde', 'luteína'],
        },
        'content': {
          'calories': 23.0,
          'proteins': 2.7,
          'fats': 0.4,
          'net_carbs': 1.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Hierro + Luteína para visión y energía',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },

      // ═════════════════════════════════════════════════════════════════════════
      // CARBOHYDRATES (IMR 4-6): Moderate carbs for energy cycling
      // ═════════════════════════════════════════════════════════════════════════
      {
        'metadata': {
          'id': 'arroz-integral',
          'name': 'Arroz Integral',
          'nameLowercase': 'arroz integral',
          'category': 'Carbohidratos',
          'tags': ['arroz', 'integral', 'fibra', 'índice-moderado'],
        },
        'content': {
          'calories': 130.0,
          'proteins': 3.0,
          'fats': 1.0,
          'net_carbs': 23.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 6,
          'svg_node': null,
          'tip': 'Ciclado de carbohidratos estratégico',
        },
        'quiz': {'impact': 'Moderado', 'level': 'Moderado'},
      },

      {
        'metadata': {
          'id': 'pasta-integral',
          'name': 'Pasta Integral',
          'nameLowercase': 'pasta integral',
          'category': 'Carbohidratos',
          'tags': ['pasta', 'integral', 'fideos', 'buen-índice'],
        },
        'content': {
          'calories': 128.0,
          'proteins': 3.0,
          'fats': 1.0,
          'net_carbs': 26.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 6,
          'svg_node': null,
          'tip': 'Buen índice glucémico con fibra',
        },
        'quiz': {'impact': 'Moderado', 'level': 'Moderado'},
      },

      {
        'metadata': {
          'id': 'arepa-maiz',
          'name': 'Arepa de Maíz',
          'nameLowercase': 'arepa de maíz',
          'category': 'Carbohidratos',
          'tags': ['arepa', 'maíz', 'tradicional', 'cultura'],
        },
        'content': {
          'calories': 130.0,
          'proteins': 3.0,
          'fats': 1.5,
          'net_carbs': 25.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 5,
          'svg_node': null,
          'tip': 'Energía tradicional moderada',
        },
        'quiz': {'impact': 'Moderado', 'level': 'Moderado'},
      },

      {
        'metadata': {
          'id': 'pan-integral',
          'name': 'Pan Integral',
          'nameLowercase': 'pan integral',
          'category': 'Carbohidratos',
          'tags': ['pan', 'integral', 'fibra', 'saciedad'],
        },
        'content': {
          'calories': 250.0,
          'proteins': 8.0,
          'fats': 3.0,
          'net_carbs': 45.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 5,
          'svg_node': null,
          'tip': 'Fibra moderada para saciedad',
        },
        'quiz': {'impact': 'Moderado', 'level': 'Moderado'},
      },

      // ═════════════════════════════════════════════════════════════════════════
      // PROCESSED (IMR 2-3) — EVITAR — Ultra-processed, pro-inflammatory
      // ═════════════════════════════════════════════════════════════════════════
      {
        'metadata': {
          'id': 'empanada',
          'name': 'Empanada',
          'nameLowercase': 'empanada',
          'category': 'Carbohidratos',
          'tags': ['empanada', 'frita', 'ultra-procesada', 'evitar'],
        },
        'content': {
          'calories': 235.0,
          'proteins': 6.0,
          'fats': 15.0,
          'net_carbs': 25.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 2,
          'svg_node': null,
          'tip': 'EVITAR: Ultra-procesada e inflamatoria',
        },
        'quiz': {'impact': 'Negativo', 'level': 'Evitar'},
      },

      {
        'metadata': {
          'id': 'pan-blanco',
          'name': 'Pan Blanco',
          'nameLowercase': 'pan blanco',
          'category': 'Carbohidratos',
          'tags': ['pan', 'blanco', 'refinado', 'azúcar-añadido'],
        },
        'content': {
          'calories': 265.0,
          'proteins': 7.0,
          'fats': 2.0,
          'net_carbs': 50.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 2,
          'svg_node': null,
          'tip': 'EVITAR: Índice glucémico alto',
        },
        'quiz': {'impact': 'Negativo', 'level': 'Evitar'},
      },

      {
        'metadata': {
          'id': 'galletas-saladas',
          'name': 'Galletas Saladas',
          'nameLowercase': 'galletas saladas',
          'category': 'Carbohidratos',
          'tags': ['galletas', 'saladas', 'sodio-alto', 'ultra-procesada'],
        },
        'content': {
          'calories': 450.0,
          'proteins': 8.0,
          'fats': 20.0,
          'net_carbs': 70.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 2,
          'svg_node': null,
          'tip': 'EVITAR: Sodio alto y ultra-procesada',
        },
        'quiz': {'impact': 'Negativo', 'level': 'Evitar'},
      },

      {
        'metadata': {
          'id': 'pasta-blanca',
          'name': 'Pasta Blanca',
          'nameLowercase': 'pasta blanca',
          'category': 'Carbohidratos',
          'tags': ['pasta', 'blanca', 'refinada', 'índice-alto'],
        },
        'content': {
          'calories': 131.0,
          'proteins': 4.0,
          'fats': 1.1,
          'net_carbs': 30.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 3,
          'svg_node': null,
          'tip': 'EVITAR: Índice glucémico alto, refinada',
        },
        'quiz': {'impact': 'Negativo', 'level': 'Evitar'},
      },
    ];
  }

  /// Get 20 Healthy Fats ('Grasas Saludables') with strict 4-Node structure
  /// Category: 'Grasas'
  /// IMR Score: 7-10 (Professional Nutrition Grade)
  static List<Map<String, dynamic>> _getGrasasHealthyFatsList() {
    return [
      {
        'metadata': {
          'id': 'aguacate_has',
          'name': 'Aguacate Has',
          'nameLowercase': 'aguacate has',
          'category': 'Grasas',
          'tags': ['keto', 'potasio', 'saciedad'],
        },
        'content': {
          'calories': 160.0,
          'proteins': 2.0,
          'fats': 15.0,
          'net_carbs': 2.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip':
              'Grasa monoinsaturada que mejora la sensibilidad a la insulina.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'aceite_oliva_ev',
          'name': 'Aceite de Oliva Extra Virgen',
          'nameLowercase': 'aceite de oliva extra virgen',
          'category': 'Grasas',
          'tags': ['corazon', 'omega9', 'longevidad'],
        },
        'content': {
          'calories': 884.0,
          'proteins': 0.0,
          'fats': 100.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip':
              'Rico en polifenoles y ácido oleico; potente antiinflamatorio.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'mantequilla_ghee',
          'name': 'Mantequilla Ghee',
          'nameLowercase': 'mantequilla ghee',
          'category': 'Grasas',
          'tags': ['estable', 'sin_lactosa', 'energia'],
        },
        'content': {
          'calories': 876.0,
          'proteins': 0.3,
          'fats': 99.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip':
              'Grasa estable a altas temperaturas; libre de lactosa y caseína.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'nueces_del_nogal',
          'name': 'Nueces del Nogal',
          'nameLowercase': 'nueces del nogal',
          'category': 'Grasas',
          'tags': ['cerebro', 'omega3', 'snack'],
        },
        'content': {
          'calories': 654.0,
          'proteins': 15.0,
          'fats': 65.0,
          'net_carbs': 7.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'La mejor fuente vegetal de Omega-3 para la salud cerebral.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'almendras_naturales',
          'name': 'Almendras Naturales',
          'nameLowercase': 'almendras naturales',
          'category': 'Grasas',
          'tags': ['magnesio', 'vitaminae', 'fibra'],
        },
        'content': {
          'calories': 579.0,
          'proteins': 21.0,
          'fats': 50.0,
          'net_carbs': 10.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip':
              'Alta densidad de Vitamina E y Magnesio para control glucémico.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'aceitunas_verdes',
          'name': 'Aceitunas Verdes',
          'nameLowercase': 'aceitunas verdes',
          'category': 'Grasas',
          'tags': ['ayuno', 'sodio', 'aperitivo'],
        },
        'content': {
          'calories': 145.0,
          'proteins': 1.0,
          'fats': 15.0,
          'net_carbs': 3.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip':
              'Aportan sodio necesario durante protocolos de ayuno intermitente.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'coco_natural',
          'name': 'Coco (Carne natural)',
          'nameLowercase': 'coco (carne natural)',
          'category': 'Grasas',
          'tags': ['mct', 'energia', 'tropical'],
        },
        'content': {
          'calories': 354.0,
          'proteins': 3.3,
          'fats': 33.0,
          'net_carbs': 6.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 8,
          'svg_node': null,
          'tip':
              'Contiene MCTs (Triglicéridos de cadena media) para energía rápida.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'chontaduro_local',
          'name': 'Chontaduro',
          'nameLowercase': 'chontaduro',
          'category': 'Grasas',
          'tags': ['local', 'preentreno', 'vitaminas'],
        },
        'content': {
          'calories': 120.0,
          'proteins': 2.5,
          'fats': 8.0,
          'net_carbs': 9.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip':
              'Superalimento local; energía sostenida y precursores de Vitamina A.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'semillas_calabaza',
          'name': 'Semillas de Calabaza',
          'nameLowercase': 'semillas de calabaza',
          'category': 'Grasas',
          'tags': ['zinc', 'testosterona', 'semillas'],
        },
        'content': {
          'calories': 559.0,
          'proteins': 30.0,
          'fats': 49.0,
          'net_carbs': 11.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip':
              'Fuente excepcional de Zinc; vital para la salud hormonal masculina.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'manteca_cerdo_pura',
          'name': 'Manteca de Cerdo (Pura)',
          'nameLowercase': 'manteca de cerdo (pura)',
          'category': 'Grasas',
          'tags': ['cocina', 'tradicional', 'estable'],
        },
        'content': {
          'calories': 900.0,
          'proteins': 0.0,
          'fats': 100.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 8,
          'svg_node': null,
          'tip':
              'Grasa tradicional estable; excelente alternativa a aceites vegetales.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'macadamias',
          'name': 'Nueces de Macadamia',
          'nameLowercase': 'nueces de macadamia',
          'category': 'Grasas',
          'tags': ['premium', 'antiinflamatorio', 'keto'],
        },
        'content': {
          'calories': 718.0,
          'proteins': 8.0,
          'fats': 76.0,
          'net_carbs': 5.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip':
              'Perfil lipídico casi perfecto; bajísimas en Omega-6 inflamatorio.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'semillas_chia_raw',
          'name': 'Semillas de Chía',
          'nameLowercase': 'semillas de chía',
          'category': 'Grasas',
          'tags': ['fibra', 'omega3', 'digestión'],
        },
        'content': {
          'calories': 486.0,
          'proteins': 17.0,
          'fats': 31.0,
          'net_carbs': 2.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip': 'Alta densidad de fibra soluble y Omega-3 ALA.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'pistachos_tostados',
          'name': 'Pistachos (Sin sal)',
          'nameLowercase': 'pistachos (sin sal)',
          'category': 'Grasas',
          'tags': ['antioxidantes', 'proteina_veg', 'snack'],
        },
        'content': {
          'calories': 562.0,
          'proteins': 20.0,
          'fats': 45.0,
          'net_carbs': 18.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 8,
          'svg_node': null,
          'tip': 'Ricos en antioxidantes y luteína para la salud visual.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'avellanas_naturales',
          'name': 'Avellanas',
          'nameLowercase': 'avellanas',
          'category': 'Grasas',
          'tags': ['biotina', 'manganeso', 'saciedad'],
        },
        'content': {
          'calories': 628.0,
          'proteins': 15.0,
          'fats': 61.0,
          'net_carbs': 7.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip':
              'Alta concentración de manganeso y biotina para piel y cabello.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'aceite_pescado_omega3',
          'name': 'Aceite de Pescado',
          'nameLowercase': 'aceite de pescado',
          'category': 'Grasas',
          'tags': ['suplemento', 'omega3', 'neuroprotector'],
        },
        'content': {
          'calories': 900.0,
          'proteins': 0.0,
          'fats': 100.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip':
              'Fuente directa de EPA y DHA; vital para desinflamación celular.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'mani_natural',
          'name': 'Maní Natural',
          'nameLowercase': 'maní natural',
          'category': 'Grasas',
          'tags': ['proteina_veg', 'economico', 'resveratrol'],
        },
        'content': {
          'calories': 567.0,
          'proteins': 26.0,
          'fats': 49.0,
          'net_carbs': 7.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 7,
          'svg_node': null,
          'tip':
              'Grasa y proteína accesible; moderar por alto contenido de Omega-6.',
        },
        'quiz': {'impact': 'Moderado', 'level': 'Moderado'},
      },
      {
        'metadata': {
          'id': 'grasa_res_sebo',
          'name': 'Sebo de Res (Tallow)',
          'nameLowercase': 'sebo de res (tallow)',
          'category': 'Grasas',
          'tags': ['carnivore', 'estable', 'vitaminas'],
        },
        'content': {
          'calories': 902.0,
          'proteins': 0.0,
          'fats': 100.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 8,
          'svg_node': null,
          'tip': 'Grasa ancestral rica en vitaminas liposolubles (A, D, E, K).',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'semillas_linaza_molida',
          'name': 'Linaza Molida',
          'nameLowercase': 'linaza molida',
          'category': 'Grasas',
          'tags': ['hormonal', 'fibra', 'omega3'],
        },
        'content': {
          'calories': 534.0,
          'proteins': 18.0,
          'fats': 42.0,
          'net_carbs': 1.6,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip':
              'Altísima en lignanos; excelente para el equilibrio hormonal femenino.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'semillas_girasol',
          'name': 'Semillas de Girasol',
          'nameLowercase': 'semillas de girasol',
          'category': 'Grasas',
          'tags': ['vitaminae', 'minerales', 'snack'],
        },
        'content': {
          'calories': 584.0,
          'proteins': 21.0,
          'fats': 51.0,
          'net_carbs': 11.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 7,
          'svg_node': null,
          'tip': 'Ricas en Vitamina E; consumir con moderación por Omega-6.',
        },
        'quiz': {'impact': 'Moderado', 'level': 'Moderado'},
      },
      {
        'metadata': {
          'id': 'leche_coco_full_fat',
          'name': 'Leche de Coco (Full Fat)',
          'nameLowercase': 'leche de coco (full fat)',
          'category': 'Grasas',
          'tags': ['sustituto_lacteos', 'mct', 'cocina'],
        },
        'content': {
          'calories': 230.0,
          'proteins': 2.3,
          'fats': 24.0,
          'net_carbs': 3.3,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 8,
          'svg_node': null,
          'tip': 'Excelente base para batidos saciantes y café metabólico.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
    ];
  }

  /// Get 30 Complete Proteins with strict 4-Node structure
  static List<Map<String, dynamic>> _getProteinsCompleteList() {
    return [
      {
        'metadata': {
          'id': 'pechuga_pollo_asada',
          'name': 'Pechuga de Pollo',
          'nameLowercase': 'pechuga de pollo',
          'category': 'Proteinas',
          'tags': ['musculo', 'magro', 'basico'],
        },
        'content': {
          'calories': 165.0,
          'proteins': 31.0,
          'fats': 3.6,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip':
              'Proteína magra de alta biodisponibilidad; ideal para síntesis proteica.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'huevo_entero_cocido',
          'name': 'Huevo Entero',
          'nameLowercase': 'huevo entero',
          'category': 'Proteinas',
          'tags': ['completo', 'vitaminas', 'economico'],
        },
        'content': {
          'calories': 155.0,
          'proteins': 13.0,
          'fats': 11.0,
          'net_carbs': 1.1,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip':
              'El patrón oro de la proteína; contiene colina para la salud cerebral.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'carne_res_magra',
          'name': 'Carne de Res (Magra)',
          'nameLowercase': 'carne de res (magra)',
          'category': 'Proteinas',
          'tags': ['hierro', 'fuerza', 'b12'],
        },
        'content': {
          'calories': 250.0,
          'proteins': 26.0,
          'fats': 15.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip': 'Rica en Hierro Hemo, Zinc y Vitamina B12 esencial.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'salmon_salvaje',
          'name': 'Salmón',
          'nameLowercase': 'salmón',
          'category': 'Proteinas',
          'tags': ['omega3', 'longevidad', 'corazon'],
        },
        'content': {
          'calories': 208.0,
          'proteins': 20.0,
          'fats': 13.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip':
              'Proteína premium + Omega-3 EPA/DHA; potente antiinflamatorio.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'sardinas_atlanticas',
          'name': 'Sardinas',
          'nameLowercase': 'sardinas',
          'category': 'Proteinas',
          'tags': ['calcio', 'densidad', 'mar'],
        },
        'content': {
          'calories': 208.0,
          'proteins': 25.0,
          'fats': 11.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip':
              'Superalimento: Proteína, calcio (espinas) y ácidos grasos esenciales.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'pata_de_res_cocida',
          'name': 'Pata de Res (Colágeno)',
          'nameLowercase': 'pata de res (colágeno)',
          'category': 'Proteinas',
          'tags': ['colageno', 'articulaciones', 'caldo'],
        },
        'content': {
          'calories': 125.0,
          'proteins': 18.0,
          'fats': 5.0,
          'net_carbs': 0.5,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip':
              'Fuente de glicina y colágeno para salud articular e intestinal.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'higado_de_res',
          'name': 'Hígado de Res',
          'nameLowercase': 'hígado de res',
          'category': 'Proteinas',
          'tags': ['organos', 'multivitaminico', 'energia'],
        },
        'content': {
          'calories': 135.0,
          'proteins': 20.0,
          'fats': 4.0,
          'net_carbs': 4.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip':
              'Órgano más denso en nutrientes; dosis masiva de Vitamina A y Cobre.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'atun_en_agua',
          'name': 'Atún (en agua)',
          'nameLowercase': 'atún (en agua)',
          'category': 'Proteinas',
          'tags': ['magro', 'rapido', 'musculo'],
        },
        'content': {
          'calories': 116.0,
          'proteins': 26.0,
          'fats': 1.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip':
              'Proteína casi pura; excelente para control calórico estricto.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'trucha_arcoiris',
          'name': 'Trucha Arcoíris',
          'nameLowercase': 'trucha arcoíris',
          'category': 'Proteinas',
          'tags': ['local', 'fresco', 'andino'],
        },
        'content': {
          'calories': 141.0,
          'proteins': 21.0,
          'fats': 6.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip': 'Proteína andina local con gran perfil de grasas saludables.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'yogur_griego_natural',
          'name': 'Yogur Griego Natural',
          'nameLowercase': 'yogur griego natural',
          'category': 'Proteinas',
          'tags': ['probioticos', 'lacteo', 'saciedad'],
        },
        'content': {
          'calories': 59.0,
          'proteins': 10.0,
          'fats': 0.4,
          'net_carbs': 3.6,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip': 'Proteína láctea de absorción intermedia con probióticos.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'lomo_de_cerdo',
          'name': 'Lomo de Cerdo',
          'nameLowercase': 'lomo de cerdo',
          'category': 'Proteinas',
          'tags': ['magro', 'tiamina', 'economico'],
        },
        'content': {
          'calories': 143.0,
          'proteins': 26.0,
          'fats': 4.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip': 'Corte muy magro; excelente fuente de Tiamina (B1).',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'queso_cottage_bajo_grasa',
          'name': 'Queso Cottage',
          'nameLowercase': 'queso cottage',
          'category': 'Proteinas',
          'tags': ['caseina', 'noche', 'musculo'],
        },
        'content': {
          'calories': 98.0,
          'proteins': 11.0,
          'fats': 4.3,
          'net_carbs': 3.4,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip': 'Rico en Caseína; ideal para evitar el catabolismo nocturno.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'claras_de_huevo',
          'name': 'Claras de Huevo',
          'nameLowercase': 'claras de huevo',
          'category': 'Proteinas',
          'tags': ['albumina', 'sin_grasa', 'volumen'],
        },
        'content': {
          'calories': 52.0,
          'proteins': 11.0,
          'fats': 0.2,
          'net_carbs': 0.7,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Albúmina pura; la forma más magra de aumentar proteína.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'muslo_pollo_sin_piel',
          'name': 'Muslo de Pollo',
          'nameLowercase': 'muslo de pollo',
          'category': 'Proteinas',
          'tags': ['zinc', 'sabor', 'pollo'],
        },
        'content': {
          'calories': 170.0,
          'proteins': 24.0,
          'fats': 8.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 8,
          'svg_node': null,
          'tip': 'Más jugoso y rico en zinc que la pechuga; grasa moderada.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'camarones_cocidos',
          'name': 'Camarones',
          'nameLowercase': 'camarones',
          'category': 'Proteinas',
          'tags': ['antioxidante', 'selenio', 'mar'],
        },
        'content': {
          'calories': 99.0,
          'proteins': 24.0,
          'fats': 0.3,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip': 'Altos en Selenio y Astaxantina (antioxidante potente).',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'proteina_whey_isolate',
          'name': 'Proteína Whey (Aislada)',
          'nameLowercase': 'proteína whey (aislada)',
          'category': 'Proteinas',
          'tags': ['postentreno', 'leucina', 'suplemento'],
        },
        'content': {
          'calories': 370.0,
          'proteins': 85.0,
          'fats': 1.0,
          'net_carbs': 2.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip':
              'Absorción ultra rápida; pico de leucina para post-entrenamiento.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'tilapia_fresca',
          'name': 'Tilapia',
          'nameLowercase': 'tilapia',
          'category': 'Proteinas',
          'tags': ['blanco', 'ligero', 'digestión'],
        },
        'content': {
          'calories': 128.0,
          'proteins': 26.0,
          'fats': 2.7,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 8,
          'svg_node': null,
          'tip': 'Pescado blanco magro; bajo en mercurio y fácil digestión.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'carne_cordero',
          'name': 'Carne de Cordero',
          'nameLowercase': 'carne de cordero',
          'category': 'Proteinas',
          'tags': ['cla', 'grasa_saludable', 'fuerza'],
        },
        'content': {
          'calories': 294.0,
          'proteins': 25.0,
          'fats': 21.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 8,
          'svg_node': null,
          'tip':
              'Rica en CLA (Ácido Linoleico Conjugado) que ayuda a quemar grasa.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'pavo_pechuga',
          'name': 'Pechuga de Pavo',
          'nameLowercase': 'pechuga de pavo',
          'category': 'Proteinas',
          'tags': ['triptofano', 'magro', 'pavo'],
        },
        'content': {
          'calories': 135.0,
          'proteins': 30.0,
          'fats': 1.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Contiene Triptófano; precursor de serotonina y melatonina.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'tofu_firme',
          'name': 'Tofu Firme',
          'nameLowercase': 'tofu firme',
          'category': 'Proteinas',
          'tags': ['vegetal', 'isoflavonas', 'soja'],
        },
        'content': {
          'calories': 144.0,
          'proteins': 15.0,
          'fats': 8.0,
          'net_carbs': 2.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 7,
          'svg_node': null,
          'tip': 'Proteína vegetal completa; contiene isoflavonas protectoras.',
        },
        'quiz': {'impact': 'Moderado', 'level': 'Moderado'},
      },
      {
        'metadata': {
          'id': 'corazon_de_res',
          'name': 'Corazón de Res',
          'nameLowercase': 'corazón de res',
          'category': 'Proteinas',
          'tags': ['coq10', 'mitocondria', 'organos'],
        },
        'content': {
          'calories': 165.0,
          'proteins': 28.0,
          'fats': 5.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip':
              'La mejor fuente natural de Coenzima Q10 para salud mitocondrial.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'bacalao_fresco',
          'name': 'Bacalao',
          'nameLowercase': 'bacalao',
          'category': 'Proteinas',
          'tags': ['yodo', 'tiroides', 'magro'],
        },
        'content': {
          'calories': 82.0,
          'proteins': 18.0,
          'fats': 0.7,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip': 'Muy bajo en calorías y rico en Yodo para la tiroides.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'cuy_asado_local',
          'name': 'Cuy (Conejillo de Indias)',
          'nameLowercase': 'cuy (conejillo de indias)',
          'category': 'Proteinas',
          'tags': ['ancestral', 'andino', 'saludable'],
        },
        'content': {
          'calories': 96.0,
          'proteins': 19.0,
          'fats': 1.6,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Carne andina ancestral; bajísima en grasa y alta en hierro.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'tempeh_fermentado',
          'name': 'Tempeh',
          'nameLowercase': 'tempeh',
          'category': 'Proteinas',
          'tags': ['fermentado', 'vegetal', 'prebiotico'],
        },
        'content': {
          'calories': 193.0,
          'proteins': 19.0,
          'fats': 11.0,
          'net_carbs': 9.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 8,
          'svg_node': null,
          'tip':
              'Proteína vegetal fermentada; mejor digestión que la soja común.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'conejo_carne',
          'name': 'Carne de Conejo',
          'nameLowercase': 'carne de conejo',
          'category': 'Proteinas',
          'tags': ['premium', 'magro', 'fuerza'],
        },
        'content': {
          'calories': 173.0,
          'proteins': 33.0,
          'fats': 3.5,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip':
              'Una de las carnes más magras y ricas en proteínas que existen.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'mojarra_asada',
          'name': 'Mojarra',
          'nameLowercase': 'mojarra',
          'category': 'Proteinas',
          'tags': ['popular', 'blanco', 'economico'],
        },
        'content': {
          'calories': 129.0,
          'proteins': 26.0,
          'fats': 3.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 8,
          'svg_node': null,
          'tip': 'Pescado blanco común; buena relación calidad-precio.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'mollejas_de_pollo',
          'name': 'Mollejas de Pollo',
          'nameLowercase': 'mollejas de pollo',
          'category': 'Proteinas',
          'tags': ['glucosamina', 'barato', 'musculo'],
        },
        'content': {
          'calories': 146.0,
          'proteins': 30.0,
          'fats': 2.7,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip': 'Altísimas en proteína y ricas en glucosamina natural.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'gelatina_sin_azucar',
          'name': 'Gelatina (Sin Azúcar)',
          'nameLowercase': 'gelatina (sin azúcar)',
          'category': 'Proteinas',
          'tags': ['ayuno', 'postre', 'colageno'],
        },
        'content': {
          'calories': 7.0,
          'proteins': 1.6,
          'fats': 0.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 7,
          'svg_node': null,
          'tip': 'Aporta aminoácidos para el tejido conectivo; sin calorías.',
        },
        'quiz': {'impact': 'Positivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'lentejas_cocidas',
          'name': 'Lentejas',
          'nameLowercase': 'lentejas',
          'category': 'Proteinas',
          'tags': ['fibra', 'legumbre', 'hierro'],
        },
        'content': {
          'calories': 116.0,
          'proteins': 9.0,
          'fats': 0.4,
          'net_carbs': 12.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 7,
          'svg_node': null,
          'tip':
              'Fuente de proteína vegetal y fibra; moderar por carga de carbos.',
        },
        'quiz': {'impact': 'Moderado', 'level': 'Moderado'},
      },
      {
        'metadata': {
          'id': 'garbanzos_cocidos',
          'name': 'Garbanzos',
          'nameLowercase': 'garbanzos',
          'category': 'Proteinas',
          'tags': ['energia', 'legumbre', 'carbo'],
        },
        'content': {
          'calories': 164.0,
          'proteins': 9.0,
          'fats': 2.6,
          'net_carbs': 22.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 6,
          'svg_node': null,
          'tip':
              'Proteína vegetal con mayor carga glucémica; usar con estrategia.',
        },
        'quiz': {'impact': 'Moderado', 'level': 'Moderado'},
      },
      {
        'metadata': {
          'id': 'chicharron_natural',
          'name': 'Chicharrón (Piel de Cerdo)',
          'nameLowercase': 'chicharrón (piel de cerdo)',
          'category': 'Proteinas',
          'tags': ['colageno', 'keto', 'saciedad'],
        },
        'content': {
          'calories': 544.0,
          'proteins': 61.0,
          'fats': 31.0,
          'net_carbs': 0.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 7,
          'svg_node': null,
          'tip':
              'Sorprendentemente alto en glicina y colágeno; controlar por calorías.',
        },
        'quiz': {'impact': 'Moderado', 'level': 'Moderado'},
      },
    ];
  }

  /// Seed 15 Complete Vegetables using WriteBatch for atomicity
  static Future<void> seedVegetablesComplete() async {
    print(
      '[VEGETABLES SEEDER] Beginning atomic WriteBatch injection of 15 Vegetales 🥦...',
    );

    try {
      final vegetablesList = _getVegetablesCompleteList();
      final batch = FirebaseFirestore.instance.batch();

      int successCount = 0;

      for (final vegetableDoc in vegetablesList) {
        try {
          final id = vegetableDoc['metadata']['id'] as String;
          final name = vegetableDoc['metadata']['name'] as String;

          final docRef = FirebaseFirestore.instance
              .collection('master_food_db')
              .doc(id);

          final docSnapshot = await docRef.get();

          if (!docSnapshot.exists) {
            batch.set(docRef, vegetableDoc);
            successCount++;
            print('✅ [VEGETABLES] Queued "$name" for atomic write');
          } else {
            print('⚠️ [VEGETABLES] "$name" already exists. Skipping.');
          }
        } catch (e) {
          print('❌ [VEGETABLES] Error preparing for batch: $e');
          debugPrint('[VEGETABLES] $e');
        }
      }

      if (successCount > 0) {
        await batch.commit();
        print(
          '[VEGETABLES] ✅ WriteBatch committed! $successCount Vegetales injected atomically.',
        );
      } else {
        print(
          '[VEGETABLES] ℹ️ No new Vegetales to inject (all exist or were skipped).',
        );
      }
    } catch (e) {
      print('[VEGETABLES] ❌ Error in seedVegetablesComplete: $e');
      debugPrint('[VEGETABLES] $e');
    }
  }

  /// Get 15 Complete Vegetables with strict 4-Node structure
  static List<Map<String, dynamic>> _getVegetablesCompleteList() {
    return [
      {
        'metadata': {
          'id': 'brocoli_fresco',
          'name': 'Brócoli',
          'nameLowercase': 'brócoli',
          'category': 'Vegetales',
          'tags': ['fibra', 'sulforafano', 'crucifera'],
        },
        'content': {
          'calories': 34.0,
          'proteins': 3.0,
          'fats': 0.0,
          'net_carbs': 4.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip':
              'Contiene sulforafano; potente activador de la desintoxicación hepática.',
        },
        'quiz': {'impact': 'Antiinflamatorio', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'espinaca_baby',
          'name': 'Espinaca',
          'nameLowercase': 'espinaca',
          'category': 'Vegetales',
          'tags': ['hierro', 'magnesio', 'hoja_verde'],
        },
        'content': {
          'calories': 23.0,
          'proteins': 3.0,
          'fats': 0.0,
          'net_carbs': 1.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip':
              'Densidad extrema de magnesio y potasio; vital para la bomba sodio-potasio.',
        },
        'quiz': {'impact': 'Micronutrientes', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'lechuga_fresca',
          'name': 'Lechuga',
          'nameLowercase': 'lechuga',
          'category': 'Vegetales',
          'tags': ['agua', 'volumen', 'ensalada'],
        },
        'content': {
          'calories': 15.0,
          'proteins': 1.0,
          'fats': 0.0,
          'net_carbs': 2.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip':
              'Aporta hidratación celular y volumen gástrico con mínima carga insulínica.',
        },
        'quiz': {'impact': 'Hidratación', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'pepino_cohombro',
          'name': 'Pepino',
          'nameLowercase': 'pepino',
          'category': 'Vegetales',
          'tags': ['fresco', 'piel', 'agua'],
        },
        'content': {
          'calories': 16.0,
          'proteins': 1.0,
          'fats': 0.0,
          'net_carbs': 2.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip': 'Rico en sílice para tejidos conectivos y alta hidratación.',
        },
        'quiz': {'impact': 'Hidratación', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'tomate_chonto',
          'name': 'Tomate',
          'nameLowercase': 'tomate',
          'category': 'Vegetales',
          'tags': ['licopeno', 'corazon', 'rojo'],
        },
        'content': {
          'calories': 18.0,
          'proteins': 1.0,
          'fats': 0.0,
          'net_carbs': 3.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip':
              'Fuente principal de licopeno; protector cardiovascular y prostático.',
        },
        'quiz': {'impact': 'Antioxidante', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'zanahoria_fresca',
          'name': 'Zanahoria',
          'nameLowercase': 'zanahoria',
          'category': 'Vegetales',
          'tags': ['vista', 'betacaroteno', 'raiz'],
        },
        'content': {
          'calories': 41.0,
          'proteins': 1.0,
          'fats': 0.0,
          'net_carbs': 7.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 7,
          'svg_node': null,
          'tip':
              'Alta en betacarotenos; consumir con moderación por carga de azúcares naturales.',
        },
        'quiz': {'impact': 'Energía', 'level': 'Moderado'},
      },
      {
        'metadata': {
          'id': 'cebolla_cabezona',
          'name': 'Cebolla',
          'nameLowercase': 'cebolla',
          'category': 'Vegetales',
          'tags': ['prebiotico', 'quercetina', 'base'],
        },
        'content': {
          'calories': 40.0,
          'proteins': 1.0,
          'fats': 0.1,
          'net_carbs': 8.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 7,
          'svg_node': null,
          'tip':
              'Rica en quercetina; prebiótico natural que alimenta la microbiota beneficiosa.',
        },
        'quiz': {'impact': 'Digestivo', 'level': 'Moderado'},
      },
      {
        'metadata': {
          'id': 'ajo_fresco',
          'name': 'Ajo',
          'nameLowercase': 'ajo',
          'category': 'Vegetales',
          'tags': ['alicina', 'presion', 'defensas'],
        },
        'content': {
          'calories': 149.0,
          'proteins': 6.0,
          'fats': 0.5,
          'net_carbs': 30.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 8,
          'svg_node': null,
          'tip':
              'Contiene alicina; potente antibacteriano y modulador de la presión arterial.',
        },
        'quiz': {'impact': 'Inmunológico', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'pimenton_rojo',
          'name': 'Pimentón',
          'nameLowercase': 'pimentón',
          'category': 'Vegetales',
          'tags': ['vitamina_c', 'rojo', 'colageno'],
        },
        'content': {
          'calories': 31.0,
          'proteins': 1.0,
          'fats': 0.3,
          'net_carbs': 4.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip':
              'Concentración de Vitamina C superior a los cítricos; cofactor de colágeno.',
        },
        'quiz': {'impact': 'Antioxidante', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'calabacin_verde',
          'name': 'Calabacín (Zucchini)',
          'nameLowercase': 'calabacín (zucchini)',
          'category': 'Vegetales',
          'tags': ['bajo_carbo', 'ligero', 'cena'],
        },
        'content': {
          'calories': 17.0,
          'proteins': 1.2,
          'fats': 0.3,
          'net_carbs': 3.1,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip':
              'Bajísimo en carbohidratos; ideal para sustituir pastas en la cena.',
        },
        'quiz': {'impact': 'Digestivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'berenjena_fresca',
          'name': 'Berenjena',
          'nameLowercase': 'berenjena',
          'category': 'Vegetales',
          'tags': ['fibra', 'saciedad', 'morado'],
        },
        'content': {
          'calories': 25.0,
          'proteins': 1.0,
          'fats': 0.2,
          'net_carbs': 6.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 8,
          'svg_node': null,
          'tip':
              'Contiene antocianinas; favorece la saciedad por su contenido de fibra.',
        },
        'quiz': {'impact': 'Digestivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'coliflor_fresca',
          'name': 'Coliflor',
          'nameLowercase': 'coliflor',
          'category': 'Vegetales',
          'tags': ['keto', 'sustituto', 'crucifera'],
        },
        'content': {
          'calories': 25.0,
          'proteins': 2.0,
          'fats': 0.3,
          'net_carbs': 3.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 10,
          'svg_node': null,
          'tip': 'Sustituto metabólico ideal para el arroz y el puré de papa.',
        },
        'quiz': {'impact': 'Metabólico', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'repollo_blanco',
          'name': 'Repollo',
          'nameLowercase': 'repollo',
          'category': 'Vegetales',
          'tags': ['gastritis', 'microbiota', 'intestino'],
        },
        'content': {
          'calories': 25.0,
          'proteins': 1.3,
          'fats': 0.1,
          'net_carbs': 4.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip':
              'Fuente de Vitamina U y glutamina; excelente para reparar la mucosa gástrica.',
        },
        'quiz': {'impact': 'Digestivo', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'esparragos_verdes',
          'name': 'Espárragos',
          'nameLowercase': 'espárragos',
          'category': 'Vegetales',
          'tags': ['detox', 'diuretico', 'riñon'],
        },
        'content': {
          'calories': 20.0,
          'proteins': 2.2,
          'fats': 0.1,
          'net_carbs': 2.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip':
              'Diurético natural rico en asparagina; favorece la eliminación de toxinas.',
        },
        'quiz': {'impact': 'Diurético', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'champiñon_paris',
          'name': 'Champiñones',
          'nameLowercase': 'champiñones',
          'category': 'Vegetales',
          'tags': ['hongos', 'selenio', 'inmunidad'],
        },
        'content': {
          'calories': 22.0,
          'proteins': 3.1,
          'fats': 0.3,
          'net_carbs': 2.3,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 9,
          'svg_node': null,
          'tip':
              'Aportan selenio y betaglucanos para fortalecer la respuesta inmune.',
        },
        'quiz': {'impact': 'Inmunológico', 'level': 'Excelente'},
      },
    ];
  }

  /// Seed 15 Complete Carbs using WriteBatch for atomicity
  static Future<void> seedCarbsComplete() async {
    print(
      '[CARBS SEEDER] Beginning atomic WriteBatch injection of 15 Carbohidratos 🍞...',
    );

    try {
      final carbsList = _getCarbsCompleteList();
      final batch = FirebaseFirestore.instance.batch();

      int successCount = 0;

      for (final carbDoc in carbsList) {
        try {
          final id = carbDoc['metadata']['id'] as String;
          final name = carbDoc['metadata']['name'] as String;

          final docRef = FirebaseFirestore.instance
              .collection('master_food_db')
              .doc(id);

          final docSnapshot = await docRef.get();

          if (!docSnapshot.exists) {
            batch.set(docRef, carbDoc);
            successCount++;
            print('✅ [CARBS] Queued "$name" for atomic write');
          } else {
            print('⚠️ [CARBS] "$name" already exists. Skipping.');
          }
        } catch (e) {
          print('❌ [CARBS] Error preparing for batch: $e');
          debugPrint('[CARBS] $e');
        }
      }

      if (successCount > 0) {
        await batch.commit();
        print(
          '[CARBS] ✅ WriteBatch committed! $successCount Carbohidratos injected atomically.',
        );
      } else {
        print(
          '[CARBS] ℹ️ No new Carbohidratos to inject (all exist or were skipped).',
        );
      }
    } catch (e) {
      print('[CARBS] ❌ Error in seedCarbsComplete: $e');
      debugPrint('[CARBS] $e');
    }
  }

  /// Get 15 Complete Carbs with strict 4-Node structure
  static List<Map<String, dynamic>> _getCarbsCompleteList() {
    return [
      {
        'metadata': {
          'id': 'arroz_blanco_cocido',
          'name': 'Arroz Blanco',
          'nameLowercase': 'arroz blanco',
          'category': 'Carbohidratos',
          'tags': ['almidon', 'energia_rapida', 'blanco'],
        },
        'content': {
          'calories': 130.0,
          'proteins': 2.7,
          'fats': 0.3,
          'net_carbs': 28.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 3,
          'svg_node': null,
          'tip':
              'Alto índice glucémico; priorizar solo post-entrenamiento intenso.',
        },
        'quiz': {'impact': 'Glucosa', 'level': 'Evitar'},
      },
      {
        'metadata': {
          'id': 'arroz_integral_fibra',
          'name': 'Arroz Integral',
          'nameLowercase': 'arroz integral',
          'category': 'Carbohidratos',
          'tags': ['fibra', 'grano_entero', 'saciedad'],
        },
        'content': {
          'calories': 111.0,
          'proteins': 2.6,
          'fats': 0.9,
          'net_carbs': 23.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 6,
          'svg_node': null,
          'tip':
              'Mantiene la cáscara y el salvado; absorción más lenta que el blanco.',
        },
        'quiz': {'impact': 'Energía', 'level': 'Moderado'},
      },
      {
        'metadata': {
          'id': 'pan_blanco_procesado',
          'name': 'Pan Blanco',
          'nameLowercase': 'pan blanco',
          'category': 'Carbohidratos',
          'tags': ['procesado', 'trigo', 'inflamatorio'],
        },
        'content': {
          'calories': 265.0,
          'proteins': 9.0,
          'fats': 3.2,
          'net_carbs': 49.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 2,
          'svg_node': null,
          'tip': 'Harina refinada; genera picos de insulina y hambre reactiva.',
        },
        'quiz': {'impact': 'Glucosa', 'level': 'Evitar'},
      },
      {
        'metadata': {
          'id': 'pan_integral_real',
          'name': 'Pan Integral',
          'nameLowercase': 'pan integral',
          'category': 'Carbohidratos',
          'tags': ['fibra', 'trigo_entero', 'desayuno'],
        },
        'content': {
          'calories': 247.0,
          'proteins': 13.0,
          'fats': 3.4,
          'net_carbs': 41.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 5,
          'svg_node': null,
          'tip':
              'Aporta vitaminas del grupo B; verificar que no contenga azúcar añadida.',
        },
        'quiz': {'impact': 'Energía', 'level': 'Moderado'},
      },
      {
        'metadata': {
          'id': 'avena_en_hojuelas',
          'name': 'Avena',
          'nameLowercase': 'avena',
          'category': 'Carbohidratos',
          'tags': ['beta-glucanos', 'saciedad', 'avena'],
        },
        'content': {
          'calories': 389.0,
          'proteins': 16.9,
          'fats': 6.9,
          'net_carbs': 56.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 6,
          'svg_node': null,
          'tip':
              'Rica en beta-glucanos; ayuda a modular el colesterol y la glucosa.',
        },
        'quiz': {'impact': 'Energía', 'level': 'Moderado'},
      },
      {
        'metadata': {
          'id': 'quinoa_cocida',
          'name': 'Quinoa',
          'nameLowercase': 'quinoa',
          'category': 'Carbohidratos',
          'tags': ['superfood', 'proteina_veg', 'completo'],
        },
        'content': {
          'calories': 120.0,
          'proteins': 4.4,
          'fats': 1.9,
          'net_carbs': 18.5,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 7,
          'svg_node': null,
          'tip': 'Pseudo-cereal con perfil completo de aminoácidos esenciales.',
        },
        'quiz': {'impact': 'Energía', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'papa_pastusa_cocida',
          'name': 'Papa',
          'nameLowercase': 'papa',
          'category': 'Carbohidratos',
          'tags': ['tubérculo', 'local', 'almidón'],
        },
        'content': {
          'calories': 77.0,
          'proteins': 2.0,
          'fats': 0.1,
          'net_carbs': 15.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 4,
          'svg_node': null,
          'tip':
              'Alta densidad calórica; consumir fría para crear almidón resistente.',
        },
        'quiz': {'impact': 'Glucosa', 'level': 'Moderado'},
      },
      {
        'metadata': {
          'id': 'batata_camote_asado',
          'name': 'Batata (Camote)',
          'nameLowercase': 'batata (camote)',
          'category': 'Carbohidratos',
          'tags': ['vitamina_a', 'complejo', 'dulce'],
        },
        'content': {
          'calories': 86.0,
          'proteins': 1.6,
          'fats': 0.1,
          'net_carbs': 17.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 7,
          'svg_node': null,
          'tip':
              'Carbohidrato complejo rico en vitamina A; menor impacto que la papa.',
        },
        'quiz': {'impact': 'Energía', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'yuca_cocida_local',
          'name': 'Yuca',
          'nameLowercase': 'yuca',
          'category': 'Carbohidratos',
          'tags': ['energia_densa', 'local', 'tubérculo'],
        },
        'content': {
          'calories': 160.0,
          'proteins': 1.4,
          'fats': 0.3,
          'net_carbs': 35.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 3,
          'svg_node': null,
          'tip':
              'Energía muy densa; evitar en fases de pérdida de grasa estricta.',
        },
        'quiz': {'impact': 'Glucosa', 'level': 'Evitar'},
      },
      {
        'metadata': {
          'id': 'platano_maduro_asado',
          'name': 'Plátano',
          'nameLowercase': 'plátano',
          'category': 'Carbohidratos',
          'tags': ['potasio', 'deporte', 'fruta'],
        },
        'content': {
          'calories': 89.0,
          'proteins': 1.1,
          'fats': 0.3,
          'net_carbs': 20.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 5,
          'svg_node': null,
          'tip':
              'Excelente fuente de potasio; ideal para reponer glucógeno post-pesos.',
        },
        'quiz': {'impact': 'Energía', 'level': 'Moderado'},
      },
      {
        'metadata': {
          'id': 'manzana_roja_verde',
          'name': 'Manzana',
          'nameLowercase': 'manzana',
          'category': 'Carbohidratos',
          'tags': ['pectina', 'fibra', 'fruta'],
        },
        'content': {
          'calories': 52.0,
          'proteins': 0.3,
          'fats': 0.2,
          'net_carbs': 11.4,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 8,
          'svg_node': null,
          'tip':
              'Contiene pectina (fibra soluble) que ralentiza la absorción de fructosa.',
        },
        'quiz': {'impact': 'Energía', 'level': 'Excelente'},
      },
      {
        'metadata': {
          'id': 'banano_maduro',
          'name': 'Banano',
          'nameLowercase': 'banano',
          'category': 'Carbohidratos',
          'tags': ['potasio', 'rapido', 'azucar'],
        },
        'content': {
          'calories': 89.0,
          'proteins': 1.1,
          'fats': 0.3,
          'net_carbs': 20.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 5,
          'svg_node': null,
          'tip':
              'Alto contenido de azúcares simples; preferir banano menos maduro.',
        },
        'quiz': {'impact': 'Glucosa', 'level': 'Moderado'},
      },
      {
        'metadata': {
          'id': 'azucar_blanca_refinada',
          'name': 'Azúcar',
          'nameLowercase': 'azúcar',
          'category': 'Carbohidratos',
          'tags': ['veneno', 'insulina', 'inflamacion'],
        },
        'content': {
          'calories': 387.0,
          'proteins': 0.0,
          'fats': 0.0,
          'net_carbs': 100.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 1,
          'svg_node': null,
          'tip':
              'Calorías vacías; principal causante de resistencia a la insulina.',
        },
        'quiz': {'impact': 'Glucosa', 'level': 'Evitar'},
      },
      {
        'metadata': {
          'id': 'miel_abeja_natural',
          'name': 'Miel',
          'nameLowercase': 'miel',
          'category': 'Carbohidratos',
          'tags': ['natural', 'dulce', 'enzimas'],
        },
        'content': {
          'calories': 304.0,
          'proteins': 0.3,
          'fats': 0.0,
          'net_carbs': 82.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 3,
          'svg_node': null,
          'tip':
              'Contiene enzimas naturales, pero eleva la glucosa rápidamente.',
        },
        'quiz': {'impact': 'Glucosa', 'level': 'Moderado'},
      },
      {
        'metadata': {
          'id': 'refresco_soda_azucarada',
          'name': 'Refresco',
          'nameLowercase': 'refresco',
          'category': 'Carbohidratos',
          'tags': ['soda', 'quimico', 'fructosa'],
        },
        'content': {
          'calories': 41.0,
          'proteins': 0.0,
          'fats': 0.0,
          'net_carbs': 10.0,
          'serving': '100g',
        },
        'app_integration': {
          'imr_score': 1,
          'svg_node': null,
          'tip': 'Fructosa líquida; impacto directo en el hígado graso.',
        },
        'quiz': {'impact': 'Glucosa', 'level': 'Evitar'},
      },
    ];
  }
}
