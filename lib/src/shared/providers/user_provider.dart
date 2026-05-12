import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/data/user_profile_repository_impl.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';

/// Fuente de verdad única para el usuario en todo el ecosistema.
///
/// SPEC-50.5: consume `userProfileRepositoryProvider` (antes
/// `userRepositoryProvider`). El método cambia: `watchUser` → `watchProfile`.
// SPEC-73: `authState.value` ahora es `AppAccount?` (antes `UserModel?`).
// El uid vive en `.uid` (antes `.id`). Sólo emite el UserModel cuando el
// perfil está COMPLETE — para PARTIAL/NEW el router ya está mandando a
// onboarding, y consumir un UserModel parcial corrompería el cálculo
// de IMR (validado por UserProfileValidator.isComplete).
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final repository = ref.watch(userProfileRepositoryProvider);
  final account = ref.watch(authStateProvider).value;

  if (account == null) return Stream.value(null);
  if (!account.isComplete) return Stream.value(null);
  return repository.watchProfile(account.uid);
});