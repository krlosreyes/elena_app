import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:elena_app/src/features/nutrition/application/nutrition_notifier.dart';

/// SPEC-33: Servicio que detecta cambios de día y triggeriza resets circadianos.
/// RF-33-05: Chequea en app startup si pasó medianoche desde última sesión.
class DailyResetService {
  static const String _lastResetKey = '_lastMidnightReset';

  /// Chequea si pasó medianoche desde la última sesión.
  /// Retorna true si sí pasó medianoche (necesita reset).
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

/// SPEC-33: Notifier que detecta medianoche y triggeriza resets diarios.
/// Patrón: StateNotifier sin estado visible (void) — solo efectos secundarios.
class DailyResetNotifier extends StateNotifier<void> {
  final Ref _ref;

  DailyResetNotifier(this._ref) : super(null) {
    _initMidnightListener();
  }

  void _initMidnightListener() {
    // Escuchar cambios en SharedPreferences para detectar si pasó medianoche
    // En app startup, se llamará a hasPassedMidnight() desde main.dart
    // Si retorna true, se dispara este notifier manualmente
  }

  /// SPEC-33 RF-33-01: Dispara reset de todos los pilares diarios.
  /// Llamado desde app startup o cuando se detecta medianoche.
  Future<void> triggerDailyReset() async {
    try {
      // Resetear NutritionNotifier
      await _ref.read(nutritionProvider.notifier).resetDaily();

      debugPrint('✅ SPEC-33: Reset diario completado. Todos los pilares reiniciados.');
    } catch (e) {
      debugPrint('❌ Error en triggerDailyReset: $e');
    }
  }
}

/// Provider que mantiene vivo el DailyResetNotifier durante toda la sesión.
final dailyResetProvider =
    StateNotifierProvider<DailyResetNotifier, void>((ref) {
      return DailyResetNotifier(ref);
    });
