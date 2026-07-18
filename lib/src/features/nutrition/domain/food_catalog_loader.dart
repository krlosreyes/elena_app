// CODE-05: carga del catálogo de alimentos desde asset JSON en runtime.
//
// Motivación: `food_catalog.dart` define el catálogo completo (157
// alimentos) como una lista `const` de objetos `Food(...)` embebida en
// código Dart. Cada alimento nuevo/editado requiere tocar código y
// recompilar la app. Este loader permite, a futuro, mover esa data a un
// asset (`assets/nutrition/food_catalog.json`) que se puede regenerar sin
// recompilar (e incluso, más adelante, servir desde backend).
//
// IMPORTANTE — estado actual (2026-07-11): este loader existe pero NO
// está conectado a los consumidores de `FoodCatalog`. `FoodCatalog.all`,
// `.search()`, `.byId()` y `.byCategory()` siguen siendo síncronos y se
// usan hoy dentro de `build()` methods y getters síncronos (ver
// `plate_ratio_sheet.dart` y `nutrition_log.dart`). Migrar esos
// consumidores a async (FutureBuilder/AsyncNotifier + estado de carga)
// es un refactor no trivial que, sin compilador disponible para
// verificarlo en este entorno, se consideró más seguro dejar pendiente
// que aplicar a medias. Este archivo queda listo para cuando se decida
// hacer esa migración.
//
// El JSON en `assets/nutrition/food_catalog.json` se generó a partir del
// `food_catalog.dart` original preservando id, name, category,
// qualityScore, nova, searchAliases, portionLabel y servingUnit
// exactamente — ver script de migración (no versionado) usado para la
// extracción 1:1 de las 157 entradas.

import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;

import 'food_catalog.dart';

/// Carga el catálogo de alimentos desde el asset JSON en runtime.
///
/// Uso (cuando se decida conectar):
/// ```dart
/// final foods = await FoodCatalogLoader.load();
/// ```
class FoodCatalogLoader {
  const FoodCatalogLoader._();

  static const String assetPath = 'assets/nutrition/food_catalog.json';

  /// Lee y parsea `assets/nutrition/food_catalog.json` a una lista de
  /// [Food]. Async porque `rootBundle.loadString` lo es.
  static Future<List<Food>> load() async {
    final raw = await rootBundle.loadString(assetPath);
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((entry) => _foodFromJson(entry as Map<String, dynamic>))
        .toList(growable: false);
  }

  static Food _foodFromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String,
      name: json['name'] as String,
      category: FoodCategory.values.byName(json['category'] as String),
      qualityScore: json['qualityScore'] as int,
      nova: json['nova'] == null
          ? NovaGroup.unprocessed
          : NovaGroup.values.byName(json['nova'] as String),
      searchAliases: (json['searchAliases'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      portionLabel: json['portionLabel'] as String? ?? '1 porción',
      servingUnit: json['servingUnit'] == null
          ? ServingUnit.unit
          : ServingUnit.values.byName(json['servingUnit'] as String),
    );
  }
}
