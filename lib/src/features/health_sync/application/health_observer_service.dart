// SPEC-132.next — cliente Dart del MethodChannel de los observers de HealthKit.
//
// Nativo (HealthKitObserver.swift) → Dart: `healthDataChanged { type }`.
// Dart → Nativo: `startObserving` / `stopObserving`.
//
// El servicio NO sincroniza: solo traduce los eventos nativos a un Stream que
// el provider side-effect consume para disparar el sync real.

import 'dart:async';

import 'package:flutter/services.dart';

/// Evento de cambio en Apple Health. `type` ∈ {weight, steps, sleep}.
class HealthObserverEvent {
  final String type;
  const HealthObserverEvent(this.type);
}

class HealthObserverService {
  HealthObserverService({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('com.metamorfosis.elena/healthkit_observer') {
    _channel.setMethodCallHandler(_handle);
  }

  final MethodChannel _channel;
  final StreamController<HealthObserverEvent> _controller =
      StreamController<HealthObserverEvent>.broadcast();

  Stream<HealthObserverEvent> get events => _controller.stream;

  /// Arranca los observers nativos. No-op silencioso si la plataforma no
  /// implementa el canal (Android/web) o si falla.
  Future<void> start() async {
    try {
      await _channel.invokeMethod('startObserving');
    } catch (_) {
      // Plataforma sin observers (Android/web) o error — el path foreground
      // (HealthAutoSyncController) sigue cubriendo el sync.
    }
  }

  Future<void> stop() async {
    try {
      await _channel.invokeMethod('stopObserving');
    } catch (_) {}
  }

  Future<dynamic> _handle(MethodCall call) async {
    if (call.method == 'healthDataChanged') {
      final args = call.arguments;
      final type = (args is Map ? args['type'] : null) as String? ?? 'unknown';
      if (!_controller.isClosed) {
        _controller.add(HealthObserverEvent(type));
      }
    }
    return null;
  }

  void dispose() {
    _channel.setMethodCallHandler(null);
    _controller.close();
  }
}
