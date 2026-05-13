// SPEC-74: prefill del onboarding desde campos del ecosistema MR.
//
// AppAccount.rawProfile puede contener datos que MR ya tiene del usuario
// (name, weight, height, gender, etc.). Este helper los extrae con
// validaciones de dominio y los entrega a OnboardingScreen para reducir
// fricción del flujo.
//
// Reglas de diseño:
// - Función pura. Sin IO, sin Riverpod, sin Flutter.
// - Tolerancia total a shape inesperado: campos faltantes o inválidos
//   quedan en null. NUNCA lanza.
// - Validaciones alineadas con UserProfileMapper._validate (rangos
//   numéricos sensatos para no introducir datos basura).
// - Greppable: cada clave consultada en rawProfile aparece como literal
//   en este archivo (RF-74-12).

import 'package:equatable/equatable.dart';

class OnboardingPrefill extends Equatable {
  final String? name;
  final int? birthYear;
  final String? gender; // 'M' | 'F' | 'Otro'
  final double? weight; // kg
  final double? height; // cm
  final double? waistCircumference; // cm
  final double? neckCircumference; // cm
  final int? pantSize;
  final String? shirtSize; // 'S' | 'M' | 'L' | 'XL'

  const OnboardingPrefill({
    this.name,
    this.birthYear,
    this.gender,
    this.weight,
    this.height,
    this.waistCircumference,
    this.neckCircumference,
    this.pantSize,
    this.shirtSize,
  });

  static const empty = OnboardingPrefill();

  /// Factory pura. Lee `rawProfile` y aplica validaciones de dominio.
  /// Si rawProfile es null o vacío, retorna `OnboardingPrefill.empty`.
  ///
  /// Claves consultadas por campo (primer match no-nulo gana):
  ///   name              ← name | displayName | fullName
  ///   birthYear         ← birthYear | yearOfBirth | (derivado de birthDate ISO)
  ///   gender            ← gender | sex (normalizado a 'M' | 'F' | 'Otro')
  ///   weight            ← weight | weightKg
  ///   height            ← height | heightCm
  ///   waistCircumference← waistCircumference | waist | waistCm
  ///   neckCircumference ← neckCircumference | neck | neckCm
  ///   pantSize          ← pantSize | trouserSize
  ///   shirtSize         ← shirtSize | tshirtSize (uppercase, validado)
  factory OnboardingPrefill.from(Map<String, dynamic>? rawProfile) {
    if (rawProfile == null || rawProfile.isEmpty) return empty;

    return OnboardingPrefill(
      name: _firstNonEmptyString(
        rawProfile,
        const ['name', 'displayName', 'fullName'],
      ),
      birthYear: _readBirthYear(rawProfile),
      gender: _readGender(rawProfile),
      weight: _readBoundedDouble(
        rawProfile,
        keys: const ['weight', 'weightKg'],
        min: 20.0,
        max: 500.0,
      ),
      height: _readBoundedDouble(
        rawProfile,
        keys: const ['height', 'heightCm'],
        min: 30.0,
        max: 250.0,
      ),
      waistCircumference: _readBoundedDouble(
        rawProfile,
        keys: const ['waistCircumference', 'waist', 'waistCm'],
        min: 30.0,
        max: 250.0,
      ),
      neckCircumference: _readBoundedDouble(
        rawProfile,
        keys: const ['neckCircumference', 'neck', 'neckCm'],
        min: 20.0,
        max: 80.0,
      ),
      pantSize: _readBoundedInt(
        rawProfile,
        keys: const ['pantSize', 'trouserSize'],
        min: 20,
        max: 60,
      ),
      shirtSize: _readShirtSize(rawProfile),
    );
  }

  /// Cuántos campos del prefill quedaron no-nulos. Usado por la UI
  /// para decidir si renderizar el chip "Datos pre-llenados".
  int get filledCount {
    var n = 0;
    if (name != null) n++;
    if (birthYear != null) n++;
    if (gender != null) n++;
    if (weight != null) n++;
    if (height != null) n++;
    if (waistCircumference != null) n++;
    if (neckCircumference != null) n++;
    if (pantSize != null) n++;
    if (shirtSize != null) n++;
    return n;
  }

  bool get isEmpty => filledCount == 0;

  @override
  List<Object?> get props => [
        name,
        birthYear,
        gender,
        weight,
        height,
        waistCircumference,
        neckCircumference,
        pantSize,
        shirtSize,
      ];

  // ── helpers privados ──────────────────────────────────────────────

  static String? _firstNonEmptyString(
    Map<String, dynamic> raw,
    List<String> keys,
  ) {
    for (final k in keys) {
      final v = raw[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  static int? _readBirthYear(Map<String, dynamic> raw) {
    // Directo desde 'birthYear' o 'yearOfBirth'.
    for (final k in const ['birthYear', 'yearOfBirth']) {
      final v = raw[k];
      if (v is int && _isReasonableYear(v)) return v;
      if (v is String) {
        final parsed = int.tryParse(v);
        if (parsed != null && _isReasonableYear(parsed)) return parsed;
      }
    }
    // Fallback: parsear 'birthDate' como ISO 8601.
    final bd = raw['birthDate'];
    if (bd is String) {
      final parsed = DateTime.tryParse(bd);
      if (parsed != null && _isReasonableYear(parsed.year)) return parsed.year;
    }
    return null;
  }

  static bool _isReasonableYear(int year) {
    final now = DateTime.now().year;
    return year >= 1900 && year <= now;
  }

  static String? _readGender(Map<String, dynamic> raw) {
    for (final k in const ['gender', 'sex']) {
      final v = raw[k];
      if (v is String) {
        final norm = v.trim().toUpperCase();
        if (norm == 'M' || norm == 'MALE' || norm == 'MASCULINO') return 'M';
        if (norm == 'F' || norm == 'FEMALE' || norm == 'FEMENINO') return 'F';
        if (norm == 'OTRO' || norm == 'OTHER' || norm == 'O') return 'Otro';
      }
    }
    return null;
  }

  static double? _readBoundedDouble(
    Map<String, dynamic> raw, {
    required List<String> keys,
    required double min,
    required double max,
  }) {
    for (final k in keys) {
      final v = raw[k];
      double? parsed;
      if (v is num) {
        parsed = v.toDouble();
      } else if (v is String) {
        parsed = double.tryParse(v);
      }
      if (parsed != null && parsed >= min && parsed <= max) {
        return parsed;
      }
    }
    return null;
  }

  static int? _readBoundedInt(
    Map<String, dynamic> raw, {
    required List<String> keys,
    required int min,
    required int max,
  }) {
    for (final k in keys) {
      final v = raw[k];
      int? parsed;
      if (v is int) {
        parsed = v;
      } else if (v is num) {
        parsed = v.toInt();
      } else if (v is String) {
        parsed = int.tryParse(v);
      }
      if (parsed != null && parsed >= min && parsed <= max) {
        return parsed;
      }
    }
    return null;
  }

  static String? _readShirtSize(Map<String, dynamic> raw) {
    const valid = {'S', 'M', 'L', 'XL'};
    for (final k in const ['shirtSize', 'tshirtSize']) {
      final v = raw[k];
      if (v is String) {
        final norm = v.trim().toUpperCase();
        if (valid.contains(norm)) return norm;
      }
    }
    return null;
  }
}
