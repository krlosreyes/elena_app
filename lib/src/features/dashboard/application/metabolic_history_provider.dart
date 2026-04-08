import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../profile/application/user_controller.dart';
import '../data/metabolic_history_repository.dart';

final weeklyHistoryStreamProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null) return Stream.value([]);
  
  // CAMBIO: Usamos user.uid que es el estándar de tu modelo
  return ref.watch(metabolicHistoryRepositoryProvider).watchWeeklyHistory(user.uid);
});