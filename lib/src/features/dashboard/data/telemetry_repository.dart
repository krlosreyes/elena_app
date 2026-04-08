import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../authentication/data/auth_repository.dart';
import '../../profile/application/user_controller.dart';
import '../domain/telemetry_data.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ELENA SYSTEM — Telemetry Repository
// ─────────────────────────────────────────────────────────────────────────────
// Reads real-time telemetry from `users/{uid}/daily_logs/{date}`
// and provides write methods for panic logs + debounced hydration.
// ─────────────────────────────────────────────────────────────────────────────

class TelemetryRepository {
  final FirebaseFirestore _firestore;

  TelemetryRepository(this._firestore);

  String _todayId() => DateFormat('yyyy-MM-dd').format(DateTime.now());

  // ── READ: Real-time telemetry stream ─────────────────────────────────────

  /// Streams the current day's [TelemetryData] from Firestore.
  /// Emits a new snapshot every time the document changes.
  Stream<TelemetryData> watchTodayTelemetry({
    required String uid,
    required int hydrationGoalGlasses,
  }) {
    final todayId = _todayId();
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('daily_logs')
        .doc(todayId)
        .snapshots()
        .map((snap) {
      if (!snap.exists || snap.data() == null) {
        return TelemetryData.empty();
      }
      return TelemetryData.fromFirestore(
        snap,
        hydrationGoalGlasses: hydrationGoalGlasses,
      );
    });
  }

  // ── WRITE: Panic log ─────────────────────────────────────────────────────

  /// Records a hunger panic event in `users/{uid}/panic_logs/{autoId}`.
  ///
  /// Returns the generated document ID on success.
  Future<String> writePanicLog({
    required String uid,
    required int hungerLevel,
    required String context,
    required bool wasFasting,
    Duration? fastingElapsed,
  }) async {
    try {
      final docRef = await _firestore
          .collection('users')
          .doc(uid)
          .collection('panic_logs')
          .add({
        'timestamp': FieldValue.serverTimestamp(),
        'hungerLevel': hungerLevel,
        'context': context,
        'wasFasting': wasFasting,
        'fastingElapsedMinutes': fastingElapsed?.inMinutes ?? 0,
        'date': _todayId(),
      });
      debugPrint('✅ [TelemetryRepo] Panic log recorded: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ [TelemetryRepo] writePanicLog failed: $e');
      rethrow;
    }
  }

  // ── WRITE: Debounced hydration ───────────────────────────────────────────

  Timer? _hydrationDebounceTimer;

  /// Debounced hydration increment. Accumulates rapid taps and writes once.
  ///
  /// [onFlush] is called with the total accumulated glasses after debounce.
  void addHydrationDebounced({
    required String uid,
    required int glasses,
    required void Function(int totalPending) onFlush,
    Duration debounce = const Duration(milliseconds: 800),
  }) {
    _pendingGlasses += glasses;
    _hydrationDebounceTimer?.cancel();
    _hydrationDebounceTimer = Timer(debounce, () {
      final batch = _pendingGlasses;
      _pendingGlasses = 0;
      _flushHydration(uid, batch);
      onFlush(batch);
    });
  }

  int _pendingGlasses = 0;

  Future<void> _flushHydration(String uid, int glasses) async {
    if (glasses <= 0) return;
    final todayId = _todayId();
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('daily_logs')
          .doc(todayId)
          .set(
        {'waterGlasses': FieldValue.increment(glasses)},
        SetOptions(merge: true),
      );
      debugPrint('💧 [TelemetryRepo] Flushed $glasses glasses');
    } catch (e) {
      debugPrint('❌ [TelemetryRepo] flushHydration failed: $e');
    }
  }

  /// Cancel any pending debounced operations.
  void dispose() {
    _hydrationDebounceTimer?.cancel();
  }

  // ── READ: Suggestions from metamorfosis_posts ────────────────────────────

  /// Queries `metamorfosis_posts` collection for context-relevant content.
  ///
  /// Filters by metabolic tag matching the current state (e.g. "ayuno",
  /// "alimentacion", "autofagia"). Returns the latest post's body text.
  Stream<List<MetamorfosisPost>> watchSuggestions({
    required String metabolicTag,
    int limit = 3,
  }) {
    return _firestore
        .collection('metamorfosis_posts')
        .where('tags', arrayContains: metabolicTag)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => MetamorfosisPost.fromFirestore(doc))
            .toList())
        .handleError((e) {
      debugPrint('⚠️ [TelemetryRepo] watchSuggestions error: $e');
      return <MetamorfosisPost>[];
    });
  }
}

// ── Mini model for metamorfosis_posts ──────────────────────────────────────

class MetamorfosisPost {
  final String id;
  final String title;
  final String body;
  final List<String> tags;
  final DateTime? createdAt;

  const MetamorfosisPost({
    required this.id,
    required this.title,
    required this.body,
    required this.tags,
    this.createdAt,
  });

  factory MetamorfosisPost.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    return MetamorfosisPost(
      id: doc.id,
      title: (d['title'] as String?) ?? '',
      body: (d['body'] as String?) ?? (d['content'] as String?) ?? '',
      tags: (d['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      createdAt: d['createdAt'] is Timestamp
          ? (d['createdAt'] as Timestamp).toDate()
          : null,
    );
  }
}

// ── Providers ──────────────────────────────────────────────────────────────

final telemetryRepositoryProvider = Provider<TelemetryRepository>((ref) {
  final repo = TelemetryRepository(FirebaseFirestore.instance);
  ref.onDispose(() => repo.dispose());
  return repo;
});

/// Real-time telemetry stream for the authenticated user.
final telemetryStreamProvider =
    StreamProvider.autoDispose<TelemetryData>((ref) {
  final uid = ref.watch(authRepositoryProvider).currentUser?.uid;
  if (uid == null) return Stream.value(TelemetryData.empty());

  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  final goalGlasses =
      ((user?.currentWeightKg ?? 65.0) / 7).round().clamp(1, 20);

  return ref
      .watch(telemetryRepositoryProvider)
      .watchTodayTelemetry(uid: uid, hydrationGoalGlasses: goalGlasses);
});

/// Metabolic tag derived from current fasting state (for suggestion queries).
final _metabolicTagProvider = Provider.autoDispose<String>((ref) {
  final telemetry = ref.watch(telemetryStreamProvider).valueOrNull;
  if (telemetry == null) return 'general';

  if (telemetry.fastingElapsedHours >= 16) return 'autofagia';
  if (telemetry.fastingElapsedHours >= 12) return 'quema_grasa';
  if (telemetry.fastingStartTime != null && telemetry.fastingEndTime == null) {
    return 'ayuno';
  }
  return 'alimentacion';
});

/// Streams context-relevant suggestions from `metamorfosis_posts`.
final suggestionsStreamProvider =
    StreamProvider.autoDispose<List<MetamorfosisPost>>((ref) {
  final tag = ref.watch(_metabolicTagProvider);
  return ref.watch(telemetryRepositoryProvider).watchSuggestions(
        metabolicTag: tag,
        limit: 3,
      );
});
