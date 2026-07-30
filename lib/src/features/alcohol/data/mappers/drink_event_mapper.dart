// SPEC-261: traductor entre Map<String, dynamic> y DrinkEvent.
//
// Espejo de HydrationLogMapper (SPEC-50.1). Valida invariantes (SPEC-62)
// antes de serializar: gramos > 0, volumen > 0, timestamp no futuro más
// allá de la tolerancia.

import 'package:cloud_firestore/cloud_firestore.dart';

import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog_item.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_event.dart';

class DrinkEventMapper {
  const DrinkEventMapper();

  Map<String, dynamic> toMap(DrinkEvent event) {
    _validate(event);
    return {
      'itemId': event.itemId,
      'name': event.name,
      'category': event.category.name,
      'volumeMl': event.volumeMl,
      'grams': event.grams,
      'timestamp': Timestamp.fromDate(event.timestamp),
      'waterChaser': event.waterChaser,
      'serverAt': FieldValue.serverTimestamp(),
    };
  }

  DrinkEvent fromMap(Map<String, dynamic> map) {
    return DrinkEvent(
      itemId: (map['itemId'] as String?) ?? 'custom',
      name: (map['name'] as String?) ?? 'Bebida',
      category: _categoryFrom(map['category']),
      volumeMl: _toDouble(map['volumeMl']) ?? 0.0,
      grams: _toDouble(map['grams']) ?? 0.0,
      timestamp: _toDateTime(map['timestamp']),
      waterChaser: map['waterChaser'] == true,
    );
  }

  void _validate(DrinkEvent event) {
    if (event.grams <= 0) {
      throw OutOfRange(
        field: 'DrinkEvent.grams',
        value: event.grams,
        min: 0.0001,
        max: double.infinity,
      );
    }
    if (event.volumeMl <= 0) {
      throw OutOfRange(
        field: 'DrinkEvent.volumeMl',
        value: event.volumeMl,
        min: 0.0001,
        max: double.infinity,
      );
    }
    const tolerance = Duration(seconds: 60);
    final maxAllowed = DateTime.now().add(tolerance);
    if (event.timestamp.isAfter(maxAllowed)) {
      throw FutureTimestamp(
        field: 'DrinkEvent.timestamp',
        value: event.timestamp,
        toleranceFromNow: tolerance,
      );
    }
  }

  static DrinkCategory _categoryFrom(dynamic v) {
    if (v is String) {
      for (final c in DrinkCategory.values) {
        if (c.name == v) return c;
      }
    }
    return DrinkCategory.destilado;
  }

  static double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static DateTime _toDateTime(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) {
      return DateTime.tryParse(v) ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
    }
    return DateTime.fromMillisecondsSinceEpoch(0, isUtc: true);
  }
}
