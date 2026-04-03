import 'dart:async';
import 'dart:collection';
import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../domain/decision_output.dart';
import '../domain/user_behavior_profile.dart';

/// Tracks behavioral feedback loop for adaptive decisioning.
///
/// Pure application logic with no UI dependencies.
class BehaviorTracker {
  final BehaviorTrackerStore _store;

  UserBehaviorProfile _profile;
  String? _lastDecisionAction;
  String? _lastUserAction;
  final List<BehaviorEvent> _events;

  BehaviorTracker({
    BehaviorTrackerStore? store,
    UserBehaviorProfile? initialProfile,
  })  : _store = store ?? const LocalBehaviorTrackerStore(),
        _profile = initialProfile ?? UserBehaviorProfile(),
        _events = <BehaviorEvent>[];

  UserBehaviorProfile get profile => _profile;
  String? get lastDecisionAction => _lastDecisionAction;
  String? get lastUserAction => _lastUserAction;
  List<BehaviorEvent> get events => UnmodifiableListView(_events);

  /// Loads persisted data from storage (if available).
  Future<void> initialize() async {
    final snapshot = await _store.load();
    if (snapshot == null) return;

    _profile = snapshot.profile;
    _lastDecisionAction = snapshot.lastDecisionAction;
    _lastUserAction = snapshot.lastUserAction;
    _events
      ..clear()
      ..addAll(snapshot.events);
  }

  /// Tracks which recommendation was given to the user.
  void trackDecision(DecisionOutput decision) {
    final actionKey = _decisionActionKey(decision);
    _lastDecisionAction = actionKey;
    _profile = _profile.registerAction(actionKey);

    _events.add(
      BehaviorEvent(
        type: BehaviorEventType.decisionGiven,
        action: actionKey,
        success: null,
        timestamp: DateTime.now().toUtc(),
      ),
    );

    _persist();
  }

  /// Tracks what the user actually executed.
  void trackUserAction(String action) {
    final normalized = _normalizeAction(action);
    if (normalized.isEmpty) return;

    _lastUserAction = normalized;
    _profile = _profile.registerAction(normalized);

    _events.add(
      BehaviorEvent(
        type: BehaviorEventType.userAction,
        action: normalized,
        success: null,
        timestamp: DateTime.now().toUtc(),
      ),
    );

    _persist();
  }

  /// Tracks outcome for an action and updates success rates.
  void trackOutcome(String action, bool success) {
    final normalized = _normalizeAction(action);
    if (normalized.isEmpty) return;

    _profile = _profile.registerOutcome(normalized, success);

    _events.add(
      BehaviorEvent(
        type: BehaviorEventType.outcome,
        action: normalized,
        success: success,
        timestamp: DateTime.now().toUtc(),
      ),
    );

    _persist();
  }

  void _persist() {
    unawaited(
      _store.save(
        BehaviorTrackerSnapshot(
          profile: _profile,
          lastDecisionAction: _lastDecisionAction,
          lastUserAction: _lastUserAction,
          events: List<BehaviorEvent>.from(_events),
        ),
      ),
    );
  }

  String _decisionActionKey(DecisionOutput decision) {
    final action = decision.primaryAction.toLowerCase();

    if (action.contains('romper el ayuno') ||
        action.contains('momento de comer')) {
      return 'eat_now';
    }
    if (action.contains('mantén tu ayuno') ||
        action.contains('mantener ayuno')) {
      return 'fasting_continue';
    }
    if (action.contains('descanso')) return 'rest';
    if (action.contains('entrenar')) return 'train';
    if (action.contains('agua') || action.contains('hidrata')) return 'hydrate';

    return 'maintain';
  }

  String _normalizeAction(String action) {
    return action.trim().toLowerCase().replaceAll(' ', '_');
  }
}

abstract class BehaviorTrackerStore {
  Future<void> save(BehaviorTrackerSnapshot snapshot);
  Future<BehaviorTrackerSnapshot?> load();
}

/// Local persistence using SharedPreferences.
class LocalBehaviorTrackerStore implements BehaviorTrackerStore {
  static const String _storageKey = 'core.health.behavior_tracker.snapshot';

  const LocalBehaviorTrackerStore();

  @override
  Future<void> save(BehaviorTrackerSnapshot snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(snapshot.toJson()));
  }

  @override
  Future<BehaviorTrackerSnapshot?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) return null;
      return BehaviorTrackerSnapshot.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }
}

/// In-memory persistence for tests/mocks.
class InMemoryBehaviorTrackerStore implements BehaviorTrackerStore {
  BehaviorTrackerSnapshot? _snapshot;

  @override
  Future<void> save(BehaviorTrackerSnapshot snapshot) async {
    _snapshot = snapshot;
  }

  @override
  Future<BehaviorTrackerSnapshot?> load() async => _snapshot;
}

class BehaviorTrackerSnapshot {
  final UserBehaviorProfile profile;
  final String? lastDecisionAction;
  final String? lastUserAction;
  final List<BehaviorEvent> events;

  BehaviorTrackerSnapshot({
    required this.profile,
    this.lastDecisionAction,
    this.lastUserAction,
    this.events = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'profile': {
        'fastingTolerance': profile.fastingTolerance,
        'trainingRecoveryRate': profile.trainingRecoveryRate,
        'sleepConsistency': profile.sleepConsistency,
        'hydrationDiscipline': profile.hydrationDiscipline,
        'nutritionCompliance': profile.nutritionCompliance,
        'actionHistoryCounts': profile.actionHistoryCounts,
        'actionSuccessRates': profile.actionSuccessRates,
      },
      'lastDecisionAction': lastDecisionAction,
      'lastUserAction': lastUserAction,
      'events': events.map((e) => e.toJson()).toList(),
    };
  }

  factory BehaviorTrackerSnapshot.fromJson(Map<String, dynamic> json) {
    final profileJson =
        (json['profile'] as Map?)?.cast<String, dynamic>() ?? const {};

    return BehaviorTrackerSnapshot(
      profile: UserBehaviorProfile(
        fastingTolerance:
            _toDouble(profileJson['fastingTolerance'], fallback: 0.5),
        trainingRecoveryRate:
            _toDouble(profileJson['trainingRecoveryRate'], fallback: 0.5),
        sleepConsistency:
            _toDouble(profileJson['sleepConsistency'], fallback: 0.5),
        hydrationDiscipline:
            _toDouble(profileJson['hydrationDiscipline'], fallback: 0.5),
        nutritionCompliance:
            _toDouble(profileJson['nutritionCompliance'], fallback: 0.5),
        actionHistoryCounts: _toIntMap(profileJson['actionHistoryCounts']),
        actionSuccessRates: _toDoubleMap(profileJson['actionSuccessRates']),
      ),
      lastDecisionAction: json['lastDecisionAction'] as String?,
      lastUserAction: json['lastUserAction'] as String?,
      events: _toEvents(json['events']),
    );
  }

  static double _toDouble(dynamic value, {required double fallback}) {
    if (value is num) return value.toDouble();
    return fallback;
  }

  static Map<String, int> _toIntMap(dynamic value) {
    if (value is! Map) return const {};

    final result = <String, int>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final mapValue = entry.value;
      if (key is String && mapValue is num) {
        result[key] = mapValue.toInt();
      }
    }
    return result;
  }

  static Map<String, double> _toDoubleMap(dynamic value) {
    if (value is! Map) return const {};

    final result = <String, double>{};
    for (final entry in value.entries) {
      final key = entry.key;
      final mapValue = entry.value;
      if (key is String && mapValue is num) {
        result[key] = mapValue.toDouble();
      }
    }
    return result;
  }

  static List<BehaviorEvent> _toEvents(dynamic value) {
    if (value is! List) return const [];

    final events = <BehaviorEvent>[];
    for (final item in value) {
      if (item is Map<String, dynamic>) {
        events.add(BehaviorEvent.fromJson(item));
      } else if (item is Map) {
        events.add(BehaviorEvent.fromJson(item.cast<String, dynamic>()));
      }
    }
    return events;
  }
}

enum BehaviorEventType {
  decisionGiven('decision_given'),
  userAction('user_action'),
  outcome('outcome');

  final String value;
  const BehaviorEventType(this.value);

  static BehaviorEventType fromValue(String? value) {
    return BehaviorEventType.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BehaviorEventType.userAction,
    );
  }
}

class BehaviorEvent {
  final BehaviorEventType type;
  final String action;
  final bool? success;
  final DateTime timestamp;

  const BehaviorEvent({
    required this.type,
    required this.action,
    required this.success,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'action': action,
      'success': success,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory BehaviorEvent.fromJson(Map<String, dynamic> json) {
    return BehaviorEvent(
      type: BehaviorEventType.fromValue(json['type'] as String?),
      action: (json['action'] as String?) ?? 'unknown',
      success: json['success'] as bool?,
      timestamp: DateTime.tryParse((json['timestamp'] as String?) ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}
