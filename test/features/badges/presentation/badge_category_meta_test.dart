// SPEC-264 regresión: `retos` se agregó a BadgeCategory.all pero no a
// kBadgeCategoryMeta, y la galería (kBadgeCategoryMeta[cat]!) reventaba esa
// celda. Este test falla si CUALQUIER categoría queda sin metadata.

import 'package:elena_app/src/features/badges/domain/badge_definition.dart';
import 'package:elena_app/src/features/badges/presentation/badge_category_meta.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('toda categoría de BadgeCategory.all tiene metadata visual', () {
    for (final category in BadgeCategory.all) {
      expect(kBadgeCategoryMeta.containsKey(category), isTrue,
          reason: 'falta metadata para la categoría "$category" '
              '(la galería la pintaría vacía o antes reventaba)');
    }
  });

  test('badgeCategoryMetaFor nunca devuelve null (usa fallback)', () {
    final meta = badgeCategoryMetaFor('categoria_inexistente');
    expect(meta, same(kBadgeCategoryMetaFallback));
  });
}
