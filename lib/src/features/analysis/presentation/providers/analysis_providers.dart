import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_models.dart';
import 'package:elena_app/src/features/analysis/application/analysis_service.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

final analysisResultProvider = FutureProvider<AnalysisCache?>((ref) async {
  final user = ref.watch(currentUserStreamProvider).valueOrNull;
  if (user == null) return null;
  
  final service = ref.read(analysisServiceProvider);
  return service.calculateCorrelations(user.id);
});
