import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';

/// Fuente de verdad única para el usuario en todo el ecosistema.
///
/// SPEC-50.5: consume `userProfileRepositoryProvider` (antes
/// `userRepositoryProvider`). El método cambia: `watchUser` → `watchProfile`.
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.id;

  if (uid == null) return Stream.value(null);
  return repository.watchProfile(uid);
});