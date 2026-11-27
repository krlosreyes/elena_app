// Fix 22-nov — "Cómo lo lograste" se quedaba cargando.
//
// La card de Progreso pinta un spinner mientras `weeklyPillarDaysProvider`
// no tenga valor. Si el stream de ciclos fallaba, el provider quedaba en
// error y la card no lo distinguía de "cargando": spinner eterno. Estos
// tests fijan el contrato del que depende la card para salir de ahí.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elena_app/src/features/analysis/application/weekly_window.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';

void main() {
  test('sin ciclos cerrados entrega 0 días por pilar, no se queda cargando',
      () async {
    final container = ProviderContainer(overrides: [
      last14ClosedCyclesProvider.overrideWith((ref) => Stream.value(const [])),
    ]);
    addTearDown(container.dispose);
    final sub = container.listen(weeklyPillarDaysProvider, (_, __) {});
    addTearDown(sub.close);

    await container.read(last14ClosedCyclesProvider.future);
    final value = container.read(weeklyPillarDaysProvider);

    expect(value.hasValue, isTrue);
    expect(value.requireValue.fasting, 0);
    expect(value.requireValue.nutrition, 0);
  });

  test(
      'si el stream de ciclos falla, el provider queda en ERROR (no en '
      'loading) para que la card muestre "Reintentar"', () async {
    final container = ProviderContainer(overrides: [
      last14ClosedCyclesProvider
          .overrideWith((ref) => Stream.error(Exception('permission-denied'))),
    ]);
    addTearDown(container.dispose);
    final sub = container.listen(weeklyPillarDaysProvider, (_, __) {});
    addTearDown(sub.close);

    await expectLater(
        container.read(last14ClosedCyclesProvider.future), throwsException);
    final value = container.read(weeklyPillarDaysProvider);

    expect(value.isLoading, isFalse);
    expect(value.hasError, isTrue);
    expect(value.valueOrNull, isNull);
  });
}
