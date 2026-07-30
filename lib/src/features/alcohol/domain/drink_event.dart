// SPEC-261: un consumo registrado.
//
// Sigue el patrón de HydrationLog (SPEC-50.1): entidad simple e inmutable;
// la validación de invariantes y la (de)serialización viven en el mapper.
// Firestore auto-genera el id, así que el dominio no lo asigna.

import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog_item.dart';

class DrinkEvent {
  /// Id del ítem del catálogo (o 'custom' para entradas manuales).
  final String itemId;
  final String name;
  final DrinkCategory category;

  /// Servida efectiva en ml.
  final double volumeMl;

  /// Gramos de alcohol puro de este consumo.
  final double grams;

  /// Momento del consumo.
  final DateTime timestamp;

  /// El usuario acompañó este trago con agua (regla 1:1).
  final bool waterChaser;

  const DrinkEvent({
    required this.itemId,
    required this.name,
    required this.category,
    required this.volumeMl,
    required this.grams,
    required this.timestamp,
    this.waterChaser = false,
  });

  /// Construye el evento a partir de un ítem del catálogo, resolviendo
  /// gramos y servida en un solo lugar (evita fórmulas duplicadas).
  factory DrinkEvent.fromCatalog(
    AlcoholCatalogItem item, {
    double? servingMl,
    DateTime? at,
    bool waterChaser = false,
  }) {
    final ml = servingMl ?? item.defaultServingMl;
    return DrinkEvent(
      itemId: item.id,
      name: item.name,
      category: item.category,
      volumeMl: ml,
      grams: item.gramsFor(servingMl: ml),
      timestamp: at ?? DateTime.now(),
      waterChaser: waterChaser,
    );
  }

  DrinkEvent copyWith({bool? waterChaser}) => DrinkEvent(
        itemId: itemId,
        name: name,
        category: category,
        volumeMl: volumeMl,
        grams: grams,
        timestamp: timestamp,
        waterChaser: waterChaser ?? this.waterChaser,
      );
}
