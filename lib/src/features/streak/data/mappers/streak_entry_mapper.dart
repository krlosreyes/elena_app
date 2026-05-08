// SPEC-50.3: traductor entre Map<String, dynamic> y StreakEntry.
//
// StreakEntry tiene `toJson`/`fromJson` manuales (no Freezed). El
// mapper delega serialización al modelo y solo añade validaciones
// SPEC-62 antes de escribir.

import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';

/// Regex laxo para validar el formato `yyyy-MM-dd` que usa StreakEntry
/// como clave primaria.
final _kDateKeyRegex = RegExp(r'^\d{4}-\d{2}-\d{2}$');

class StreakEntryMapper {
  const StreakEntryMapper();

  Map<String, dynamic> toMap(StreakEntry entry) {
    _validate(entry);
    return entry.toJson();
  }

  StreakEntry fromMap(Map<String, dynamic> map) {
    return StreakEntry.fromJson(map);
  }

  void _validate(StreakEntry entry) {
    if (entry.date.isEmpty) {
      throw const EmptyField(field: 'StreakEntry.date');
    }
    if (!_kDateKeyRegex.hasMatch(entry.date)) {
      throw InvalidValue(
        field: 'StreakEntry.date',
        value: entry.date,
      );
    }
    if (entry.imrScore < 0 || entry.imrScore > 100) {
      throw OutOfRange(
        field: 'StreakEntry.imrScore',
        value: entry.imrScore,
        min: 0,
        max: 100,
      );
    }
  }
}
