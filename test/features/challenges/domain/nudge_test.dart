// SPEC-264: tests del catálogo de zumbidos (cerrado, positivo, con costo).

import 'package:elena_app/src/features/challenges/domain/nudge.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('el catálogo tiene ids únicos y costos no negativos', () {
    final ids = NudgeCatalog.all.map((k) => k.id).toSet();
    expect(ids.length, NudgeCatalog.all.length);
    for (final k in NudgeCatalog.all) {
      expect(k.cost, greaterThanOrEqualTo(0));
    }
  });

  test('byId recupera el tipo correcto y null si no existe', () {
    expect(NudgeCatalog.byId('zumbido'), NudgeCatalog.zumbido);
    expect(NudgeCatalog.byId('fuego')!.cost, 3);
    expect(NudgeCatalog.byId('inexistente'), isNull);
  });

  test('el mensaje incluye el nombre de quien envía y es positivo', () {
    final msg = NudgeCatalog.zumbido.messageFrom('Carlos');
    expect(msg.contains('Carlos'), isTrue);
    // Tono de aliento, no de burla.
    expect(msg.toLowerCase().contains('flojo'), isFalse);
  });

  test('Nudge.kind resuelve desde typeId', () {
    final n = Nudge(
      id: 'n1',
      fromUid: 'a',
      fromName: 'Ana',
      toUid: 'b',
      typeId: 'porra',
      createdAt: DateTime(2026, 8, 1),
    );
    expect(n.kind, NudgeCatalog.porra);
  });
}
