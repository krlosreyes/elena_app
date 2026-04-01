import 'package:freezed_annotation/freezed_annotation.dart';
import '../../../core/converters/timestamp_converter.dart';

part 'daily_log.freezed.dart';
part 'daily_log.g.dart';

@freezed
class DailyLog with _$DailyLog {
  const factory DailyLog({
    required String id, // YYYY-MM-DD
    @Default(0) int waterGlasses,
    @Default(0) int calories,
    @Default(0) int proteinGrams,
    @Default(0) int carbsGrams,
    @Default(0) int fatGrams,
    @Default(0) int exerciseMinutes,
    @Default(0) int sleepMinutes,
    @OptionalTimestampConverter() DateTime? fastingStartTime,
    @OptionalTimestampConverter() DateTime? fastingEndTime,
    @Default(0.0) double mtiScore,
    @Default([]) List<Map<String, dynamic>> mealEntries,
    @Default([]) List<Map<String, dynamic>> exerciseEntries,
  }) = _DailyLog;

  factory DailyLog.fromJson(Map<String, dynamic> json) =>
      _$DailyLogFromJson(json);
}
