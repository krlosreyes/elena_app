// SPEC-309: legibilidad para una audiencia mayoritariamente de 55+.
//
// La app tiene cientos de textos con tamaño fijo de 7,5 a 12 pt. En vez
// de editarlos uno por uno, este TextScaler impone un tamaño mínimo
// renderizado sin quitarle al usuario el tamaño de texto que eligió en
// iOS (Dynamic Type): primero escala con el ajuste del sistema y luego
// aplica el piso.
//
// Referencia: NIA / NLM, "Making Your Website Senior Friendly" (texto de
// 12–14 pt como mínimo) y Apple HIG (11 pt como mínimo absoluto).
// Los íconos no se ven afectados: Icon no aplica text scaling.

import 'dart:math' as math;

import 'package:flutter/widgets.dart';

class MinSizeTextScaler extends TextScaler {
  const MinSizeTextScaler(this.base, {this.minFontSize = kMinReadableFontSize});

  final TextScaler base;
  final double minFontSize;

  @override
  double scale(double fontSize) {
    final double scaled = base.scale(fontSize);
    if (fontSize <= 0) return scaled;
    return math.max(scaled, minFontSize);
  }

  @override
  // ignore: deprecated_member_use
  double get textScaleFactor => base.textScaleFactor;

  @override
  bool operator ==(Object other) =>
      other is MinSizeTextScaler &&
      other.base == base &&
      other.minFontSize == minFontSize;

  @override
  int get hashCode => Object.hash(base, minFontSize);
}

/// Tamaño mínimo de texto renderizado en la app (pt lógicos).
const double kMinReadableFontSize = 12.5;
