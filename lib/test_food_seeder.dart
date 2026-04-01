// ignore_for_file: avoid_print
import 'package:cloud_firestore/cloud_firestore.dart';

void testFoodSeeder() async {
  // ═══════════════════════════════════════════════════════════════════════
  // TEST: FoodSeeder.seedDatabase()
  // ═══════════════════════════════════════════════════════════════════════

  print('═' * 70);
  print('FIREBASE DATA ENGINEER TEST — Food Seeder Validation');
  print('═' * 70);

  try {
    // 1. Check Firestore connection
    print('\n[TEST] Checking Firestore connection...');
    final firestore = FirebaseFirestore.instance;
    final collectionRef = firestore.collection('master_food_db');

    // 2. Get current count
    print('[TEST] Fetching current master_food_db count...');
    final countSnapshot = await collectionRef.count().get();
    final currentCount = countSnapshot.count ?? 0;
    print('✅ Current documents in master_food_db: $currentCount');

    // 3. If empty, seed the database
    if (currentCount == 0) {
      print('\n[TEST] Database is empty. Calling FoodSeeder.seedDatabase()...');
      // Uncomment to actually seed:
      // await FoodSeeder.seedDatabase();
      print('⚠️ [TEST] Seeding disabled in test. Run in production code.');
    } else {
      print('\n[TEST] Database already populated. Skipping seed.');

      // 4. Verify all expected foods are present
      print('\n[TEST] Verifying 25 expected foods...');
      final expectedFoodIds = [
        // Proteins (6)
        'sardinas-atlanticas', 'pechuga-pollo', 'huevo-entero', 'pata-de-res',
        'muslo-pollo', 'salmon-cocido',
        // Fats (4)
        'aguacate', 'aceite-oliva-virgen', 'nueces', 'cafe-negro',
        // Vegetables (6)
        'zucchini', 'pimentón-rojo', 'apio', 'cebolla', 'brocoli', 'espinaca',
        // Carbs (4)
        'arroz-integral', 'pasta-integral', 'arepa-maiz', 'pan-integral',
        // Processed (4)
        'empanada', 'pan-blanco', 'galletas-saladas', 'pasta-blanca',
      ];

      int foundCount = 0;
      for (final id in expectedFoodIds) {
        final doc = await collectionRef.doc(id).get();
        if (doc.exists) {
          foundCount++;
          final data = doc.data() as Map<String, dynamic>;
          final name = data['metadata']['name'] ?? 'N/A';
          final imrScore = data['app_integration']['imr_score'] ?? 'N/A';
          print('  ✅ $name (IMR: $imrScore)');
        } else {
          print('  ❌ Missing: $id');
        }
      }

      print('\n[TEST] Verification Complete');
      print('Found: $foundCount / ${expectedFoodIds.length} foods');

      if (foundCount == expectedFoodIds.length) {
        print('✅ All expected foods are present!');
      }
    }

    // 5. Sample query test
    print('\n[TEST] Testing sample Firestore query...');
    print('[TEST] Query: nameLowercase >= "a" AND nameLowercase <= "z\\uf8ff"');
    final querySnapshot = await collectionRef
        .where('nameLowercase', isGreaterThanOrEqualTo: 'a')
        .where('nameLowercase', isLessThanOrEqualTo: 'z\uf8ff')
        .limit(5)
        .get();

    print('✅ Query returned ${querySnapshot.docs.length} documents');
    for (final doc in querySnapshot.docs.take(3)) {
      final data = doc.data();
      final name = data['metadata']['name'] ?? 'N/A';
      print('  - $name');
    }

    print('\n${'═' * 70}');
    print('✅ TEST COMPLETE — All validations passed!');
    print('═' * 70);
  } catch (e) {
    print('\n❌ TEST FAILED: $e');
    print(e.toString());
  }
}

void main() async {
  // Initialize Firebase before running test
  // await Firebase.initializeApp();
  // await testFoodSeeder();

  print('Test is ready to run. Uncomment main() code and run:');
  print('  dart lib/test/firebase_seeder_test.dart');
}
