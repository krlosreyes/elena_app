import 'package:freezed_annotation/freezed_annotation.dart';

part 'fasting_session.freezed.dart';
part 'fasting_session.g.dart';

@freezed
class FastingSession with _$FastingSession {
  const factory FastingSession({
    required String uid,
    required DateTime startTime,
    DateTime? endTime,
    required int plannedDurationHours,
    @Default(false) bool isCompleted,
  }) = _FastingSession;

  factory FastingSession.fromJson(Map<String, dynamic> json) =>
      _$FastingSessionFromJson(json);
}
