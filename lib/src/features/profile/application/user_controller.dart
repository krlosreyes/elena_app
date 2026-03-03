import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../data/user_repository.dart';
import '../domain/user_model.dart';
import '../../plan/domain/health_plan.dart';

part 'user_controller.g.dart';

@riverpod
class UserController extends _$UserController {
  @override
  void build() {}

  Future<UserModel?> getUser(String uid) {
    return ref.read(userRepositoryProvider).getUser(uid);
  }

  Future<void> saveUser(UserModel user) {
    return ref.read(userRepositoryProvider).saveUser(user);
  }

  Future<void> saveHealthPlan(String uid, HealthPlan plan) {
    return ref.read(userRepositoryProvider).saveHealthPlan(uid, plan);
  }
}

@riverpod
Stream<UserModel?> currentUserStream(Ref ref) {
  return ref.watch(currentUserProvider);
}
