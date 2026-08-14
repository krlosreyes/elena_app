// SPEC-289.3 — Emoji por alimento para los checklists del onboarding.
// Mapa por id + fallback por macronutriente. Solo presentación.

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';

const Map<String, String> _emoji = {
  // Proteínas
  'pollo': '🍗', 'pechuga_pavo': '🦃', 'muslo_pollo': '🍗', 'huevo': '🥚',
  'clara_huevo': '🥚', 'carne_res': '🥩', 'cerdo': '🥓', 'pescado': '🐟',
  'atun': '🐟', 'sardinas': '🐟', 'salmon': '🐟', 'trucha': '🐟',
  'tilapia': '🐟', 'mariscos': '🦐', 'camaron': '🦐', 'langostino': '🦐',
  'jamon': '🍖', 'queso_campesino': '🧀', 'queso_mozzarella': '🧀',
  'yogur_griego': '🥛', 'kefir': '🥛', 'ricotta': '🧀', 'suero_costeno': '🥛',
  'leche': '🥛', 'lentejas': '🫘', 'frijoles': '🫘', 'garbanzos': '🫘',
  'habichuelas': '🫛', 'tofu': '🍥', 'tempeh': '🍥', 'quinua': '🌾',
  'proteina_whey': '🥤', 'proteina_bipro': '🥤', 'proteina_isolate': '🥤',
  'proteina_caseina': '🥤', 'proteina_vegetal': '🥤', 'caldo_pollo': '🍲',
  'caldo_costilla': '🍲', 'caldo_pescado': '🍲',
  // Grasas
  'aguacate': '🥑', 'aceite_oliva': '🫒', 'aceite_coco': '🥥',
  'aceite_aguacate': '🥑', 'aceite_vegetal': '🛢️', 'almendras': '🌰',
  'nueces': '🌰', 'macadamia': '🌰', 'avellanas': '🌰', 'mani': '🥜',
  'pistachos': '🥜', 'semillas_girasol': '🌻', 'semillas_calabaza': '🎃',
  'coco': '🥥', 'mantequilla_almendras': '🥜', 'tahini': '🥣',
  'ajonjoli': '🌱', 'aceitunas': '🫒', 'mantequilla': '🧈', 'ghee': '🧈',
  'leche_coco': '🥥', 'queso_amarillo': '🧀', 'queso_crema': '🧀',
  'crema_de_leche': '🥛', 'leche_entera': '🥛', 'tocino': '🥓',
  'chicharron': '🥓', 'chorizo': '🌭', 'salchicha': '🌭', 'mayonesa': '🥣',
  'manteca': '🧈', 'margarina': '🧈', 'semillas_chia': '🌱', 'linaza': '🌱',
  // Carbohidratos (verduras, frutas, almidones, dulces, bebidas)
  'brocoli': '🥦', 'espinaca': '🥬', 'lechuga': '🥬', 'tomate': '🍅',
  'pepino': '🥒', 'calabacin': '🥒', 'coliflor': '🥦', 'pimiento': '🫑',
  'zanahoria': '🥕', 'cebolla': '🧅', 'apio': '🥬', 'champinones': '🍄',
  'berenjena': '🍆', 'kale': '🥬', 'acelga': '🥬', 'cilantro': '🌿',
  'ajo': '🧄', 'jengibre': '🫚', 'remolacha': '🥕', 'fresa': '🍓',
  'frambuesa': '🍓', 'arandanos': '🫐', 'mora': '🫐', 'uchuva': '🍒',
  'manzana': '🍎', 'pera': '🍐', 'durazno': '🍑', 'kiwi': '🥝',
  'guayaba': '🍈', 'limon': '🍋', 'uvas': '🍇', 'mandarina': '🍊',
  'naranja': '🍊', 'banano': '🍌', 'mango': '🥭', 'papaya': '🥭',
  'pina': '🍍', 'maracuya': '🍈', 'melon': '🍈', 'sandia': '🍉',
  'platano': '🍌', 'avena': '🥣', 'arroz_integral': '🍚',
  'pan_integral': '🍞', 'papa': '🥔', 'papa_criolla': '🥔', 'yuca': '🥔',
  'batata_camote': '🍠', 'tapioca': '🥣', 'maiz': '🌽', 'mazorca': '🌽',
  'arroz': '🍚', 'pan': '🍞', 'pasta': '🍝', 'arepa': '🫓',
  'tortilla': '🫓', 'harina': '🌾', 'galletas': '🍪', 'cereal': '🥣',
  'granola': '🥣', 'pandebono': '🥯', 'bunuelo': '🍩', 'patacon': '🍌',
  'tostadas': '🍞', 'azucar': '🍬', 'panela': '🍬', 'miel': '🍯',
  'chocolate': '🍫', 'bocadillo': '🍬', 'arequipe': '🍮', 'hummus': '🥣',
  'tinto': '☕', 'cafe_leche': '☕', 'capuchino': '☕',
  'chocolate_caliente': '☕', 'jugo_leche': '🥤', 'jugo_agua': '🧃',
  'agua_de_panela': '🥤', 'limonada': '🍋', 'gaseosa': '🥤', 'cocacola': '🥤',
  // Comidas y antojos
  'pizza': '🍕', 'hamburguesa': '🍔', 'salchipapa': '🍟', 'sandwich': '🥪',
  'empanada': '🥟', 'chips': '🍟', 'galletas_dulces': '🍪',
  'galletas_saladas': '🍘', 'perro_caliente': '🌭', 'taco': '🌮',
  'tamal': '🫔', 'wrap': '🌯', 'nuggets': '🍗', 'pollo_frito': '🍗',
  'papas_fritas': '🍟', 'mortadela': '🍖', 'salchichon': '🌭',
  'helado': '🍨', 'chocolatina': '🍫',
};

/// Emoji representativo de un alimento (por id; fallback por macro).
String foodEmoji(Food f) {
  final e = _emoji[f.id];
  if (e != null) return e;
  return switch (f.category) {
    FoodCategory.protein => '🍖',
    FoodCategory.fat => '🫒',
    FoodCategory.carb => '🥗',
  };
}
