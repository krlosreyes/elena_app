// SPEC-261.6: tipos de trago POPULARES que el usuario elige en el picker.
//
// Lista curada con nombres que cualquiera reconoce (no "destilado claro"):
// cerveza, vino, cuba libre, mojito, margarita, piña colada, crema de whisky,
// aguardiente, etc. Cada tipo declara los GRAMOS de alcohol puro de UNA servida
// típica (así modelamos bien cócteles y cremas, donde volumen × ABV no aplica
// limpio) y una etiqueta legible de esa servida. El resto de metadatos mueve la
// recomendación: congéneres (resaca), carbonatación (absorción) y azúcar.

import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog_item.dart';

class DrinkTypeOption {
  final String id;

  /// Nombre popular para el selector.
  final String label;

  /// Categoría del catálogo con la que se agrupa el registro de tragos.
  final DrinkCategory category;

  /// Gramos de alcohol puro en UNA servida típica de este trago.
  final double gramsPerServing;

  /// Cómo se nombra esa servida en el plan, ej. "copa de vino (150 ml)".
  final String servingLabel;

  final bool highCongeners;
  final bool carbonated;
  final bool highSugar;

  /// Frase corta que resume el consejo clave para este tipo.
  final String hint;

  const DrinkTypeOption({
    required this.id,
    required this.label,
    required this.category,
    required this.gramsPerServing,
    required this.servingLabel,
    required this.hint,
    this.highCongeners = false,
    this.carbonated = false,
    this.highSugar = false,
  });

  /// UEA (10 g) que representa una servida de este trago.
  double get standardUnitsPerServing => gramsPerServing / 10.0;
}

abstract final class DrinkTypes {
  static const List<DrinkTypeOption> all = [
    // ── Cervezas ──────────────────────────────────────────────
    DrinkTypeOption(
      id: 'cerveza',
      label: 'Cerveza',
      category: DrinkCategory.cerveza,
      gramsPerServing: 13.0, // 330 ml al 5 %
      servingLabel: 'cerveza (330 ml)',
      carbonated: true,
      hint: 'Graduación baja, pero es carbonatada: entra rápido. Sórbela.',
    ),
    DrinkTypeOption(
      id: 'cerveza-fuerte',
      label: 'Cerveza fuerte / IPA',
      category: DrinkCategory.cerveza,
      gramsPerServing: 18.5, // 330 ml al 7 %
      servingLabel: 'cerveza fuerte (330 ml)',
      carbonated: true,
      hint: 'Tiene más grados que una cerveza normal: cuenta casi 1½.',
    ),
    DrinkTypeOption(
      id: 'michelada',
      label: 'Michelada',
      category: DrinkCategory.coctel,
      gramsPerServing: 13.0,
      servingLabel: 'michelada',
      carbonated: true,
      highSugar: true,
      hint: 'Lleva casi una cerveza; el clamato y la sal esconden el alcohol.',
    ),
    // ── Vino y espumantes ─────────────────────────────────────
    DrinkTypeOption(
      id: 'vino',
      label: 'Vino',
      category: DrinkCategory.vino,
      gramsPerServing: 15.4, // 150 ml al 13 %
      servingLabel: 'copa de vino (150 ml)',
      hint: 'Una copa estándar. Acompáñala con agua.',
    ),
    DrinkTypeOption(
      id: 'espumante',
      label: 'Espumante / champaña',
      category: DrinkCategory.espumanteFortificado,
      gramsPerServing: 11.4, // 120 ml al 12 %
      servingLabel: 'copa de espumante (120 ml)',
      carbonated: true,
      hint: 'Las burbujas aceleran la borrachera: espacia más.',
    ),
    DrinkTypeOption(
      id: 'sangria',
      label: 'Sangría',
      category: DrinkCategory.coctel,
      gramsPerServing: 16.0,
      servingLabel: 'copa de sangría (200 ml)',
      highSugar: true,
      hint: 'Es vino con fruta y azúcar: entra fácil, cuenta como copa larga.',
    ),
    // ── Tragos con destilado (nombres populares) ──────────────
    DrinkTypeOption(
      id: 'cuba-libre',
      label: 'Ron con cola / cuba libre',
      category: DrinkCategory.coctel,
      gramsPerServing: 14.2, // ~45 ml de ron
      servingLabel: 'cuba libre',
      carbonated: true,
      highSugar: true,
      hint: 'El ron es 40°; la cola solo lo disfraza. Mídelo, no lo cargues.',
    ),
    DrinkTypeOption(
      id: 'tequila',
      label: 'Tequila (shot)',
      category: DrinkCategory.destilado,
      gramsPerServing: 13.9, // 44 ml al 40 %
      servingLabel: 'shot de tequila (44 ml)',
      hint: 'Se toma de un golpe: espacia y toma agua entre shots.',
    ),
    DrinkTypeOption(
      id: 'whisky',
      label: 'Whisky',
      category: DrinkCategory.destilado,
      gramsPerServing: 14.2, // ~45 ml al 40 %
      servingLabel: 'vaso de whisky (45 ml)',
      highCongeners: true,
      hint: 'Oscuro = más congéneres = peor resaca. Hidrátate bien.',
    ),
    DrinkTypeOption(
      id: 'vodka',
      label: 'Vodka (con jugo o soda)',
      category: DrinkCategory.destilado,
      gramsPerServing: 14.2, // ~45 ml al 40 %
      servingLabel: 'trago de vodka',
      highSugar: true,
      hint: 'Claro, menos resaca, pero el jugo o la soda suman azúcar.',
    ),
    DrinkTypeOption(
      id: 'gin-tonic',
      label: 'Gin tonic',
      category: DrinkCategory.coctel,
      gramsPerServing: 14.2, // ~45 ml de ginebra
      servingLabel: 'gin tonic',
      carbonated: true,
      hint: 'Ginebra 40° con tónica; la tónica también trae azúcar.',
    ),
    // ── Cócteles ──────────────────────────────────────────────
    DrinkTypeOption(
      id: 'mojito',
      label: 'Mojito',
      category: DrinkCategory.coctel,
      gramsPerServing: 14.2,
      servingLabel: 'mojito',
      carbonated: true,
      highSugar: true,
      hint: 'Ron y azúcar; la menta y la soda lo hacen fácil de encadenar.',
    ),
    DrinkTypeOption(
      id: 'margarita',
      label: 'Margarita',
      category: DrinkCategory.coctel,
      gramsPerServing: 17.0,
      servingLabel: 'margarita',
      highSugar: true,
      hint: 'Fuerte y dulce: cuenta casi como 2 tragos.',
    ),
    DrinkTypeOption(
      id: 'pina-colada',
      label: 'Piña colada',
      category: DrinkCategory.coctel,
      gramsPerServing: 15.8,
      servingLabel: 'piña colada',
      highSugar: true,
      hint: 'Cremosa y dulce: esconde bien el ron. Ojo con encadenarlas.',
    ),
    DrinkTypeOption(
      id: 'crema-whisky',
      label: 'Crema de whisky (Baileys)',
      category: DrinkCategory.destilado,
      gramsPerServing: 8.0, // ~60 ml al 17 %
      servingLabel: 'crema de whisky (60 ml)',
      highSugar: true,
      hint: 'Menos grados, pero mucho azúcar y crema: pesado para el hígado.',
    ),
    DrinkTypeOption(
      id: 'coctel',
      label: 'Otro cóctel',
      category: DrinkCategory.coctel,
      gramsPerServing: 17.0,
      servingLabel: 'cóctel',
      highSugar: true,
      hint:
          'El azúcar esconde el alcohol: en promedio, casi 2 tragos por vaso.',
    ),
    // ── LatAm ─────────────────────────────────────────────────
    DrinkTypeOption(
      id: 'aguardiente',
      label: 'Aguardiente / guaro',
      category: DrinkCategory.aguardienteLatam,
      gramsPerServing: 6.9, // ~30 ml al 29 %
      servingLabel: 'shot de guaro (30 ml)',
      hint: 'Se toma en copitas: es fácil acelerarse. Espacia y toma agua.',
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
