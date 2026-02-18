import 'package:cloud_firestore/cloud_firestore.dart';
import '../../domain/entities/nutrition_plan.dart';
import '../../domain/repositories/nutrition_repository.dart';

class NutritionRepositoryImpl implements NutritionRepository {
  final FirebaseFirestore _firestore;

  NutritionRepositoryImpl(this._firestore);

  @override
  Future<void> saveNutritionPlan(NutritionPlan plan) async {
    await _firestore
        .collection('users')
        .doc(plan.userId)
        .collection('nutrition')
        .doc('current') // Singleton document for current plan
        .set(plan.toJson());
  }

  @override
  Future<NutritionPlan?> getCurrentPlan(String userId) async {
    final doc = await _firestore
        .collection('users')
        .doc(userId)
        .collection('nutrition')
        .doc('current')
        .get();

    if (!doc.exists || doc.data() == null) return null;

    try {
      return NutritionPlan.fromJson(doc.data()!);
    } catch (e) {
      // Log error in a real app
      print('Error parsing NutritionPlan: $e');
      return null;
    }
  }

  @override
  Stream<NutritionPlan?> watchCurrentPlan(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('nutrition')
        .doc('current')
        .snapshots()
        .map((doc) {
          if (!doc.exists || doc.data() == null) return null;
          try {
            return NutritionPlan.fromJson(doc.data()!);
          } catch (e) {
             print('Error parsing NutritionPlan stream: $e');
             return null;
          }
        });
  }
}
