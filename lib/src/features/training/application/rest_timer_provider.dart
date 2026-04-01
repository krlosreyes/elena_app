import 'dart:async';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'rest_timer_provider.g.dart';

@riverpod
class RestTimer extends _$RestTimer {
  Timer? _timer;

  @override
  int build() {
    // Audit: Proper disposal to prevent memory leaks
    ref.onDispose(() => _timer?.cancel());
    return 0;
  }

  void startTimer(int seconds) {
    // Cancel existing timer
    _timer?.cancel();

    // Set initial state
    state = seconds;

    // Start periodic timer
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (state > 0) {
        state = state - 1;
      } else {
        timer.cancel();
      }
    });
  }

  void stopTimer() {
    _timer?.cancel();
    state = 0;
  }
}
