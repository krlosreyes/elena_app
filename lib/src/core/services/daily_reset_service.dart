import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/hydration_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/ui_interaction_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';

/// SPEC-33 + SPEC-58: Servicio que detecta cambios de día y triggeriza
/// resets circadianos de los 5 pilares.
///
/// SPEC-58:
/// - Reset sistémico: ayuno, nutrición, hidratación, ejercicio, sueño.
/// - Detección en startup (vía SharedPreferences) y en runtime (timer).
/// - Idempotente: invocarlo dos veces produce el mismo resultado.
/// - El ayuno NO elimina su FastingInterval — el ayuno es multi-día por
///   diseño; sólo se limpian flags efímeros del notifier.
class DailyResetService {
  static const String _lastResetKey = '_lastMidnightReset';

  /// Chequea si pasó medianoche desde la última sesión.
  /// Retorna true si sí pasó medianoche (necesita reset).
  ///
  /// Idempotente: la segunda llamada el mismo día retorna false.
  static Future<bool> hasPassedMidnight(SharedPreferences prefs) async {
    final lastReset = prefs.getString(_lastResetKey);
    final now = DateTime.now();
    final todayKey = _getTodayKey(now);

    // Si no hay registro previo o la fecha cambió, pasó medianoche
    if (lastReset == null || lastReset != todayKey) {
      await prefs.setString(_lastResetKey, todayKey);
      return true;
    }

    return false;
  }

  /// Obtiene clave única para hoy (yyyy-MM-dd)
  static String _getTodayKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

/// SPEC-58: Notifier que detecta medianoche y triggeriza resets diarios.
///
/// Patrón: StateNotifier sin estado visible (void) — solo efectos secundarios.
///
/// Ciclo de vida:
/// 1. Bootstrap al construirse: si pasó medianoche desde la última sesión
///    persistida en SharedPreferences, dispara `triggerDailyReset()`.
/// 2. Programa un Timer hasta las 00:00:00 del día siguiente para disparar
///    el reset automáticamente sin requerir reapertura de la app.
/// 3. El timer se re-arma tras cada disparo (loop infinito controlado).
/// 4. El notifier se mantiene vivo durante toda la sesión vía
///    `ref.watch(dailyResetProvider)` en el widget root (`app.dart`).
class DailyResetNotifier extends StateNotifier<void> {
  final Ref _ref;
  Timer? _midnightTimer;

  DailyResetNotifier(this._ref) : super(null) {
    _bootstrap();
  }

  /// Bootstrap: chequea si pasó medianoche desde la última sesión y, si así,
  /// dispara el reset. Después arma el timer hacia la próxima medianoche.
  Future<void> _bootstrap() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final passed = await DailyResetService.hasPassedMidnight(prefs);
      if (passed) {
        await triggerDailyReset();
      }
    } catch (e) {
      AppLogger.warning('SPEC-58 bootstrap falló', e);
    }
    _scheduleMidnightTimer();
  }

  /// Programa un Timer one-shot hasta las 00:00:00 del día siguiente.
  /// Al disparar: triggerDailyReset() + re-armar para el siguiente día.
  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DateTime(now.year, now.month, now.day + 1);
    final duration = nextMidnight.difference(now);

    AppLogger.debug(
      'SPEC-58: próximo reset programado en ${duration.inMinutes} min.',
    );

    _midnightTimer = Timer(duration, () async {
      await triggerDailyReset();
      if (mounted) _scheduleMidnightTimer();
    });
  }

  /// SPEC-58 RF-58-02: Dispara reset de los 5 pilares.
  ///
  /// Idempotente (RF-58-03): cada notifier individual debe ser idempotente
  /// en su `resetDaily()`. Una segunda invocación produce el mismo state.
  ///
  /// Llamado desde:
  /// - bootstrap (si pasó medianoche desde la última sesión)
  /// - timer al cruzar 00:00:00
  Future<void> triggerDailyReset() async {
    try {
      // Nutrición: limpia logs en memoria del día y resetea score.
      _ref.read(nutritionProvider.notifier).resetDaily();

      // Hidratación: limpia el contador en caché. El stream de Firestore
      // re-emitirá automáticamente el conteo correcto del nuevo día.
      _ref.read(hydrationProvider.notifier).resetDaily();

      // Ejercicio: limpia minutos en caché. Mismo principio que hidratación.
      _ref.read(exerciseProvider.notifier).resetDaily();

      // Sueño: resetea flags de wake-up; conserva el último log persistido.
      _ref.read(sleepProvider.notifier).resetDaily();

      // Ayuno: solo limpia el flag efímero `_fastingEndConfirmedToday`.
      // RF-58-04: NO elimina el FastingInterval del día anterior — el ayuno
      // es por diseño multi-día y puede cruzar la medianoche.
      _ref.read(fastingProvider.notifier).resetDaily();

      // SPEC-72.2: limpiar descartes de banners para que reaparezcan en el
      // nuevo día si la condición que los origina sigue activa.
      _ref.read(uiInteractionProvider.notifier).resetDismissals();

      AppLogger.debug(
        'SPEC-58: reset diario completado en 5 pilares + descartes UI.',
      );
    } catch (e, stackTrace) {
      AppLogger.error('SPEC-58: error en triggerDailyReset', e, stackTrace);
    }
  }

  @override
  void dispose() {
    _midnightTimer?.cancel();
    super.dispose();
  }
}

/// Provider que mantiene vivo el DailyResetNotifier durante toda la sesión.
/// Se debe consumir en `app.dart` con `ref.watch(dailyResetProvider)` para
/// que el bootstrap y el timer se inicien al arrancar la app.
final dailyResetProvider =
    StateNotifierProvider<DailyResetNotifier, void>((ref) {
  return DailyResetNotifier(ref);
});
