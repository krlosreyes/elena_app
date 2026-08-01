// SPEC-261.9: provider del historial de salidas.
//
// Lee alcohol_history de los últimos 90 días (query de un solo campo por
// timestamp → índice automático, sin compuesto) y lo agrupa en salidas.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/alcohol/data/consumption_repository_impl.dart';
import 'package:elena_app/src/features/alcohol/domain/outing_history.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

/// Ventana del historial. 90 días alcanza para una tendencia útil sin traer
/// toda la colección.
const Duration _historyWindow = Duration(days: 90);

final outingHistoryProvider = StreamProvider<List<Outing>>((ref) {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null) return Stream.value(const <Outing>[]);
  final repo = ref.watch(consumptionRepositoryProvider);
  final since = DateTime.now().subtract(_historyWindow);
  return repo.watchSince(user.id, since).map(OutingHistory.fromDrinks);
});
