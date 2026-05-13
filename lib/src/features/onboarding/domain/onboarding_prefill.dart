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
  /// SPEC-84: además de las claves planas legacy, consulta el shape
  /// canónico del sitio web Metamorfosis Real (`bio.*, habits.*,
  /// displayName, genderCanonical, birthDate, birthYear`).
  ///
  /// Estrategia: aplanamos primero el doc combinando shape canónico
  /// derivado + shape plano. El plano gana en duplicidades. Después
  /// leemos cada campo del prefill desde el mapa combinado.
  factory OnboardingPrefill.from(Map<String, dynamic>? rawProfile) {
    if (rawProfile == null || rawProfile.isEmpty) return empty;

    // Combinar shape canónico → legacy (SPEC-84) y luego el legacy
    // original encima. Así el plano siempre gana cuando coexiste.
    final flat = <String, dynamic>{
      ..._flattenCanonical(rawProfile),
      ...rawProfile,
    };

    return OnboardingPrefill(
      name: _firstNonEmptyString(
        flat,
        const ['name', 'displayName', 'fullName'],
      ),
      birthYear: _readBirthYear(flat),
      gender: _readGender(flat),
      weight: _readBoundedDouble(
        flat,
        keys: const ['weight', 'weightKg'],
        min: 20.0,
        max: 500.0,
      ),
      height: _readBoundedDouble(
        flat,
        keys: const ['height', 'heightCm'],
        min: 30.0,
        max: 250.0,
      ),
      waistCircumference: _readBoundedDouble(
        flat,
        keys: const ['waistCircumference', 'waist', 'waistCm'],
        min: 30.0,
        max: 250.0,
      ),
      neckCircumference: _readBoundedDouble(
        flat,
        keys: const ['neckCircumference', 'neck', 'neckCm'],
        min: 20.0,
        max: 80.0,
      ),
      pantSize: _readBoundedInt(
        flat,
        keys: const ['pantSize', 'trouserSize'],
        min: 20,
        max: 60,
      ),
      shirtSize: _readShirtSize(flat),
    );
  }

  /// SPEC-84: extrae los campos canónicos (`bio.*`, `habits.*`,
  /// `displayName`, `genderCanonical`) y los aplana al nivel raíz para
  /// que las helpers existentes los lean. No usamos
  /// `CanonicalToLegacyAdapter` aquí porque ese genera valores con
  /// coerciones más fuertes (DateTime, enums) que el prefill no
  /// necesita — el prefill solo recolecta primitivos.
  static Map<String, dynamic> _flattenCanonical(Map<String, dynamic> raw) {
    final out = <String, dynamic>{};

    final displayName = raw['displayName'];
    if (displayName is String && displayName.trim().isNotEmpty) {
      out['name'] = displayName;
    }

    final genderCanonical = raw['genderCanonical'];
    if (genderCanonical is String) {
      out['gender'] = genderCanonical;
    }

    final bio = raw['bio'];
    if (bio is Map) {
      final b = bio.cast<String, dynamic>();
      if (b['weightKg'] != null) out['weight'] = b['weightKg'];
      if (b['heightCm'] != null) out['height'] = b['heightCm'];
      if (b['waistCm'] != null) out['waistCircumference'] = b['waistCm'];
      if (b['neckCm'] != null) out['neckCircumference'] = b['neckCm'];
    }

    // birthDate / birthYear ya los lee `_readBirthYear` desde la raíz
    // sin necesidad de re-mapeo.

    return out;
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
