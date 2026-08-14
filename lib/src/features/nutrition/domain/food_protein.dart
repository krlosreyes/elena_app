// SPEC-294 — Proteína por PORCIÓN de referencia de cada alimento (gramos).
//
// `portionLabel` de cada Food describe UNA porción; aquí van los gramos de
// proteína de esa porción, según tablas nutricionales estándar (USDA/valores
// típicos LatAm). El total de una comida escala por la cantidad del usuario
// (huevo ×3 = 3× la proteína de un huevo). Cubre los 173 alimentos; lo que no
// esté cae a 0 (verduras/frutas/aceites/dulces aportan ~0 proteína).

import 'package:elena_app/src/features/nutrition/domain/food_catalog.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_plan.dart';

const Map<String, double> _proteinPerPortion = {
  // ── Proteínas ──
  'pollo': 26, 'pechuga_pavo': 29, 'muslo_pollo': 24, 'huevo': 6,
  'clara_huevo': 11, 'carne_res': 26, 'cerdo': 26, 'pescado': 24,
  'atun': 20, 'sardinas': 21, 'salmon': 24, 'trucha': 24, 'tilapia': 26,
  'mariscos': 20, 'camaron': 20, 'langostino': 20, 'jamon': 7,
  'queso_campesino': 9, 'queso_mozzarella': 7, 'yogur_griego': 18,
  'kefir': 8, 'ricotta': 7, 'suero_costeno': 3, 'leche': 8, 'lentejas': 9,
  'frijoles': 8, 'garbanzos': 7, 'habichuelas': 2, 'tofu': 10, 'tempeh': 19,
  'quinua': 4, 'proteina_whey': 24, 'proteina_bipro': 24,
  'proteina_isolate': 27, 'proteina_caseina': 24, 'proteina_vegetal': 20,
  'caldo_pollo': 5, 'caldo_costilla': 5, 'caldo_pescado': 4,
  // ── Grasas ──
  'aguacate': 2, 'aceite_oliva': 0, 'aceite_coco': 0, 'aceite_aguacate': 0,
  'aceite_vegetal': 0, 'almendras': 6, 'nueces': 4, 'macadamia': 2,
  'avellanas': 4, 'mani': 7, 'pistachos': 6, 'semillas_girasol': 4,
  'semillas_calabaza': 6, 'coco': 1, 'mantequilla_almendras': 7, 'tahini': 5,
  'ajonjoli': 2, 'aceitunas': 0, 'mantequilla': 0, 'ghee': 0, 'leche_coco': 2,
  'queso_amarillo': 5, 'queso_crema': 2, 'crema_de_leche': 1,
  'leche_entera': 8, 'tocino': 11, 'chicharron': 30, 'chorizo': 16,
  'salchicha': 6, 'mayonesa': 0, 'manteca': 0, 'margarina': 0,
  'semillas_chia': 2, 'linaza': 2,
  // ── Carbohidratos (verduras/frutas/almidones/dulces/bebidas) ──
  'brocoli': 3, 'espinaca': 1, 'lechuga': 1, 'tomate': 1, 'pepino': 1,
  'calabacin': 1, 'coliflor': 2, 'pimiento': 1, 'zanahoria': 1, 'cebolla': 1,
  'apio': 1, 'champinones': 2, 'berenjena': 1, 'kale': 2, 'acelga': 1,
  'cilantro': 0, 'ajo': 0, 'jengibre': 0, 'remolacha': 2, 'fresa': 1,
  'frambuesa': 1, 'arandanos': 1, 'mora': 2, 'uchuva': 2, 'manzana': 0,
  'pera': 1, 'durazno': 1, 'kiwi': 1, 'guayaba': 2, 'limon': 0, 'uvas': 1,
  'mandarina': 1, 'naranja': 1, 'banano': 1, 'mango': 1, 'papaya': 1,
  'pina': 1, 'maracuya': 0, 'melon': 1, 'sandia': 1, 'platano': 1,
  'avena': 5, 'arroz_integral': 3, 'pan_integral': 4, 'papa': 3,
  'papa_criolla': 2, 'yuca': 1, 'batata_camote': 2, 'tapioca': 0, 'maiz': 3,
  'mazorca': 5, 'arroz': 2, 'pan': 3, 'pasta': 4, 'arepa': 2, 'tortilla': 3,
  'harina': 3, 'galletas': 2, 'cereal': 2, 'granola': 3, 'pandebono': 5,
  'bunuelo': 4, 'patacon': 1, 'tostadas': 3, 'azucar': 0, 'panela': 0,
  'miel': 0, 'chocolate': 2, 'bocadillo': 0, 'arequipe': 2, 'hummus': 2,
  'pizza': 12, 'hamburguesa': 17, 'salchipapa': 10, 'sandwich': 10,
  'empanada': 6, 'chips': 2, 'galletas_dulces': 2, 'galletas_saladas': 3,
  'tinto': 0, 'cafe_leche': 4, 'capuchino': 4, 'chocolate_caliente': 4,
  'jugo_leche': 4, 'jugo_agua': 0, 'agua_de_panela': 0, 'limonada': 0,
  'gaseosa': 0, 'cocacola': 0,
  // ── Comidas y antojos nuevos ──
  'perro_caliente': 10, 'taco': 10, 'tamal': 8, 'wrap': 12, 'nuggets': 13,
  'pollo_frito': 22, 'papas_fritas': 4, 'mortadela': 5, 'salchichon': 6,
  'helado': 3, 'chocolatina': 2,
};

/// Gramos de proteína de UNA porción de referencia del alimento.
double proteinPerPortion(Food f) => _proteinPerPortion[f.id] ?? 0;

/// Proteína total (g) de un conjunto de ítems del plato, ESCALANDO por la
/// cantidad de cada uno (SPEC-293/294). Ej: huevo ×3 = 3 × 6 g = 18 g.
double platedProteinG(Iterable<PlanItem> items) {
  var total = 0.0;
  for (final it in items) {
    final f = FoodCatalog.byId(it.foodId);
    if (f == null) continue;
    total += proteinPerPortion(f) * it.quantity;
  }
  return total;
}
