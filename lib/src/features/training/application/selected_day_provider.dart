import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_day_provider.g.dart';

@riverpod
class SelectedDay extends _$SelectedDay {
  @override
  int build() {
    // Initial state is the current day of the week (1=Mon, 7=Sun)
    return DateTime.now().weekday;
  }

  void selectDay(int dayIndex) {
    if (dayIndex >= 1 && dayIndex <= 7) {
      state = dayIndex;
    }
  }
}
