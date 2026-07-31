// SPEC-261.4: tipo de trago que el usuario elige en el Cupertino picker.
//
// Es una lista CURADA (no las ~30 bebidas del catálogo) pensada para que el
// usuario elija rápido "qué va a tomar" y con eso el motor arme el plan. Cada
// tipo trae los metadatos que mueven la recomendación: graduación, recipiente,
// congéneres, carbonatación y azúcar.

import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog_item.dart';

class DrinkTypeOption {
  final String id;
  final String label;

  /// Categoría del catálogo con la que se agrupa el registro de tragos.
  final DrinkCategory category;

  /// Graduación representativa (fracción, 0,40 = 40 %).
  final double abv;

  /// Recipiente típico.
  final DrinkVessel vessel;

  final bool highCongeners;
  final bool carbonated;
  final bool highSugar;

  /// Frase corta que resume el consejo clave para este tipo.
  final String hint;

  const DrinkTypeOption({
    required this.id,
    required this.label,
    required this.category,
    required this.abv,
    required this.vessel,
    required this.hint,
    this.highCongeners = false,
    this.carbonated = false,
    this.highSugar = false,
  });
}

abstract final class DrinkTypes {
  static const List<DrinkTypeOption> all = [
    DrinkTypeOption(
      id: 'cerveza',
      label: 'Cerveza',
      category: DrinkCategory.cerveza,
      abv: 0.05,
      vessel: DrinkVessel.vaso,
      carbonated: true,
      hint: 'Graduación baja, pero es carbonatada: entra rápido. Sórbela.',
    ),
    DrinkTypeOption(
      id: 'vino',
      label: 'Vino',
      category: DrinkCategory.vino,
      abv: 0.13,
      vessel: DrinkVessel.copa,
      hint: 'Una copa estándar (150 ml). Acompáñala con agua.',
    ),
    DrinkTypeOption(
      id: 'espumante',
      label: 'Espumante / champán',
      category: DrinkCategory.espumanteFortificado,
      abv: 0.12,
      vessel: DrinkVessel.copa,
      carbonated: true,
      hint: 'Las burbujas aceleran la borrachera: espacia más.',
    ),
    DrinkTypeOption(
      id: 'destilado-claro',
      label: 'Destilado claro',
      category: DrinkCategory.destilado,
      abv: 0.40,
      vessel: DrinkVessel.trago,
      hint: 'Vodka, gin, tequila, ron blanco: menos congéneres → mejor resaca. '
          'Mídelo, evita servidas dobles.',
    ),
    DrinkTypeOption(
      id: 'destilado-oscuro',
      label: 'Destilado oscuro',
      category: DrinkCategory.destilado,
      abv: 0.42,
      vessel: DrinkVessel.trago,
      highCongeners: true,
      hint: 'Whisky, ron añejo, brandy: más congéneres = peor resaca. '
          'Si puedes, prefiere uno claro.',
    ),
    DrinkTypeOption(
      id: 'coctel',
      label: 'Cóctel',
      category: DrinkCategory.coctel,
      abv: 0.12,
      vessel: DrinkVessel.vaso,
      highSugar: true,
      hint: 'El azúcar esconde el alcohol: cuenta en UEA, no en vasos.',
    ),
    DrinkTypeOption(
      id: 'aguardiente',
      label: 'Aguardiente / guaro',
      category: DrinkCategory.aguardienteLatam,
      abv: 0.29,
      vessel: DrinkVessel.trago,
      hint: 'Se toma en shots: es fácil acelerarse. Espacia y toma agua.',
    ),
  ];

  static DrinkTypeOption? byId(String? id) {
    if (id == null) return null;
    for (final t in all) {
      if (t.id == id) return t;
    }
    return null;
  }
}
