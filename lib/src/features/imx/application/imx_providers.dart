import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../data/imx_repository.dart';
import '../domain/imx_engine.dart';
import '../../profile/application/user_controller.dart';
import '../../fasting/data/fasting_repository.dart';
import '../../fasting/domain/fasting_session.dart';
import '../../progress/application/progress_controller.dart';
import './imx_controller.dart';

/// Provider for SharedPreferences - MUST be overridden in main.dart
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('SharedPreferences must be initialized in main.dart and overridden');
});

/// Provider for IMX Repository
final imxRepositoryProvider = Provider<ImxRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ImxRepository(prefs: prefs);
});

/// Fasting history stream for IMX calculation
final fastingHistoryStreamProvider = StreamProvider<List<FastingSession>>((ref) {
  final userState = ref.watch(currentUserStreamProvider);
  return userState.when(
    data: (user) {
      if (user == null) return const Stream.empty();
      return ref.watch(fastingRepositoryProvider).getHistoryStream(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (e, st) => const Stream.empty(),
  );
});

/// The global IMX Score Provider (Motor v2)
final imxScoreProvider = AsyncNotifierProvider<ImxController, ImxResult>(() {
  return ImxController();
});

/// Full IMX result helper provider
final currentImxResultProvider = Provider<AsyncValue<ImxResult>>((ref) {
  return ref.watch(imxScoreProvider);
});

/// Simple double score provider for legacy UI
final currentImxProvider = Provider<AsyncValue<double>>((ref) {
  final result = ref.watch(imxScoreProvider);
  return result.when(
    data: (r) => AsyncValue.data(r.total),
    loading: () => const AsyncValue.loading(),
    error: (e, st) => AsyncValue.error(e, st),
  );
});
