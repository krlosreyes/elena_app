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
//
// SPEC-84: `isCompleteFromRaw` ahora reconoce DOS contratos para no
// rechazar a usuarios que vienen del sitio web Metamorfosis Real con
// shape canónico (sin campos planos legacy). Un doc es completo si
// satisface el contrato legacy O el contrato canónico. La conversión
// canónico→legacy se hace en `CanonicalToLegacyAdapter`.

import 'package:elena_app/src/features/auth/domain/canonical_to_legacy_adapter.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

class UserProfileValidator {
  const UserProfileValidator._();

  /// Verdadero si el UserModel cumple los invariantes mínimos para que
  /// la app pueda calcular IMR y permitir el flujo de dashboard.
  ///
  /// Invariantes:
  ///   - age > 0
  ///   - weight > 0
  ///   - height > 0
  ///   - profile != null (CircadianProfile presente)
  static bool isComplete(UserModel user) {
    return user.age > 0 && user.weight > 0 && user.height > 0;
  }

  /// SPEC-84: verdadero si un mapa crudo de Firestore satisface los
  /// invariantes mínimos. Acepta dos shapes:
  ///   1. Legacy puro (planos `age, weight, height, profile`).
  ///   2. Canónico puro (`bio.heightCm/weightKg/bodyFatPct` +
  ///      birthDate/birthYear + profile con los 4 horarios).
  ///   3. Mezclado (campos plano + bio.* coexistiendo): basta con que
  ///      al combinar ambos shapes se satisfagan los invariantes
  ///      legacy.
  static bool isCompleteFromRaw(Map<String, dynamic> raw) {
    // Combinamos shape legacy con campos derivados del canónico.
    // El legacy gana cuando hay duplicidad (el doc lo escribió con
    // intención reciente).
    final fromCanonical = CanonicalToLegacyAdapter.deriveLegacyFields(raw);
    final merged = <String, dynamic>{...fromCanonical, ...raw};

    final age = (merged['age'] as num?)?.toInt() ?? 0;
    final weight = (merged['weight'] as num?)?.toDouble() ?? 0.0;
    final height = (merged['height'] as num?)?.toDouble() ?? 0.0;
    final hasProfileMap = merged['profile'] is Map;
    return age > 0 && weight > 0 && height > 0 && hasProfileMap;
  }
}
