// SPEC-196 — estado de derecho de acceso (entitlement) del usuario.
//
// Abstracción única que consume el gating (SPEC-197) y el paywall (SPEC-198):
// la app solo pregunta `isPremium`, no qué producto se compró. Inmutable y
// Dart puro (CONSTITUTION §3.1) — NO importa el SDK de cobro.

/// Origen del acceso premium activo.
enum EntitlementSource {
  /// Sin premium (tier Free).
  none,

  /// Premium activo vía periodo de prueba (trial, SPEC-198).
  trial,

  /// Premium activo por suscripción pagada (mensual o anual).
  paid,
}

class EntitlementStatus {
  const EntitlementStatus({
    required this.isPremium,
    this.willRenew = false,
    this.expiration,
    this.activeProductId,
    this.source = EntitlementSource.none,
  });

  /// Estado por defecto: usuario Free. Es el valor mientras carga el SDK,
  /// tras logout, y cuando el cobro aún no está habilitado.
  const EntitlementStatus.free()
      : isPremium = false,
        willRenew = false,
        expiration = null,
        activeProductId = null,
        source = EntitlementSource.none;

  /// True si el usuario tiene acceso premium (por trial o pago).
  final bool isPremium;

  /// True si la suscripción se renovará automáticamente.
  final bool willRenew;

  /// Cuándo expira el acceso actual (null si no aplica).
  final DateTime? expiration;

  /// Identificador del producto activo (null en Free).
  final String? activeProductId;

  /// De dónde viene el acceso premium.
  final EntitlementSource source;

  /// True si el premium proviene de un trial (útil para nudges SPEC-198).
  bool get isTrial => source == EntitlementSource.trial;

  EntitlementStatus copyWith({
    bool? isPremium,
    bool? willRenew,
    DateTime? expiration,
    String? activeProductId,
    EntitlementSource? source,
  }) {
    return EntitlementStatus(
      isPremium: isPremium ?? this.isPremium,
      willRenew: willRenew ?? this.willRenew,
      expiration: expiration ?? this.expiration,
      activeProductId: activeProductId ?? this.activeProductId,
      source: source ?? this.source,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is EntitlementStatus &&
      other.isPremium == isPremium &&
      other.willRenew == willRenew &&
      other.expiration == expiration &&
      other.activeProductId == activeProductId &&
      other.source == source;

  @override
  int get hashCode =>
      Object.hash(isPremium, willRenew, expiration, activeProductId, source);

  @override
  String toString() =>
      'EntitlementStatus(premium: $isPremium, source: ${source.name}, '
      'willRenew: $willRenew, product: $activeProductId)';
}
