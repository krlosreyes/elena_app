// Fix notificaciones (2026-10-30): máximo 3 avisos al día.
//
// Antes la app programaba entre 30 y 40 notificaciones diarias (unas 20 solo
// de hidratación, una cada 45 min) y los usuarios — incluido el fundador —
// la desinstalaban. Esta política es el ÚNICO filtro por el que pasa toda
// notificación: `NotificationService.scheduleAt()` y `showImmediate()` la
// consultan antes de agendar. Si el ID no está permitido, no se agenda.
//
// Reglas:
//   - Solo existen 8 tipos de aviso, uno por tipo (ver [NotificationKind]).
//   - Por defecto están activos los 3 del día metabólico (2026-11-04): ventana
//     abre, cierra tu día y rescate. Antes eran mañana, comidas y buenas
//     noches — avisos de reloj que hicieron perder el concepto de día
//     metabólico (feedback de Carlos tras 2 días de uso de la build 74).
//   - Nunca se permiten más de [kHardMaxPerDay] tipos a la vez, aunque el
//     usuario active más o algún código futuro agende otros IDs.
//   - Cualquier ID que no sea uno de estos 5 queda bloqueado (hitos de
//     12/18/24 h, check-ins, "soltar el día", rutina de sueño, muro de pago,
//     etc.). Para volver a habilitar uno, hay que agregarlo aquí a propósito.

import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

/// Los únicos tipos de aviso que la app puede mandar.
enum NotificationKind {
  /// Día metabólico: "Tu ventana abrió" al cumplir la meta de ayuno (ID 310).
  cicloVentana,

  /// Día metabólico: "Cierra tu día" al fin estimado de la ventana (ID 311).
  cicloCierre,

  /// Día metabólico: rescate a la mañana si el día quedó sin cerrar (ID 312).
  cicloRescate,

  /// "🎯 Tus objetivos de hoy", 15 min después de despertar (ID 108).
  manana,

  /// "⏰ 30 minutos para cerrar tu ventana" (ID 102).
  comidas,

  /// Buenas noches / preparación para dormir (ID 611).
  sueno,

  /// Aviso al cumplir 16 h de ayuno (ID 203). Apagado por defecto.
  ayuno,

  /// Un solo recordatorio de agua al mediodía (ID 400). Apagado por defecto.
  agua,
}

/// Tope duro de avisos por día. No es configurable hacia arriba.
const int kHardMaxPerDay = 3;

class NotificationPolicy {
  NotificationPolicy._();

  // IDs — deben coincidir con `NotificationIds` (mobile y web). Se repiten
  // como literales para que este archivo sea puro y testeable sin el plugin.
  static const int _idCicloVentana = 310; // NotificationIds.cycleWindowOpens
  static const int _idCicloCierre = 311; // NotificationIds.cycleCloseDay
  static const int _idCicloRescate = 312; // NotificationIds.cycleRescue
  static const int _idManana = 108; // NotificationIds.dailyGoalsSummary
  static const int _idComidas = 102; // NotificationIds.lastMealWarning
  static const int _idSueno = 611; // NotificationIds.goodNight
  static const int _idAyuno = 203; // NotificationIds.fasting16h
  static const int _idAgua = 400; // NotificationIds.hydrationStart

  static const Map<NotificationKind, int> idByKind = {
    NotificationKind.cicloVentana: _idCicloVentana,
    NotificationKind.cicloCierre: _idCicloCierre,
    NotificationKind.cicloRescate: _idCicloRescate,
    NotificationKind.manana: _idManana,
    NotificationKind.comidas: _idComidas,
    NotificationKind.sueno: _idSueno,
    NotificationKind.ayuno: _idAyuno,
    NotificationKind.agua: _idAgua,
  };

  /// Orden de prioridad si por algún motivo hay más tipos activos que el tope.
  static const List<NotificationKind> priority = [
    NotificationKind.cicloCierre,
    NotificationKind.cicloRescate,
    NotificationKind.cicloVentana,
    NotificationKind.manana,
    NotificationKind.comidas,
    NotificationKind.sueno,
    NotificationKind.ayuno,
    NotificationKind.agua,
  ];

  static const Set<NotificationKind> defaultEnabled = {
    NotificationKind.cicloVentana,
    NotificationKind.cicloCierre,
    NotificationKind.cicloRescate,
  };

  /// Todos los IDs que la app ha usado alguna vez para avisos programados.
  /// [purgeTargets] los usa para limpiar del sistema operativo lo que quedó
  /// agendado por versiones anteriores (hidratación cada 45 min, etc.).
  /// NO incluye 700 (progreso en vivo del ayuno, que no es un aviso).
  static const List<(int, int)> _knownIdRanges = [
    (100, 109), // circadianas
    (200, 209), // hitos de ayuno
    (300, 301), // cierre automático / próxima comida
    (310, 312), // día metabólico: ventana abre, cierra tu día, rescate
    (400, 450), // hidratación + snooze
    (500, 501), // muro de pago
    (600, 619), // check-ins + sueño
  ];

  // ── Estado (cargado de SharedPreferences) ──────────────────────────────
  static const String _kPrefsEnabled = 'notificationPolicy.enabledKinds';
  static const String _kPrefsMax = 'notificationPolicy.maxPerDay';
  static const String _kPrefsVersion = 'notificationPolicy.version';

  /// v2 (2026-11-04): defaults pasan a los avisos del día metabólico. Una
  /// configuración guardada con v1 se descarta una sola vez — si no, quien
  /// ya instaló la build 74 seguiría sin los avisos de inicio/cierre.
  static const int _kCurrentVersion = 2;

  static Set<NotificationKind> _enabled = {...defaultEnabled};
  static int _maxPerDay = kHardMaxPerDay;

  static Set<NotificationKind> get enabled => {..._enabled};
  static int get maxPerDay => _maxPerDay;

  // ── Lógica pura ────────────────────────────────────────────────────────

  /// Tipos que efectivamente se envían: los activos, en orden de prioridad,
  /// recortados al límite elegido y al tope duro.
  static List<NotificationKind> effectiveKinds(
    Set<NotificationKind> enabled,
    int maxPerDay,
  ) {
    final cap = math.max(0, math.min(maxPerDay, kHardMaxPerDay));
    return priority.where(enabled.contains).take(cap).toList();
  }

  /// IDs permitidos para una configuración dada.
  static Set<int> allowedIdsFor(Set<NotificationKind> enabled, int maxPerDay) =>
      effectiveKinds(enabled, maxPerDay).map((k) => idByKind[k]!).toSet();

  /// ¿Se puede agendar este ID con la configuración actual?
  static bool allows(int id) =>
      allowedIdsFor(_enabled, _maxPerDay).contains(id);

  /// IDs conocidos que hay que cancelar del sistema operativo porque ya no
  /// están permitidos.
  static List<int> purgeTargets(Set<int> allowed) => [
        for (final (from, to) in _knownIdRanges)
          for (var id = from; id <= to; id++)
            if (!allowed.contains(id)) id,
      ];

  // ── Persistencia ───────────────────────────────────────────────────────

  static Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if ((prefs.getInt(_kPrefsVersion) ?? 1) < _kCurrentVersion) {
        _enabled = {...defaultEnabled};
        _maxPerDay = kHardMaxPerDay;
        await prefs.setStringList(
            _kPrefsEnabled, _enabled.map((k) => k.name).toList());
        await prefs.setInt(_kPrefsMax, _maxPerDay);
        await prefs.setInt(_kPrefsVersion, _kCurrentVersion);
        return;
      }
      final names = prefs.getStringList(_kPrefsEnabled);
      if (names != null) {
        _enabled = {
          for (final n in names)
            for (final k in NotificationKind.values)
              if (k.name == n) k,
        };
      }
      _maxPerDay = (prefs.getInt(_kPrefsMax) ?? kHardMaxPerDay)
          .clamp(1, kHardMaxPerDay)
          .toInt();
    } catch (_) {
      // Sin preferencias legibles: quedan los valores por defecto.
    }
  }

  static Future<void> save({
    required Set<NotificationKind> enabled,
    required int maxPerDay,
  }) async {
    _enabled = {...enabled};
    _maxPerDay = maxPerDay.clamp(1, kHardMaxPerDay).toInt();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _kPrefsEnabled, _enabled.map((k) => k.name).toList());
      await prefs.setInt(_kPrefsMax, _maxPerDay);
      await prefs.setInt(_kPrefsVersion, _kCurrentVersion);
    } catch (_) {
      // Si no se pudo guardar, la configuración vale para esta sesión.
    }
  }
}
