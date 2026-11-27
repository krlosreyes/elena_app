// SPEC-168.4.4 (2026-06-03): zona de composición corporal según
// rangos del American Council on Exercise (ACE), iguales al sitio. Misma escala que GoalSuggestionEngine._fatZoneLabel
// — extraída para reuso visual (silueta + badge).
//
// Pure Dart — sin Flutter ni Riverpod.

import 'package:flutter/material.dart';

enum BodyZone {
  esencial,
  atletico,
  fitness,
  promedio,
  alto;

  String get label {
    switch (this) {
      case BodyZone.esencial:
        return 'Esencial';
      case BodyZone.atletico:
        return 'Atletas';
      case BodyZone.fitness:
        return 'Fitness';
      case BodyZone.promedio:
        return 'Promedio';
      case BodyZone.alto:
        return 'Obesidad';
    }
  }

  /// Color del badge y del tinte de silueta. Verde = saludable;
  /// ámbar = transición; naranja = riesgo.
  Color get color {
    switch (this) {
      case BodyZone.esencial:
        // Muy debajo del rango — atletas de élite o riesgo opuesto.
        return const Color(0xFF60A5FA); // azul informativo
      case BodyZone.atletico:
        return const Color(0xFF10B981); // verde
      case BodyZone.fitness:
        return const Color(0xFF34D399); // verde-lima
      case BodyZone.promedio:
        return const Color(0xFFF59E0B); // ámbar
      case BodyZone.alto:
        return const Color(0xFFFB923C); // naranja
    }
  }
}

/// Clasifica un % de grasa en una zona ACE según el género.
/// Devuelve null si la entrada es inválida.
///
/// Rangos ACE (igual que el sitio y GoalSuggestionEngine):
///   Hombre: <6 esencial, <14 atlético, <18 fitness, <25 promedio, ≥25 alto
///   Mujer:  <14 esencial, <21 atlético, <25 fitness, <32 promedio, ≥32 alto
BodyZone? bodyZoneFor(double? bf, bool isMale) {
  if (bf == null || bf <= 0) return null;
  if (isMale) {
    if (bf < 6) return BodyZone.esencial;
    if (bf < 14) return BodyZone.atletico;
    if (bf < 18) return BodyZone.fitness;
    if (bf < 25) return BodyZone.promedio;
    return BodyZone.alto;
  } else {
    if (bf < 14) return BodyZone.esencial;
    if (bf < 21) return BodyZone.atletico;
    if (bf < 25) return BodyZone.fitness;
    if (bf < 32) return BodyZone.promedio;
    return BodyZone.alto;
  }
}
