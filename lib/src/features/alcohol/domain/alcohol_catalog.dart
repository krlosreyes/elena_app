// SPEC-261: catálogo base de licores.
//
// Muestra representativa y amplia por categoría. Ampliable sin tocar
// lógica: basta añadir un `AlcoholCatalogItem`. Los valores de ABV son
// promedios típicos; el usuario puede ajustar la servida al registrar.
//
// Los cócteles se cargan como presets con gramos de alcohol estimados de
// recetas estándar (editables).

import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog_item.dart';

abstract final class AlcoholCatalog {
  /// Lista completa e inmutable del catálogo base.
  static const List<AlcoholCatalogItem> all = [
    // ── Cervezas ────────────────────────────────────────────────────
    AlcoholCatalogItem(
      id: 'cerveza-lager',
      name: 'Cerveza lager estándar',
      category: DrinkCategory.cerveza,
      defaultServingMl: 355,
      abv: 0.050,
    ),
    AlcoholCatalogItem(
      id: 'cerveza-light',
      name: 'Cerveza light',
      category: DrinkCategory.cerveza,
      defaultServingMl: 355,
      abv: 0.042,
    ),
    AlcoholCatalogItem(
      id: 'cerveza-ipa',
      name: 'Cerveza artesanal / IPA',
      category: DrinkCategory.cerveza,
      defaultServingMl: 355,
      abv: 0.065,
    ),
    AlcoholCatalogItem(
      id: 'cerveza-fuerte',
      name: 'Cerveza fuerte / doble malta',
      category: DrinkCategory.cerveza,
      defaultServingMl: 330,
      abv: 0.085,
    ),

    // ── Vinos ───────────────────────────────────────────────────────
    AlcoholCatalogItem(
      id: 'vino-tinto',
      name: 'Copa de vino tinto',
      category: DrinkCategory.vino,
      defaultServingMl: 150,
      abv: 0.135,
    ),
    AlcoholCatalogItem(
      id: 'vino-blanco',
      name: 'Copa de vino blanco',
      category: DrinkCategory.vino,
      defaultServingMl: 150,
      abv: 0.120,
    ),
    AlcoholCatalogItem(
      id: 'vino-dulce',
      name: 'Copa de vino dulce / de postre',
      category: DrinkCategory.vino,
      defaultServingMl: 90,
      abv: 0.150,
    ),

    // ── Espumantes y fortificados ───────────────────────────────────
    AlcoholCatalogItem(
      id: 'espumante',
      name: 'Copa de champán / espumante',
      category: DrinkCategory.espumanteFortificado,
      defaultServingMl: 120,
      abv: 0.120,
    ),
    AlcoholCatalogItem(
      id: 'oporto-jerez',
      name: 'Copa de oporto / jerez',
      category: DrinkCategory.espumanteFortificado,
      defaultServingMl: 90,
      abv: 0.180,
      highCongeners: true,
    ),
    AlcoholCatalogItem(
      id: 'vermut',
      name: 'Vermut',
      category: DrinkCategory.espumanteFortificado,
      defaultServingMl: 90,
      abv: 0.160,
    ),

    // ── Destilados (trago 44 ml) ────────────────────────────────────
    AlcoholCatalogItem(
      id: 'tequila',
      name: 'Tequila',
      category: DrinkCategory.destilado,
      defaultServingMl: 44,
      abv: 0.40,
    ),
    AlcoholCatalogItem(
      id: 'whisky',
      name: 'Whisky',
      category: DrinkCategory.destilado,
      defaultServingMl: 44,
      abv: 0.43,
      highCongeners: true,
    ),
    AlcoholCatalogItem(
      id: 'ron',
      name: 'Ron',
      category: DrinkCategory.destilado,
      defaultServingMl: 44,
      abv: 0.40,
      highCongeners: true,
    ),
    AlcoholCatalogItem(
      id: 'vodka',
      name: 'Vodka',
      category: DrinkCategory.destilado,
      defaultServingMl: 44,
      abv: 0.40,
    ),
    AlcoholCatalogItem(
      id: 'ginebra',
      name: 'Ginebra',
      category: DrinkCategory.destilado,
      defaultServingMl: 44,
      abv: 0.40,
    ),
    AlcoholCatalogItem(
      id: 'mezcal',
      name: 'Mezcal',
      category: DrinkCategory.destilado,
      defaultServingMl: 44,
      abv: 0.45,
      highCongeners: true,
    ),
    AlcoholCatalogItem(
      id: 'pisco',
      name: 'Pisco',
      category: DrinkCategory.destilado,
      defaultServingMl: 44,
      abv: 0.40,
    ),
    AlcoholCatalogItem(
      id: 'brandy-conac',
      name: 'Brandy / coñac',
      category: DrinkCategory.destilado,
      defaultServingMl: 44,
      abv: 0.40,
      highCongeners: true,
    ),

    // ── Aguardientes LatAm ──────────────────────────────────────────
    AlcoholCatalogItem(
      id: 'aguardiente-guaro',
      name: 'Aguardiente / guaro',
      category: DrinkCategory.aguardienteLatam,
      defaultServingMl: 40,
      abv: 0.29,
    ),
    AlcoholCatalogItem(
      id: 'cachaca',
      name: 'Cachaça',
      category: DrinkCategory.aguardienteLatam,
      defaultServingMl: 44,
      abv: 0.40,
    ),

    // ── Cócteles (presets por composición) ──────────────────────────
    AlcoholCatalogItem(
      id: 'margarita',
      name: 'Margarita',
      category: DrinkCategory.coctel,
      defaultServingMl: 120,
      abv: 0.19,
      gramsOverride: 18,
    ),
    AlcoholCatalogItem(
      id: 'mojito',
      name: 'Mojito',
      category: DrinkCategory.coctel,
      defaultServingMl: 240,
      abv: 0.08,
      gramsOverride: 14,
    ),
    AlcoholCatalogItem(
      id: 'cuba-libre',
      name: 'Cuba libre / ron con cola',
      category: DrinkCategory.coctel,
      defaultServingMl: 240,
      abv: 0.08,
      gramsOverride: 14,
      highCongeners: true,
    ),
    AlcoholCatalogItem(
      id: 'gin-tonic',
      name: 'Gin tonic',
      category: DrinkCategory.coctel,
      defaultServingMl: 240,
      abv: 0.08,
      gramsOverride: 14,
    ),
    AlcoholCatalogItem(
      id: 'aperol-spritz',
      name: 'Aperol spritz',
      category: DrinkCategory.coctel,
      defaultServingMl: 180,
      abv: 0.09,
      gramsOverride: 13,
    ),
    AlcoholCatalogItem(
      id: 'pina-colada',
      name: 'Piña colada',
      category: DrinkCategory.coctel,
      defaultServingMl: 240,
      abv: 0.09,
      gramsOverride: 17,
    ),
    AlcoholCatalogItem(
      id: 'caipirinha',
      name: 'Caipiriña',
      category: DrinkCategory.coctel,
      defaultServingMl: 200,
      abv: 0.10,
      gramsOverride: 16,
    ),
    AlcoholCatalogItem(
      id: 'negroni',
      name: 'Negroni',
      category: DrinkCategory.coctel,
      defaultServingMl: 90,
      abv: 0.24,
      gramsOverride: 20,
      highCongeners: true,
    ),

    // ── Sin / bajo alcohol ──────────────────────────────────────────
    AlcoholCatalogItem(
      id: 'cerveza-cero',
      name: 'Cerveza 0,0 %',
      category: DrinkCategory.sinAlcohol,
      defaultServingMl: 355,
      abv: 0.004,
    ),
    AlcoholCatalogItem(
      id: 'vino-desalcoholizado',
      name: 'Vino desalcoholizado',
      category: DrinkCategory.sinAlcohol,
      defaultServingMl: 150,
      abv: 0.005,
    ),
  ];

  /// Busca por id. Devuelve null si no existe.
  static AlcoholCatalogItem? byId(String id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Ítems de una categoría, en el orden del catálogo.
  static List<AlcoholCatalogItem> byCategory(DrinkCategory category) =>
      all.where((i) => i.category == category).toList(growable: false);
}
