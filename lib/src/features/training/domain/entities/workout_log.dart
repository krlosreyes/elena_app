import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'workout_log.freezed.dart';
part 'workout_log.g.dart';

/// Converts Firestore Timestamp ↔ Dart DateTime for Freezed JSON serialization.
class TimestampConverter implements JsonConverter<DateTime, dynamic> {
  const TimestampConverter();

  @override
  DateTime fromJson(dynamic json) {
    if (json is Timestamp) {
      return json.toDate();
    }
    if (json is String) {
      return DateTime.parse(json);
    }
    if (json is int) {
      return DateTime.fromMillisecondsSinceEpoch(json);
    }
    throw ArgumentError('Cannot convert $json (${json.runtimeType}) to DateTime');
  }

  @override
  dynamic toJson(DateTime date) => Timestamp.fromDate(date);
}

@freezed
class WorkoutLog with _$WorkoutLog {
  const WorkoutLog._();

  const factory WorkoutLog({
    required String id,
    required String templateId,
    @TimestampConverter() required DateTime date,
    required int sessionRirScore,
    required List<Map<String, dynamic>> completedExercises, 
    int? durationMinutes,
    int? caloriesBurned,
  }) = _WorkoutLog;

  factory WorkoutLog.fromJson(Map<String, dynamic> json) => _$WorkoutLogFromJson(json);
}
