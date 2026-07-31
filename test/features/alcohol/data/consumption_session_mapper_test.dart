// SPEC-261.4: round-trip del mapper de sesión (persistencia consistente).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/features/alcohol/data/mappers/consumption_session_mapper.dart';
import 'package:elena_app/src/features/alcohol/domain/consumption_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const mapper = ConsumptionSessionMapper();

  test('toMap → fromMap preserva los metadatos', () {
    final start = DateTime(2026, 8, 1, 20, 0);
    final wake = DateTime(2026, 8, 2, 7, 0);
    final bed = DateTime(2026, 8, 1, 23, 30);
    final lastCall = DateTime(2026, 8, 1, 20, 30);

    final session = ConsumptionSession(
      phase: ConsumptionPhase.durante,
      budgetStandardUnits: 3,
      drinkTypeId: 'vino',
      startTime: start,
      worksTomorrow: true,
      wakeTime: wake,
      bedtime: bed,
      lastCallTarget: lastCall,
      hydratedBefore: true,
      ateBefore: false,
      recoveryFastPlanned: true,
    );

    final map = mapper.toMap(session);
    final back = mapper.fromMap(map);

    expect(back.phase, ConsumptionPhase.durante);
    expect(back.budgetStandardUnits, 3);
    expect(back.drinkTypeId, 'vino');
    expect(back.worksTomorrow, isTrue);
    expect(back.hydratedBefore, isTrue);
    expect(back.ateBefore, isFalse);
    expect(back.recoveryFastPlanned, isTrue);
    expect(back.startTime!.isAtSameMomentAs(start), isTrue);
    expect(back.wakeTime!.isAtSameMomentAs(wake), isTrue);
    expect(back.bedtime!.isAtSameMomentAs(bed), isTrue);
    expect(back.lastCallTarget!.isAtSameMomentAs(lastCall), isTrue);
    // No se persiste `drinks` en este documento.
    expect(back.drinks, isEmpty);
  });

  test('fromMap tolera un mapa vacío (defaults inactivos)', () {
    final back = mapper.fromMap(<String, dynamic>{});
    expect(back.phase, ConsumptionPhase.inactive);
    expect(back.drinkTypeId, isNull);
    expect(back.worksTomorrow, isFalse);
  });

  test('serializa fechas como Timestamp', () {
    final session = ConsumptionSession(startTime: DateTime(2026, 8, 1, 20));
    final map = mapper.toMap(session);
    expect(map['startTime'], isA<Timestamp>());
    expect(map['phase'], 'inactive');
  });
}
