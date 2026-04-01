import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/daily_log.dart';
import '../../profile/data/user_repository.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/domain/logic/elena_brain.dart';

class HealthRepository {
  final FirebaseFirestore _firestore;
  final Ref _ref;

  HealthRepository(this._firestore, this._ref);

  CollectionReference<Map<String, dynamic>> _dailyLogsCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('daily_logs');

  String _getTodayId() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Log hydration (Water)
  Future<void> logHydration(String uid, int glasses) async {
    final todayId = _getTodayId();
    final docRef = _dailyLogsCollection(uid).doc(todayId);
    final userRef = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final currentData = snapshot.exists
          ? DailyLog.fromJson(snapshot.data()!)
          : DailyLog(id: todayId);

      final updatedLog = currentData.copyWith(
        waterGlasses: currentData.waterGlasses + glasses,
      );

      transaction.set(docRef, updatedLog.toJson());

      // ✅ FIX: Usar el objeto transaction para el segundo write
      transaction.update(userRef, {
        'dailyHydration': FieldValue.increment(glasses),
        'lastLogUpdate': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// Log Nutrition (Food)
  Future<void> logNutrition(String uid, Map<String, dynamic> entry) async {
    final todayId = _getTodayId();
    final docRef = _dailyLogsCollection(uid).doc(todayId);

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. All READS first
        final logSnapshot = await transaction.get(docRef);
        final userSnapshot =
            await transaction.get(_firestore.collection('users').doc(uid));

        // 2. Data Preparation with enhanced robustness
        DailyLog currentData;
        try {
          if (logSnapshot.exists && logSnapshot.data() != null) {
            currentData = DailyLog.fromJson(logSnapshot.data()!);
          } else {
            currentData = DailyLog(id: todayId);
          }
        } catch (e) {
          debugPrint("⚠️ Erro al deserializar DailyLog: $e. Usando nuevo.");
          currentData = DailyLog(id: todayId);
        }

        final meals = List<Map<String, dynamic>>.from(currentData.mealEntries);
        meals.add(entry);

        // Safe numeric addition
        int safeInt(dynamic val) => (val as num?)?.toInt() ?? 0;

        var updatedLog = currentData.copyWith(
          mealEntries: meals,
          calories: currentData.calories + safeInt(entry['calories']),
          proteinGrams: currentData.proteinGrams + safeInt(entry['protein']),
          carbsGrams: currentData.carbsGrams + safeInt(entry['carbs']),
          fatGrams: currentData.fatGrams + safeInt(entry['fats']),
        );

        // 3. Calculate and update IED if user data is available
        if (userSnapshot.exists && userSnapshot.data() != null) {
          try {
            final user = UserModel.fromJson(userSnapshot.data()!);
            final mti = _calculateMtiPure(user, updatedLog);
            if (!mti.isNaN && !mti.isInfinite) {
              updatedLog = updatedLog.copyWith(mtiScore: mti);
            }
          } catch (e) {
            debugPrint("⚠️ Error calculando IED en transacción: $e");
          }
        }

        // 4. All WRITES last
        transaction.set(docRef, updatedLog.toJson());
      });
    } catch (e, stack) {
      debugPrint("❌ Error Crítico en logNutrition (Transacción): $e");
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Clear all meals for today (Pure Telemetry)
  Future<void> clearTodayMeals(String uid) async {
    final todayId = _getTodayId();
    final docRef = _dailyLogsCollection(uid).doc(todayId);

    try {
      await _firestore.runTransaction((transaction) async {
        final logSnapshot = await transaction.get(docRef);
        final userSnapshot =
            await transaction.get(_firestore.collection('users').doc(uid));

        if (!logSnapshot.exists) return;

        final currentData = DailyLog.fromJson(logSnapshot.data()!);
        var updatedLog = currentData.copyWith(
          mealEntries: [],
          calories: 0,
          proteinGrams: 0,
          carbsGrams: 0,
          fatGrams: 0,
        );

        if (userSnapshot.exists && userSnapshot.data() != null) {
          final user = UserModel.fromJson(userSnapshot.data()!);
          final mti = _calculateMtiPure(user, updatedLog);
          updatedLog = updatedLog.copyWith(mtiScore: mti);
        }

        transaction.set(docRef, updatedLog.toJson());
      });
    } catch (e) {
      debugPrint("❌ Error clearing today's meals: $e");
      rethrow;
    }
  }

  double _calculateMtiPure(UserModel user, DailyLog log) {
    double fastingHours = 12.0;
    if (log.fastingStartTime != null && log.fastingEndTime != null) {
      fastingHours =
          log.fastingEndTime!.difference(log.fastingStartTime!).inMinutes /
              60.0;
    }

    final hydrationGoal = (user.currentWeightKg / 7).round();
    final hydrationScore =
        (log.waterGlasses / hydrationGoal.clamp(1, 100)) * 100;

    return ElenaBrain.calculateTotalMTI(
      user,
      realTimeFastingHours: fastingHours,
      realTimeNutritionScore: 80.0,
      realTimeExerciseScore: (log.exerciseMinutes / 30.0 * 100).clamp(0, 100),
      realTimeSleepHours: (log.sleepMinutes / 60.0),
      realTimeHydrationScore: hydrationScore,
    );
  }

  Future<void> logFasting(String uid, {DateTime? start, DateTime? end}) async {
    final todayId = _getTodayId();

    final Map<String, dynamic> userUpdates = {};
    final Map<String, dynamic> logUpdates = {};

    if (start != null) {
      userUpdates['currentFastingStartTime'] = Timestamp.fromDate(start);
      logUpdates['fastingStartTime'] = Timestamp.fromDate(start);
    }
    if (end != null) {
      userUpdates['currentFastingEndTime'] = Timestamp.fromDate(end);
      logUpdates['fastingEndTime'] = Timestamp.fromDate(end);
    }

    await _dailyLogsCollection(uid)
        .doc(todayId)
        .set(logUpdates, SetOptions(merge: true));
    await _ref.read(userRepositoryProvider).updateUser(uid, userUpdates);
  }

  /// Log Exercise
  Future<void> logExercise(String uid, Map<String, dynamic> entry) async {
    final todayId = _getTodayId();
    final docRef = _dailyLogsCollection(uid).doc(todayId);

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. All READS first
        final logSnapshot = await transaction.get(docRef);
        final userSnapshot =
            await transaction.get(_firestore.collection('users').doc(uid));

        // 2. Data Preparation
        DailyLog currentData;
        try {
          if (logSnapshot.exists && logSnapshot.data() != null) {
            currentData = DailyLog.fromJson(logSnapshot.data()!);
          } else {
            currentData = DailyLog(id: todayId);
          }
        } catch (e) {
          debugPrint("⚠️ Erro al deserializar DailyLog en exercise: $e. Usando nuevo.");
          currentData = DailyLog(id: todayId);
        }

        final exercises =
            List<Map<String, dynamic>>.from(currentData.exerciseEntries);
        exercises.add(entry);

        int safeInt(dynamic val) => (val as num?)?.toInt() ?? 0;

        var updatedLog = currentData.copyWith(
          exerciseEntries: exercises,
          exerciseMinutes:
              currentData.exerciseMinutes + safeInt(entry['minutes']),
        );

        // 3. Calculate and update IED if user data is available
        if (userSnapshot.exists && userSnapshot.data() != null) {
          try {
            final user = UserModel.fromJson(userSnapshot.data()!);
            final mti = _calculateMtiPure(user, updatedLog);
            if (!mti.isNaN && !mti.isInfinite) {
              updatedLog = updatedLog.copyWith(mtiScore: mti);
            }
          } catch (e) {
            debugPrint("⚠️ Error calculando IED en transacción (ejercicio): $e");
          }
        }

        // 4. All WRITES last
        transaction.set(docRef, updatedLog.toJson());
      });
    } catch (e, stack) {
      debugPrint("❌ Error Crítico en logExercise (Transacción): $e");
      debugPrint(stack.toString());
      rethrow;
    }
  }

  Stream<DailyLog?> watchTodayLog(String uid) {
    final todayId = _getTodayId();
    return _dailyLogsCollection(uid).doc(todayId).snapshots().map((snapshot) {
      if (snapshot.exists && snapshot.data() != null) {
        return DailyLog.fromJson(snapshot.data()!);
      }
      return DailyLog(id: todayId);
    });
  }

  Stream<List<DailyLog>> watchLogsHistory(String uid, int days) {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days));
    final startDateId = DateFormat('yyyy-MM-dd').format(startDate);

    return _dailyLogsCollection(uid)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startDateId)
        .snapshots()
        .map((snapshot) {
      final logs =
          snapshot.docs.map((doc) => DailyLog.fromJson(doc.data())).toList();
      logs.sort((a, b) => a.id.compareTo(b.id));
      return logs;
    });
  }
}

final weeklyLogsProvider =
    StreamProvider.autoDispose.family<List<DailyLog>, String>((ref, uid) {
  return ref.watch(healthRepositoryProvider).watchLogsHistory(uid, 7);
});

final logsHistoryProvider = StreamProvider.autoDispose
    .family<List<DailyLog>, ({String uid, int days})>((ref, arg) {
  return ref
      .watch(healthRepositoryProvider)
      .watchLogsHistory(arg.uid, arg.days);
});

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(FirebaseFirestore.instance, ref);
});

final todayLogProvider =
    StreamProvider.autoDispose.family<DailyLog?, String>((ref, uid) {
  return ref.watch(healthRepositoryProvider).watchTodayLog(uid);
});
