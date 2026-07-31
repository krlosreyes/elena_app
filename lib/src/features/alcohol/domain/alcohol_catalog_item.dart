// SPEC-261: entrada del catálogo de licores.
//
// El catálogo NO es una lista cerrada: es una base gobernada por la
// fórmula de AlcoholMath. Cada bebida se describe con volumen, ABV y
// categoría; los gramos, UEA y tiempo de metabolización se derivan.
//
// Los cócteles combinan varios licores y azúcares, así que aceptan un
// `gramsOverride` (gramos de alcohol estimados por receta) que sustituye
// al cálculo volumen × ABV.

import 'package:elena_app/src/features/alcohol/domain/alcohol_math.dart';

/// Familia de la bebida. Se usa para agrupar en la UI y (a futuro) para
/// heurísticas de congéneres/resaca.
enum DrinkCategory {
  cerveza,
  vino,
  espumanteFortificado,
  destilado,
  aguardienteLatam,
  coctel,
  sinAlcohol,
}

/// Recipiente típico. Importa para el protocolo: en vaso/jarra se sirve más
/// y se toma más rápido; en copa/trago medido es más fácil dosificar.
enum DrinkVessel { copa, vaso, jarra, trago }

extension DrinkVesselLabel on DrinkVessel {
  String get label => switch (this) {
        DrinkVessel.copa => 'copa',
        DrinkVessel.vaso => 'vaso',
        DrinkVessel.jarra => 'jarra',
        DrinkVessel.trago => 'trago',
      };
}

class AlcoholCatalogItem {
  /// Id estable y determinístico (kebab-case). Se persiste en el evento.
  final String id;
  final String name;
  final DrinkCategory category;

  /// Servida por defecto en ml (editable por el usuario al registrar).
  final double defaultServingMl;

  /// Graduación como fracción (0,40 = 40 %). Para cócteles es indicativa.
  final double abv;

  /// Gramos de alcohol fijos (cócteles). Si es null se calcula por fórmula.
  final double? gramsOverride;

  /// Licores oscuros (whisky, ron añejo) → más congéneres, peor resaca.
  final bool highCongeners;

  /// Recipiente típico en el que se sirve.
  final DrinkVessel vessel;

  /// Carbonatado (espumante, tragos con soda) → acelera la absorción y la
  /// borrachera: el protocolo pide espaciar más.
  final bool carbonated;

  /// Mezclador azucarado (cócteles dulces, refrescos) → picos de glucosa.
  final bool highSugar;

  const AlcoholCatalogItem({
    required this.id,
    required this.name,
    required this.category,
    required this.defaultServingMl,
    required this.abv,
    this.gramsOverride,
    this.highCongeners = false,
    this.vessel = DrinkVessel.trago,
    this.carbonated = false,
    this.highSugar = false,
  });

  /// Gramos de alcohol para una servida concreta (o la de por defecto).
  double gramsFor({double? servingMl}) {
    if (gramsOverride != null) return gramsOverride!;
    return AlcoholMath.gramsOfAlcohol(
      volumeMl: servingMl ?? defaultServingMl,
      abv: abv,
    );
  }

  /// UEA para una servida concreta (o la de por defecto).
  double standardUnitsFor({double? servingMl}) =>
      AlcoholMath.standardUnits(gramsFor(servingMl: servingMl));

  /// Horas para metabolizar una servida, según el peso del usuario.
  double hoursToMetabolizeFor({
    double? servingMl,
    double weightKg = AlcoholMath.referenceWeightKg,
  }) =>
      AlcoholMath.hoursToMetabolize(
        grams: gramsFor(servingMl: servingMl),
        weightKg: weightKg,
      );

  bool get isCocktail => category == DrinkCategory.coctel;
}
