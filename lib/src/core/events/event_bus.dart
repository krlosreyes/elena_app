import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ─────────────────────────────────────────────────────────────────────────────
/// AppEvent
/// Modelo base para todos los eventos del sistema
/// ─────────────────────────────────────────────────────────────────────────────
class AppEvent {
  final String type;
  final Map<String, dynamic> payload;
  final DateTime timestamp;

  AppEvent({
    required this.type,
    required this.payload,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'AppEvent(type: $type, payload: $payload, timestamp: $timestamp)';
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// EventBus
/// Stream global desacoplado para emitir y escuchar eventos
/// ─────────────────────────────────────────────────────────────────────────────
class EventBus {
  final StreamController<AppEvent> _controller =
      StreamController<AppEvent>.broadcast();

  /// Stream público para listeners
  Stream<AppEvent> get stream => _controller.stream;

  /// Emitir evento
  void emit(AppEvent event) {
    _controller.add(event);
  }

  /// Cerrar stream (no usar por ahora en MVP)
  void dispose() {
    _controller.close();
  }
}

/// ─────────────────────────────────────────────────────────────────────────────
/// Provider global
/// ─────────────────────────────────────────────────────────────────────────────
final eventBusProvider = Provider<EventBus>((ref) {
  final bus = EventBus();

  ref.onDispose(() {
    bus.dispose();
  });

  return bus;
});