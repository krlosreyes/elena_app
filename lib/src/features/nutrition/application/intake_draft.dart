// SPEC-289 (fase 3) — Builder mutable del intake para la UI de onboarding.
//
// Modelo NUEVO: el usuario NO asigna alimentos a comidas. Marca con check lo
// que come (repertorio), lo que pica (snacks) y declara régimen + alergias.
// El motor decide cuándo va cada cosa. Reemplaza el draft por-comida anterior.
//
// Dart puro (sin Flutter) a propósito — testeable sin montar la UI.

import 'package:elena_app/src/features/nutrition/domain/nutrition_intake.dart';

class IntakeDraft {
  /// Régimen declarado (omnívoro/pescetariano/vegetariano/vegano/otro).
  DietType diet;

  /// foodIds del catálogo que el usuario marca que come (repertorio plano).
  final Set<String> repertoire;

  /// foodIds que el usuario marca como snacks / lo que pica entre comidas.
  final Set<String> snackIds;

  /// Alergias/intolerancias declaradas (texto o ids) — exclusión dura.
  final List<String> allergies;

  IntakeDraft({
    this.diet = DietType.omnivore,
    Set<String>? repertoire,
    Set<String>? snackIds,
    List<String>? allergies,
  })  : repertoire = repertoire ?? <String>{},
        snackIds = snackIds ?? <String>{},
        allergies = allergies ?? <String>[];

  factory IntakeDraft.initial() => IntakeDraft();

  /// Reconstruye el draft desde un intake guardado (para editar). Toma el
  /// repertorio nuevo; si es un intake viejo (por comida), levanta sus foodIds
  /// como repertorio para no perder lo que el usuario ya había declarado.
  factory IntakeDraft.fromIntake(NutritionIntake i) {
    final rep = <String>{...i.repertoireFoodIds};
    if (rep.isEmpty) {
      for (final m in i.meals) {
        for (final it in m.items) {
          final id = it.foodId;
          if (id != null && id.isNotEmpty) rep.add(id);
        }
      }
    }
    final snacks = <String>{
      for (final s in i.snacks)
        if (s.foodId != null && s.foodId!.isNotEmpty) s.foodId!,
    };
    return IntakeDraft(
      diet: i.restrictions.diet,
      repertoire: rep,
      snackIds: snacks,
      allergies: List<String>.of(i.restrictions.allergies),
    );
  }

  /// Marca/desmarca un alimento del repertorio.
  void toggle(String foodId) {
    if (!repertoire.remove(foodId)) repertoire.add(foodId);
  }

  bool has(String foodId) => repertoire.contains(foodId);

  /// Marca/desmarca un snack.
  void toggleSnack(String foodId) {
    if (!snackIds.remove(foodId)) snackIds.add(foodId);
  }

  bool hasSnack(String foodId) => snackIds.contains(foodId);

  /// Mínimo para generar una minuta: al menos 3 alimentos marcados.
  bool get isComplete => repertoire.length >= 3;

  /// Convierte el draft a un `NutritionIntake` inmutable. `derived` (ventana,
  /// proteína) lo recalcula el notifier desde el UserModel al guardar.
  NutritionIntake build() {
    return NutritionIntake(
      updatedAt: DateTime.now(),
      repertoire: repertoire
          .map((id) => IntakeItem(foodId: id))
          .toList(growable: false),
      snacks:
          snackIds.map((id) => IntakeSnack(foodId: id)).toList(growable: false),
      restrictions: IntakeRestrictions(
        diet: diet,
        allergies: List<String>.of(allergies),
      ),
    );
  }
}
