// SPEC-73: providers del feature auth.
//
// authStateProvider pasa de StreamProvider<UserModel?> a
// StreamProvider<AppAccount?>. Es el cambio que destraba a los
// usuarios provenientes de metamorfosisreal.com con shape de doc
// distinto al UserModel estricto.
//
// Consumidores que migraron en este mismo commit:
// - app_router.dart                              → lee profileStatus
// - shared/providers/user_provider.dart          → toma uid de AppAccount
// - features/onboarding/.../onboarding_screen    → toma uid + displayName
// - features/dashboard/.../fasting_notifier      → toma uid

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/domain/app_account.dart';
import 'package:elena_app/src/features/auth/domain/auth_repository.dart';
import 'package:elena_app/src/features/auth/data/firebase_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

final authStateProvider = StreamProvider<AppAccount?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});
