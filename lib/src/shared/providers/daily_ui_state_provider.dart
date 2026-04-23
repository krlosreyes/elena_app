import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/daily_ui_state.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

final dailyUIStateProvider = StateNotifierProvider<DailyUIStateNotifier, DailyUIState>((ref) {
  return DailyUIStateNotifier(ref);
});

class DailyUIStateNotifier extends StateNotifier<DailyUIState> {
  final Ref _ref;
  String? _userId;

  DailyUIStateNotifier(this._ref) : super(DailyUIState.initial()) {
    _init();
  }

  void _init() {
    _ref.listen(currentUserStreamProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          _userId = user.uid;
          _loadState();
        } else {
          _userId = null;
          state = DailyUIState.initial();
        }
      });
    }, fireImmediately: true);
  }

  Future<void> _loadState() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      final loadedState = await _ref.read(userRepositoryProvider).getDailyUIState(uid);
      if (mounted) {
        state = loadedState;
      }
    } catch (e) {
      // Ignorar, usar inicial
    }
  }

  Future<void> markFastingStarted() async {
    state = state.copyWith(fastingStarted: true);
    await _saveState();
  }

  Future<void> markNutritionCompletedShown() async {
    state = state.copyWith(nutritionCompletedShown: true);
    await _saveState();
  }

  Future<void> markFastingCompletedShown() async {
    state = state.copyWith(fastingCompletedShown: true);
    await _saveState();
  }

  Future<void> reset() async {
    state = DailyUIState.initial();
    await _saveState();
  }

  Future<void> _saveState() async {
    final uid = _userId;
    if (uid == null) return;
    try {
      await _ref.read(userRepositoryProvider).saveDailyUIState(uid, state);
    } catch (e) {
      // Log error
    }
  }
}
