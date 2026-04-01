import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_repository.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/domain/models/health_plan.dart';
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

  Future<void> updateUserBodyMetrics(String uid, Map<String, double> metrics) {
    return _repository.saveBodyLog(uid, metrics);
  }
}

final userControllerProvider =
    StateNotifierProvider<UserController, void>((ref) {
  return UserController(ref.watch(userRepositoryProvider));
});

// currentUserStreamProvider consolidado aquí
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      debugPrint('👤 [USER STREAM] Watching profile for UID: ${user.uid}');
      return ref.watch(userRepositoryProvider).watchUser(user.uid);
    },
    loading: () => const Stream.empty(),
    error: (e, st) {
      debugPrint('❌ [USER STREAM] Error: $e');
      return Stream.value(null);
    },
  );
});

