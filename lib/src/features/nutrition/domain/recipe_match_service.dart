// SPEC-278 — Motor de cruce recetas ↔ preferencias del usuario.
//
// Recomienda recetas del `RecipeCatalog` según el REPERTORIO del usuario
// (los alimentos que ya come, tomados de su intake) y respetando sus
// restricciones (dieta + alimentos vetados). También arma la lista de
// mercado sumando ingredientes sin duplicar. Dart PURO → testeable.

import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';
import 'package:elena_app/src/features/nutrition/domain/recipe_catalog.dart';

/// Una receta con su afinidad al usuario.
class RecipeMatch {
  final Recipe recipe;

  /// Cuántos ingredientes centrales de la receta ya come el usuario.
  final int overlap;

  /// Puntaje de recomendación (mayor = mejor encaje).
  final double score;

  const RecipeMatch({
    required this.recipe,
    required this.overlap,
    required this.score,
  });
}

class RecipeMatchService {
  const RecipeMatchService();

  /// Recomienda recetas cruzando el intake del usuario con el recetario.
  ///
  /// - [slot]: si se da, solo recetas que encajan en esa comida.
  /// - Filtra por dieta declarada y excluye recetas con alimentos vetados.
  /// - Ordena por afinidad (overlap con lo que ya come), penalizando
  ///   ingredientes desconocidos y tiempos largos.
  List<RecipeMatch> match({
    required NutritionIntake intake,
    MealSlot? slot,
    int limit = 5,
    List<Recipe> catalog = RecipeCatalog.all,
  }) {
    final banned = _bannedSet(intake.restrictions.allBanned);
    final diet = intake.restrictions.diet;
    final userFoods = _userFoods(intake);

    final matches = <RecipeMatch>[];
    for (final r in catalog) {
      if (slot != null && !r.fitsSlot(slot)) continue;
      if (!r.fitsDiet(diet)) continue;
      if (_usesBanned(r, banned)) continue;

      final ids = r.foodIds;
      final overlap = ids.where(userFoods.contains).length;
      final unknown = ids.length - overlap;
      final score = overlap * 3.0 - unknown * 0.5 - r.prepMinutes * 0.02;
      matches.add(RecipeMatch(recipe: r, overlap: overlap, score: score));
    }

    matches.sort((a, b) {
      final byScore = b.score.compareTo(a.score);
      if (byScore != 0) return byScore;
      return a.recipe.name.compareTo(b.recipe.name);
    });
    return matches.take(limit).toList();
  }

  /// Lista de mercado a partir de varias recetas, sin duplicar (por foodId
  /// cuando existe; por texto normalizado cuando no).
  List<String> shoppingList(List<Recipe> recipes) {
    final seenFood = <String>{};
    final seenText = <String>{};
    final out = <String>[];
    for (final r in recipes) {
      for (final ing in r.ingredients) {
        final id = ing.foodId;
        if (id != null && id.isNotEmpty) {
          if (!seenFood.add(id)) continue;
        } else {
          if (!seenText.add(ing.text.toLowerCase().trim())) continue;
        }
        out.add(ing.text);
      }
    }
    return out;
  }

  // ─── Internos ───────────────────────────────────────────────────────────

  Set<String> _userFoods(NutritionIntake intake) {
    final s = <String>{};
    // SPEC-289: el repertorio plano (modelo nuevo) es la fuente principal.
    for (final it in intake.repertoire) {
      final id = it.foodId;
      if (id != null && id.isNotEmpty) s.add(id);
    }
    // Modelo viejo (por comida) — compatibilidad.
    for (final m in intake.meals) {
      for (final it in m.items) {
        final id = it.foodId;
        if (id != null && id.isNotEmpty) s.add(id);
      }
    }
    for (final sn in intake.snacks) {
      final id = sn.foodId;
      if (id != null && id.isNotEmpty) s.add(id);
    }
    return s;
  }

  bool _usesBanned(Recipe r, Set<String> banned) {
    if (banned.isEmpty) return false;
    for (final ing in r.ingredients) {
      final id = ing.foodId;
      if (id != null && banned.contains(id.toLowerCase())) return true;
      final t = ing.text.toLowerCase();
      for (final b in banned) {
        if (b.isNotEmpty && t.contains(b)) return true;
      }
    }
    return false;
  }

  Set<String> _bannedSet(List<String> raw) =>
      raw.map((e) => e.trim().toLowerCase()).where((e) => e.isNotEmpty).toSet();
}
