import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/analysis/application/daily_summary_persistence_service.dart';
import 'package:elena_app/src/features/fasting/application/fasting_notifier.dart';
import 'package:elena_app/src/features/hydration/application/hydration_notifier.dart';
import 'package:elena_app/src/features/sleep/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/application/ui_interaction_notifier.dart';
import 'package:elena_app/src/features/exercise/application/exercise_notifier.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';
import 'package:elena_app/src/features/streak/application/streak_notifier.dart';

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

  /// Obtiene clave única para hoy (yyyy-MM-dd).
  /// SPEC-138: delega en la fuente única del día.
  static String _getTodayKey(DateTime date) =>
      DayBoundaryResolver.dayKeyIso(date);
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
  /// dispara la red de seguridad calendárica. Después arma el timer hacia
  /// la próxima medianoche.
  Future<void> _bootstrap() async {
    try {
      final prefs = _ref.read(sharedPreferencesProvider);
      final passed = await DailyResetService.hasPassedMidnight(prefs);
      if (passed) {
        await triggerCalendarSafetyNet();
      }
    } catch (e) {
      AppLogger.warning('SPEC-58 bootstrap falló', e);
    }
    _scheduleMidnightTimer();
  }

  /// Programa un Timer one-shot hasta las 00:00:00 del día siguiente.
  /// Al disparar: red de seguridad calendárica + re-armar para el
  /// siguiente día.
  void _scheduleMidnightTimer() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final nextMidnight = DayBoundaryResolver.endOfDay(now);
    final duration = nextMidnight.difference(now);

    AppLogger.debug(
      'SPEC-58: próximo chequeo de medianoche en ${duration.inMinutes} min.',
    );

    _midnightTimer = Timer(duration, () async {
      // SPEC-138 §4.4: en el cruce de medianoche con la app viva, cerramos
      // atómicamente el día que termina antes de limpiar los pilares.
      await triggerCalendarSafetyNet(flushClosingDay: true);
      if (mounted) _scheduleMidnightTimer();
    });
  }

  /// 18-jul ("Día Metabólico: dos sistemas de día en paralelo" — hallazgo
  /// central de la auditoría): red de seguridad puramente CALENDÁRICA.
  ///
  /// ANTES, este mismo timer de medianoche llamaba a `triggerDailyReset()`
  /// — el mismo método que resetea los 5 pilares Y fuerza una
  /// re-evaluación de la racha (`streakNotifier.beginReset()/endReset()`)
  /// — SIN chequear si había un ciclo metabólico abierto. Eso violaba
  /// METABOLIC_DAY_CONSTITUTION.md §1 ("cero referencia al reloj del
  /// calendario") y §2.1 ("crossing medianoche NO crea/cierra nada"): un
  /// ayuno que seguía activo a medianoche disparaba de todas formas un
  /// reset de pilares (parpadeo, inofensivo porque `resetDaily()` re-
  /// suscribe con el mismo `since` del ciclo abierto) Y una re-evaluación
  /// forzada de `_evaluateToday()` justo en el instante en que `_todayKey`
  /// cambiaba de día — el disparador mecánico exacto de la partición de
  /// un día metabólico en dos `StreakEntry`.
  ///
  /// AHORA: lo único que sigue siendo legítimamente calendárico (por
  /// decisión consciente, documentada en METABOLIC_DAY_CONSTITUTION.md
  /// SPEC-192.1 como EXCEPCIÓN para `daily_summary` y sus gráficos
  /// retrospectivos) se aísla acá: el flush del snapshot legacy de
  /// `daily_summary` y el reseteo de descartes de banners de UI. Ninguno
  /// de los dos toca pilares ni racha.
  ///
  /// El reset de pilares + racha (`triggerDailyReset`, sin cambios) queda
  /// como responsabilidad EXCLUSIVA del cierre real de ciclo metabólico,
  /// vía `metabolicCycleEvaluatorProvider` — que ya lo dispara
  /// correctamente cuando `MetabolicCycleService.evaluateAndApply`
  /// detecta cierre + apertura encadenada.
  Future<void> triggerCalendarSafetyNet({bool flushClosingDay = false}) async {
    try {
      if (flushClosingDay) {
        await _ref.read(dailySummaryPersistenceServiceProvider).flushClosingDay();
      }
      _ref.read(uiInteractionProvider.notifier).resetDismissals();
      AppLogger.debug(
        'SPEC-58: red de seguridad calendárica ejecutada '
        '(daily_summary${flushClosingDay ? " + flush" : ""} + descartes UI). '
        'Pilares y racha NO tocados — eso es solo responsabilidad del '
        'cierre de ciclo metabólico.',
      );
    } catch (e, stackTrace) {
      AppLogger.error(
          'SPEC-58: error en triggerCalendarSafetyNet', e, stackTrace);
    }
  }

  /// SPEC-58 RF-58-02: Dispara reset de los 5 pilares + racha.
  ///
  /// Idempotente (RF-58-03): cada notifier individual debe ser idempotente
  /// en su `resetDaily()`. Una segunda invocación produce el mismo state.
  ///
  /// 18-jul: llamado EXCLUSIVAMENTE desde `metabolicCycleEvaluatorProvider`
  /// al detectar un cierre de ciclo real (con apertura encadenada del
  /// siguiente). Ya NO lo llama el timer de medianoche ni el bootstrap —
  /// ver `triggerCalendarSafetyNet` arriba y METABOLIC_DAY_CONSTITUTION.md
  /// §1/§2.1.
  ///
  /// Ya NO acepta `flushClosingDay` — ese flush es exclusivamente
  /// calendárico (`daily_summary` legacy, SPEC-192.1) y vive en
  /// `triggerCalendarSafetyNet`. Un cierre de ciclo metabólico nunca debe
  /// sellar el snapshot calendárico del día — son dos relojes distintos.
  Future<void> triggerDailyReset() async {
    try {
      // SPEC-242: señalar al StreakNotifier que los siguientes cambios de
      // pilar son un reset transitorio, NO acciones del usuario. Durante
      // este ventana, _evaluateToday() usa HWM para preservar el progreso
      // del ciclo cerrado. Una vez terminado el reset (150ms de margen para
      // que todos los listeners Riverpod hayan disparado), endReset() activa
      // el modo dinámico: borrar agua baja el score inmediatamente.
      final streakNotifier = _ref.read(streakProvider.notifier);
      streakNotifier.beginReset();

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

      // SPEC-242: dar tiempo a que todos los listeners de pilares disparen
      // (todos sincrónicos en Riverpod, pero el microtask queue necesita
      // un frame para propagarse a través de ref.listen). 150ms es seguro.
      Future.delayed(const Duration(milliseconds: 150), streakNotifier.endReset);

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
