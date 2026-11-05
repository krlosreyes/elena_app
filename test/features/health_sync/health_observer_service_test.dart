// SPEC-132.next — tests del cliente Dart del MethodChannel de observers.

import 'package:elena_app/src/features/health_sync/application/health_observer_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.metamorfosis.elena/healthkit_observer');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
  });

  test('start() invoca startObserving en el canal nativo', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });

    final service = HealthObserverService();
    await service.start();

    expect(calls, contains('startObserving'));
    service.dispose();
  });

  test('stop() invoca stopObserving', () async {
    final calls = <String>[];
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      return null;
    });

    final service = HealthObserverService();
    await service.stop();

    expect(calls, contains('stopObserving'));
    service.dispose();
  });

  test('un evento nativo healthDataChanged emite en el stream', () async {
    final service = HealthObserverService();
    final firstEvent = service.events.first;

    // Simular llamada nativo → Dart. 2026-11-04: la respuesta a iOS llega
    // solo cuando quien procesa el evento completa `done`.
    var replied = false;
    final reply = messenger.handlePlatformMessage(
      channel.name,
      const StandardMethodCodec().encodeMethodCall(
        const MethodCall('healthDataChanged', {'type': 'weight'}),
      ),
      (_) => replied = true,
    );

    final event = await firstEvent;
    expect(event.type, 'weight');
    await Future<void>.delayed(const Duration(milliseconds: 50));
    expect(replied, isFalse, reason: 'iOS espera a que termine el sync');
    event.done!.complete();
    await reply;
    expect(replied, isTrue);
    service.dispose();
  });

  test('start() no lanza si la plataforma no implementa el canal', () async {
    // Sin mock handler → invokeMethod lanza MissingPluginException, que el
    // servicio absorbe. No debe propagar.
    final service = HealthObserverService();
    await expectLater(service.start(), completes);
    service.dispose();
  });
}
