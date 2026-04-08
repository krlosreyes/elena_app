import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../health/application/decision_engine.dart';
import '../health/domain/entities/health_state.dart';

final healthStateProvider = Provider<HealthState>((ref) {
  try {
    final engine = DecisionEngine();
    return engine.computeHealthState();
  } catch (_) {
    return HealthState.initial();
  }
});
