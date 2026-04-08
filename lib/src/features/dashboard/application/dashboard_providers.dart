import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/health/providers/health_snapshot_provider.dart';
import 'dashboard_adapter.dart';

final dashboardTabIndexProvider = StateProvider<int>((ref) => 0);

/// 🧊 GUARDIÁN DE REGISTRO: Rastrea el último hito de comida disparado automáticamente
final lastAutomatedMealIndexProvider = StateProvider<int>((ref) => -1);

final dailyComplianceScoreProvider = Provider<double>((ref) {
  final snapshotData = ref.watch(healthSnapshotProvider).valueOrNull;
  if (snapshotData == null) return 0.0;
  const adapter = DashboardAdapter();
  final snapshot =
      adapter.adapt(snapshotData.state, decision: snapshotData.decision);
  return snapshot.compliance.totalImr;
});

final dailyMotivationalPhraseProvider = Provider<String>((ref) {
  final snapshotData = ref.watch(healthSnapshotProvider).valueOrNull;
  if (snapshotData == null) return 'Cargando tu estado metabólico…';
  const adapter = DashboardAdapter();
  final snapshot =
      adapter.adapt(snapshotData.state, decision: snapshotData.decision);
  return snapshot.mainMessage;
});

// `healthSnapshotProvider` is the single source for UI-facing dashboard state.
