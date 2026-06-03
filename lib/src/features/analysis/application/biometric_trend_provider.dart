// SPEC-152: provider derivado del historial biométrico ya persistido
// por SPEC-143.
//
// Filtra la lista en cliente a los últimos N días y la ordena
// ascendente (más antiguo primero — orden natural para plotear).
//
// No genera I/O adicional vs lo que progress_notifier ya consume; el
// repo expone el mismo stream y Riverpod no duplica suscripciones.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/progress/data/biometric_repository.dart';
import 'package:elena_app/src/features/progress/domain/biometric_checkin.dart';

/// Días válidos para el selector temporal del widget de tendencia.
/// Mantener sincronizado con `BodyCompositionTrendChart`.
const List<int> kBiometricTrendWindowDays = [30, 60, 90];

/// Stream de BiometricCheckIn de los últimos [days] días, ascendente
/// por fecha (más antiguo primero). Familia parametrizada por días
/// para que el widget pueda alternar 30/60/90 sin re-suscribir el repo.
///
/// La query subyacente es watchHistory(limit: 365) — el filtro es
/// client-side. Costo: despreciable (al peor 365 docs / usuario).
final biometricTrendProvider = StreamProvider.family
    .autoDispose<List<BiometricCheckIn>, int>((ref, days) {
  final account = ref.watch(authStateProvider).value;
  if (account == null) return Stream.value(const []);

  final cutoff = DateTime.now().subtract(Duration(days: days));

  return ref
      .watch(biometricRepositoryProvider)
      .watchHistory(account.uid)
      .map((list) {
    // Filtrar por ventana temporal. `date` viene como yyyy-MM-dd —
    // comparamos contra cutoff parseado igual.
    final cutoffKey = _dateKey(cutoff);
    final filtered = list.where((c) {
      // Si el doc tiene `date` válido lo usamos; si no, fallback a createdAt.
      return c.date.compareTo(cutoffKey) >= 0;
    }).toList();

    // El repo retorna descendente — invertimos para tener orden ascendente
    // (más viejo a más nuevo) que es lo natural para plotear de izquierda
    // a derecha.
    filtered.sort((a, b) => a.date.compareTo(b.date));
    return filtered;
  });
});

String _dateKey(DateTime dt) =>
    '${dt.year.toString().padLeft(4, '0')}-'
    '${dt.month.toString().padLeft(2, '0')}-'
    '${dt.day.toString().padLeft(2, '0')}';
