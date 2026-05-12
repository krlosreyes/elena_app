// SPEC-73: AppAccount — contrato de identidad post-autenticación.
//
// AppAccount viaja entre data (FirebaseAuthRepository) y application
// (AuthController, GoRouter). Representa el estado de un usuario que
// Firebase Auth ya validó, e indica si el documento `users/{uid}` está:
//   - ausente (NEW_PROFILE)              → onboarding completo
//   - presente pero incompleto (PARTIAL) → onboarding con datos preservados
//   - presente y completo (COMPLETE)     → dashboard directo
//
// Esto reemplaza la asunción anterior — que cualquier credencial válida
// de Firebase Auth implicaba un doc `users/{uid}` con shape estricto de
// UserModel — y desbloquea el flujo de usuarios provenientes de
// metamorfosisreal.com cuya BD ya está unificada a nivel Firebase Auth
// pero NO a nivel de shape del perfil app.
//
// rawProfile preserva el shape original del documento Firestore para
// que el OnboardingController pueda hacer `merge` y no destruya los
// campos MR (subscription, purchases, programs, etc.).
//
// Decisión técnica: AppAccount usa Equatable en lugar de Freezed para
// evitar dependencia de `build_runner` en un cambio de plumbing de
// identidad. Si en el futuro AppAccount necesita serialización JSON o
// copyWith más complejo, se migra a Freezed con su propia SPEC.

import 'package:equatable/equatable.dart';

enum AppProfileStatus {
  /// No existe documento `users/{uid}` en Firestore.
  newProfile,

  /// Existe documento pero no cumple los invariantes mínimos de UserModel
  /// (age > 0 && weight > 0 && height > 0 && profile != null).
  /// Caso típico: usuario MR cuyo doc tiene shape `{name, email, subscription}`.
  partialProfile,

  /// Documento existe y cumple los invariantes mínimos de UserModel.
  completeProfile,
}

class AppAccount extends Equatable {
  final String uid;
  final String email;
  final String? displayName;
  final AppProfileStatus profileStatus;

  /// Documento crudo de Firestore tal como vino, sin coerción a UserModel.
  /// Se preserva para que OnboardingController haga `merge` y no pierda
  /// campos desconocidos del ecosistema MR.
  /// Null sólo si profileStatus == newProfile.
  final Map<String, dynamic>? rawProfile;

  final DateTime? createdAt;

  const AppAccount({
    required this.uid,
    required this.email,
    this.displayName,
    required this.profileStatus,
    this.rawProfile,
    this.createdAt,
  });

  /// Conveniencia para el router: el usuario está listo para `/dashboard`.
  bool get isComplete => profileStatus == AppProfileStatus.completeProfile;

  /// Conveniencia para el router: el usuario debe pasar por `/onboarding`.
  bool get needsOnboarding =>
      profileStatus == AppProfileStatus.newProfile ||
      profileStatus == AppProfileStatus.partialProfile;

  AppAccount copyWith({
    String? uid,
    String? email,
    String? displayName,
    AppProfileStatus? profileStatus,
    Map<String, dynamic>? rawProfile,
    DateTime? createdAt,
  }) {
    return AppAccount(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      profileStatus: profileStatus ?? this.profileStatus,
      rawProfile: rawProfile ?? this.rawProfile,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        uid,
        email,
        displayName,
        profileStatus,
        rawProfile,
        createdAt,
      ];
}
