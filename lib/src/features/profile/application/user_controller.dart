import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/user_repository.dart';
import '../domain/user_model.dart';
import '../../plan/domain/health_plan.dart';
import '../../authentication/application/auth_controller.dart';

class UserController extends StateNotifier<void> {
  final UserRepository _repository;

  UserController(this._repository) : super(null);

  Future<UserModel?> getUser(String uid) {
    return _repository.getUser(uid);
  }

  Future<void> saveUser(UserModel user) {
    return _repository.saveUser(user);
  }

  Future<void> saveHealthPlan(String uid, HealthPlan plan) {
    return _repository.saveHealthPlan(uid, plan);
  }
}

final userControllerProvider =
    StateNotifierProvider<UserController, void>((ref) {
  return UserController(ref.watch(userRepositoryProvider));
});

/// Reactive stream of the currently signed-in user's profile.
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      return ref.watch(userRepositoryProvider).watchUser(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (_, __) => Stream.value(null),
  );
});
