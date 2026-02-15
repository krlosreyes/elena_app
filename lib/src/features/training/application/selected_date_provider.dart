import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'selected_date_provider.g.dart';

@riverpod
class SelectedDate extends _$SelectedDate {
  @override
  DateTime build() {
    return DateTime.now(); // Defaults to today
  }

  void selectDate(DateTime date) {
    state = date;
  }
}
