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
SleepRepository sleepRepository(Ref ref) {
  return SleepRepositoryImpl(FirebaseFirestore.instance);
}

@riverpod
Stream<List<SleepLog>> recentSleepLogs(Ref ref) {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return Stream.value([]);

  return ref.watch(sleepRepositoryProvider).watchRecentSleepLogs(user.uid);
}

@riverpod
class SleepController extends _$SleepController {
  @override
  void build() {}

  /// ✅ WAKE TRIGGER: Detecta la primera interacción después de la hora meta
  Future<void> checkWakeInteraction(
    UserModel user,
    bool isResting,
    BuildContext context,
  ) async {
    if (user.wakeUpTime == null || !isResting) return;

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().split('T')[0];
    final lastProcessed = prefs.getString('last_wakeup_processed');

    if (lastProcessed == today) return;

    // Verificar si ya pasó la hora de despertar
    final targetWake = _parseTimeToToday(user.wakeUpTime!);
    if (DateTime.now().isAfter(targetWake)) {
      // Mostrar TimePicker automático
      if (context.mounted) {
        final pickedTime = await showTimePicker(
          context: context,
          initialTime: TimeOfDay.fromDateTime(targetWake),
          helpText: '¿A QUÉ HORA DESPERTASTE EXACTAMENTE?',
        );

        if (pickedTime != null) {
          final now = DateTime.now();
          final wakeDateTime = DateTime(
            now.year,
            now.month,
            now.day,
            pickedTime.hour,
            pickedTime.minute,
          );

          // Buscar el inicio del sueño (ayer o hoy temprano)
          final lastSleepStart = await _getLastSleepStart(user.uid);
          if (lastSleepStart != null) {
            final lastMealTime = await getLastMealTime(user.uid);
            final score = ElenaBrain.calculateSleepQuality(
              checkIn: lastSleepStart,
              checkOut: wakeDateTime,
              targetSleepTime: user.bedTime,
              targetWakeTime: user.wakeUpTime,
              lastMealTime: lastMealTime,
            );

            final duration =
                wakeDateTime.difference(lastSleepStart).inMinutes / 60.0;
            await logSleep(duration, score: score, date: wakeDateTime);

            // Actualizar usuario con el último score e isResting = false
            await ref.read(userRepositoryProvider).updateUser(user.uid, {
              'isResting': false,
              'lastSleepScore': score,
              'averageSleepHours': duration, // Actualizar pilar
            });
          }

          await prefs.setString('last_wakeup_processed', today);
        }
      }
    }
  }

  /// ✅ NIGHT TRIGGER: Inicia protocolo de sueño
  Future<void> startSleepProtocol(String uid) async {
    await ref.read(userRepositoryProvider).updateUser(uid, {
      'isResting': true,
      'lastSleepStart': FieldValue.serverTimestamp(),
    });
  }

  Future<DateTime?> _getLastSleepStart(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    final data = doc.data();
    if (data == null || data['lastSleepStart'] == null) return null;
    return (data['lastSleepStart'] as Timestamp).toDate();
  }

  Future<DateTime?> getLastMealTime(String uid) async {
    final todayId = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(todayId)
        .get();

    if (!doc.exists) return null;
    final meals = doc.data()?['mealEntries'] as List? ?? [];
    if (meals.isEmpty) return null;

    DateTime? last;
    for (var m in meals) {
      final ts = m['timestamp'];
      if (ts != null) {
        final dt = ts is Timestamp
            ? ts.toDate()
            : DateTime.tryParse(ts.toString());
        if (dt != null && (last == null || dt.isAfter(last))) {
          last = dt;
        }
      }
    }
    return last;
  }

  DateTime _parseTimeToToday(String time) {
    final parts = time.split(':');
    final now = DateTime.now();
    return DateTime(
      now.year,
      now.month,
      now.day,
      int.parse(parts[0]),
      int.parse(parts[1]),
    );
  }

  Future<void> saveRoutine({
    required String bedTime,
    required String wakeUpTime,
  }) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    final userRepository = ref.read(userRepositoryProvider);
    await userRepository.updateUser(user.uid, {
      'bedTime': bedTime,
      'wakeUpTime': wakeUpTime,
    });

    // Programar notificación de preparación (1h antes)
    final prepTime = _parseTimeToToday(
      bedTime,
    ).subtract(const Duration(hours: 1));
    if (prepTime.isAfter(DateTime.now())) {
      await NotificationService.scheduleSleepPrep(prepTime);
    }
  }

  Future<void> logSleep(
    double hours, {
    double score = 0.0,
    DateTime? date,
  }) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    final log = SleepLog(
      id: const Uuid().v4(),
      userId: user.uid,
      hours: hours,
      timestamp: date ?? DateTime.now(),
    );

    await ref.read(sleepRepositoryProvider).saveSleepLog(log);

    // ✅ Sync to DailyLog so IMR recalculates with real sleep data
    await ref
        .read(healthRepositoryProvider)
        .logSleepToDailyLog(user.uid, hours);

    AnalyticsService.logSleepLogged(hours);
  }
}

/// ✅ MANUAL PROVIDER (Bypasses build_runner mismatch)
final sleepStatusProvider =
    StreamProvider<({bool isResting, double lastSleepScore})>((ref) {
      final user = ref.watch(authRepositoryProvider).currentUser;
      if (user == null) {
        return Stream.value((isResting: false, lastSleepScore: 0.0));
      }

      return FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots()
          .map((snapshot) {
            if (!snapshot.exists || snapshot.data() == null) {
              return (isResting: false, lastSleepScore: 0.0);
            }
            final data = snapshot.data()!;
            return (
              isResting: data['isResting'] as bool? ?? false,
              lastSleepScore:
                  (data['lastSleepScore'] as num?)?.toDouble() ?? 0.0,
            );
          });
    });

final lastMealProvider = FutureProvider<DateTime?>((ref) async {
  final user = ref.watch(authRepositoryProvider).currentUser;
  if (user == null) return null;
  return ref.read(sleepControllerProvider.notifier).getLastMealTime(user.uid);
});
