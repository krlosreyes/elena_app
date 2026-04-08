import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../core/converters/timestamp_converter.dart';

part 'set_log.freezed.dart';
part 'set_log.g.dart';

// ═══════════════════════════════════════════════════════════════════════════════
// SET LOG — Individual set record
// Firestore path: users/{uid}/weekly_routines/{weekId}/set_logs/{setLogId}
// ═══════════════════════════════════════════════════════════════════════════════

@freezed
sealed class SetLog with _$SetLog {
  const factory SetLog({
    @Default('') String id,
    required String exerciseId,
    required int dayIndex,
    required int setNumber,
    required int reps,
    @Default(0.0) double weightKg,
    @Default(5) int rpe,
    @TimestampConverter() required DateTime loggedAt,
  }) = _SetLog;

  factory SetLog.fromJson(Map<String, dynamic> json) => _$SetLogFromJson(json);
}
