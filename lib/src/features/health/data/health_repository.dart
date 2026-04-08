import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/domain/logic/elena_brain.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/analytics_service.dart';
import '../domain/daily_log.dart';

class HealthRepository {
  final FirebaseFirestore _firestore;

  HealthRepository(this._firestore);

  CollectionReference<Map<String, dynamic>> _dailyLogsCollection(String uid) =>
      _firestore.collection('users').doc(uid).collection('daily_logs');

  String _getTodayId() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  /// Log hydration (Water)
  Future<void> logHydration(String uid, int glasses) async {
    final todayId = _getTodayId();
    final docRef = _dailyLogsCollection(uid).doc(todayId);

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. All READS first
        final logSnapshot = await transaction.get(docRef);
        final userSnapshot = await transaction.get(
          _firestore.collection('users').doc(uid),
        );

        // 2. Data Preparation
        DailyLog currentData;
        try {
          if (logSnapshot.exists && logSnapshot.data() != null) {
            currentData = DailyLog.fromJson(logSnapshot.data()!);
          } else {
            currentData = DailyLog(id: todayId);
          }
        } catch (e) {
          debugPrint(
            "⚠️ Error al deserializar DailyLog en hydration: $e. Usando nuevo.",
          );
          currentData = DailyLog(id: todayId);
        }

        var updatedLog = currentData.copyWith(
          waterGlasses: currentData.waterGlasses + glasses,
        );

        // 3. Calculate and update IMR if user data is available
        if (userSnapshot.exists && userSnapshot.data() != null) {
          try {
            final user = UserModel.fromJson(userSnapshot.data()!);
            final imr = _calculateImrPure(user, updatedLog);
            if (!imr.isNaN && !imr.isInfinite) {
              updatedLog = updatedLog.copyWith(imrScore: imr);
            }
          } catch (e) {
            debugPrint(
              "⚠️ Error calculando IMR en transacción (hidratación): $e",
            );
          }
        }

        // 4. All WRITES last
        transaction.set(docRef, updatedLog.toJson());
      });
    } catch (e, stack) {
      debugPrint("❌ Error Crítico en logHydration (Transacción): $e");
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Log Nutrition (Food)
  Future<void> logNutrition(String uid, Map<String, dynamic> entry) async {
    final todayId = _getTodayId();
    final docRef = _dailyLogsCollection(uid).doc(todayId);

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. All READS first
        final logSnapshot = await transaction.get(docRef);
        final userSnapshot = await transaction.get(
          _firestore.collection('users').doc(uid),
        );

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

        // 3. Calculate and update IMR if user data is available
        if (userSnapshot.exists && userSnapshot.data() != null) {
          try {
            final user = UserModel.fromJson(userSnapshot.data()!);
            final imr = _calculateImrPure(user, updatedLog);
            if (!imr.isNaN && !imr.isInfinite) {
              updatedLog = updatedLog.copyWith(imrScore: imr);
            }
          } catch (e) {
            debugPrint("⚠️ Error calculando IMR en transacción: $e");
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
        final userSnapshot = await transaction.get(
          _firestore.collection('users').doc(uid),
        );

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
          final imr = _calculateImrPure(user, updatedLog);
          updatedLog = updatedLog.copyWith(imrScore: imr);
        }

        transaction.set(docRef, updatedLog.toJson());
      });
    } catch (e) {
      debugPrint("❌ Error clearing today's meals: $e");
      rethrow;
    }
  }

  double _calculateImrPure(UserModel user, DailyLog log) {
    // Fasting hours: real if available, else estimate from user profile
    double fastingHours = 12.0;
    if (log.fastingStartTime != null && log.fastingEndTime != null) {
      fastingHours =
          log.fastingEndTime!.difference(log.fastingStartTime!).inMinutes /
          60.0;
    } else if (log.fastingStartTime != null) {
      // Fasting is still in progress — calculate elapsed
      fastingHours =
          DateTime.now().difference(log.fastingStartTime!).inMinutes / 60.0;
    }

    // Hydration score: glasses logged vs goal (weight_kg / 7)
    final hydrationGoal = (user.currentWeightKg / 7).round().clamp(1, 20);
    final hydrationScore = ((log.waterGlasses / hydrationGoal) * 100).clamp(
      0.0,
      100.0,
    );

    // Nutrition score: based on calories logged vs BMR target
    // If no meals logged yet → 0. If calories in range [80%–120%] of target → 100.
    double nutritionScore = 0.0;
    if (log.mealEntries.isNotEmpty && log.calories > 0) {
      final targetCalories = ElenaBrain.calculateBMR(
        user,
      ).clamp(1200.0, 4000.0);
      final ratio = log.calories / targetCalories;
      // Score peaks at 100% of target, decays toward 0 at 0% or 150%+
      nutritionScore = (100.0 * (1.0 - (ratio - 1.0).abs().clamp(0.0, 1.0)))
          .clamp(0.0, 100.0);
    }

    final exerciseGoal = ElenaBrain.getDailyExerciseGoalMinutes(user);
    final score = ElenaBrain.calculateTotalIMR(
      user,
      realTimeFastingHours: fastingHours,
      realTimeNutritionScore: nutritionScore,
      realTimeExerciseScore: (log.exerciseMinutes / exerciseGoal * 100).clamp(
        0.0,
        100.0,
      ),
      realTimeSleepHours: (log.sleepMinutes / 60.0),
      realTimeHydrationScore: hydrationScore,
    );

    AnalyticsService.logImrCalculated(score);

    return score;
  }

  Future<void> logFasting(String uid, {DateTime? start, DateTime? end}) async {
    final todayId = _getTodayId();
    final docRef = _dailyLogsCollection(uid).doc(todayId);

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. All READS first
        final logSnapshot = await transaction.get(docRef);
        final userSnapshot = await transaction.get(
          _firestore.collection('users').doc(uid),
        );

        // 2. Data Preparation
        DailyLog currentData;
        try {
          if (logSnapshot.exists && logSnapshot.data() != null) {
            currentData = DailyLog.fromJson(logSnapshot.data()!);
          } else {
            currentData = DailyLog(id: todayId);
          }
        } catch (e) {
          debugPrint(
            "⚠️ Error al deserializar DailyLog en fasting: $e. Usando nuevo.",
          );
          currentData = DailyLog(id: todayId);
        }

        var updatedLog = currentData.copyWith(
          fastingStartTime: start ?? currentData.fastingStartTime,
          fastingEndTime: end ?? currentData.fastingEndTime,
        );

        // 3. Calculate IMR
        if (userSnapshot.exists && userSnapshot.data() != null) {
          try {
            final user = UserModel.fromJson(userSnapshot.data()!);
            final imr = _calculateImrPure(user, updatedLog);
            if (!imr.isNaN && !imr.isInfinite) {
              updatedLog = updatedLog.copyWith(imrScore: imr);
            }
          } catch (e) {
            debugPrint("⚠️ Error calculando IMR en transacción (fasting): $e");
          }
        }

        // 4. All WRITES last
        transaction.set(docRef, updatedLog.toJson());

        // Update user fasting timestamps (keep sync with UserModel)
        final Map<String, dynamic> userUpdates = {
          'lastLogUpdate': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        };
        if (start != null) {
          userUpdates['currentFastingStartTime'] = Timestamp.fromDate(start);
        }
        if (end != null) {
          userUpdates['currentFastingEndTime'] = Timestamp.fromDate(end);
        }
        transaction.update(userSnapshot.reference, userUpdates);
      });
    } catch (e, stack) {
      debugPrint("❌ Error Crítico en logFasting (Transacción): $e");
      debugPrint(stack.toString());
      rethrow;
    }
  }

  /// Log Exercise
  Future<void> logExercise(String uid, Map<String, dynamic> entry) async {
    final todayId = _getTodayId();
    final docRef = _dailyLogsCollection(uid).doc(todayId);

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. All READS first
        final logSnapshot = await transaction.get(docRef);
        final userSnapshot = await transaction.get(
          _firestore.collection('users').doc(uid),
        );

        // 2. Data Preparation
        DailyLog currentData;
        try {
          if (logSnapshot.exists && logSnapshot.data() != null) {
            currentData = DailyLog.fromJson(logSnapshot.data()!);
          } else {
            currentData = DailyLog(id: todayId);
          }
        } catch (e) {
          debugPrint(
            "⚠️ Erro al deserializar DailyLog en exercise: $e. Usando nuevo.",
          );
          currentData = DailyLog(id: todayId);
        }

        final exercises = List<Map<String, dynamic>>.from(
          currentData.exerciseEntries,
        );
        exercises.add(entry);

        int safeInt(dynamic val) => (val as num?)?.toInt() ?? 0;

        var updatedLog = currentData.copyWith(
          exerciseEntries: exercises,
          exerciseMinutes:
              currentData.exerciseMinutes + safeInt(entry['minutes']),
        );

        // 3. Calculate and update IMR if user data is available
        if (userSnapshot.exists && userSnapshot.data() != null) {
          try {
            final user = UserModel.fromJson(userSnapshot.data()!);
            final imr = _calculateImrPure(user, updatedLog);
            if (!imr.isNaN && !imr.isInfinite) {
              updatedLog = updatedLog.copyWith(imrScore: imr);
            }
          } catch (e) {
            debugPrint(
              "⚠️ Error calculando IMR en transacción (ejercicio): $e",
            );
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

  /// Updates sleepMinutes in today's DailyLog and recalculates IMR.
  Future<void> logSleepToDailyLog(String uid, double sleepHours) async {
    final todayId = _getTodayId();
    final docRef = _dailyLogsCollection(uid).doc(todayId);

    try {
      await _firestore.runTransaction((transaction) async {
        // 1. All READS first
        final logSnapshot = await transaction.get(docRef);
        final userSnapshot = await transaction.get(
          _firestore.collection('users').doc(uid),
        );

        // 2. Data Preparation
        DailyLog currentData;
        try {
          if (logSnapshot.exists && logSnapshot.data() != null) {
            currentData = DailyLog.fromJson(logSnapshot.data()!);
          } else {
            currentData = DailyLog(id: todayId);
          }
        } catch (e) {
          debugPrint("⚠️ Error deserializando DailyLog en sleep: $e");
          currentData = DailyLog(id: todayId);
        }

        var updatedLog = currentData.copyWith(
          sleepMinutes: (sleepHours * 60).round(),
        );

        // 3. Calculate IMR
        if (userSnapshot.exists && userSnapshot.data() != null) {
          try {
            final user = UserModel.fromJson(userSnapshot.data()!);
            final imr = _calculateImrPure(user, updatedLog);
            if (!imr.isNaN && !imr.isInfinite) {
              updatedLog = updatedLog.copyWith(imrScore: imr);
            }
          } catch (e) {
            debugPrint("⚠️ Error calculando IMR en sleep: $e");
          }
        }

        // 4. All WRITES last
        transaction.set(docRef, updatedLog.toJson());
      });
    } catch (e, stack) {
      debugPrint("❌ Error en logSleepToDailyLog: $e");
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
          final logs = snapshot.docs
              .map((doc) => DailyLog.fromJson(doc.data()))
              .toList();
          logs.sort((a, b) => a.id.compareTo(b.id));
          return logs;
        });
  }

  /// Retorna los DailyLog de los últimos [days] días ordenados por fecha ascendente.
  /// One-shot Future (no Stream) — ideal para cálculos de progreso.
  Future<List<DailyLog>> fetchRecentLogs(String uid, {int days = 30}) async {
    final startDateId = DateFormat(
      'yyyy-MM-dd',
    ).format(DateTime.now().subtract(Duration(days: days)));

    final snap = await _dailyLogsCollection(uid)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: startDateId)
        .orderBy(FieldPath.documentId)
        .get();

    return snap.docs
        .map((d) => DailyLog.fromJson({...d.data(), 'id': d.id}))
        .toList();
  }

  /// Recalcula y persiste el imrScore del DailyLog de hoy usando los valores
  /// ya almacenados en el log y el UserModel actualizado.
  /// Se llama después de actualizar medidas biométricas en el perfil.
  Future<void> recalculateImrForToday(String uid) async {
    final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dailyLogRef = _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(todayId);
    final userRef = _firestore.collection('users').doc(uid);

    await _firestore.runTransaction((transaction) async {
      final logSnap = await transaction.get(dailyLogRef);
      final userSnap = await transaction.get(userRef);

      if (!userSnap.exists) return;

      final user = UserModel.fromJson(userSnap.data()!);

      // Si no hay log de hoy, no hay nada que recalcular
      if (!logSnap.exists) return;

      final log = DailyLog.fromJson({...logSnap.data()!, 'id': todayId});
      final newImr = _calculateImrPure(user, log);

      transaction.update(dailyLogRef, {
        'imrScore': newImr,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }
}

final weeklyLogsProvider = StreamProvider.autoDispose
    .family<List<DailyLog>, String>((ref, uid) {
      return ref.watch(healthRepositoryProvider).watchLogsHistory(uid, 7);
    });

final logsHistoryProvider = StreamProvider.autoDispose
    .family<List<DailyLog>, ({String uid, int days})>((ref, arg) {
      return ref
          .watch(healthRepositoryProvider)
          .watchLogsHistory(arg.uid, arg.days);
    });

final healthRepositoryProvider = Provider<HealthRepository>((ref) {
  return HealthRepository(FirebaseFirestore.instance);
});

final todayLogProvider = StreamProvider.autoDispose.family<DailyLog?, String>((
  ref,
  uid,
) {
  return ref.watch(healthRepositoryProvider).watchTodayLog(uid);
});
