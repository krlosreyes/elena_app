import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../health/domain/entities/health_state.dart';

// 🛡️ FIX: computeHealthState() ahora requiere un UserHealthState como argumento.
// Este provider heredado no tiene acceso al estado completo, por lo que devuelve
// el estado inicial. El pipeline real corre por healthSnapshotProvider.
final healthStateProvider = Provider<HealthState>((ref) {
  return HealthState.initial();
});
