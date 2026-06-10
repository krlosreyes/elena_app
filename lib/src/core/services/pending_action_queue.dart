import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'app_logger.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPEC-199 Fase A — Cola de acciones pendientes (bucle cerrado)
// ─────────────────────────────────────────────────────────────────────────────
//
// El usuario responde a un prompt accionable (p. ej. la notificación de
// hidratación "¿Ya tomaste tu vaso? Sí/No"). El handler de la notificación
// corre en un contexto SIN Riverpod (callback estático registrado antes de
// runApp, a veces en un isolate de background). Por eso NO escribe Firestore
// directo: ENCOLA la intención aquí (SharedPreferences) y la app la VACÍA en
// foreground vía `CoachingActionRouter.flush` (al reanudar o cuando hay
// usuario), llamando al notifier correcto.
//
// Reglas:
//   - Idempotente: `enqueue` deduplica por `id`. El `id` se deriva de forma
//     determinista (acción + notifId + hora) para que un doble-tap colapse.
//   - Persistente: sobrevive cold start. Se aplica cuando hay usuario.
//   - Infra de `core`: no depende de ninguna feature. El router (feature)
//     es quien conoce los notifiers concretos.

/// Identificadores de las acciones de notificación (compartidos entre el
/// `NotificationService`, que los registra en la categoría, y esta cola, que
/// los traduce a intenciones encoladas).
const String kHydrationCategoryId = 'elena_hydration';
const String kHydrationYesActionId = 'hydration_yes';
const String kHydrationNoActionId = 'hydration_no';

/// Litros por "vaso" registrado desde un prompt. Default razonable; el tope
/// y el tamaño exacto son decisión abierta del SPEC-199 §10.
const double kHydrationGlassLiters = 0.25;

enum PendingActionType { addWater, hydrationSnoozed }

class PendingAction {
  final String id;
  final PendingActionType type;
  final double? amount;
  final int millisSinceEpoch;

  const PendingAction({
    required this.id,
    required this.type,
    required this.millisSinceEpoch,
    this.amount,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'amount': amount,
        'ms': millisSinceEpoch,
      };

  static PendingAction? fromJson(Map<String, dynamic> j) {
    final typeName = j['type'] as String?;
    PendingActionType? type;
    for (final t in PendingActionType.values) {
      if (t.name == typeName) {
        type = t;
        break;
      }
    }
    if (j['id'] is! String || type == null) return null;
    return PendingAction(
      id: j['id'] as String,
      type: type,
      amount: (j['amount'] as num?)?.toDouble(),
      millisSinceEpoch: (j['ms'] as num?)?.toInt() ?? 0,
    );
  }
}

class PendingActionQueue {
  PendingActionQueue._();

  static const String _prefsKey = 'coaching.pending_actions';

  // ── API base ────────────────────────────────────────────────────────────

  static Future<void> enqueue(PendingAction action) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actions = _read(prefs);
      // Idempotencia: no re-encolar el mismo id (doble-tap, fg+bg handler).
      if (actions.any((a) => a.id == action.id)) return;
      actions.add(action);
      await _write(prefs, actions);
      AppLogger.debug('[PendingActionQueue] enqueue ${action.type.name} '
          '(${action.id})');
    } catch (e) {
      AppLogger.error('[PendingActionQueue] enqueue falló', e);
    }
  }

  static Future<List<PendingAction>> peekAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return _read(prefs);
    } catch (e) {
      AppLogger.error('[PendingActionQueue] peekAll falló', e);
      return const [];
    }
  }

  static Future<void> remove(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final actions = _read(prefs)..removeWhere((a) => a.id == id);
      await _write(prefs, actions);
    } catch (e) {
      AppLogger.error('[PendingActionQueue] remove falló', e);
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
  }

  // ── Traducción desde una acción de notificación ──────────────────────────

  /// Llamado por el handler (fore/background) del `NotificationService`.
  /// Mapea el `actionId` de la notificación a una intención encolada.
  /// Determinista por hora para que un doble-tap dentro de la misma hora
  /// produzca el mismo `id` y se deduplique.
  static Future<void> handleNotificationAction(
    String? actionId,
    int? notificationId, {
    DateTime? now,
  }) async {
    final t = now ?? DateTime.now();
    final bucket = '${t.year}'
        '${_two(t.month)}${_two(t.day)}${_two(t.hour)}';
    switch (actionId) {
      case kHydrationYesActionId:
        await enqueue(PendingAction(
          id: 'addWater_${notificationId ?? 0}_$bucket',
          type: PendingActionType.addWater,
          amount: kHydrationGlassLiters,
          millisSinceEpoch: t.millisecondsSinceEpoch,
        ));
        break;
      case kHydrationNoActionId:
        await enqueue(PendingAction(
          id: 'hydrationSnoozed_${notificationId ?? 0}_$bucket',
          type: PendingActionType.hydrationSnoozed,
          millisSinceEpoch: t.millisecondsSinceEpoch,
        ));
        break;
      default:
        // Tap en el cuerpo (sin actionId) u otra categoría: nada que encolar.
        break;
    }
  }

  // ── Internos ──────────────────────────────────────────────────────────────

  static List<PendingAction> _read(SharedPreferences prefs) {
    final raw = prefs.getStringList(_prefsKey) ?? const [];
    final out = <PendingAction>[];
    for (final s in raw) {
      try {
        final j = jsonDecode(s);
        if (j is Map<String, dynamic>) {
          final a = PendingAction.fromJson(j);
          if (a != null) out.add(a);
        }
      } catch (_) {
        // Entrada corrupta: se descarta silenciosamente.
      }
    }
    return out;
  }

  static Future<void> _write(
      SharedPreferences prefs, List<PendingAction> actions) async {
    await prefs.setStringList(
      _prefsKey,
      actions.map((a) => jsonEncode(a.toJson())).toList(),
    );
  }

  static String _two(int n) => n.toString().padLeft(2, '0');
}
