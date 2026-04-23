import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Un provider que emite el tiempo actual cada segundo.
/// Sirve como trigger reactivo para cálculos que dependen del tiempo (ej: duración de ayuno).
final clockProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 1), (_) => DateTime.now());
});

/// Un ticker más lento para tareas que no requieren precisión de segundos (ej: cada minuto).
final minuteTickerProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(minutes: 1), (_) => DateTime.now());
});

/// Pulso para recálculos metabólicos (ej: cada 10 segundos).
/// Optimiza el rendimiento evitando recomputar scores pesados cada segundo.
final metabolicPulseProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 10), (_) => DateTime.now());
});

