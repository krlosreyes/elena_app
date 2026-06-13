// SPEC-63 + SPEC-64: traductor entre Map<String, dynamic> y NutritionLog.
//
// SPEC-64 amplía el formato persistido con macronutrientes nullables. Los
// logs antiguos (escritos antes de SPEC-64) NO tendrán esos campos en el
// payload — el mapper los leerá como null, lo que semánticamente significa
// "no se midió". Backward compatible.
//
// SPEC-137: persiste también `ratio` (MealRatio.persistenceKey, default
// "a2e1" si el log no lo tiene) y `isCheatDay` (bool, default false).
// Logs antiguos pre-SPEC-137 caen al default a2e1 — documentado en
// `MealRatio.fromPersistenceKey(null)` y en NUTRITION_BIBLIOGRAPHY.md
// §13.
//
// SPEC-138: persiste `upfSlots` y `totalSlots` (int? ambos) cuando el
// plato fue armado con PlateBuilder (UI nueva). Logs pre-SPEC-138 los
// leen como null — `% UPF` se ignora hasta que haya histórico nuevo.
// Marco normativo en NUTRITION_BIBLIOGRAPHY.md §16.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
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
    // SPEC-137: ratio e isCheatDay son siempre persistidos (no son
    // nullables en el modelo). Para logs nuevos esto siempre escribe
    // el valor canónico. Para logs antiguos, fromMap inyectó el default
    // al leer y toMap volverá a escribirlo, materializando la migración
    // de manera incremental sin necesidad de un script de backfill.
    map['ratio'] = log.ratio.persistenceKey;
    map['isCheatDay'] = log.isCheatDay;
    // SPEC-138: solo persistir si el log trae los campos. Logs antiguos
    // o registros heurísticos sin composición de plato no escriben estos
    // campos, preservando la semántica null = "sin datos NOVA".
    if (log.upfSlots != null) map['upfSlots'] = log.upfSlots;
    if (log.totalSlots != null) map['totalSlots'] = log.totalSlots;
    // SPEC-BUG6: persiste solo si el log trae ids de alimentos.
    if (log.plateItemIds.isNotEmpty) map['plateItemIds'] = log.plateItemIds;
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

    // SPEC-137: logs antiguos sin campo `ratio` caen al default a2e1
    // vía MealRatio.fromPersistenceKey(null). Logs sin `isCheatDay`
    // caen a false. Ambos son retrocompatibles por diseño.
    final ratio = MealRatio.fromPersistenceKey(map['ratio'] as String?);
    final isCheatDay = map['isCheatDay'] as bool? ?? false;

    // SPEC-138: campos NOVA del plato (null si log pre-138 o sin
    // composición conocida). Defensa contra payload corrupto: si
    // upfSlots > totalSlots, descartamos ambos (caen a null).
    int? upfSlots = _toInt(map['upfSlots']);
    int? totalSlots = _toInt(map['totalSlots']);
    if (upfSlots != null && totalSlots == null) {
      upfSlots = null;
    } else if (upfSlots != null &&
        totalSlots != null &&
        upfSlots > totalSlots) {
      upfSlots = null;
      totalSlots = null;
    }
    if (upfSlots != null && upfSlots < 0) {
      upfSlots = null;
      totalSlots = null;
    }

    // SPEC-BUG6: lista de ids de alimentos para pre-cargar el PlateBuilder
    // al editar. Logs pre-BUG6 no tienen el campo → lista vacía.
    final plateItemIds =
        (map['plateItemIds'] as List<dynamic>?)?.cast<String>() ?? const <String>[];

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
      ratio: ratio,
      isCheatDay: isCheatDay,
      upfSlots: upfSlots,
      totalSlots: totalSlots,
      plateItemIds: plateItemIds,
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
