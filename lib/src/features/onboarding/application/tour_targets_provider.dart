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
