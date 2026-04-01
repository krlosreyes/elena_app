import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/data/user_repository.dart';
import '../../profile/application/user_controller.dart';
import '../../fasting/data/fasting_repository.dart';


class TransitionState {
  final DateTime? lastFirstMealTime;
  final String? lastBreakingFastOption;

  const TransitionState({
    this.lastFirstMealTime,
    this.lastBreakingFastOption,
  });

  TransitionState copyWith({
    DateTime? lastFirstMealTime,
    String? lastBreakingFastOption,
  }) {
    return TransitionState(
      lastFirstMealTime: lastFirstMealTime ?? this.lastFirstMealTime,
      lastBreakingFastOption:
          lastBreakingFastOption ?? this.lastBreakingFastOption,
    );
  }
}

class TransitionController extends StateNotifier<TransitionState> {
  final UserRepository _repository;
  final FastingRepository _fastingRepository;
  final String _uid;

  TransitionController(this._repository, this._fastingRepository, this._uid, TransitionState initial)
      : super(initial);

  Future<void> recordFirstMeal(String option, DateTime time) async {
    await _repository.recordFirstMeal(_uid, option, time);
    await _fastingRepository.markInitialMealLogged(_uid);
    // State will be updated by the stream sync in the provider
  }

  void updateFromRaw(Map<String, dynamic>? data) {
    if (data == null) return;

    final mealTimeData = data['lastFirstMealTime'];
    DateTime? mealTime;
    if (mealTimeData is Timestamp) {
      mealTime = mealTimeData.toDate();
    } else if (mealTimeData is String) {
      mealTime = DateTime.tryParse(mealTimeData);
    }

    final option = data['lastBreakingFastOption'] as String?;

    if (state.lastFirstMealTime != mealTime ||
        state.lastBreakingFastOption != option) {
      state = TransitionState(
        lastFirstMealTime: mealTime,
        lastBreakingFastOption: option,
      );
    }
  }
}

// Global provider for transition data
final transitionProvider =
    StateNotifierProvider<TransitionController, TransitionState>((ref) {
  final user = ref.watch(currentUserStreamProvider).value;
  final repository = ref.watch(userRepositoryProvider);
  final fastingRepository = ref.watch(fastingRepositoryProvider);

  if (user == null) {
    return TransitionController(repository, fastingRepository, '', const TransitionState());
  }

  final controller =
      TransitionController(repository, fastingRepository, user.uid, const TransitionState());

  // Sync with raw document to get fields not in UserModel
  final subscription = repository.watchUserRaw(user.uid).listen((data) {
    controller.updateFromRaw(data);
  });

  ref.onDispose(() => subscription.cancel());

  return controller;
});
