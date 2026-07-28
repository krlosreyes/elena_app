// SPEC-143 §RF-143-07: tests del biometricBackfillProvider.
//
// Verifica los tres escenarios principales:
//   1. Usuario sin historial → backfill se ejecuta.
//   2. Usuario CON historial → backfill se skipea.
//   3. Segunda emisión del stream → no re-dispara (one-shot por sesión).

import 'dart:async';

import 'package:elena_app/src/features/progress/application/biometric_backfill_provider.dart';
import 'package:elena_app/src/features/progress/application/biometric_history_service.dart';
import 'package:elena_app/src/features/progress/data/biometric_repository.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _defaultProfile = CircadianProfile(
  wakeUpTime: DateTime(2026, 1, 1, 7, 0),
  sleepTime: DateTime(2026, 1, 1, 23, 0),
);

UserModel _user({String id = 'u1'}) => UserModel(
      id: id,
      age: 35,
      gender: 'M',
      weight: 75,
      height: 175,
      waistCircumference: 90,
      neckCircumference: 38,
      bodyFatPercentage: 20,
      profile: _defaultProfile,
    );

/// Stream controller para simular emisiones del currentUserStreamProvider.
class _UserStreamController {
  final controller = StreamController<UserModel?>.broadcast();
  Stream<UserModel?> get stream => controller.stream;
  void emit(UserModel? user) => controller.add(user);
  Future<void> close() => controller.close();
}

/// Fake del servicio que cuenta llamadas a writeSpec143BackfillEntry.
class _CountingHistoryService extends BiometricHistoryService {
  _CountingHistoryService(FakeFirebaseFirestore fs)
      : super(biometricRepo: BiometricRepository(fs));

  int backfillCalls = 0;
  bool shouldFail = false;

  @override
  Future<void> writeSpec143BackfillEntry({
    required UserModel currentUser,
  }) async {
    if (shouldFail) throw Exception('disk full');
    backfillCalls++;
    // No invocamos al super para no escribir realmente.
  }
}

void main() {
  late FakeFirebaseFirestore firestore;
  late BiometricRepository realRepo;
  late _CountingHistoryService service;
  late _UserStreamController userStream;
  late ProviderContainer container;

  setUp(() {
    firestore = FakeFirebaseFirestore();
    realRepo = BiometricRepository(firestore);
    service = _CountingHistoryService(firestore);
    userStream = _UserStreamController();
    container = ProviderContainer(overrides: [
      currentUserStreamProvider.overrideWith((ref) => userStream.stream),
      biometricRepositoryProvider.overrideWithValue(realRepo),
      biometricHistoryServiceProvider.overrideWithValue(service),
    ]);
  });

  tearDown(() async {
    container.dispose();
    await userStream.close();
  });

  test('Usuario sin historial → backfill se ejecuta una vez', () async {
    container.read(biometricBackfillProvider);

    userStream.emit(_user());
    // Yield para que el async listen termine I/O simulado.
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(service.backfillCalls, 1);
  });

  test('Usuario CON historial → backfill se skipea', () async {
    // Pre-cargar una entrada para que fetchLatest no retorne null.
    await firestore
        .collection('users')
        .doc('u1')
        .collection('biometric_history')
        .doc('2025-06-01')
        .set({
      'date': '2025-06-01',
      'userId': 'u1',
      'weight': 75.0,
      'createdAt': '2025-06-01T10:00:00.000Z',
    });

    container.read(biometricBackfillProvider);

    userStream.emit(_user());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(service.backfillCalls, 0,
        reason: 'Usuario ya tiene historial — no necesita backfill');
  });

  test('Segunda emisión del stream NO re-dispara (one-shot por sesión)',
      () async {
    container.read(biometricBackfillProvider);

    userStream.emit(_user());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    // Re-emitir (simula token refresh, edit profile, etc.).
    userStream.emit(_user());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(service.backfillCalls, 1, reason: 'Solo una vez por sesión');
  });

  test('Stream emite null primero, luego user → backfill al user', () async {
    container.read(biometricBackfillProvider);

    userStream.emit(null);
    await Future<void>.delayed(Duration.zero);

    expect(service.backfillCalls, 0, reason: 'Null user no dispara backfill');

    userStream.emit(_user());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(service.backfillCalls, 1);
  });

  test('Error del servicio → resetea flag, próxima emisión puede reintentar',
      () async {
    service.shouldFail = true;
    container.read(biometricBackfillProvider);

    userStream.emit(_user());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(service.backfillCalls, 0, reason: 'Falló sin contar');

    // Reintentamos sin la falla — debe ejecutar.
    service.shouldFail = false;
    userStream.emit(_user());
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);

    expect(service.backfillCalls, 1, reason: 'Segunda vez sí escribió');
  });
}
