// 17-jul: tests de `SleepRepositoryImpl.watchLatest` — la resolución
// "manual gana sobre auto" del lado de LECTURA (ver comentario extenso
// en `sleep_repository_impl.dart`). Carlos reportó "el anillo de sueño
// no muestra el dato correcto" incluso después del guard de escritura
// en `HealthImportService` — la causa era que `watchLatest` elegía
// ciegamente el doc con `wokeUp` más tardío sin importar origen, así
// que datos automáticos ya escritos ANTES del guard seguían ganando.
// Esta resolución corre en lectura y autorepara ese escenario.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:elena_app/src/features/sleep/data/sleep_repository_impl.dart';
import 'package:elena_app/src/features/sleep/data/sources/sleep_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeSleepDataSource implements SleepDataSource {
  final _recentController =
      StreamController<List<Map<String, dynamic>>>.broadcast();

  @override
  Stream<Map<String, dynamic>?> streamLatest(String userId) =>
      const Stream.empty();

  @override
  Stream<List<Map<String, dynamic>>> streamRecent({
    required String userId,
    required int limit,
  }) =>
      _recentController.stream;

  @override
  Future<void> persist({
    required String userId,
    required String docId,
    required Map<String, dynamic> data,
  }) async {}

  @override
  Future<void> deleteDoc({
    required String userId,
    required String docId,
  }) async {}

  @override
  Future<Map<String, dynamic>?> fetchById({
    required String userId,
    required String docId,
  }) async =>
      null;

  /// Simula una emisión de `streamRecent` — ya ordenada por `wokeUp`
  /// desc, como haría Firestore real.
  void emit(List<Map<String, dynamic>> docs) => _recentController.add(docs);

  void dispose() => _recentController.close();
}

Map<String, dynamic> _doc({
  required String id,
  required DateTime fellAsleep,
  required DateTime wokeUp,
}) {
  return {
    '__docId': id,
    'fellAsleep': Timestamp.fromDate(fellAsleep),
    'wokeUp': Timestamp.fromDate(wokeUp),
    'lastMealTime':
        Timestamp.fromDate(fellAsleep.subtract(const Duration(hours: 3))),
  };
}

void main() {
  late _FakeSleepDataSource source;
  late SleepRepositoryImpl repo;
  const userId = 'user-1';

  setUp(() {
    source = _FakeSleepDataSource();
    repo = SleepRepositoryImpl(source: source);
  });

  tearDown(() => source.dispose());

  test('sin manual: gana el automático con wokeUp más tardío (sin cambios de comportamiento)',
      () async {
    final future = repo.watchLatest(userId).first;
    source.emit([
      _doc(
        id: 'hk_sleep_b',
        fellAsleep: DateTime(2026, 5, 26, 23),
        wokeUp: DateTime(2026, 5, 27, 7, 15),
      ),
      _doc(
        id: 'hk_sleep_a',
        fellAsleep: DateTime(2026, 5, 26, 22, 50),
        wokeUp: DateTime(2026, 5, 27, 7),
      ),
    ]);
    final result = await future;
    expect(result?.id, 'hk_sleep_b');
  });

  test(
      'manual + auto de la MISMA noche, auto con wokeUp más tardío → gana el manual (bug reportado)',
      () async {
    final future = repo.watchLatest(userId).first;
    source.emit([
      // El auto tiene wokeUp MÁS TARDÍO (típico: etapa "despierto"
      // espuria del reloj) — antes del fix esto ganaba y desplazaba lo
      // que el usuario registró a mano.
      _doc(
        id: 'hk_sleep_espurio',
        fellAsleep: DateTime(2026, 5, 26, 23),
        wokeUp: DateTime(2026, 5, 27, 7, 45),
      ),
      _doc(
        id: 'sleep_20260527',
        fellAsleep: DateTime(2026, 5, 26, 23),
        wokeUp: DateTime(2026, 5, 27, 7),
      ),
    ]);
    final result = await future;
    expect(result?.id, 'sleep_20260527');
  });

  test(
      'manual de anoche vs auto de una siesta más tarde el mismo día → gana el manual',
      () async {
    // La siesta y la noche caen en la misma "noche de atribución"
    // (ambas el mismo día calendario del punto medio) — el manual de
    // la noche real sigue ganando sobre el fragmento automático de la
    // siesta, aunque la siesta sea cronológicamente posterior.
    final future = repo.watchLatest(userId).first;
    source.emit([
      _doc(
        id: 'hk_sleep_siesta',
        fellAsleep: DateTime(2026, 5, 27, 14),
        wokeUp: DateTime(2026, 5, 27, 14, 30),
      ),
      _doc(
        id: 'sleep_20260527',
        fellAsleep: DateTime(2026, 5, 26, 23),
        wokeUp: DateTime(2026, 5, 27, 7),
      ),
    ]);
    final result = await future;
    expect(result?.id, 'sleep_20260527');
  });

  test('manual de una noche vieja NO gana sobre un automático de una noche más reciente',
      () async {
    // "Manual gana" es un criterio DENTRO de la misma noche, no un
    // comodín global — una noche más reciente siempre gana sobre una
    // más vieja, sea cual sea el origen.
    final future = repo.watchLatest(userId).first;
    source.emit([
      _doc(
        id: 'hk_sleep_anoche',
        fellAsleep: DateTime(2026, 5, 27, 23),
        wokeUp: DateTime(2026, 5, 28, 7),
      ),
      _doc(
        id: 'sleep_20260526',
        fellAsleep: DateTime(2026, 5, 25, 23),
        wokeUp: DateTime(2026, 5, 26, 7),
      ),
    ]);
    final result = await future;
    expect(result?.id, 'hk_sleep_anoche');
  });

  test('lista vacía → null', () async {
    final future = repo.watchLatest(userId).first;
    source.emit(const []);
    final result = await future;
    expect(result, isNull);
  });

  test(
      '17-jul: sin manual, siesta vespertina con wokeUp más tardío YA NO le gana al sueño real (bug de Carlos)',
      () async {
    // Este es el escenario que "manual gana" no cubría: sin ningún
    // manual esa noche, dos automáticos compiten y antes ganaba
    // ciegamente el de `wokeUp` más tardío — la siesta de las 3pm le
    // ganaba al sueño real de esa madrugada. Con el filtro "nocturno y
    // de calidad" la siesta queda descartada antes de competir.
    final future = repo.watchLatest(userId).first;
    source.emit([
      _doc(
        id: 'hk_sleep_siesta',
        fellAsleep: DateTime(2026, 5, 27, 14),
        wokeUp: DateTime(2026, 5, 27, 15, 30),
      ),
      _doc(
        id: 'hk_sleep_real',
        fellAsleep: DateTime(2026, 5, 26, 23),
        wokeUp: DateTime(2026, 5, 27, 7),
      ),
    ]);
    final result = await future;
    expect(result?.id, 'hk_sleep_real');
  });

  test('17-jul: solo hay una siesta capturada (sin sueño nocturno real) → null, no la siesta',
      () async {
    final future = repo.watchLatest(userId).first;
    source.emit([
      _doc(
        id: 'hk_sleep_siesta',
        fellAsleep: DateTime(2026, 5, 27, 14),
        wokeUp: DateTime(2026, 5, 27, 15, 30),
      ),
    ]);
    final result = await future;
    expect(result, isNull);
  });

  test('doc corrupto se descarta en silencio, el resto se resuelve igual', () async {
    // "Corrupto" en el sentido que el mapper realmente rechaza: el
    // constructor de SleepLog valida rangos de los campos SPEC-69
    // (subjectiveQuality debe ser 1-5). Timestamps ausentes o mal
    // parseados degradan a epoch sin lanzar (comportamiento ya
    // existente del mapper) — no sirven para probar esta rama.
    final corrupto = _doc(
      id: 'hk_sleep_corrupto',
      fellAsleep: DateTime(2026, 5, 27, 3),
      wokeUp: DateTime(2026, 5, 27, 9),
    )..['subjectiveQuality'] = 99;

    final future = repo.watchLatest(userId).first;
    source.emit([
      corrupto,
      _doc(
        id: 'sleep_20260527',
        fellAsleep: DateTime(2026, 5, 26, 23),
        wokeUp: DateTime(2026, 5, 27, 7),
      ),
    ]);
    final result = await future;
    expect(result?.id, 'sleep_20260527');
  });
}
