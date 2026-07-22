// SPEC-50.4: traductor entre Map<String, dynamic> y FastingInterval.
//
// FastingInterval es Freezed con `@TimestampConverter()` y
// `@OptionalTimestampConverter()` aplicados (SPEC-72.5). El mapper
// delega serialización al modelo y solo añade validaciones SPEC-62.

import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart'
    show FastingInterval;

class FastingIntervalMapper {
  const FastingIntervalMapper();

  Map<String, dynamic> toMap(FastingInterval interval) {
    _validate(interval);
    return interval.toJson();
  }

  FastingInterval fromMap(Map<String, dynamic> map) {
    return FastingInterval.fromJson(map);
  }

  void _validate(FastingInterval interval) {
    if (interval.id.isEmpty) {
      throw const EmptyField(field: 'FastingInterval.id');
    }
    if (interval.userId.isEmpty) {
      throw const EmptyField(field: 'FastingInterval.userId');
    }
    if (interval.endTime != null &&
        interval.endTime!.isBefore(interval.startTime)) {
      throw InvalidValue(
        field: 'FastingInterval.endTime',
        value: interval.endTime!.toIso8601String(),
      );
    }
    const tolerance = Duration(seconds: 60);
    final maxAllowed = DateTime.now().add(tolerance);
    if (interval.startTime.isAfter(maxAllowed)) {
      throw FutureTimestamp(
        field: 'FastingInterval.startTime',
        value: interval.startTime,
        toleranceFromNow: tolerance,
      );
    }
  }
}
