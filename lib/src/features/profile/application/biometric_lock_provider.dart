// SPEC-BUG7: provider reactivo del bloqueo biométrico.
//
// Lee dos fuentes:
//   - SharedPreferences (`biometry_last_edit_at`) para el timestamp
//     del último edit de biometría.
//   - cheatDayProvider para el último cheat day registrado.
//
// Se recomputa automáticamente cuando cualquiera de las dos cambia
// (Riverpod dependency tracking). Eso significa que activar un cheat
// day mientras el Perfil está abierto desbloquea la edición sin
// necesidad de refrescar la pantalla.

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/features/nutrition/application/cheat_day_notifier.dart';
import 'package:elena_app/src/features/profile/domain/biometric_lock_service.dart';

final biometricLockProvider = Provider<BiometricLockState>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  final cheatDay = ref.watch(cheatDayProvider);

  return BiometricLockService.compute(
    lastEditIso: prefs.getString(BiometricLockService.kLastEditKey),
    lastCheatDate: cheatDay.lastCheatDate,
  );
});
