// SPEC-211: Tests del patrón de resiliencia de streams.
//
// Verifica que el patrón onDone + re-suscripción funciona correctamente
// cuando un stream de Dart se cierra (simulando token refresh / reconexión
// de Firestore). Los notifiers usan exactamente este patrón.
//
// No usa Riverpod ni Firebase — prueba la mecánica de streams pura.

import 'dart:async';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SPEC-211 — patrón onDone re-suscripción', () {
    test(
        'SPEC-211-01: onDone se invoca cuando un stream se cierra '
        '(simula token refresh de Firestore)', () async {
      final controller = StreamController<int>();
      var onDoneCalled = false;
      var dataReceived = 0;

      controller.stream.listen(
        (data) => dataReceived = data,
        onDone: () => onDoneCalled = true,
      );

      controller.add(42);
      await Future<void>.delayed(Duration.zero);
      expect(dataReceived, 42);
      expect(onDoneCalled, isFalse);

      // Simula cierre del stream (token refresh / reconexión Firestore)
      await controller.close();
      await Future<void>.delayed(Duration.zero);

      expect(onDoneCalled, isTrue,
          reason: 'onDone debe dispararse al cerrar el stream');
    });

    test(
        'SPEC-211-02: re-suscripción tras onDone recibe nuevos datos '
        '(simula reconexión exitosa)', () async {
      // Simula el patrón en los notifiers:
      // - stream1 se cierra (onDone)
      // - onDone crea stream2 (re-suscripción)
      // - stream2 entrega datos nuevos

      final controller1 = StreamController<int>();
      final controller2 = StreamController<int>();
      var lastData = 0;
      var subscribeCount = 0;

      void subscribe(StreamController<int> ctrl) {
        subscribeCount++;
        ctrl.stream.listen(
          (data) => lastData = data,
          onDone: () {
            // Re-suscripción al cerrar (patrón SPEC-211)
            if (subscribeCount < 2) subscribe(controller2);
          },
        );
      }

      subscribe(controller1);
      expect(subscribeCount, 1);

      controller1.add(10);
      await Future<void>.delayed(Duration.zero);
      expect(lastData, 10);

      // Stream 1 se cierra → re-suscripción a stream2
      await controller1.close();
      await Future<void>.delayed(Duration.zero);
      expect(subscribeCount, 2,
          reason: 'onDone debe haber disparado re-suscripción');

      // Stream2 entrega datos post-reconexión
      controller2.add(99);
      await Future<void>.delayed(Duration.zero);
      expect(lastData, 99,
          reason: 'La re-suscripción debe recibir datos nuevos');

      await controller2.close();
    });

    test(
        'SPEC-211-03: onError loguea pero no rompe la suscripción '
        '(simula error transitorio de red)', () async {
      final controller = StreamController<int>();
      var errorCaptured = false;
      var dataAfterError = 0;

      controller.stream.listen(
        (data) => dataAfterError = data,
        onError: (Object e) {
          errorCaptured = true;
          // No re-lanzar — el patrón SPEC-211 solo loguea
        },
        cancelOnError: false, // la suscripción sobrevive al error
      );

      controller.addError(Exception('connection_reset'));
      await Future<void>.delayed(Duration.zero);
      expect(errorCaptured, isTrue);

      // La suscripción sigue activa — puede recibir datos
      controller.add(55);
      await Future<void>.delayed(Duration.zero);
      expect(dataAfterError, 55,
          reason: 'La suscripción debe seguir activa tras un error transitorio');

      await controller.close();
    });

    test(
        'SPEC-211-04: cancelar antes de onDone no dispara re-suscripción '
        '(simula dispose del notifier)', () async {
      final controller = StreamController<int>();
      var onDoneCalled = false;
      var resubscribed = false;

      final sub = controller.stream.listen(
        (_) {},
        onDone: () {
          onDoneCalled = true;
          resubscribed = true; // en un notifier real: if (mounted) _subscribe()
        },
      );

      // Cancelar antes de cerrar (simula dispose del notifier)
      await sub.cancel();
      await controller.close();
      await Future<void>.delayed(Duration.zero);

      // onDone NO se llama si se canceló primero
      expect(onDoneCalled, isFalse,
          reason: 'cancel() previene onDone — dispose no causa re-suscripción');
      expect(resubscribed, isFalse);
    });
  });
}
