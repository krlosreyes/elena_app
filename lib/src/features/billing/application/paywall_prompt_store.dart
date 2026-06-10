// SPEC-198 — recuerda si el paywall proactivo ya se mostró HOY (para no
// saturar). Prefs-backed, simple e imperativo (lo consulta el orquestador
// del Home, no necesita reactividad).

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';

class PaywallPromptStore {
  PaywallPromptStore(this._prefs);

  final SharedPreferences _prefs;
  static const String _kKey = 'paywall.lastAutoShownDate';

  static String _dateKey(DateTime dt) =>
      '${dt.year.toString().padLeft(4, '0')}-'
      '${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')}';

  /// ¿Ya se mostró el paywall proactivo hoy?
  bool shownToday(DateTime now) => _prefs.getString(_kKey) == _dateKey(now);

  /// Marca que se mostró hoy.
  Future<void> markShown(DateTime now) =>
      _prefs.setString(_kKey, _dateKey(now));
}

final paywallPromptStoreProvider = Provider<PaywallPromptStore>((ref) {
  return PaywallPromptStore(ref.watch(sharedPreferencesProvider));
});
