// SPEC-50.5: traductor entre Map<String, dynamic> y UserModel.
//
// UserModel es Freezed con json_serializable. El mapper delega
// serialización al modelo y solo añade validaciones SPEC-62.
//
// SPEC-82: además del shape legacy plano (toJson), produce campos
// canónicos agrupados (`displayName, genderCanonical, bio, habits,
// meta`) que el sitio web Metamorfosis Real consume. Ambos shapes
// coexisten en el mismo doc `users/{uid}`. La app sigue leyendo el
// shape legacy via Freezed (ignora keys desconocidas como `bio`,
// `habits`, `imr`, `meta`); el sitio lee el canónico.

import 'package:elena_app/src/core/engine/score_engine.dart';
import 'package:elena_app/src/core/errors/validation_error.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

class UserProfileMapper {
  const UserProfileMapper();

  /// SPEC-82: produce el doc completo a persistir en Firestore.
  /// Mezcla shape legacy + shape canónico.
  Map<String, dynamic> toMap(UserModel user) {
    _validate(user);
    final legacy = user.toJson();
    final canonical = userToCanonicalMirror(user);
    return {...legacy, ...canonical};
  }

  UserModel fromMap(Map<String, dynamic> map) {
    return UserModel.fromJson(map);
  }

  void _validate(UserModel user) {
    if (user.id.isEmpty) {
      throw const EmptyField(field: 'UserModel.id');
    }
    if (user.age < 0 || user.age > 130) {
      throw OutOfRange(
        field: 'UserModel.age',
        value: user.age,
        min: 0,
        max: 130,
      );
    }
    if (user.weight <= 0) {
      throw OutOfRange(
        field: 'UserModel.weight',
        value: user.weight,
        min: 0.1,
        max: 500,
      );
    }
    if (user.height <= 0) {
      throw OutOfRange(
        field: 'UserModel.height',
        value: user.height,
        min: 30,
        max: 250,
      );
    }
    // SPEC-92: bodyFatPercentage es nullable. Solo validamos el rango
    // si hay un valor — null significa "sin medidas suficientes" y el
    // ScoreEngine cae a fallback poblacional con confidence BAJA.
    final bf = user.bodyFatPercentage;
    if (bf != null && (bf < 0 || bf > 70)) {
      throw OutOfRange(
        field: 'UserModel.bodyFatPercentage',
        value: bf,
        min: 0,
        max: 70,
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────
// SPEC-82: helpers puros para el shape canónico.
// ─────────────────────────────────────────────────────────────────────

/// Produce los campos canónicos derivados del UserModel para que el
/// sitio web Metamorfosis Real pueda consumirlos. Coexiste con el
/// shape legacy en el mismo doc `users/{uid}`.
///
/// Top-level: `displayName, genderCanonical, bio, habits, meta`.
/// Importante: NO sobrescribe `gender` (legacy `'M'|'F'`) — el
/// canónico es `genderCanonical: 'male'|'female'` como campo aparte.
Map<String, dynamic> userToCanonicalMirror(UserModel user) {
  final String nowIso = DateTime.now().toUtc().toIso8601String();
  final String genderCanonical =
      user.gender.toUpperCase() == 'M' ? 'male' : 'female';
  final int? fastingHours = _parseFastingProtocol(user.fastingProtocol);
  final double? lastMealHour = _toHourFloat(user.profile.lastMealGoal);

  return <String, dynamic>{
    'displayName': user.name,
    'genderCanonical': genderCanonical,
    'bio': <String, dynamic>{
      'heightCm': user.height,
      'weightKg': user.weight,
      'waistCm': user.waistCircumference,
      'neckCm': user.neckCircumference,
      'hipCm': null,
      // SPEC-92: si bodyFat es null, el sitio MR debe ver null también
      // — no inventar 20% poblacional como hacíamos antes.
      'bodyFatPct': user.bodyFatPercentage,
      'leanMassPct': user.bodyFatPercentage == null
          ? null
          : 100.0 - user.bodyFatPercentage!,
      'updatedAt': nowIso,
    },
    'habits': <String, dynamic>{
      'fastingHours': fastingHours,
      'dinnerHour': lastMealHour,
      'lastMealHour': lastMealHour,
      'exerciseMinutesPerDay': user.exerciseGoalMinutes,
      'sleepQuality': null,
      'hydrationLitresPerDay': null,
      // SPEC-137: el sistema nervioso vive bajo habits.nervousSystem.*
      // en el shape canónico para que el sitio MR pueda leerlo si
      // quiere personalizar contenido. La app sigue leyéndolo del
      // shape legacy plano.
      'nervousSystem': <String, dynamic>{
        'classification': user.nervousSystem,
        'declared': user.nervousSystemDeclared,
        'score': user.nervousSystemScore,
      },
      'source': 'self_report',
      'updatedAt': nowIso,
    },
    'onboarding': <String, dynamic>{
      'protocolWarningAccepted': user.protocolWarningAccepted,
    },
    'meta': <String, dynamic>{
      'schemaVersion': 1,
      'createdAt': nowIso,
    },
  };
}

/// Convierte un IMRv2Result al shape canónico que el sitio web lee en
/// `users/{uid}.imr.current`.
///
/// SPEC-141 (2026-06-05): si el resultado tiene `longitudinalScore`
/// poblado (proveniente de `calculateLongitudinalIMR`), el shape pasa
/// a schemaVersion 2 con:
///   - `imrScore`  → el longitudinal (lo que el sitio renderiza)
///   - `legacyDailyScore` → el diario, ventana de transición 30d
///   - `subscores` → desglose del longitudinal (estructura, behavior,
///     adherence, coherence)
///   - `meta.schemaVersion = 2` y `scoreVariant = 'longitudinal'`
///
/// Si NO hay `longitudinalScore` (call desde `calculateIMR` legacy o
/// `calculateBaseline`), se mantiene schemaVersion 1 — el sitio sigue
/// recibiendo el shape antiguo sin breaking change durante la
/// transición.
Map<String, dynamic> imrToCanonicalMap(IMRv2Result imr) {
  final base = <String, dynamic>{
    'imrScore': imr.totalScore,
    'label': imr.zone,
    'blocks': <String, double>{
      'E': imr.structureScore,
      'M': imr.metabolicScore,
      'C': imr.behaviorScore,
    },
    'ica': imr.ica,
    'imc': imr.imc,
    'tmb': imr.tmb,
    'metabolicAge': imr.metabolicAge,
    'ffmi': imr.ffmi,
    'whtr': imr.whtr,
  };

  // SPEC-141: si hay snapshot longitudinal, sobreescribir `imrScore`
  // con el longitudinal y exponer el diario como `legacyDailyScore`.
  // El sitio Astro Metamorfosis Real renderiza `imrScore` directamente.
  final longScore = imr.longitudinalScore;
  if (longScore != null) {
    base['imrScore'] = longScore;
    base['legacyDailyScore'] = imr.totalScore;
    base['scoreVariant'] = 'longitudinal';
    base['schemaVersion'] = 2;
    base['subscores'] = <String, double>{
      'structure': imr.structureScore,
      'behaviorTrend': imr.subscoreBehaviorTrend ?? 0.0,
      'adherence': imr.subscoreAdherence ?? 0.0,
      'coherence': imr.subscoreCoherence ?? 0.0,
    };
  } else {
    base['schemaVersion'] = 1;
    base['scoreVariant'] = 'daily';
  }

  return base;
}

/// Convierte `'Ninguno' | '16:8' | '18:6' | '20:4'` a horas de ayuno.
/// Retorna null si el protocolo no se reconoce (no inventamos).
int? _parseFastingProtocol(String protocol) {
  switch (protocol) {
    case 'Ninguno':
      return 0;
    case '16:8':
      return 16;
    case '18:6':
      return 18;
    case '20:4':
      return 20;
    default:
      return null;
  }
}

/// Convierte un DateTime a hora float (ej. 21:30 → 21.5).
/// Retorna null si el DateTime es null.
double? _toHourFloat(DateTime? dt) {
  if (dt == null) return null;
  return dt.hour + dt.minute / 60.0;
}
