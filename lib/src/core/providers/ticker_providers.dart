import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// B-21 (auditoría 2026-07-27): este archivo declaraba además `clockProvider`
// (1 s) y `minuteTickerProvider` (1 min). Un grep sobre todo `lib/` devolvió
// CERO consumidores de ambos: eran dos `Stream.periodic` permanentes,
// documentados como si estuvieran en uso, en el núcleo de la app. Se
// retiraron. Si en el futuro hace falta una cadencia distinta, se añade
// entonces y con su consumidor.

/// Pulso para recálculos metabólicos (cada 10 segundos).
///
/// Es el ÚNICO ticker de la aplicación. Alimenta `metabolicStateProvider`,
/// `fastingNotifier`, `eatingWindowProvider`, `metabolicCycleEvaluator`,
/// `nextMealProvider` y el banner de próxima comida.
///
/// I-01 (auditoría 2026-07-27): que este pulso emita no implica que se
/// recompute nada. `MetabolicState` implementa igualdad estructural y
/// `maxFastingHoursToday` se redondea a la centésima de hora, de modo que
/// dos ticks consecutivos producen un estado idéntico y Riverpod corta la
/// propagación. Antes del redondeo, cada tick disparaba el recálculo
/// completo del IMR: ~5.760 veces por ayuno de 16 h.
final metabolicPulseProvider = StreamProvider<DateTime>((ref) {
  return Stream.periodic(const Duration(seconds: 10), (_) => DateTime.now());
});
