// SPEC-257 Eje D: registro liviano de síntomas de hipoglucemia al
// terminar un ayuno antes de tiempo.
//
// Grounding: Suárez marca mareo/temblor/palpitaciones como señal de
// alarma dura — "quítese", no una lista de diagnósticos a autoevaluar
// (ver SPEC-257 §2, fuente primaria preguntaleafrank.com). Este archivo
// persiste esa señal para que `AdaptiveEngine` dispare `simplify` de
// inmediato, sin esperar a que la adherencia semanal caiga lo bastante
// como para que `EngagementLevel.critico` lo detecte por su cuenta.
//
// SharedPreferences en vez de Firestore: es una señal de coaching
// efímera con ventana de 7 días, no un dato clínico que deba
// sincronizarse entre dispositivos ni sobrevivir una reinstalación.
//
// Marco normativo: specs/SPEC-257-clasificacion-protocolo-ayuno.md §4 Eje D.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';

class FastingSymptomLog {
  FastingSymptomLog._();

  static const String _kLastHypoglycemiaReportKey =
      'fasting_hypoglycemia_report_at';

  /// Ventana en la que un reporte cuenta como "reciente" para
  /// `AdaptiveEngine` — misma duración que la ventana semanal que ya
  /// usa `EngagementLevel`/`weeklyAdherence`, para no introducir un
  /// segundo período de referencia distinto en el motor.
  static const Duration recentWindow = Duration(days: 7);

  /// Registra que el usuario reportó síntomas de hipoglucemia al
  /// terminar un ayuno antes de tiempo (`early_fasting_end_dialog.dart`).
  static Future<void> reportHypoglycemia(SharedPreferences prefs) {
    return prefs.setString(
      _kLastHypoglycemiaReportKey,
      DateTime.now().toIso8601String(),
    );
  }

  /// true si hay un reporte dentro de [recentWindow]. `now` es
  /// inyectable para tests.
  static bool hasRecentReport(SharedPreferences prefs, {DateTime? now}) {
    final raw = prefs.getString(_kLastHypoglycemiaReportKey);
    if (raw == null) return false;
    final reportedAt = DateTime.tryParse(raw);
    if (reportedAt == null) return false;
    final reference = now ?? DateTime.now();
    final diff = reference.difference(reportedAt);
    return diff >= Duration.zero && diff <= recentWindow;
  }
}

/// true si hay un reporte de hipoglucemia reciente. `adaptiveProvider`
/// lo lee para forzar `SuggestionType.simplify` (SPEC-257 §4 Eje D)
/// sin importar el nivel de engagement.
final recentHypoglycemiaReportProvider = Provider<bool>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FastingSymptomLog.hasRecentReport(prefs);
});
