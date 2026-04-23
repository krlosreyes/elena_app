import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:elena_app/src/core/engine/metabolic_state_provider.dart';

class MetabolicObserver extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    if (provider.name == 'metabolicStateProvider') {
  debugPrint('------ METABOLIC STATE ------');
  debugPrint(newValue.toString());
}
  }
}