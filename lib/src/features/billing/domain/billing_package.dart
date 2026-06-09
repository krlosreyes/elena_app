// SPEC-196 — paquete comprable, abstracción del Package de RevenueCat.
//
// La capa de presentación (paywall, SPEC-198) muestra estos objetos sin
// conocer el SDK. El `priceString` viene YA localizado desde la tienda
// (nunca se hardcodea el precio — SPEC-198 §2.3). Dart puro.

/// Periodo de la suscripción.
enum BillingPeriod { monthly, annual, unknown }

class BillingPackage {
  const BillingPackage({
    required this.id,
    required this.productId,
    required this.title,
    required this.priceString,
    required this.period,
  });

  /// Identificador del package dentro de la Offering (p. ej. "$rc_monthly").
  final String id;

  /// Identificador del producto de tienda (p. ej. "elena_premium_monthly").
  final String productId;

  /// Título mostrable.
  final String title;

  /// Precio YA localizado por la tienda (p. ej. "US$9.99", "$199.00 MXN").
  final String priceString;

  final BillingPeriod period;

  @override
  bool operator ==(Object other) =>
      other is BillingPackage &&
      other.id == id &&
      other.productId == productId &&
      other.title == title &&
      other.priceString == priceString &&
      other.period == period;

  @override
  int get hashCode => Object.hash(id, productId, title, priceString, period);

  @override
  String toString() =>
      'BillingPackage($productId, ${period.name}, $priceString)';
}
