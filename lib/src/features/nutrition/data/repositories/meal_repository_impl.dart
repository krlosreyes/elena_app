import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/meal_log.dart';
import '../../domain/repositories/meal_repository.dart';

class MealRepositoryImpl implements MealRepository {
  final FirebaseFirestore _firestore;

  MealRepositoryImpl(this._firestore);

  @override
  Future<void> saveMeal(MealLog meal) async {
    await _firestore
        .collection('users')
        .doc(meal.userId)
        .collection('meals')
        .doc(meal.id)
        .set(meal.toJson());
  }

  @override
  Future<List<MealLog>> getRecentMeals(String userId, {int limit = 5}) async {
    final snapshot = await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .get();

    return snapshot.docs.map((doc) => MealLog.fromJson(doc.data())).toList();
  }

  @override
  Stream<List<MealLog>> watchRecentMeals(String userId, {int limit = 5}) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => MealLog.fromJson(doc.data())).toList());
  }

  @override
  Future<void> deleteMeal(String userId, String mealId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('meals')
        .doc(mealId)
        .delete();
  }
}

final mealRepositoryProvider = Provider<MealRepository>((ref) {
  return MealRepositoryImpl(FirebaseFirestore.instance);
});
