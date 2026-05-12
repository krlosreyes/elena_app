// SPEC-73: UserProfileValidator — invariante de "perfil completo".
//
// Antes de SPEC-73, los campos age/gender/weight/height eran `required`
// a nivel de Freezed. Esa decisión rompía la deserialización para
// documentos MR con shape distinto. SPEC-73 los movió a `@Default`,
// trasladando el invariante de "perfil completo" desde el modelo al
// dominio.
//
// Este validador es la ÚNICA fuente de verdad para decidir si un
// UserModel está "completo" en el sentido funcional de la app.
// Lo consume:
//   - el repositorio Auth (para clasificar AppProfileStatus)
//   - el router (vía AppAccount.profileStatus)
//   - el OnboardingController (para decidir cuándo marcar al usuario
//     como onboarded)
//   - eventualmente el imrProvider (para no calcular IMR si el perfil
//     está incompleto — ver SPEC-47 §Out of Scope)

import 'package:elena_app/src/shared/domain/models/user_model.dart';

class UserProfileValidator {
  const UserProfileValidator._();

  /// Verdadero si el UserModel cumple los invariantes mínimos para que
  /// la app pueda calcular IMR y permitir el flujo de dashboard.
  ///
  /// Invariantes (alineados con `isUserOnboarded` previo, ahora
  /// centralizados):
  ///   - age > 0
  ///   - weight > 0
  ///   - height > 0
  ///   - profile != null (CircadianProfile presente)
  static bool isComplete(UserModel user) {
    return user.age > 0 &&
        user.weight > 0 &&
        user.height > 0 &&
        user.profile != null;
  }

  /// Verdadero si un mapa crudo de Firestore satisface los invariantes
  /// mínimos. Usado por el repositorio Auth ANTES de intentar parsear
  /// el documento a UserModel — evita tener que construir un UserModel
  /// parcial sólo para clasificarlo.
  static bool isCompleteFromRaw(Map<String, dynamic> raw) {
    final age = (raw['age'] as num?)?.toInt() ?? 0;
    final weight = (raw['weight'] as num?)?.toDouble() ?? 0.0;
    final height = (raw['height'] as num?)?.toDouble() ?? 0.0;
    final hasProfileMap = raw['profile'] is Map;
    return age > 0 && weight > 0 && height > 0 && hasProfileMap;
  }
}
