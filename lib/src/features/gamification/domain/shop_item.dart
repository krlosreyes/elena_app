// SPEC-262: catálogo de la Tienda — canjear estrellas por congeladores.

/// Un producto de la Tienda: un paquete de congeladores por un costo en
/// estrellas.
class ShopItem {
  final String id;
  final String label;
  final int frostyQty;
  final int starCost;

  const ShopItem({
    required this.id,
    required this.label,
    required this.frostyQty,
    required this.starCost,
  });
}

abstract final class Shop {
  /// Paquetes disponibles. Más cantidad = mejor precio por congelador.
  static const List<ShopItem> items = [
    ShopItem(id: 'frosty-1', label: 'Congelador', frostyQty: 1, starCost: 50),
    ShopItem(
        id: 'frosty-3', label: '3 congeladores', frostyQty: 3, starCost: 125),
    ShopItem(
        id: 'frosty-5', label: '5 congeladores', frostyQty: 5, starCost: 200),
  ];

  static ShopItem? byId(String id) {
    for (final it in items) {
      if (it.id == id) return it;
    }
    return null;
  }
}
