import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../nutrition/domain/entities/nutrition_plan.dart'; // Reuse TimestampConverter

part 'sleep_log.freezed.dart';
part 'sleep_log.g.dart';

@freezed
sealed class SleepLog with _$SleepLog {
  const factory SleepLog({
    required String id,
    required String userId,
    required double hours,
    @TimestampConverter() required DateTime timestamp,
  }) = _SleepLog;

  factory SleepLog.fromJson(Map<String, dynamic> json) => _$SleepLogFromJson(json);
}
