// SPEC-261.4: traductor entre el documento Firestore y ConsumptionSession
// (solo los METADATOS de la ocasión; los `drinks` viven en alcohol_history).

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/features/alcohol/domain/consumption_session.dart';

class ConsumptionSessionMapper {
  const ConsumptionSessionMapper();

  Map<String, dynamic> toMap(ConsumptionSession s) {
    return {
      'phase': s.phase.name,
      'budget': s.budgetStandardUnits,
      'lastCallTarget': _ts(s.lastCallTarget),
      'bedtime': _ts(s.bedtime),
      'drinkTypeId': s.drinkTypeId,
      'startTime': _ts(s.startTime),
      'worksTomorrow': s.worksTomorrow,
      'wakeTime': _ts(s.wakeTime),
      'hydratedBefore': s.hydratedBefore,
      'ateBefore': s.ateBefore,
      'recoveryFastPlanned': s.recoveryFastPlanned,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  ConsumptionSession fromMap(Map<String, dynamic> m) {
    return ConsumptionSession(
      phase: _phaseFrom(m['phase']),
      budgetStandardUnits: _toDouble(m['budget']) ?? 4.0,
      lastCallTarget: _toDate(m['lastCallTarget']),
      bedtime: _toDate(m['bedtime']),
      drinkTypeId: m['drinkTypeId'] as String?,
      startTime: _toDate(m['startTime']),
      worksTomorrow: m['worksTomorrow'] == true,
      wakeTime: _toDate(m['wakeTime']),
      hydratedBefore: m['hydratedBefore'] == true,
      ateBefore: m['ateBefore'] == true,
      recoveryFastPlanned: m['recoveryFastPlanned'] == true,
    );
  }

  static Timestamp? _ts(DateTime? d) =>
      d == null ? null : Timestamp.fromDate(d);

  static ConsumptionPhase _phaseFrom(dynamic v) {
    if (v is String) {
      for (final p in ConsumptionPhase.values) {
        if (p.name == v) return p;
      }
    }
    return ConsumptionPhase.inactive;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static DateTime? _toDate(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }
}
