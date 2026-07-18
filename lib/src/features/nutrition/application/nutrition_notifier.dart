// SPEC-63: NutritionNotifier consume el NutritionRepository — los logs
// ahora persisten en Firestore en lugar de vivir solo en memoria.
//
// Antes: la lista de logs vivía en `state.todayLogs` y se perdía al cerrar
// la app. Ahora: el repositorio es la fuente de verdad; el state local
// sólo es un cache reactivo del stream `watchTodayLogs`.
//
// CONSTITUTION §3.2: este archivo NO importa cloud_firestore. Solo conoce
// el contrato `NutritionRepository`.

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

// SPEC-194.1 (2026-06-06): day_boundary_resolver reintroducido como
// fallback exclusivo para el caso "sin ciclo abierto". Con ciclo, sigue
// cycle-aware (Constitución §1). Sin ciclo, ventana startOfDay para
// que los logs del día sean visibles en el ring.
import 'package:elena_app/src/core/analytics/analytics_events.dart';
import 'package:elena_app/src/core/offline_first_stream_mixin.dart';
import 'package:elena_app/src/core/orchestrator/biological_phases.dart';
import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/coaching/application/coaching_completion_service.dart';
import 'package:elena_app/src/core/services/notification_scheduler.dart';
import 'package:elena_app/src/features/metabolic_cycle/application/metabolic_cycle_providers.dart';
import 'package:elena_app/src/features/metabolic_cycle/domain/metabolic_cycle.dart';
import 'package:elena_app/src/features/nutrition/data/nutrition_repository_impl.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_interval_rules.dart';
import 'package:elena_app/src/features/nutrition/domain/meal_ratio.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_log.dart';
import 'package:elena_app/src/features/nutrition/domain/nutrition_score_calculator.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

// SPEC-253 (fix de regresión, 2026-07-08): helper para loguear un id
// truncado sin reventar con RangeError cuando el id es más corto que 8
// caracteres (p. ej. ids de fixtures de test como 'log-1'). El bug
// original hacía `l.id.substring(0, 8)` directo, que en Dart lanza si el
// string tiene menos de 8 caracteres — rompía tests que usan ids cortos.
String _shortId(String id) => id.length > 8 ? id.substring(0, 8) : id;

// ─── State ────────────────────────────────────────────────────────────────────

class NutritionState {
  /// Cuántas comidas tiene como objetivo el usuario por día.
  final int targetMeals;

  /// Logs del día actual (cache reactivo del stream del repositorio).
  final List<NutritionLog> todayLogs;

  /// Score 0.0-1.0 que el ScoreEngine consume para el bloque Conducta.
  /// 60% adherencia de cantidad + 40% adherencia de ventana circadiana.
  final double nutritionScore;

  /// % de comidas registradas dentro de la ventana circadiana.
  final double windowAdherence;

  final bool isSaving;

  const NutritionState({
    this.targetMeals = 3,
    this.todayLogs = const [],
    this.nutritionScore = 0.0,
    this.windowAdherence = 0.0,
    this.isSaving = false,
  });

  int get mealsLoggedToday => todayLogs.length;

  double get progressPercentage =>
      (mealsLoggedToday / targetMeals.clamp(1, 10)).clamp(0.0, 1.0);

  String get nextMealLabel {
    switch (mealsLoggedToday) {
      case 0:
        return 'Desayuno';
      case 1:
        return targetMeals <= 2 ? 'Cena' : 'Almuerzo';
      case 2:
        return 'Cena';
      default:
        return 'Snack';
    }
  }

  NutritionState copyWith({
    int? targetMeals,
    List<NutritionLog>? todayLogs,
    double? nutritionScore,
    double? windowAdherence,
    bool? isSaving,
  }) {
    return NutritionState(
      targetMeals: targetMeals ?? this.targetMeals,
      todayLogs: todayLogs ?? this.todayLogs,
      nutritionScore: nutritionScore ?? this.nutritionScore,
      windowAdherence: windowAdherence ?? this.windowAdherence,
      isSaving: isSaving ?? this.isSaving,
    );
  }
}

// ─── Notifier ─────────────────────────────────────────────────────────────────

class NutritionNotifier extends StateNotifier<NutritionState>
    with OfflineFirstStreamMixin<NutritionState> {
  NutritionNotifier(this._ref) : super(const NutritionState()) {
    _init();
  }

  final Ref _ref;
  CircadianProfile? _circadianProfile;
  String? _activeUserId;
  DateTime? _currentCycleStartedAt;

  // SPEC-253: ids que ESTE notifier pidió eliminar explícitamente (vía
  // deleteMealById, replaceMeal o removeLastMeal). Un id en este set puede
  // desaparecer legítimamente de un snapshot futuro. Cualquier OTRO log
  // que el usuario vio en pantalla y que un snapshot posterior "olvida"
  // sin que el usuario lo haya borrado se trata como anomalía transitoria
  // del stream/ventana de Firestore — ver `_mergeWithBaseline`.
  final Set<String> _explicitlyRemovedIds = {};

  // SPEC-253.1 (fix de regresión real, 2026-07-08): baseline de logs
  // confirmados, ahora a nivel de NOTIFIER (no local a `_subscribeFor`).
  //
  // Bug encontrado en revisión línea por línea tras el segundo reporte de
  // Carlos (comida desaparece pese a la guardia v1): la v1 de la guardia
  // guardaba el baseline en una variable LOCAL dentro de `_subscribeFor`,
  // reseteándolo a `const []` en CADA llamada a ese método — incluyendo
  // `onDone` (reconexión del stream de Firestore por blip de red, cambio
  // de token, o cierre del listener) y el listener de usuario, que
  // vuelven a llamar `_subscribeFor` con el MISMO `since` (misma ventana,
  // no una transición real de ciclo). Si la reconexión ocurre justo entre
  // dos registros de comida (plausible: cambio de red, app a background
  // un instante, refresh de token), el primer snapshot de la NUEVA
  // suscripción puede venir incompleto de la reconciliación de caché
  // local — y como el baseline ya estaba vacío por el reset, la guardia
  // no tenía nada que preservar. Exactamente el síntoma reportado.
  //
  // Fix: el baseline ahora vive a nivel de instancia, indexado por
  // `since`. Solo se limpia cuando `since` CAMBIA de verdad (nueva
  // ventana — transición real de Día Metabólico, SPEC-149) o cuando se
  // fuerza explícitamente (nuevo usuario, `resetDaily()`). Una
  // resuscripción con el MISMO `since` (reconexión, blip de red) hereda
  // el baseline existente — la guardia sigue protegiendo.
  DateTime? _baselineSince;
  List<NutritionLog> _baseline = const [];

  void _init() {
    // Escucha cambios de usuario para targetMeals, perfil circadiano y stream.
    _ref.listen<AsyncValue<UserModel?>>(
      currentUserStreamProvider,
      (previous, next) {
        next.whenData((user) {
          if (user == null) {
            _activeUserId = null;
            cancelActiveSubscription();
            if (mounted) state = const NutritionState();
            return;
          }
          _circadianProfile = user.profile;
          if (_activeUserId != user.id) {
            _activeUserId = user.id;
            // SPEC-253.1: usuario nuevo (login) — forzar baseline fresco
            // aunque `since` coincida por casualidad con el de otro usuario.
            _subscribeFor(_currentCycleStartedAt, forceFreshBaseline: true);
          }
          // Recalcula con los nuevos parámetros del usuario.
          final updated = _recalculate(state.todayLogs, user.mealsPerDay);
          state = updated.copyWith(targetMeals: user.mealsPerDay);
        });
      },
      fireImmediately: true,
    );

    // SPEC-149.2: re-suscribir cuando cambia el inicio del ciclo
    // metabólico — el conteo de comidas se ancla al Día Metabólico.
    _ref.listen<AsyncValue<MetabolicCycle?>>(
      currentMetabolicCycleProvider,
      (previous, next) {
        next.whenData((cycle) {
          final newSince = cycle?.startedAt;
          // SPEC-253 (diagnóstico temporal): loguea cada emisión de
          // currentMetabolicCycleProvider para detectar transiciones de
          // ciclo (cierre/apertura) durante una sesión de registro de
          // comidas. Quitar tras diagnosticar.
          AppLogger.debug(
            '[nutritionDebug] currentMetabolicCycleProvider emitió: '
            'cycleId=${cycle?.cycleId} startedAt=$newSince '
            '(anterior=$_currentCycleStartedAt, hasActiveSubscription=$hasActiveSubscription)',
          );
          // SPEC-178.bugfix2 (2026-06-05): si el primer fire emite con
          // cycle == null, newSince == _currentCycleStartedAt (ambos null)
          // y la igualdad bloqueaba la suscripción inicial. Subscribe
          // siempre que no haya subscription activa.
          if (!hasActiveSubscription ||
              newSince != _currentCycleStartedAt) {
            _currentCycleStartedAt = newSince;
            _subscribeFor(newSince);
          }
        });
      },
      fireImmediately: true,
    );
  }

  /// SPEC-149.2 + SPEC-189 + SPEC-194.1 (2026-06-06): suscripción al
  /// stream filtrado por la ventana del ciclo metabólico, con FALLBACK
  /// `startOfDay(now)` cuando no hay ciclo abierto.
  ///
  /// Cycle-aware (Constitución §1) con ciclo activo: ventana desde
  /// `cycle.startedAt`. SIN ciclo (primer uso, post-cierre antes del
  /// próximo ayuno, desync), ventana desde `startOfDay(now)` para que
  /// las comidas registradas hoy sean visibles en el ring. Antes el
  /// state quedaba con lista vacía y el ring en 0% aunque hubiese
  /// nutrition_logs en Firestore — bug post-SPEC-194 al quitar el
  /// placeholder. Cuando el usuario inicie el próximo ayuno, el
  /// listener al cycle re-suscribe automáticamente con la nueva ventana.
  void _subscribeFor(DateTime? cycleStartedAt, {bool forceFreshBaseline = false}) {
    final userId = _activeUserId;
    if (userId == null) return;
    final since = cycleStartedAt ??
        DayBoundaryResolver.startOfDay(DateTime.now());
    // SPEC-253: diagnóstico (Carlos reportó comidas desapareciendo al
    // registrar/editar). Se deja el logging — es barato y sigue siendo
    // útil para depurar futuras regresiones de la ventana de consulta.
    AppLogger.debug(
      '[nutritionDebug] _subscribeFor: cycleStartedAt=$cycleStartedAt '
      '→ since=$since (${cycleStartedAt == null ? "fallback startOfDay" : "cycle.startedAt"}) '
      'forceFreshBaseline=$forceFreshBaseline baselineSince=$_baselineSince',
    );

    // SPEC-253.1: solo limpiar el baseline si la VENTANA cambió de verdad
    // (transición real de ciclo/Día Metabólico) o si se pide explícitamente
    // (nuevo usuario, resetDaily). Si `since` es el mismo que la última vez
    // (p.ej. reconexión del stream por blip de red vía `onDone`), el
    // baseline se preserva — ver comentario en el campo `_baseline`.
    if (forceFreshBaseline || since != _baselineSince) {
      _baseline = const [];
      _baselineSince = since;
    }

    final repo = _ref.read(nutritionRepositoryProvider);
    attachSubscription(repo.watchSinceLogs(userId, since).listen(
      (logs) {
        if (!mounted) return;
        final merged = _mergeWithBaseline(_baseline, logs);
        _baseline = merged;
        AppLogger.debug(
          '[nutritionDebug] snapshot recibido: ${logs.length} logs '
          '(merge final: ${merged.length}) → '
          '${merged.map((l) => "${l.label}@${l.timestamp} (id=${_shortId(l.id)})").join(", ")}',
        );
        state = _recalculate(merged, state.targetMeals);
      },
      onError: (Object e) {
        // Error transitorio de red o permiso. Mantener estado previo;
        // el próximo evento estable corregirá.
        AppLogger.warning('nutrition stream error (transitorio): $e');
      },
      onDone: () {
        // BUGFIX (2026-06-14): Firestore puede cerrar el stream por
        // reconexión, cambio de token o error irrecuperable. Si no
        // re-suscribimos, los logs nuevos nunca llegan al estado.
        //
        // SPEC-253.1: NO forzar baseline fresco acá — es la misma ventana,
        // solo se reconecta el listener. El baseline (`_baseline` a nivel
        // de instancia) sigue protegiendo contra un primer snapshot
        // incompleto de la reconciliación de caché tras reconectar.
        if (mounted) _subscribeFor(_currentCycleStartedAt);
      },
    ));
  }

  /// SPEC-253: guardia definitiva contra pérdida silenciosa de datos.
  ///
  /// Causa raíz reportada por Carlos (2026-07-08): registrar o editar una
  /// comida hacía desaparecer OTRA comida ya visible, incluso después de
  /// reiniciar la app — es decir, el snapshot de Firestore para la MISMA
  /// query/ventana dejaba de incluir un doc que un snapshot anterior sí
  /// traía, sin que el usuario hubiera pedido borrarlo. El mecanismo
  /// exacto (listener de Firestore, caché local, o alguna interacción con
  /// el ciclo metabólico) no se pudo confirmar con certeza vía logs, pero
  /// el síntoma es inequívoco: datos que el usuario ve, desaparecen solos.
  ///
  /// En vez de seguir apostando a diagnosticar la causa exacta, esta
  /// guardia hace la garantía explícita: un log que el usuario vio en
  /// pantalla NUNCA desaparece de la vista salvo que el propio notifier
  /// haya pedido borrarlo (`_explicitlyRemovedIds`). Si Firestore reporta
  /// un log de menos sin que nosotros lo hayamos borrado, lo preservamos
  /// y logueamos un warning — preferimos un log "zombie" temporal (que se
  /// autocorrige en el próximo snapshot completo) a que el usuario pierda
  /// el registro de lo que comió.
  List<NutritionLog> _mergeWithBaseline(
    List<NutritionLog> baseline,
    List<NutritionLog> fresh,
  ) {
    if (baseline.isEmpty) return fresh;
    final freshIds = fresh.map((l) => l.id).toSet();
    final missing = baseline.where(
      (old) =>
          !freshIds.contains(old.id) &&
          !_explicitlyRemovedIds.contains(old.id),
    );
    if (missing.isEmpty) return fresh;
    AppLogger.warning(
      '[nutrition] SPEC-253: el snapshot de Firestore no trae '
      '${missing.length} log(s) que el usuario no borró explícitamente — '
      'se preservan en el state para evitar pérdida visual de datos. '
      'ids: ${missing.map((l) => '${l.label}@${l.timestamp}').join(", ")}',
    );
    return [...fresh, ...missing]
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));
  }

  // ─── API pública ─────────────────────────────────────────────────────────

  /// Registra una comida.
  ///
  /// [label]    — etiqueta semántica opcional; si no se provee se infiere.
  /// [mealTime] — timestamp opcional; si no se provee se usa `DateTime.now()`.
  ///
  /// SPEC-71.3: macros opcionales (SPEC-64). Si el usuario no los provee,
  /// quedan null y el log se persiste sin información nutricional — el
  /// ScoreEngine sigue contando la comida en el ratio meal/target sin
  /// penalizar la ausencia de macros (peso 0.12 conservador, ver
  /// IMR_BIBLIOGRAPHY.md §4.4).
  Future<void> logMeal({
    String? label,
    DateTime? mealTime,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    int? glycemicIndex,
    NutritionLogSource source = NutritionLogSource.userInput,
    // SPEC-137: clasificación A:E del plato. Default a2e1 (2x1) para
    // callers que no pasen ratio (tests existentes, código legacy).
    MealRatio ratio = MealRatio.a2e1,
    // SPEC-137: marca el log como día de permitidos. Default false.
    bool isCheatDay = false,
    // SPEC-137 E.5: si true, ignora el warning de intervalo 2-3h y
    // registra igual. NO ignora el bloqueo (<2h). UI debe pasarlo en
    // true solo después de que el usuario acepte el dialog de warning.
    bool forceLog = false,
    // SPEC-138: slots NOVA 4 del plato (numerador del % UPF).
    // Null si el caller no usa PlateBuilder (tests, código legacy).
    int? upfSlots,
    // SPEC-138: total de slots del plato (denominador).
    // Null si el caller no usa PlateBuilder.
    int? totalSlots,
    // SPEC-BUG6: ids de alimentos del PlateBuilder para pre-cargar edición.
    List<String> plateItemIds = const [],
    // SPEC-252: id del log que esta llamada va a REEMPLAZAR (modo edición
    // vía `replaceMeal`). Se excluye de `state.todayLogs` al calcular
    // `lastMealAt` y al armar la lista optimista — sin esto, editar la
    // comida más reciente comparaba el intervalo contra SÍ MISMA (delta
    // ≈ 0 < 2h), disparaba `MealTooSoonException` incondicionalmente
    // (el bloqueo no respeta `forceLog`), y el log nunca se re-creaba —
    // pero `replaceMeal` ya había disparado el borrado del viejo antes de
    // llamar aquí. Resultado: editar una comida la eliminaba sin guardar
    // la nueva versión. Ver SPEC-252.
    String? replacingLogId,
  }) async {
    final userId = _activeUserId;
    if (userId == null) return;

    final timestamp = mealTime ?? DateTime.now();
    final effectiveLabel = label ?? state.nextMealLabel;
    final withinWindow = _isWithinCircadianWindow(timestamp);

    // SPEC-137 E.5: validar intervalo entre comidas. Día de permitidos
    // suspende la regla. Si el log es retroactivo (mealTime en el
    // pasado), validamos contra el timestamp ingresado, no contra now.
    //
    // SPEC-252: excluir `replacingLogId` — el log que se está editando
    // no debe contar como "última comida" de sí mismo.
    final logsForIntervalCheck = replacingLogId == null
        ? state.todayLogs
        : state.todayLogs.where((l) => l.id != replacingLogId).toList();
    final lastMealAt = MealIntervalRules.lastMealOf(logsForIntervalCheck);
    final check = MealIntervalRules.check(
      lastMealAt: lastMealAt,
      attemptAt: timestamp,
      cheatDayActive: isCheatDay,
    );

    switch (check) {
      case MealIntervalCheck.blocked:
        throw MealTooSoonException(
          lastMealAt: lastMealAt!,
          attemptedAt: timestamp,
          canRegisterAt:
              lastMealAt.add(MealIntervalRules.minInterval),
        );
      case MealIntervalCheck.warning:
        if (!forceLog) {
          throw MealIntervalWarning(
            lastMealAt: lastMealAt!,
            attemptedAt: timestamp,
            recommendedAt:
                lastMealAt.add(MealIntervalRules.recommendedInterval),
          );
        }
      case MealIntervalCheck.ok:
      case MealIntervalCheck.firstMeal:
      case MealIntervalCheck.cheatDayBypass:
        break;
    }

    final log = NutritionLog(
      id: const Uuid().v4(),
      timestamp: timestamp,
      label: effectiveLabel,
      withinCircadianWindow: withinWindow,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      glycemicIndex: glycemicIndex,
      source: source,
      ratio: ratio,
      isCheatDay: isCheatDay,
      // SPEC-138: solo persistir si ambos vienen y son coherentes.
      // La validación dura está en el constructor de NutritionLog.
      upfSlots: upfSlots,
      totalSlots: totalSlots,
      // SPEC-BUG6: ids para pre-cargar edición.
      plateItemIds: plateItemIds,
    );

    final repo = _ref.read(nutritionRepositoryProvider);

    // SPEC-206 (offline-first) + BUGFIX (2026-06-14): update optimista
    // inmediato — el conteo sube al instante en UI sin depender de que
    // el stream de Firestore emita primero. El stream confirmará (o
    // corregirá) la lista cuando llegue el snapshot de la caché local.
    // Antes: si el stream tenía un error silenciado, el conteo quedaba
    // en 0 aunque el write fuera exitoso.
    if (mounted) {
      // SPEC-252: en modo edición, quitar el log viejo del cache local
      // ANTES de agregar el nuevo — evita un duplicado transitorio
      // (viejo + nuevo) hasta que el stream de Firestore reconcilie.
      final optimisticBase = replacingLogId == null
          ? state.todayLogs
          : state.todayLogs.where((l) => l.id != replacingLogId).toList();
      final optimisticLogs = List<NutritionLog>.from(optimisticBase)..add(log);
      state = _recalculate(optimisticLogs, state.targetMeals);
    }

    // SPEC-193/194: analytics (se auto-encola sin red) + coaching.
    AnalyticsService.logEvent(
      AnalyticsEvents.mealLogged,
      params: {AnalyticsParams.qualityBucket: ratio.name},
    );
    _ref.read(coachingCompletionProvider).onPillarActivity(Pillar.nutrition);

    // SPEC-251: el guardado real se dispara PRIMERO. Antes, la lectura de
    // `fastingProvider` (bloque de abajo, solo necesaria para decidir la
    // notificación de próxima comida) ocurría ANTES de este `saveMeal`.
    // Si esa lectura lanzaba una excepción, `logMeal()` abortaba sin
    // haber llamado nunca a `repo.saveMeal` — pero el estado local
    // optimista (arriba) ya mostraba la comida como guardada. Resultado:
    // una comida "fantasma" que el usuario ve en pantalla pero que nunca
    // llegó a Firestore, y que desaparece al re-sincronizar el stream.
    unawaited(repo.saveMeal(userId, log).catchError((Object e) {
      AppLogger.error('Persistencia de comida falló (reintenta al sync)', e);
    }));

    // SPEC-137 E.5: notificación de próxima comida (local, no requiere
    // red). Guard de ayuno: si el usuario está ayunando activamente, no
    // agendar "Tu próxima comida es a las HH:MM" — es incoherente con el
    // ayuno. Envuelto en try/catch (SPEC-251): un fallo acá — por
    // ejemplo si `fastingProvider` está en estado de error — nunca debe
    // impedir el guardado de arriba, que ya se disparó.
    try {
      final isFastingNow = _ref.read(fastingProvider).isActive;
      if (isCheatDay || isFastingNow) {
        unawaited(NotificationScheduler.cancelNextMealReminder());
      } else {
        final nextAt = timestamp.add(MealIntervalRules.recommendedInterval);
        unawaited(NotificationScheduler.scheduleNextMealReminder(
          nextMealAt: nextAt,
          leadTime: MealIntervalRules.notificationLeadTime,
        ));
      }
    } catch (e) {
      AppLogger.warning(
        'logMeal: no se pudo evaluar/agendar notificación de próxima comida',
        e,
      );
    }
  }

  /// Elimina el último registro del ciclo actual (acción "deshacer").
  Future<void> removeLastMeal() async {
    final userId = _activeUserId;
    if (userId == null) return;
    final repo = _ref.read(nutritionRepositoryProvider);
    // SPEC-210: usar inicio del ciclo actual como ventana, no medianoche.
    // Fallback a startOfDay si no hay ciclo activo (primer uso del día).
    final since = _currentCycleStartedAt ??
        DayBoundaryResolver.startOfDay(DateTime.now());
    // SPEC-253: el repo borra "el más reciente dentro de `since`" en el
    // servidor — coincide con `state.todayLogs.last` porque el notifier
    // usa la misma ventana. Lo marcamos como explícitamente eliminado
    // ANTES del borrado para que la guardia de `_mergeWithBaseline` no lo
    // preserve por error cuando el snapshot deje de traerlo.
    if (state.todayLogs.isNotEmpty) {
      _explicitlyRemovedIds.add(state.todayLogs.last.id);
    }
    // SPEC-206 (offline-first): borrado no bloqueante. El stream refleja la
    // lista actualizada desde la caché al instante; sincroniza al reconectar.
    unawaited(repo.removeLastMeal(userId, since: since).catchError((Object e) {
      AppLogger.error('Borrado de comida falló (reintenta al sync)', e);
    }));

    // SPEC-137 E.5: si después de remover queda alguna comida hoy,
    // re-agendar la notificación con la nueva "última comida". Si no
    // queda ninguna, o si el usuario está ayunando, cancelar.
    // SPEC-251: try/catch defensivo — un fallo al leer `fastingProvider`
    // no debe propagarse como si `removeLastMeal()` hubiera fallado (el
    // borrado de arriba ya se disparó de forma independiente).
    try {
      final remaining = state.todayLogs.length > 1
          ? state.todayLogs.sublist(0, state.todayLogs.length - 1)
          : <NutritionLog>[];
      final lastAt = MealIntervalRules.lastMealOf(remaining);
      final isFastingNow = _ref.read(fastingProvider).isActive;
      if (lastAt == null || isFastingNow) {
        await NotificationScheduler.cancelNextMealReminder();
      } else {
        final nextAt = lastAt.add(MealIntervalRules.recommendedInterval);
        await NotificationScheduler.scheduleNextMealReminder(
          nextMealAt: nextAt,
          leadTime: MealIntervalRules.notificationLeadTime,
        );
      }
    } catch (e) {
      AppLogger.warning(
        'removeLastMeal: no se pudo evaluar/agendar notificación de '
        'próxima comida',
        e,
      );
    }
  }

  /// Reemplaza un log existente (editar plato): registra la nueva versión
  /// y, si se guarda correctamente, elimina el log viejo con [oldId].
  ///
  /// SPEC-252 (bugfix crítico): el orden se invirtió respecto a la versión
  /// original. Antes se eliminaba `oldId` INCONDICIONALMENTE (fire-and-
  /// forget) y RECIÉN DESPUÉS se intentaba crear el nuevo log. Pero
  /// `logMeal()` valida el intervalo entre comidas usando `state.todayLogs`
  /// — que todavía contenía el log viejo (la eliminación es asíncrona,
  /// no había actualización optimista de por medio) — así que el intervalo
  /// se calculaba entre el nuevo timestamp y EL MISMO log que se estaba
  /// reemplazando. Como editar normalmente no cambia demasiado la hora,
  /// el delta era ≈0 → `MealIntervalCheck.blocked` (<2h) → `logMeal()`
  /// lanzaba `MealTooSoonException` INCONDICIONALMENTE (el bloqueo no
  /// respeta `forceLog`, ver comentario en `logMeal`). Resultado: el log
  /// viejo ya se había borrado, pero el nuevo nunca se creaba — editar
  /// una comida la eliminaba sin guardar nada.
  ///
  /// Ahora: (1) `logMeal()` se llama primero, pasando `replacingLogId:
  /// oldId` para que excluya ese log al validar el intervalo (ver
  /// `logMeal`); (2) solo si `logMeal()` no lanzó excepción, se dispara
  /// la eliminación del log viejo (no bloqueante, offline-first). Si
  /// `logMeal()` falla por cualquier motivo real (p.ej. choca con OTRA
  /// comida existente), el log viejo se conserva intacto — no hay
  /// pérdida de datos.
  Future<void> replaceMeal({
    required String oldId,
    String? label,
    DateTime? mealTime,
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    int? glycemicIndex,
    NutritionLogSource source = NutritionLogSource.userInput,
    MealRatio ratio = MealRatio.a2e1,
    bool isCheatDay = false,
    bool forceLog = true,
    int? upfSlots,
    int? totalSlots,
    List<String> plateItemIds = const [],
  }) async {
    final userId = _activeUserId;
    if (userId == null) return;

    // SPEC-253: marcar oldId como explícitamente eliminado ANTES de
    // llamar a logMeal — así la guardia de `_mergeWithBaseline` sabe que
    // su desaparición del próximo snapshot es intencional (edición), no
    // una anomalía a preservar.
    _explicitlyRemovedIds.add(oldId);

    // Registrar el nuevo primero. `replacingLogId` excluye el log viejo
    // de la validación de intervalo (SPEC-252) — sin esto, comparar contra
    // sí mismo siempre da un delta ≈0 y bloquea el registro.
    await logMeal(
      label: label,
      mealTime: mealTime,
      calories: calories,
      protein: protein,
      carbs: carbs,
      fat: fat,
      fiber: fiber,
      glycemicIndex: glycemicIndex,
      source: source,
      ratio: ratio,
      isCheatDay: isCheatDay,
      forceLog: forceLog,
      upfSlots: upfSlots,
      totalSlots: totalSlots,
      plateItemIds: plateItemIds,
      replacingLogId: oldId,
    );

    // Solo si el registro anterior no lanzó: eliminar el log viejo.
    // No bloqueante (offline-first) — el stream reconcilia la lista.
    unawaited(
      _ref
          .read(nutritionRepositoryProvider)
          .deleteMealById(userId, oldId)
          .catchError((Object e) {
        AppLogger.error('replaceMeal: eliminación del viejo falló', e);
      }),
    );
  }

  /// SPEC-240: Elimina un log específico por su id.
  ///
  /// A diferencia de [removeLastMeal] (que solo borra el último), este
  /// método permite eliminar cualquier comida del historial del Día
  /// Metabólico activo desde [MealHistorySheet].
  ///
  /// Patrón offline-first (SPEC-206): borrado optimista inmediato en el
  /// state local; Firestore sincroniza en background. El stream de
  /// Firestore confirmará (o corregirá) el estado cuando llegue el
  /// siguiente snapshot.
  Future<void> deleteMealById(String mealId) async {
    final userId = _activeUserId;
    if (userId == null) return;

    // SPEC-253: marcar como explícitamente eliminado — la guardia de
    // `_mergeWithBaseline` no debe "resucitar" este log cuando el
    // próximo snapshot deje de traerlo.
    _explicitlyRemovedIds.add(mealId);

    // Borrado optimista: quitar del cache local antes del round-trip.
    if (mounted) {
      final updated = state.todayLogs
          .where((log) => log.id != mealId)
          .toList(growable: false);
      state = _recalculate(updated, state.targetMeals);
    }

    // SPEC-251: el borrado real en Firestore se dispara ANTES de la
    // lógica de notificación (misma corrección que en `logMeal`). Antes,
    // si la lectura de `fastingProvider` de abajo lanzaba, este borrado
    // nunca se ejecutaba — el usuario veía la comida desaparecer en la
    // UI (state optimista de arriba) pero seguía viva en Firestore, y
    // reaparecía en el próximo snapshot del stream.
    unawaited(
      _ref
          .read(nutritionRepositoryProvider)
          .deleteMealById(userId, mealId)
          .catchError((Object e) {
        AppLogger.error('deleteMealById: Firestore falló (reintenta al sync)', e);
      }),
    );

    // Reajustar notificación de próxima comida. Envuelto en try/catch:
    // un fallo acá nunca debe impedir el borrado de arriba, que ya se
    // disparó.
    try {
      final remaining = state.todayLogs;
      final lastAt = MealIntervalRules.lastMealOf(remaining);
      final isFastingNow = _ref.read(fastingProvider).isActive;
      if (lastAt == null || isFastingNow) {
        unawaited(NotificationScheduler.cancelNextMealReminder());
      } else {
        final nextAt = lastAt.add(MealIntervalRules.recommendedInterval);
        unawaited(NotificationScheduler.scheduleNextMealReminder(
          nextMealAt: nextAt,
          leadTime: MealIntervalRules.notificationLeadTime,
        ));
      }
    } catch (e) {
      AppLogger.warning(
        'deleteMealById: no se pudo evaluar/agendar notificación de '
        'próxima comida',
        e,
      );
    }
  }

  /// SPEC-58 + SPEC-149.2: Reset idempotente disparado al cierre del
  /// ciclo metabólico o a medianoche calendárica (red de seguridad).
  ///
  /// Limpia el cache local y re-suscribe el stream usando el `since`
  /// del ciclo activo (anclado al Día Metabólico). Los logs persistidos
  /// quedan intactos para análisis longitudinal.
  void resetDaily() {
    if (!mounted) return;
    state = state.copyWith(
      todayLogs: const [],
      nutritionScore: 0.0,
      windowAdherence: 0.0,
    );
    // SPEC-253.1: reset explícito — forzar baseline fresco aunque `since`
    // termine coincidiendo con el anterior (p.ej. reset por medianoche
    // dentro del mismo ciclo sin cambio de ventana).
    _subscribeFor(_currentCycleStartedAt, forceFreshBaseline: true);
  }

  // ─── Lógica interna ──────────────────────────────────────────────────────

  bool _isWithinCircadianWindow(DateTime time) {
    final profile = _circadianProfile;
    if (profile == null) return true;
    final first = profile.firstMealGoal;
    final last = profile.lastMealGoal;
    if (first == null || last == null) return true;
    final timeMinutes = time.hour * 60 + time.minute;
    final firstMinutes = first.hour * 60 + first.minute;
    final lastMinutes = last.hour * 60 + last.minute;
    return timeMinutes >= firstMinutes && timeMinutes <= lastMinutes;
  }

  /// Recalcula nutritionScore y windowAdherence dado un conjunto de logs.
  ///
  /// SPEC-audit CODE-02: la fórmula (pesos 0.60/0.40) ahora vive en
  /// `NutritionScoreCalculator` — mismos valores, solo con nombre.
  NutritionState _recalculate(List<NutritionLog> logs, int target) {
    final double mealCountScore =
        NutritionScoreCalculator.mealCountScore(logs.length, target);
    final double windowAdherence =
        NutritionScoreCalculator.windowAdherence(logs);
    final double score = NutritionScoreCalculator.score(
      mealCountScore: mealCountScore,
      windowAdherence: windowAdherence,
    );
    return state.copyWith(
      todayLogs: logs,
      nutritionScore: score,
      windowAdherence: windowAdherence,
    );
  }
}

// ─── Provider ─────────────────────────────────────────────────────────────────

final nutritionProvider =
    StateNotifierProvider<NutritionNotifier, NutritionState>((ref) {
  return NutritionNotifier(ref);
});
