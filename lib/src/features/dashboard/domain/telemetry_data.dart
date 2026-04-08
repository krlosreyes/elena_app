import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ELENA SYSTEM — Telemetry Data Model
// ─────────────────────────────────────────────────────────────────────────────
// Immutable snapshot of the user's daily telemetry sourced from Firestore
// via `users/{uid}/daily_logs/{date}`.
// This is the single source of truth for the Dashboard's real-time data.
// ─────────────────────────────────────────────────────────────────────────────

class TelemetryData {
  // ── Hydration ──
  final int hydrationGlasses;
  final int hydrationGoalGlasses;
  final double hydrationLiters;
  final double hydrationGoalLiters;

  // ── Nutrition ──
  final int nutritionKcal;
  final int proteinGrams;
  final int carbsGrams;
  final int fatGrams;
  final int mealCount;

  // ── Sleep ──
  final int sleepMinutes;
  final double sleepHours;

  // ── Fasting ──
  final DateTime? fastingStartTime;
  final DateTime? fastingEndTime;
  final double fastingElapsedHours;

  // ── Exercise ──
  final int exerciseMinutes;
  final int exerciseEntryCount;

  // ── Composite ──
  final double imrScore;

  // ── Metadata ──
  final String logId; // YYYY-MM-DD
  final DateTime fetchedAt;

  const TelemetryData({
    required this.hydrationGlasses,
    required this.hydrationGoalGlasses,
    required this.hydrationLiters,
    required this.hydrationGoalLiters,
    required this.nutritionKcal,
    required this.proteinGrams,
    required this.carbsGrams,
    required this.fatGrams,
    required this.mealCount,
    required this.sleepMinutes,
    required this.sleepHours,
    this.fastingStartTime,
    this.fastingEndTime,
    required this.fastingElapsedHours,
    required this.exerciseMinutes,
    required this.exerciseEntryCount,
    required this.imrScore,
    required this.logId,
    required this.fetchedAt,
  });

  /// Parses a Firestore `daily_logs/{date}` document into [TelemetryData].
  ///
  /// [hydrationGoalGlasses] is calculated externally from user weight.
  factory TelemetryData.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, {
    required int hydrationGoalGlasses,
  }) {
    final d = doc.data() ?? {};
    final waterGlasses = (d['waterGlasses'] as num?)?.toInt() ?? 0;
    final sleepMins = (d['sleepMinutes'] as num?)?.toInt() ?? 0;
    final goalGlasses = hydrationGoalGlasses.clamp(1, 20);

    // Parse fasting timestamps
    DateTime? fastStart;
    DateTime? fastEnd;
    if (d['fastingStartTime'] is Timestamp) {
      fastStart = (d['fastingStartTime'] as Timestamp).toDate();
    }
    if (d['fastingEndTime'] is Timestamp) {
      fastEnd = (d['fastingEndTime'] as Timestamp).toDate();
    }

    double fastingHours = 0.0;
    if (fastStart != null) {
      final end = fastEnd ?? DateTime.now();
      fastingHours = end.difference(fastStart).inMinutes / 60.0;
    }

    final meals = (d['mealEntries'] as List?)?.length ?? 0;

    return TelemetryData(
      hydrationGlasses: waterGlasses,
      hydrationGoalGlasses: goalGlasses,
      hydrationLiters: waterGlasses * 0.25,
      hydrationGoalLiters: goalGlasses * 0.25,
      nutritionKcal: (d['calories'] as num?)?.toInt() ?? 0,
      proteinGrams: (d['proteinGrams'] as num?)?.toInt() ?? 0,
      carbsGrams: (d['carbsGrams'] as num?)?.toInt() ?? 0,
      fatGrams: (d['fatGrams'] as num?)?.toInt() ?? 0,
      mealCount: meals,
      sleepMinutes: sleepMins,
      sleepHours: sleepMins / 60.0,
      fastingStartTime: fastStart,
      fastingEndTime: fastEnd,
      fastingElapsedHours: fastingHours,
      exerciseMinutes: (d['exerciseMinutes'] as num?)?.toInt() ?? 0,
      exerciseEntryCount: (d['exerciseEntries'] as List?)?.length ?? 0,
      imrScore: (d['mtiScore'] as num?)?.toDouble() ?? 0.0,
      logId: doc.id,
      fetchedAt: DateTime.now(),
    );
  }

  /// Parses from an already-decoded [DailyLog]-style map (used when bridging
  /// from the existing `todayLogProvider`).
  factory TelemetryData.fromDailyLogMap(
    Map<String, dynamic> d, {
    required String logId,
    required int hydrationGoalGlasses,
  }) {
    final waterGlasses = (d['waterGlasses'] as num?)?.toInt() ?? 0;
    final sleepMins = (d['sleepMinutes'] as num?)?.toInt() ?? 0;
    final goalGlasses = hydrationGoalGlasses.clamp(1, 20);

    DateTime? fastStart;
    DateTime? fastEnd;
    if (d['fastingStartTime'] is Timestamp) {
      fastStart = (d['fastingStartTime'] as Timestamp).toDate();
    } else if (d['fastingStartTime'] is DateTime) {
      fastStart = d['fastingStartTime'] as DateTime;
    }
    if (d['fastingEndTime'] is Timestamp) {
      fastEnd = (d['fastingEndTime'] as Timestamp).toDate();
    } else if (d['fastingEndTime'] is DateTime) {
      fastEnd = d['fastingEndTime'] as DateTime;
    }

    double fastingHours = 0.0;
    if (fastStart != null) {
      final end = fastEnd ?? DateTime.now();
      fastingHours = end.difference(fastStart).inMinutes / 60.0;
    }

    final meals = (d['mealEntries'] as List?)?.length ?? 0;

    return TelemetryData(
      hydrationGlasses: waterGlasses,
      hydrationGoalGlasses: goalGlasses,
      hydrationLiters: waterGlasses * 0.25,
      hydrationGoalLiters: goalGlasses * 0.25,
      nutritionKcal: (d['calories'] as num?)?.toInt() ?? 0,
      proteinGrams: (d['proteinGrams'] as num?)?.toInt() ?? 0,
      carbsGrams: (d['carbsGrams'] as num?)?.toInt() ?? 0,
      fatGrams: (d['fatGrams'] as num?)?.toInt() ?? 0,
      mealCount: meals,
      sleepMinutes: sleepMins,
      sleepHours: sleepMins / 60.0,
      fastingStartTime: fastStart,
      fastingEndTime: fastEnd,
      fastingElapsedHours: fastingHours,
      exerciseMinutes: (d['exerciseMinutes'] as num?)?.toInt() ?? 0,
      exerciseEntryCount: (d['exerciseEntries'] as List?)?.length ?? 0,
      imrScore: (d['mtiScore'] as num?)?.toDouble() ?? 0.0,
      logId: logId,
      fetchedAt: DateTime.now(),
    );
  }

  /// Empty telemetry used as fallback.
  factory TelemetryData.empty() => TelemetryData(
        hydrationGlasses: 0,
        hydrationGoalGlasses: 8,
        hydrationLiters: 0.0,
        hydrationGoalLiters: 2.0,
        nutritionKcal: 0,
        proteinGrams: 0,
        carbsGrams: 0,
        fatGrams: 0,
        mealCount: 0,
        sleepMinutes: 0,
        sleepHours: 0.0,
        fastingElapsedHours: 0.0,
        exerciseMinutes: 0,
        exerciseEntryCount: 0,
        imrScore: 0.0,
        logId: '',
        fetchedAt: DateTime.now(),
      );
}
