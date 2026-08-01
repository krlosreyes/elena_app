// SPEC-261.9: tests del agrupador de salidas.

import 'package:elena_app/src/features/alcohol/domain/alcohol_catalog_item.dart';
import 'package:elena_app/src/features/alcohol/domain/drink_event.dart';
import 'package:elena_app/src/features/alcohol/domain/outing_history.dart';
import 'package:flutter_test/flutter_test.dart';

DrinkEvent _drink(DateTime at, {double grams = 15.0}) => DrinkEvent(
      itemId: 'x',
      name: 'Trago',
      category: DrinkCategory.destilado,
      volumeMl: 150,
      grams: grams,
      timestamp: at,
    );

void main() {
  test('nightOf: antes de las 6am cuenta como la noche anterior', () {
    expect(
      OutingHistory.nightOf(DateTime(2026, 8, 2, 2, 0)),
      DateTime(2026, 8, 1),
    );
    expect(
      OutingHistory.nightOf(DateTime(2026, 8, 1, 21, 0)),
      DateTime(2026, 8, 1),
    );
  });

  test('agrupa una noche que cruza la medianoche en UNA salida', () {
    final drinks = [
      _drink(DateTime(2026, 8, 1, 22, 0), grams: 14),
      _drink(DateTime(2026, 8, 2, 1, 30), grams: 16), // 1:30am = misma noche
    ];
    final out = OutingHistory.fromDrinks(drinks);
    expect(out.length, 1);
    expect(out.first.night, DateTime(2026, 8, 1));
    expect(out.first.drinkCount, 2);
    expect(out.first.totalGrams, 30);
    expect(out.first.totalStandardUnits, 3.0);
  });

  test('dos noches → dos salidas, la más reciente primero', () {
    final drinks = [
      _drink(DateTime(2026, 7, 25, 21, 0)),
      _drink(DateTime(2026, 8, 1, 20, 0)),
    ];
    final out = OutingHistory.fromDrinks(drinks);
    expect(out.length, 2);
    expect(out.first.night, DateTime(2026, 8, 1)); // reciente primero
    expect(out.last.night, DateTime(2026, 7, 25));
  });

  test('lista vacía → sin salidas', () {
    expect(OutingHistory.fromDrinks(const []), isEmpty);
  });

  test('resumen de últimos 30 días', () {
    final all = OutingHistory.fromDrinks([
      _drink(DateTime(2026, 8, 1, 21, 0), grams: 20),
      _drink(DateTime(2026, 5, 1, 21, 0), grams: 20), // fuera de ventana
    ]);
    final s = OutingHistory.summary(all, now: DateTime(2026, 8, 2), days: 30);
    expect(s.outings, 1);
    expect(s.totalUnits, 2.0);
  });

  test('intensidad por UEA', () {
    final night = DateTime(2026, 8, 1);
    expect(
      Outing(night: night, drinkCount: 1, totalGrams: 15).intensityLabel,
      'Ligera',
    );
    expect(
      Outing(night: night, drinkCount: 4, totalGrams: 55).intensityLabel,
      'Alta',
    );
  });
}
