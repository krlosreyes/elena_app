import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/health/data/health_repository.dart';
import 'package:elena_app/src/features/authentication/application/auth_controller.dart';

class HealthService {
  final Ref _ref;

  HealthService(this._ref);

  Future<void> logWater(int glasses) async {
    final user = _ref.read(authControllerProvider.notifier).currentUser;
    if (user == null) return;

    // Brain Validation (Sanity Check)
    final validatedGlasses = glasses.clamp(1, 10);

    await _ref
        .read(healthRepositoryProvider)
        .logHydration(user.uid, validatedGlasses);
  }

  Future<void> logMeal({
    required String name,
    required int calories,
    required double protein,
    required double carbs,
    required double fats,
  }) async {
    final user = _ref.read(authControllerProvider.notifier).currentUser;
    if (user == null) return;

    final entry = {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fats': fats,
    };

    await _ref.read(healthRepositoryProvider).logNutrition(user.uid, {
      'name': name,
      ...entry,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> logExercise({
    required String type,
    required int minutes,
    required String intensity,
  }) async {
    final user = _ref.read(authControllerProvider.notifier).currentUser;
    if (user == null) return;

    final entry = {
      'type': type,
      'minutes': minutes,
      'intensity': intensity,
      'timestamp': DateTime.now().toIso8601String(),
    };

    await _ref.read(healthRepositoryProvider).logExercise(user.uid, entry);
  }

  Future<void> startFast() async {
    final user = _ref.read(authControllerProvider.notifier).currentUser;
    if (user == null) return;
    await _ref
        .read(healthRepositoryProvider)
        .logFasting(user.uid, start: DateTime.now());
  }

  Future<void> endFast() async {
    final user = _ref.read(authControllerProvider.notifier).currentUser;
    if (user == null) return;
    await _ref
        .read(healthRepositoryProvider)
        .logFasting(user.uid, end: DateTime.now());
  }
}

final healthServiceProvider = Provider<HealthService>((ref) {
  return HealthService(ref);
});
