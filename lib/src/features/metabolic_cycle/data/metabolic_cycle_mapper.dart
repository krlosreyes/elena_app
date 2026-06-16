// SPEC-149: mapper entre MetabolicCycle y Map<String, dynamic> (Firestore).
//
// La serialización es delicada porque MetabolicCycle tiene varios campos
// opcionales que solo se populan al cierre (closedAt, closureReason,
// dailyScore, pillarsCompleted, magnitudes, feedback). Mientras el
// ciclo está abierto, esos campos quedan ausentes del doc.
//
// Schema final canónico documentado en SPEC-149 §RF-149-05.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/metabolic_cycle/domain/closure_reason.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/cycle_feedback.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';

class MetabolicCycleMapper {
  const MetabolicCycleMapper();

  // ─── MetabolicCycle ↔ Map ──────────────────────────────────────────────────

  Map<String, dynamic> toMap(MetabolicCycle cycle) {
    final m = <String, dynamic>{
      'cycleId': cycle.cycleId,
      'startedAt': Timestamp.fromDate(cycle.startedAt),
      'fastingProtocol': cycle.fastingProtocol,
      'meta': {
        'schemaVersion': 1,
        'tzOffsetMinutes': cycle.tzOffsetMinutes,
      },
    };
    if (cycle.closedAt != null) {
      m['closedAt'] = Timestamp.fromDate(cycle.closedAt!);
    }
    if (cycle.closureReason != null) {
      m['closureReason'] = cycle.closureReason!.value;
    }
    if (cycle.fastingDurationHours != null) {
      m['fastingDurationHours'] = cycle.fastingDurationHours;
    }
    if (cycle.feedingWindowHours != null) {
      m['feedingWindowHours'] = cycle.feedingWindowHours;
    }
    if (cycle.dailyScore != null) {
      m['dailyScore'] = cycle.dailyScore;
    }
    if (cycle.pillarsCompleted != null) {
      m['pillarsCompleted'] = _pillarsToMap(cycle.pillarsCompleted!);
    }
    if (cycle.magnitudes != null) {
      m['magnitudes'] = _magnitudesToMap(cycle.magnitudes!);
    }
    if (cycle.feedback != null) {
      m['feedback'] = _feedbackToMap(cycle.feedback!);
    }
    // SPEC-227: liveScore solo existe en ciclos abiertos; no se escribe
    // en el documento de cierre para no contaminar el schema histórico.
    if (cycle.liveScore != null) {
      m['liveScore'] = cycle.liveScore;
    }
    return m;
  }

  MetabolicCycle? fromMap(Map<String, dynamic> data) {
    try {
      final cycleId = data['cycleId'] as String?;
      final startedAtRaw = data['startedAt'];
      final fastingProtocol = data['fastingProtocol'] as String?;
      if (cycleId == null || startedAtRaw == null || fastingProtocol == null) {
        return null;
      }
      final startedAt = _readTimestamp(startedAtRaw);
      if (startedAt == null) return null;

      final meta = data['meta'] is Map
          ? Map<String, dynamic>.from(data['meta'] as Map)
          : <String, dynamic>{};
      final tzOffsetMinutes = (meta['tzOffsetMinutes'] as num?)?.toInt() ?? 0;

      return MetabolicCycle(
        cycleId: cycleId,
        startedAt: startedAt,
        closedAt: _readTimestamp(data['closedAt']),
        closureReason: ClosureReasonSerialization.fromString(
          data['closureReason'] as String?,
        ),
        fastingDurationHours:
            (data['fastingDurationHours'] as num?)?.toDouble(),
        feedingWindowHours: (data['feedingWindowHours'] as num?)?.toDouble(),
        dailyScore: (data['dailyScore'] as num?)?.toInt(),
        pillarsCompleted: data['pillarsCompleted'] is Map
            ? _pillarsFromMap(
                Map<String, dynamic>.from(data['pillarsCompleted'] as Map),
              )
            : null,
        magnitudes: data['magnitudes'] is Map
            ? _magnitudesFromMap(
                Map<String, dynamic>.from(data['magnitudes'] as Map),
              )
            : null,
        feedback: data['feedback'] is Map
            ? _feedbackFromMap(
                Map<String, dynamic>.from(data['feedback'] as Map),
              )
            : null,
        fastingProtocol: fastingProtocol,
        tzOffsetMinutes: tzOffsetMinutes,
        liveScore: (data['liveScore'] as num?)?.toInt(),
      );
    } catch (_) {
      return null;
    }
  }

  // ─── Sub-objetos ──────────────────────────────────────────────────────────

  Map<String, dynamic> _pillarsToMap(CyclePillarsCompleted p) => {
        'fasting': p.fasting,
        'sleep': p.sleep,
        'hydration': p.hydration,
        'exercise': p.exercise,
        'nutrition': p.nutrition,
      };

  CyclePillarsCompleted _pillarsFromMap(Map<String, dynamic> m) =>
      CyclePillarsCompleted(
        fasting: m['fasting'] as bool? ?? false,
        sleep: m['sleep'] as bool? ?? false,
        hydration: m['hydration'] as bool? ?? false,
        exercise: m['exercise'] as bool? ?? false,
        nutrition: m['nutrition'] as bool? ?? false,
      );

  Map<String, dynamic> _magnitudesToMap(CycleMagnitudes mag) => {
        'fastingMagnitude': mag.fastingMagnitude,
        'sleepQualityScore': mag.sleepQualityScore,
        'hydrationMagnitude': mag.hydrationMagnitude,
        'exerciseMagnitude': mag.exerciseMagnitude,
        'nutritionMagnitude': mag.nutritionMagnitude,
      };

  CycleMagnitudes _magnitudesFromMap(Map<String, dynamic> m) => CycleMagnitudes(
        fastingMagnitude: (m['fastingMagnitude'] as num?)?.toDouble() ?? 0,
        sleepQualityScore: (m['sleepQualityScore'] as num?)?.toDouble() ?? 0,
        hydrationMagnitude: (m['hydrationMagnitude'] as num?)?.toDouble() ?? 0,
        exerciseMagnitude: (m['exerciseMagnitude'] as num?)?.toDouble() ?? 0,
        nutritionMagnitude: (m['nutritionMagnitude'] as num?)?.toDouble() ?? 0,
      );

  Map<String, dynamic> _feedbackToMap(CycleFeedback f) => {
        'achievements': f.achievements,
        'gaps': f.gaps,
        'insight': f.insight,
        if (f.citation != null) 'citation': f.citation,
      };

  CycleFeedback _feedbackFromMap(Map<String, dynamic> m) => CycleFeedback(
        achievements: (m['achievements'] as List?)
                ?.map((e) => e.toString())
                .toList() ??
            const [],
        gaps: (m['gaps'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        insight: m['insight'] as String? ?? '',
        citation: m['citation'] as String?,
      );

  // ─── Helpers ──────────────────────────────────────────────────────────────

  DateTime? _readTimestamp(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String) return DateTime.tryParse(raw);
    return null;
  }
}
