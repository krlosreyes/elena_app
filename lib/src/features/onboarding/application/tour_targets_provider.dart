// SPEC-243 fix — GlobalKey compartido para medir posición real de los pilares.
//
// El AppTourOverlay vive en el root Stack de app.dart, fuera del árbol de
// navegación. Para calcular las coordenadas del spotlight de cada pilar
// necesita la posición real en pantalla del Row que los contiene.
//
// Flujo:
//   1. DashboardScreen asigna `pillarRowKeyProvider` al Row de PillarRings.
//   2. AppTourOverlay lee la misma key y llama `localToGlobal()` para
//      obtener el origen Y real, independientemente de cuántas cards
//      condicionales aparezcan encima en el scroll.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// GlobalKey del Row que contiene los 5 PillarRings en DashboardScreen.
/// Lifetime: toda la sesión (Provider sin autoDispose).
final pillarRowKeyProvider = Provider<GlobalKey>((ref) => GlobalKey());

/// GlobalKey del widget DualScoreRing en DashboardScreen.
/// Permite a AppTourOverlay calcular la posición exacta del scoreCard
/// spotlight independientemente del scroll y de las cards condicionales.
final dualScoreRingKeyProvider = Provider<GlobalKey>((ref) => GlobalKey());

/// ScrollController del SingleChildScrollView de DashboardScreen.
///
/// Lo comparte con AppTourOverlay para dos propósitos:
///   1. Hacer scroll automático cuando el tour activa un paso de pilar,
///      trayendo el Row de anillos a una posición visible.
///   2. Rebuilds reactivos del overlay al scrollear, de modo que el
///      spotlight siga el Row en tiempo real durante la animación.
final dashboardScrollControllerProvider = Provider<ScrollController>((ref) {
  final ctrl = ScrollController();
  ref.onDispose(ctrl.dispose);
  return ctrl;
});
