import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'calendar_state_provider.g.dart';

@riverpod
class CalendarState extends _$CalendarState {
  @override
  DateTime build() {
    return DateTime.now();
  }

  void selectDate(DateTime date) {
    state = date;
  }

  void nextWeek() {
    state = state.add(const Duration(days: 7));
  }

  void prevWeek() {
    state = state.subtract(const Duration(days: 7));
  }
  
  bool get canGoNextWeek {
    final now = DateTime.now();
    final nextWeekLimit = now.add(const Duration(days: 7));
    // Allow going up to 1 week into the future roughly
    return state.isBefore(nextWeekLimit);
  }
}
