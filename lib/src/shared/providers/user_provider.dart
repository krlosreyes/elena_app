import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/domain/services/user_repository.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';

/// Fuente de verdad única para el usuario en todo el ecosistema
final currentUserStreamProvider = StreamProvider<UserModel?>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  final authState = ref.watch(authStateProvider);
  final uid = authState.value?.id;
  
  if (uid == null) return Stream.value(null);
  return repository.watchUser(uid);
});