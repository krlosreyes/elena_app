import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../health/data/health_repository.dart';
import '../../authentication/data/auth_repository.dart';
import '../../../core/services/notification_service.dart';

class HydrationController extends AutoDisposeAsyncNotifier<void> {
  @override
  Future<void> build() async {
    // Initial state
  }

  Future<void> addWater(int glasses) async {
    final user = ref.read(authRepositoryProvider).currentUser;
    if (user == null) return;

    state = const AsyncLoading();
    state = await AsyncValue.guard(() =>
        ref.read(healthRepositoryProvider).logHydration(user.uid, glasses));
  }

  Future<void> toggleHydraReminder(bool active) async {
    ref.read(hydraReminderProtocolProvider.notifier).state = active;
    if (active) {
      await NotificationService.scheduleHydrationReminder(
          const Duration(minutes: 30));
    } else {
      await NotificationService.cancelHydrationReminder();
    }
  }
}

final hydraReminderProtocolProvider = StateProvider<bool>((ref) => false);

final hydrationControllerProvider =
    AsyncNotifierProvider.autoDispose<HydrationController, void>(() {
  return HydrationController();
});
