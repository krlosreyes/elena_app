// SPEC-84: adapter inverso del shape canónico al shape legacy.
//
// SPEC-82 ya escribe el shape canónico al doc `users/{uid}` además del
// legacy. Cuando un usuario se registra en el sitio web Metamorfosis
// Real, el doc tiene SOLO el canónico (sin campos planos). Esta clase
// hace el camino inverso: lee el canónico y produce los valores legacy
// que la app espera.
//
// Reglas de diseño:
// - Función pura. Sin IO, sin Riverpod, sin Flutter.
// - Tolerancia total a shape inesperado: campos faltantes o inválidos
//   quedan en null. NUNCA lanza.
// - Las coerciones invierten exactamente las de
//   `user_profile_mapper.dart::userToCanonicalMirror` (SPEC-82).

class CanonicalToLegacyAdapter {
  const CanonicalToLegacyAdapter._();

  /// Recibe un rawProfile que puede tener shape canónico, legacy o
  /// mezclado. Retorna los campos legacy derivados que estaban
  /// presentes en el canónico. NO devuelve campos legacy que ya
  /// estaban planos — el caller decide cómo combinarlos.
  ///
  /// Campos producidos (cuando hay datos canónicos para derivarlos):
  ///   - name              ← displayName
  ///   - gender            ← genderCanonical | gender
  ///   - age               ← derivado de birthDate ISO o birthYear
  ///   - weight            ← bio.weightKg
  ///   - height            ← bio.heightCm
  ///   - waistCircumference← bio.waistCm
  ///   - neckCircumference ← bio.neckCm
  ///   - bodyFatPercentage ← bio.bodyFatPct
  ///   - fastingProtocol   ← inverso de habits.fastingHours
  ///   - exerciseGoalMinutes ← habits.exerciseMinutesPerDay
  ///   - lastMealGoal      ← habits.lastMealHour (float → DateTime)
  ///   - healthDisclaimerAccepted ← raw.healthDisclaimerAccepted
  static Map<String, dynamic> deriveLegacyFields(
    Map<String, dynamic>? raw,
  ) {
    if (raw == null || raw.isEmpty) return const {};

    final result = <String, dynamic>{};
    final bio = raw['bio'];
    final habits = raw['habits'];

    // name ← displayName (si no estaba ya plano).
    final displayName = raw['displayName'];
    if (displayName is String && displayName.trim().isNotEmpty) {
      result['name'] = displayName.trim();
    }

    // gender ← genderCanonical 'male'/'female' → 'M'/'F'.
    final genderCanonical = raw['genderCanonical'];
    if (genderCanonical is String) {
      final norm = genderCanonical.trim().toLowerCase();
      if (norm == 'male') result['gender'] = 'M';
      if (norm == 'female') result['gender'] = 'F';
    }

    // age ← birthDate ISO o birthYear.
    final age = _deriveAge(raw);
    if (age != null) result['age'] = age;

    // Biometría desde bio.*
    if (bio is Map) {
      final bioMap = bio.cast<String, dynamic>();
      final heightCm = _toDouble(bioMap['heightCm']);
      if (heightCm != null) result['height'] = heightCm;
      final weightKg = _toDouble(bioMap['weightKg']);
      if (weightKg != null) result['weight'] = weightKg;
      final waistCm = _toDouble(bioMap['waistCm']);
      if (waistCm != null) result['waistCircumference'] = waistCm;
      final neckCm = _toDouble(bioMap['neckCm']);
      if (neckCm != null) result['neckCircumference'] = neckCm;
      final bodyFatPct = _toDouble(bioMap['bodyFatPct']);
      if (bodyFatPct != null) result['bodyFatPercentage'] = bodyFatPct;
    }

    // Hábitos desde habits.*
    if (habits is Map) {
      final habitsMap = habits.cast<String, dynamic>();
      final fastingProtocol = _hoursToProtocol(habitsMap['fastingHours']);
      if (fastingProtocol != null) {
        result['fastingProtocol'] = fastingProtocol;
      }
      final exerciseMinutes = _toInt(habitsMap['exerciseMinutesPerDay']);
      if (exerciseMinutes != null) {
        result['exerciseGoalMinutes'] = exerciseMinutes;
      }
      final lastMealHour = _toDouble(
        habitsMap['lastMealHour'] ?? habitsMap['dinnerHour'],
      );
      if (lastMealHour != null) {
        result['lastMealGoal'] = _hourFloatToDateTime(lastMealHour);
      }
    }

    // Disclaimer médico (si el sitio lo capturó).
    final disclaimerAccepted = raw['healthDisclaimerAccepted'];
    if (disclaimerAccepted is bool) {
      result['healthDisclaimerAccepted'] = disclaimerAccepted;
    }

    return result;
  }

  // ── helpers privados ──────────────────────────────────────────────

  /// Deriva la edad cronológica desde `birthDate` (ISO) o `birthYear`.
  /// Retorna null si no se puede derivar o el valor es absurdo.
  static int? _deriveAge(Map<String, dynamic> raw) {
    // Si ya viene plano, no lo derivamos (el caller decide).
    final flat = _toInt(raw['age']);
    if (flat != null && flat > 0 && flat < 130) return flat;

    final now = DateTime.now();

    // birthDate ISO 8601 ej. '1985-03-12'.
    final birthDate = raw['birthDate'];
    if (birthDate is String) {
      final parsed = DateTime.tryParse(birthDate);
      if (parsed != null) {
        final years = now.year - parsed.year;
        final hadBirthdayThisYear = (now.month > parsed.month) ||
            (now.month == parsed.month && now.day >= parsed.day);
        final age = hadBirthdayThisYear ? years : years - 1;
        if (age > 0 && age < 130) return age;
      }
    }

    // birthYear directo.
    final birthYear = _toInt(raw['birthYear']) ?? _toInt(raw['yearOfBirth']);
    if (birthYear != null && birthYear >= 1900 && birthYear <= now.year) {
      final age = now.year - birthYear;
      if (age > 0 && age < 130) return age;
    }

    return null;
  }

  /// Inverso de `_parseFastingProtocol` de SPEC-82.
  /// 0 → 'Ninguno', 16 → '16:8', 18 → '18:6', 20 → '20:4'.
  /// Retorna null si no coincide con ningún protocolo conocido.
  static String? _hoursToProtocol(dynamic hours) {
    final h = _toInt(hours);
    if (h == null) return null;
    switch (h) {
      case 0:
        return 'Ninguno';
      case 16:
        return '16:8';
      case 18:
        return '18:6';
      case 20:
        return '20:4';
      default:
        return null;
    }
  }

  /// Inverso de `_toHourFloat` de SPEC-82.
  /// 21.5 → DateTime(hoy, 21, 30). El día queda en local.
  static DateTime _hourFloatToDateTime(double hourFloat) {
    final now = DateTime.now();
    final hour = hourFloat.floor();
    final minutes = ((hourFloat - hour) * 60).round();
    return DateTime(now.year, now.month, now.day, hour, minutes);
  }

  static double? _toDouble(dynamic v) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }

  static int? _toInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.tryParse(v);
    return null;
  }
}
