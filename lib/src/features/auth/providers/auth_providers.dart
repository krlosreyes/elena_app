import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/auth/domain/auth_repository.dart';
import 'package:elena_app/src/features/auth/data/firebase_auth_repository.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

// Expone la implementación concreta del repositorio
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository();
});

// Stream que monitorea el estado de la sesión en tiempo real
final authStateProvider = StreamProvider<UserModel?>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});