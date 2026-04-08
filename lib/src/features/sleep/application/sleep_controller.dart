import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../../core/services/analytics_service.dart';
import '../../../core/services/notification_service.dart';
import '../../../domain/logic/elena_brain.dart';
import '../../../shared/domain/models/user_model.dart';
import '../../authentication/data/auth_repository.dart';
import '../../health/data/health_repository.dart';
import '../../profile/data/user_repository.dart';
import '../data/repositories/sleep_repository_impl.dart';
import '../domain/entities/sleep_log.dart';
import '../domain/repositories/sleep_repository.dart';

part 'sleep_controller.g.dart';

@Riverpod(keepAlive: true)
SleepRepository sleepRepository(Ref ref) => SleepRepositoryImpl(FirebaseFirestore.instance);

@riverpod
Stream<List<SleepLog>> recentSleepLogs(Ref ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  return user == null ? Stream.value([]) : ref.watch(sleepRepositoryProvider).watchRecentSleepLogs(user.uid);
}

@riverpod
class SleepController extends _$SleepController {
  @override build() {}

  Future<void> checkWakeInteraction(UserModel user, bool isResting, BuildContext context) async {
    if (user.wakeUpTime == null || !isResting) return;
    final targetWake = _parseTimeToToday(user.wakeUpTime!);
    if (DateTime.now().isBefore(targetWake)) return;

    if (context.mounted) {
      final pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(targetWake),
        helpText: '¿A QUÉ HORA DESPERTASTE?',
      );

      if (pickedTime != null) {
        final now = DateTime.now();
        final wakeDT = DateTime(now.year, now.month, now.day, pickedTime.hour, pickedTime.minute);
        final startDT = await _getLastSleepStart(user.uid);
        
        if (startDT != null) {
          final lastMeal = await getLastMealTime(user.uid);
          Duration diff = wakeDT.difference(startDT);
          if (diff.isNegative) diff += const Duration(hours: 24);

          double hours = (diff.inMinutes / 60.0).clamp(0.0, 24.0);
          final score = ElenaBrain.calculateSleepQuality(
            checkIn: startDT, checkOut: wakeDT, 
            targetSleepTime: user.bedTime, targetWakeTime: user.wakeUpTime,
            lastMealTime: lastMeal,
          );

          await logSleep(hours, score: score, date: wakeDT);
          await ref.read(userRepositoryProvider).updateUser(user.uid, {
            'isResting': false,
            'lastSleepScore': score,
            'averageSleepHours': hours,
          });
        }
      }
    }
  }

  Future<void> startSleepProtocol(String uid) async {
    await ref.read(userRepositoryProvider).updateUser(uid, {
      'isResting': true,
      'lastSleepStart': FieldValue.serverTimestamp(),
    });
  }

  Future<DateTime?> _getLastSleepStart(String uid) async {
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return (snap.data()?['lastSleepStart'] as Timestamp?)?.toDate();
  }

  Future<DateTime?> getLastMealTime(String uid) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('daily_logs').doc(today).get();
    final meals = snap.data()?['mealEntries'] as List? ?? [];
    if (meals.isEmpty) return null;
    return (meals.last['timestamp'] as Timestamp).toDate();
  }

  DateTime _parseTimeToToday(String time) {
    try {
      final parts = time.replaceAll(RegExp(r'[^0-9:]'), '').split(':');
      int h = int.parse(parts[0]);
      int m = parts.length > 1 ? int.parse(parts[1]) : 0;
      if (time.toUpperCase().contains('PM') && h < 12) h += 12;
      return DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day, h, m);
    } catch (_) { return DateTime.now(); }
  }

  Future<void> logSleep(double hours, {double score = 0.0, DateTime? date}) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;
    final log = SleepLog(id: const Uuid().v4(), userId: user.uid, hours: hours, timestamp: date ?? DateTime.now());
    await ref.read(sleepRepositoryProvider).saveSleepLog(log);
    await ref.read(healthRepositoryProvider).logSleepToDailyLog(user.uid, hours);
  }
}

// PROVIDERS PARA UI
final sleepStatusProvider = StreamProvider<({bool isResting, double lastSleepScore})>((ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return Stream.value((isResting: false, lastSleepScore: 0.0));
  return FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots().map((snap) => (
    isResting: snap.data()?['isResting'] as bool? ?? false,
    lastSleepScore: (snap.data()?['lastSleepScore'] as num?)?.toDouble() ?? 0.0,
  ));
});

final lastMealProvider = FutureProvider<DateTime?>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  return user == null ? null : ref.read(sleepControllerProvider.notifier).getLastMealTime(user.uid);
});