// SPEC-217: test de la lógica de prioridad de streamLatest.
//
// No instancia FirestoreFastingIntervalV1Source (requiere Firebase).
// Verifica la mecánica de selección de doc (prioridad A/B/C de SPEC-100)
// con la misma lógica que usa el source real — de forma pura.

import 'package:flutter_test/flutter_test.dart';

// ─── Replica de la lógica de prioridad de streamLatest ───────────────────────

/// Retorna el Map "ganador" de [docs] según la prioridad SPEC-100:
/// (a) Primero con isFasting=true y endTime=null  [ayuno abierto]
/// (b) Primero con endTime=null                   [ventana de comida abierta]
/// (c) El primero de la lista                     [más reciente cerrado]
Map<String, dynamic>? _selectLatest(List<Map<String, dynamic>> docs) {
  if (docs.isEmpty) return null;

  for (final data in docs) {
    if (data['endTime'] == null && data['isFasting'] == true) return data;
  }
  for (final data in docs) {
    if (data['endTime'] == null) return data;
  }
  return docs.first;
}

void main() {
  group('SPEC-217 — prioridad streamLatest (lógica pura SPEC-100)', () {
    test('SPEC-217-01: lista vacía → null', () {
      expect(_selectLatest([]), isNull);
    });

    test('SPEC-217-02: ayuno abierto gana sobre cualquier otro doc', () {
      final docs = [
        {'isFasting': false, 'endTime': null, 'label': 'ventana'},
        {'isFasting': true, 'endTime': null, 'label': 'ayuno-abierto'},
        {'isFasting': true, 'endTime': 'ts', 'label': 'ayuno-cerrado'},
      ];
      final result = _selectLatest(docs);
      expect(result?['label'], 'ayuno-abierto');
    });

    test('SPEC-217-03: sin ayuno abierto → primera ventana de comida abierta',
        () {
      final docs = [
        {'isFasting': true, 'endTime': 'ts', 'label': 'ayuno-cerrado'},
        {'isFasting': false, 'endTime': null, 'label': 'ventana-abierta'},
      ];
      final result = _selectLatest(docs);
      expect(result?['label'], 'ventana-abierta');
    });

    test('SPEC-217-04: todo cerrado → primer doc (más reciente por startTime)',
        () {
      final docs = [
        {'isFasting': true, 'endTime': 'ts2', 'label': 'reciente'},
        {'isFasting': true, 'endTime': 'ts1', 'label': 'antiguo'},
      ];
      final result = _selectLatest(docs);
      expect(result?['label'], 'reciente');
    });

    test('SPEC-217-05: un solo doc cerrado → ese doc', () {
      final docs = [
        {'isFasting': true, 'endTime': 'ts', 'label': 'único'},
      ];
      final result = _selectLatest(docs);
      expect(result?['label'], 'único');
    });
  });
}
