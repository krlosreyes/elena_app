import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/glucose/data/glucose_repository.dart'
    hide glucoseRepositoryProvider;
import 'package:elena_app/src/features/glucose/domain/glucose_model.dart';
import 'package:elena_app/src/features/authentication/application/auth_controller.dart';

// 1. Provider del Repositorio (CORREGIDO)
final glucoseRepositoryProvider = Provider<GlucoseRepository>((ref) {
  // FIX: Pasamos la instancia de Firestore requerida por el constructor
  return GlucoseRepository(FirebaseFirestore.instance);
});

// Enum for Time Filter
enum TimeFilter { semana, mes, ano }

// Provider for the selected filter
class GlucoseTimeFilterNotifier extends Notifier<TimeFilter> {
  @override
  TimeFilter build() => TimeFilter.semana;

  void setFilter(TimeFilter filter) {
    state = filter;
  }
}

// Provider for the selected filter
final glucoseTimeFilterProvider =
    NotifierProvider<GlucoseTimeFilterNotifier, TimeFilter>(
        GlucoseTimeFilterNotifier.new);

// 2. Provider de Datos Filtrados (Reactivo)
final filteredGlucoseProvider =
    StreamProvider.autoDispose<List<GlucoseLog>>((ref) {
  // Escuchamos al usuario actual
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;

  // Si no hay usuario, devolvemos stream vacío
  if (user == null) {
    return const Stream.empty();
  }

  // Escuchamos el filtro seleccionado
  final filter = ref.watch(glucoseTimeFilterProvider);

  // Calculamos startDate según el filtro
  // Calculamos startDate según el filtro
  DateTime startDate =
      DateTime.now().subtract(const Duration(days: 7)); // Default value
  switch (filter) {
    case TimeFilter.semana:
      startDate = DateTime.now().subtract(const Duration(days: 7));
      break;
    case TimeFilter.mes:
      startDate = DateTime.now().subtract(const Duration(days: 30));
      break;
    case TimeFilter.ano:
      startDate = DateTime.now().subtract(const Duration(days: 365));
      break;
  }

  // Obtenemos el repo y pedimos los datos con el UID y startDate
  final repository = ref.watch(glucoseRepositoryProvider);
  return repository.getGlucoseLogs(uid: user.uid, startDate: startDate);
});

// 3. Proveedor del último registro (para el Hub Metabólico)
final latestGlucoseLogProvider = StreamProvider.autoDispose<GlucoseLog?>((ref) {
  final authState = ref.watch(authStateChangesProvider);
  final user = authState.value;
  if (user == null) return const Stream.empty();

  final repository = ref.watch(glucoseRepositoryProvider);
  // Obtenemos el último registro (limit 1)
  return repository.getLatestGlucoseLog(user.uid);
});
