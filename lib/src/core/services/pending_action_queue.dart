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

// SPEC-224: categorías e IDs de acción para Ayuno, Ejercicio y Nutrición.
// Misma convención que hidratación; constantes compartidas entre
// NotificationService (registro de categorías) y esta cola (traducción).
const String kFastingActionCategoryId = 'elena_fasting_action';
const String kFastingCloseActionId = 'fasting_close';
const String kFastingSnoozeActionId = 'fasting_snooze';

const String kExerciseCategoryId = 'elena_exercise_action';
const String kExerciseLogActionId = 'exercise_log';
const String kExerciseSnoozeActionId = 'exercise_snooze';

const String kNutritionCategoryId = 'elena_nutrition_action';
const String kNutritionLogActionId = 'nutrition_log';
const String kNutritionSnoozeActionId = 'nutrition_snooze';

// SPEC-232: check-ins emocionales durante el ayuno.
// 4 acciones en la notificación (límite iOS); las 2 restantes solo in-app.
const String kCheckInCategoryId = 'elena_checkin';
const String kCheckInEnergizedActionId = 'checkin_energized';
const String kCheckInGoodActionId = 'checkin_good';
const String kCheckInHungryActionId = 'checkin_hungry';
const String kCheckInTiredActionId = 'checkin_tired';

// SPEC-241: hitos de ayuno accionables — ¿Cómo te sientes? Bien/Mal.
// Categoría separada de check-ins para que el motor los distinga.
const String kMilestoneCategoryId = 'elena_milestone';
const String kMilestoneGoodActionId = 'milestone_good';
const String kMilestoneBadActionId = 'milestone_bad';

/// Minutos por sesión de ejercicio registrada desde un prompt.
/// Valor conservador; el usuario puede ajustar desde el pilar.
const int kExercisePromptMinutes = 30;

enum PendingActionType {
  addWater,
  hydrationSnoozed,
  // SPEC-224: nuevas acciones de pilares
  closeFasting,
  logExercise,
  logMeal,
  // SPEC-232: check-in emocional durante ayuno.
  // `amount` codifica el ordinal de FastingFeeling (0=energized...5=irritable).
  checkInFeeling,
  // SPEC-241: sentimiento en hito de ayuno (Bien/Mal).
  // `amount` codifica las horas del hito (12, 16, 18, 24).
  milestoneFeelingGood,
  milestoneFeelingBad,
}

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

      // SPEC-224: Ayuno — cerrar ventana en el momento del prompt.
      case kFastingCloseActionId:
        await enqueue(PendingAction(
          id: 'closeFasting_${notificationId ?? 0}_$bucket',
          type: PendingActionType.closeFasting,
          millisSinceEpoch: t.millisecondsSinceEpoch,
        ));
        break;
      case kFastingSnoozeActionId:
        // "Continuar ayuno" → no encolar nada; el usuario eligió seguir.
        break;

      // SPEC-224: Ejercicio — registrar sesión de 30 min.
      case kExerciseLogActionId:
        await enqueue(PendingAction(
          id: 'logExercise_${notificationId ?? 0}_$bucket',
          type: PendingActionType.logExercise,
          amount: kExercisePromptMinutes.toDouble(),
          millisSinceEpoch: t.millisecondsSinceEpoch,
        ));
        break;
      case kExerciseSnoozeActionId:
        break;

      // SPEC-224: Nutrición — registrar comida con defaults seguros.
      case kNutritionLogActionId:
        await enqueue(PendingAction(
          id: 'logMeal_${notificationId ?? 0}_$bucket',
          type: PendingActionType.logMeal,
          millisSinceEpoch: t.millisecondsSinceEpoch,
        ));
        break;
      case kNutritionSnoozeActionId:
        break;

      // SPEC-232: check-ins emocionales (4 acciones de notificación).
      // El ordinal de FastingFeeling se codifica en `amount`.
      case kCheckInEnergizedActionId:
        await enqueue(PendingAction(
          id: 'checkIn_${notificationId ?? 0}_$bucket',
          type: PendingActionType.checkInFeeling,
          amount: 0, // FastingFeeling.energized.index
          millisSinceEpoch: t.millisecondsSinceEpoch,
        ));
        break;
      case kCheckInGoodActionId:
        await enqueue(PendingAction(
          id: 'checkIn_${notificationId ?? 0}_$bucket',
          type: PendingActionType.checkInFeeling,
          amount: 2, // FastingFeeling.good.index
          millisSinceEpoch: t.millisecondsSinceEpoch,
        ));
        break;
      case kCheckInHungryActionId:
        await enqueue(PendingAction(
          id: 'checkIn_${notificationId ?? 0}_$bucket',
          type: PendingActionType.checkInFeeling,
          amount: 3, // FastingFeeling.hungry.index
          millisSinceEpoch: t.millisecondsSinceEpoch,
        ));
        break;
      case kCheckInTiredActionId:
        await enqueue(PendingAction(
          id: 'checkIn_${notificationId ?? 0}_$bucket',
          type: PendingActionType.checkInFeeling,
          amount: 4, // FastingFeeling.tired.index
          millisSinceEpoch: t.millisecondsSinceEpoch,
        ));
        break;

      // SPEC-241: hito de ayuno — sentimiento Bien/Mal.
      // `amount` = horas del hito; se extrae del notificationId range (200-203).
      case kMilestoneGoodActionId:
        await enqueue(PendingAction(
          id: 'milestoneGood_${notificationId ?? 0}_$bucket',
          type: PendingActionType.milestoneFeelingGood,
          amount: _milestoneHoursFromId(notificationId),
          millisSinceEpoch: t.millisecondsSinceEpoch,
        ));
        break;
      case kMilestoneBadActionId:
        await enqueue(PendingAction(
          id: 'milestoneBad_${notificationId ?? 0}_$bucket',
          type: PendingActionType.milestoneFeelingBad,
          amount: _milestoneHoursFromId(notificationId),
          millisSinceEpoch: t.millisecondsSinceEpoch,
        ));
        break;

      default:
        // Tap en el cuerpo (sin actionId) u otra categoría: nada que encolar.
        break;
    }
  }

  /// Convierte el ID de notificación de hito al número de horas correspondiente.
  /// fasting12h=200 → 12h, fasting16h=203 → 16h, fasting18h=201 → 18h, fasting24h=202 → 24h.
  static double _milestoneHoursFromId(int? id) {
    switch (id) {
      case 200: return 12;
      case 201: return 18;
      case 202: return 24;
      case 203: return 16;
      default:  return 0;
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
