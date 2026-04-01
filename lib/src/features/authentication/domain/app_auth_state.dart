import 'package:firebase_auth/firebase_auth.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

enum AuthStatus {
  initial,
  unauthenticated,
  unregistered, // Authenticated in Firebase but no Firestore profile
  authenticatedWithProfile,
}

class AppAuthState {
  final AuthStatus status;
  final User? user;
  final UserModel? profile;

  const AppAuthState({
    required this.status,
    this.user,
    this.profile,
  });

  factory AppAuthState.initial() =>
      const AppAuthState(status: AuthStatus.initial);

  factory AppAuthState.unauthenticated() =>
      const AppAuthState(status: AuthStatus.unauthenticated);

  factory AppAuthState.unregistered(User user) => AppAuthState(
        status: AuthStatus.unregistered,
        user: user,
      );

  factory AppAuthState.authenticated(User user, UserModel profile) =>
      AppAuthState(
        status: AuthStatus.authenticatedWithProfile,
        user: user,
        profile: profile,
      );

  bool get isLoading => status == AuthStatus.initial;
  bool get isAuthenticated => status == AuthStatus.authenticatedWithProfile;
}
