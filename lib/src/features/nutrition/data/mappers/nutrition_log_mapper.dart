// SPEC-63 + SPEC-64: traductor entre Map<String, dynamic> y NutritionLog.
//
// SPEC-64 amplía el formato persistido con macronutrientes nullables. Los
// logs antiguos (escritos antes de SPEC-64) NO tendrán esos campos en el
// payload — el mapper los leerá como null, lo que semánticamente significa
// "no se midió". Backward compatible.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';

const Set<String> _kValidLabels = {
  'Desayuno',
  'Almuerzo',
  'Cena',
  'Snack',
};

class NutritionLogMapper {
  const NutritionLogMapper();

  Map<String, dynamic> toMap(NutritionLog log) {
    _validate(log);
    final map = <String, dynamic>{
      'id': log.id,
      'timestamp': Timestamp.fromDate(log.timestamp),
      'label': log.label,
      'withinCircadianWindow': log.withinCircadianWindow,
      'source': log.source.name,
    };
    // Solo persistir los campos de macros que tienen valor — preservamos
    // la semántica null = "no se midió".
    if (log.calories != null) map['calories'] = log.calories;
    if (log.protein != null) map['protein'] = log.protein;
    if (log.carbs != null) map['carbs'] = log.carbs;
    if (log.fat != null) map['fat'] = log.fat;
    if (log.fiber != null) map['fiber'] = log.fiber;
    if (log.glycemicIndex != null) map['glycemicIndex'] = log.glycemicIndex;
    return map;
  }

  NutritionLog fromMap(Map<String, dynamic> map, {required String docId}) {
    final id = (map['id'] as String?)?.isNotEmpty == true
        ? map['id'] as String
        : docId;

    final rawTs = map['timestamp'];
    final DateTime timestamp;
    if (rawTs is Timestamp) {
      timestamp = rawTs.toDate();
    } else if (rawTs is String) {
      timestamp = DateTime.tryParse(rawTs) ?? _epoch();
    } else {
      timestamp = _epoch();
    }

    final label = map['label'] as String? ?? 'Snack';
    final withinWindow = map['withinCircadianWindow'] as bool? ?? false;

    final source = _parseSource(map['source'] as String?);

    final log = NutritionLog(
      id: id,
      timestamp: timestamp,
      label: label,
      withinCircadianWindow: withinWindow,
      calories: _toDouble(map['calories']),
      protein: _toDouble(map['protein']),
      carbs: _toDouble(map['carbs']),
      fat: _toDouble(map['fat']),
      fiber: _toDouble(map['fiber']),
      glycemicIndex: _toInt(map['glycemicIndex']),
      source: source,
    );
    _validate(log);
    return log;
  }

  void _validate(NutritionLog log) {
    // SPEC-62: errores tipados por caso. UI puede pattern-match sobre
    // ValidationError sin parsear strings.
    if (log.id.isEmpty) {
      throw const EmptyField(field: 'NutritionLog.id');
    }
    if (log.label.trim().isEmpty) {
      throw const EmptyField(field: 'NutritionLog.label');
    }
    if (!_kValidLabels.contains(log.label)) {
      throw InvalidValue(
        field: 'NutritionLog.label',
        value: log.label,
        expectedOneOf: _kValidLabels.toList(),
      );
    }
    const tolerance = Duration(seconds: 60);
    final maxAllowed = DateTime.now().add(tolerance);
    if (log.timestamp.isAfter(maxAllowed)) {
      throw FutureTimestamp(
        field: 'NutritionLog.timestamp',
        value: log.timestamp,
        toleranceFromNow: tolerance,
      );
    }
    // Las invariantes >= 0 de macros y rango 0-100 de glycemicIndex se
    // validan en el constructor de NutritionLog. No hace falta repetirlas.
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }

  static NutritionLogSource _parseSource(String? raw) {
    return NutritionLogSource.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => NutritionLogSource.userInput,
    );
  }

  static DateTime _epoch() =>
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
}
