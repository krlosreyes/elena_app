import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';

// ─────────────────────────────────────────────────────────────────────────────
// SPEC-255 RF-02: resultado de una racha "protegida" (con reservas/freeze).
// ─────────────────────────────────────────────────────────────────────────────

/// Resultado de [StreakEngine.computeCurrentStreakWithFreezes]. Solo debe
/// usarse para el número que ve el usuario (header/card) — NUNCA para
/// alimentar [StreakEngine.computeAdherenceTrend] ni el IMR longitudinal,
/// que siguen usando [StreakEngine.computeCurrentStreak] sin protección.
class StreakFreezeState {
  /// Racha visible al usuario: cuenta días reales Y días perdonados por
  /// una reserva.
  final int currentStreak;

  /// Reservas disponibles ahora mismo (0-2). Se gana 1 cada 7 días
  /// consecutivos REALES (sin usar reserva), tope 2.
  final int freezesAvailable;

  /// True si algún día de la cadena actual fue perdonado por una reserva.
  final bool currentStreakHasProtectedDay;

  const StreakFreezeState({
    required this.currentStreak,
    required this.freezesAvailable,
    required this.currentStreakHasProtectedDay,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// StreakEngine — Motor de cómputo puro (sin estado, sin side-effects)
// ─────────────────────────────────────────────────────────────────────────────

/// Computa métricas de racha a partir del historial de [StreakEntry].
///
/// Todas las funciones son estáticas y puras: misma entrada → misma salida.
/// Esto facilita testing unitario sin mocks ni providers.
class StreakEngine {
  StreakEngine._();

  // ─────────────────────────────────────────────────────────────────────────
  // Evaluación de cumplimiento diario por pilar
  // ─────────────────────────────────────────────────────────────────────────

  /// Evalúa si el ayuno del día cumple el umbral.
  /// SPEC-70 §7.5 — ENGINEERING JUDGMENT (80% deja margen para días
  /// imperfectos; 10h sin protocolo cubre ayuno nocturno saludable).
  ///
  /// - Protocolo activo: ≥80% de las horas objetivo.
  /// - Sin protocolo ('Ninguno'): ≥10h (ayuno nocturno natural suficiente).
  static bool evaluateFasting({
    required double fastingHours,
    required String fastingProtocol,
  }) {
    if (fastingProtocol == 'Ninguno') {
      return fastingHours >= 10.0;
    }
    final parts = fastingProtocol.split(':');
    final targetHours = double.tryParse(parts.first) ?? 16.0;
    return fastingHours >= targetHours * 0.8;
  }

  /// Evalúa si el sueño cumple el mínimo restaurador.
  /// SPEC-70.5 §7.1 — MEDIUM (validado por revisión clínica externa).
  /// Umbral movido de 6.5h a 7.0h tras feedback: "6.5h es supervivencia,
  /// no metamorfosis". AASM Practice Guidelines establece 7-9h como rango
  /// óptimo; por debajo de 7h el eje grelina/leptina se altera y aumenta
  /// el riesgo de obesidad, T2D e hipertensión.
  ///
  /// HOTFIX 2026-06-17: alineado a ≥6.5h para ser consistente con el
  /// doc en StreakEntry ("≥6.5 horas de sueño efectivo registrado").
  /// 6.5h es el umbral mínimo funcional — no el óptimo. Un usuario que
  /// duerme 6:40 merece crédito por el pilar; el score de calidad
  /// multidimensional (SPEC-69) ya penaliza <7h de forma continua.
  static bool evaluateSleep({required double sleepHours}) => sleepHours >= 6.5;

  /// Evalúa si la hidratación alcanzó el 75% de la meta.
  /// SPEC-70 §7.2 — ENGINEERING JUDGMENT (mínimo funcional sin
  /// requerir perfección; el goal mismo ya es conservadoramente alto).
  static bool evaluateHydration({required double progressPercentage}) =>
      progressPercentage >= 0.75;

  /// Evalúa si se registró ejercicio suficiente.
  /// SPEC-70 §7.3 — MEDIUM (20 min ≈ ACSM 150min/sem ÷ 7).
  static bool evaluateExercise({required int exerciseMinutes}) =>
      exerciseMinutes >= 20;

  /// Evalúa si se registró al menos 1 comida en el día.
  /// SPEC-70 §7.4 — LOW (proxy de engagement, no de calidad nutricional).
  static bool evaluateNutrition({required int mealsLogged}) => mealsLogged >= 1;

  // ─────────────────────────────────────────────────────────────────────────
  // Métricas de racha desde historial
  // ─────────────────────────────────────────────────────────────────────────

  /// Calcula la racha actual: días consecutivos hacia atrás desde hoy/ayer
  /// en que [StreakEntry.qualifiesForStreak] es true.
  ///
  /// La racha no se rompe si "hoy" aún no califica — se cuenta desde ayer.
  /// Se rompe cuando hay un día no calificado o una brecha en el calendario.
  static int computeCurrentStreak(List<StreakEntry> history) {
    if (history.isEmpty) return 0;

    final sorted = _sortedDescending(history);
    final today = _todayKey();
    final yesterday =
        _dateKey(DateTime.now().subtract(const Duration(days: 1)));

    // Punto de partida: si hoy califica, empezar desde hoy; si no, desde ayer.
    int start = 0;
    if (sorted.isNotEmpty &&
        sorted.first.date == today &&
        !sorted.first.qualifiesForStreak) {
      start = 1; // Saltar el día de hoy incompleto
    }

    int streak = 0;
    String? expectedDate;

    for (int i = start; i < sorted.length; i++) {
      final entry = sorted[i];

      if (!entry.qualifiesForStreak) break;

      if (expectedDate == null) {
        // Primer día válido — debe ser hoy o ayer para que la racha sea activa
        if (entry.date != today && entry.date != yesterday && i == start) break;
        expectedDate = entry.date;
        streak++;
      } else {
        final expected =
            DateTime.parse(expectedDate).subtract(const Duration(days: 1));
        if (entry.date == _dateKey(expected)) {
          streak++;
          expectedDate = entry.date;
        } else {
          break; // Brecha en el calendario
        }
      }
    }

    return streak;
  }

  /// SPEC-255 RF-02: versión "protegida" de [computeCurrentStreak] — perdona
  /// UN día no calificado dentro de la cadena si hay una reserva disponible.
  /// No perdona huecos de calendario (>1 día) ni dos días seguidos sin
  /// calificar. Nunca usada para IMR/adherencia — solo para el número
  /// motivacional que ve el usuario.
  ///
  /// Mecánica (§6 Fase 3 del spec): cada 7 días CONSECUTIVOS reales
  /// (sin usar reserva) que califican, se gana 1 reserva, tope 2. Gratis
  /// para todos los tiers — no repite el problema de credibilidad de RF-05.
  ///
  /// Propiedad clave de no-regresión: mientras un usuario nunca acumule
  /// 7 días reales consecutivos, `protectedDates` queda vacío y el
  /// resultado es IDÉNTICO a [computeCurrentStreak].
  static StreakFreezeState computeCurrentStreakWithFreezes(
    List<StreakEntry> history,
  ) {
    if (history.isEmpty) {
      return const StreakFreezeState(
        currentStreak: 0,
        freezesAvailable: 0,
        currentStreakHasProtectedDay: false,
      );
    }

    // Paso 1 (adelante, cronológico): marcar qué fechas quedan protegidas
    // y calcular cuántas reservas quedan disponibles al final.
    final forward = _forwardPassProtection(history);
    final protectedDates = forward.protectedDates;
    final banked = forward.banked;

    // Paso 2 (atrás, igual que computeCurrentStreak): un día cuenta si
    // califica O fue protegido por una reserva.
    final descending = _sortedDescending(history);
    final today = _todayKey();
    final yesterday =
        _dateKey(DateTime.now().subtract(const Duration(days: 1)));

    bool countsForStreak(StreakEntry e) =>
        e.qualifiesForStreak || protectedDates.contains(e.date);

    int start = 0;
    if (descending.isNotEmpty &&
        descending.first.date == today &&
        !countsForStreak(descending.first)) {
      start = 1;
    }

    int streak = 0;
    String? expectedDate;
    bool hasProtectedDay = false;

    for (int i = start; i < descending.length; i++) {
      final entry = descending[i];
      if (!countsForStreak(entry)) break;

      if (expectedDate == null) {
        if (entry.date != today && entry.date != yesterday && i == start) {
          break;
        }
        expectedDate = entry.date;
        streak++;
      } else {
        final expected =
            DateTime.parse(expectedDate).subtract(const Duration(days: 1));
        if (entry.date == _dateKey(expected)) {
          if (protectedDates.contains(entry.date)) hasProtectedDay = true;
          streak++;
          expectedDate = entry.date;
        } else {
          break;
        }
      }
      if (protectedDates.contains(entry.date)) hasProtectedDay = true;
    }

    return StreakFreezeState(
      currentStreak: streak,
      freezesAvailable: banked,
      currentStreakHasProtectedDay: hasProtectedDay,
    );
  }

  /// SPEC-256 RF-02: set de fechas ('yyyy-MM-dd') perdonadas por una
  /// reserva en TODO el historial (no solo la cadena actual) — para
  /// pintar el heatmap de racha en Progreso. Reusa el mismo cálculo
  /// forward que [computeCurrentStreakWithFreezes] (§ misma mecánica,
  /// una sola fuente de verdad).
  static Set<String> computeProtectedDates(List<StreakEntry> history) {
    if (history.isEmpty) return const {};
    return _forwardPassProtection(history).protectedDates;
  }

  /// Propuesta "racha protagonista" (2026-07-15, P3): encuentra el día
  /// más reciente que causó la ruptura de la racha — el primero (de más
  /// reciente a más antiguo) que no calificó y tampoco fue perdonado por
  /// una reserva. Se usa para explicar POR QUÉ se rompió la racha, no
  /// solo QUE se rompió (ver [StreakEntry.missReason]).
  ///
  /// `null` si no hay ningún día así en el historial (defensivo — no
  /// debería ocurrir cuando se llama justo tras detectar una ruptura,
  /// pero evita un crash si el caller lo hace en otro momento).
  static StreakEntry? findBreakingEntry(
    List<StreakEntry> history,
    Set<String> protectedDates,
  ) {
    final descending = _sortedDescending(history);
    for (final entry in descending) {
      if (!entry.qualifiesForStreak && !protectedDates.contains(entry.date)) {
        return entry;
      }
    }
    return null;
  }

  /// Paso 1 compartido por [computeCurrentStreakWithFreezes] y
  /// [computeProtectedDates]: recorre el historial en orden cronológico
  /// y devuelve qué fechas quedaron protegidas por una reserva, más
  /// cuántas reservas quedan disponibles al final del historial.
  static ({Set<String> protectedDates, int banked}) _forwardPassProtection(
    List<StreakEntry> history,
  ) {
    final ascending = _sortedAscending(history);
    final protectedDates = <String>{};
    int banked = 0;
    int consecutiveRealQualifying = 0;
    DateTime? prevDate;

    for (final entry in ascending) {
      final d = DateTime.tryParse(entry.date);
      if (d == null) continue;

      final isNextCalendarDay =
          prevDate != null && d.difference(prevDate).inDays == 1;

      if (prevDate != null && !isNextCalendarDay) {
        // Hueco de calendario (>1 día): rompe la racha de días reales
        // usada para ganar reservas.
        consecutiveRealQualifying = 0;
      }

      if (entry.qualifiesForStreak) {
        consecutiveRealQualifying++;
      } else if (isNextCalendarDay && banked > 0) {
        // Perdona este día puntual — consume una reserva.
        banked--;
        protectedDates.add(entry.date);
        consecutiveRealQualifying = 0; // no fue una completación real
      } else {
        consecutiveRealQualifying = 0;
      }

      if (consecutiveRealQualifying > 0 &&
          consecutiveRealQualifying % 7 == 0 &&
          banked < 2) {
        banked++;
      }

      prevDate = d;
    }

    return (protectedDates: protectedDates, banked: banked);
  }

  /// Calcula la racha más larga de toda la historia.
  static int computeLongestStreak(List<StreakEntry> history) {
    if (history.isEmpty) return 0;

    final sorted = _sortedAscending(history);
    int longest = 0;
    int current = 0;
    String? prevDate;

    for (final entry in sorted) {
      if (!entry.qualifiesForStreak) {
        current = 0;
        prevDate = null;
        continue;
      }

      if (prevDate == null) {
        current = 1;
      } else {
        final prev = DateTime.parse(prevDate);
        final curr = DateTime.parse(entry.date);
        final diff = curr.difference(prev).inDays;
        current = (diff == 1) ? current + 1 : 1;
      }

      prevDate = entry.date;
      if (current > longest) longest = current;
    }

    return longest;
  }

  /// SPEC-219: Tasa de completación semanal (sin requisito de IMR).
  /// Proporción de los últimos 7 días donde el usuario completó ≥3 pilares.
  /// Alimenta al ScoreEngine vía MetabolicState.weeklyAdherence.
  ///
  /// ANTES (pre SPEC-219): usaba `isEngaged` (IMR ≥ 60 + ≥3 pilares),
  /// creando un loop circular: IMR depende de adherencia, adherencia
  /// depende de IMR. Ahora solo mide completación binaria de pilares.
  static double computeWeeklyCompletionRate(List<StreakEntry> history) {
    final now = DateTime.now();
    final cutoff = DayBoundaryResolver.startOfDay(now)
        .subtract(const Duration(days: 6));

    final lastWeek = history.where((e) {
      final eDate = DateTime.tryParse(e.date);
      return eDate != null && !eDate.isBefore(cutoff);
    });

    if (lastWeek.isEmpty) return 0.0;

    final qualified = lastWeek.where((e) => e.qualifiesForStreak).length;
    return (qualified / 7.0).clamp(0.0, 1.0);
  }

  /// SPEC-219: Tasa de engagement semanal (con requisito de IMR).
  /// Proporción de los últimos 7 días donde `isEngaged` (IMR ≥ 60 + ≥3
  /// pilares). Para analytics y display en Análisis — NO alimenta al
  /// ScoreEngine (rompe circularidad).
  static double computeWeeklyEngagementRate(List<StreakEntry> history) {
    final now = DateTime.now();
    final cutoff = DayBoundaryResolver.startOfDay(now)
        .subtract(const Duration(days: 6));

    final lastWeek = history.where((e) {
      final eDate = DateTime.tryParse(e.date);
      return eDate != null && !eDate.isBefore(cutoff);
    });

    if (lastWeek.isEmpty) return 0.0;

    final qualified = lastWeek.where((e) => e.isEngaged).length;
    return (qualified / 7.0).clamp(0.0, 1.0);
  }

  /// SPEC-53: calidad ponderada de los últimos 7 días.
  ///
  /// Promedio simple de [StreakEntry.dailyQualityScore] sobre las
  /// entradas que caen en la ventana [hoy-6, hoy]. A diferencia de
  /// [computeWeeklyCompletionRate] (binario "calificó o no"), esta métrica
  /// captura el "cuánto" — un día con magnitudes de 0.85 puntúa más
  /// que un día apenas en 0.61, aunque ambos califiquen.
  ///
  /// Casos:
  /// - Historial vacío o sin entradas en la ventana → 0.0 (mismo
  ///   comportamiento que [computeWeeklyCompletionRate], evita penalizar
  ///   diferente al usuario nuevo).
  /// - Entradas legacy sin magnitudes → su `dailyQualityScore` cae al
  ///   fallback `pillarsCompleted/5`, así que la mezcla legacy+modernas
  ///   sigue produciendo un número significativo.
  /// - El divisor es la cantidad de entradas en la ventana, NO 7. Un
  ///   usuario con 3 días en la app obtiene el promedio de esos 3 días,
  ///   no `total/7` (que penalizaría artificialmente).
  static double computeWeeklyQualityScore(List<StreakEntry> history) {
    final now = DateTime.now();
    // SPEC-138: inicio del día vía fuente única.
    final cutoff = DayBoundaryResolver.startOfDay(now)
        .subtract(const Duration(days: 6));

    final lastWeek = history.where((e) {
      final eDate = DateTime.tryParse(e.date);
      return eDate != null && !eDate.isBefore(cutoff);
    }).toList();

    if (lastWeek.isEmpty) return 0.0;

    final sum = lastWeek.fold<double>(
      0.0,
      (acc, e) => acc + e.dailyQualityScore,
    );
    return (sum / lastWeek.length).clamp(0.0, 1.0);
  }

  /// SPEC-141 §RF-141-03: promedio del dailyQualityScore en ventana de
  /// 30 días. Espejo de [computeWeeklyQualityScore] con ventana extendida
  /// — es el input primario del IMR longitudinal (peso 35%).
  ///
  /// Casos (mismos que la versión semanal):
  /// - Historial vacío o sin entradas en ventana → 0.0.
  /// - Menos de 30 entries → promedio sobre las disponibles (no divide
  ///   por 30 — un usuario con 5 días en la app obtiene el promedio de
  ///   esos 5).
  /// - Entradas legacy sin magnitudes → fallback `pillarsCompleted/5`.
  ///
  /// Bibliografía: Petersen-Shulman 2018 (Physiol Rev) — turnover de
  /// marcadores metabólicos (HOMA-IR, triglicéridos) se mueve en
  /// escala 2-4 semanas; 30d cubre el límite superior conservador.
  static double computeMonthlyQualityScore(List<StreakEntry> history) {
    final now = DateTime.now();
    final cutoff = DayBoundaryResolver.startOfDay(now)
        .subtract(const Duration(days: 29));

    final lastMonth = history.where((e) {
      final eDate = DateTime.tryParse(e.date);
      return eDate != null && !eDate.isBefore(cutoff);
    }).toList();

    if (lastMonth.isEmpty) return 0.0;

    final sum = lastMonth.fold<double>(
      0.0,
      (acc, e) => acc + e.dailyQualityScore,
    );
    return (sum / lastMonth.length).clamp(0.0, 1.0);
  }

  /// SPEC-141 §RF-141-03: cuenta días con `qualifiesForStreak == true`
  /// en los últimos 90 días. Es el denominador de la "presencia
  /// sostenida" del usuario, input de [computeAdherenceTrend].
  ///
  /// Casos:
  /// - Historial vacío → 0.
  /// - Entradas fuera de la ventana → ignoradas.
  /// - Días duplicados (mismo `date`) → contados una sola vez.
  static int computeActiveDaysLast90(List<StreakEntry> history) {
    if (history.isEmpty) return 0;
    final now = DateTime.now();
    final cutoff = DayBoundaryResolver.startOfDay(now)
        .subtract(const Duration(days: 89));
    final daysInWindow = <String>{};
    for (final e in history) {
      if (!e.qualifiesForStreak) continue;
      final eDate = DateTime.tryParse(e.date);
      if (eDate == null || eDate.isBefore(cutoff)) continue;
      daysInWindow.add(e.date);
    }
    return daysInWindow.length;
  }

  /// SPEC-141 §RF-141-03: tendencia de adherencia 0..1 combinando racha
  /// actual y presencia en los últimos 90 días. Sin literatura directa
  /// pero refleja Dansinger 2005 JAMA: la adherencia sostenida domina
  /// sobre la elección puntual de intervención.
  ///
  /// Fórmula (juicio de ingeniería, calibrada para que un usuario
  /// "altamente consistente" cruce 0.80):
  ///   streakNormalized   = min(currentStreak / 14, 1.0)   // 14 días = streak alta
  ///   activeDaysFraction = activeDaysLast90 / 90          // 0..1
  ///   adherenceTrend     = 0.55 * streakNormalized + 0.45 * activeDaysFraction
  ///
  /// Casos:
  /// - Historial vacío → 0.0.
  /// - Usuario nuevo con streak=1, 1 día activo en 90 → ~0.044 (bajo).
  /// - Usuario perfecto streak=14+, 90/90 días activos → 1.0.
  ///
  /// Reusa los helpers existentes [computeCurrentStreak] y
  /// [computeActiveDaysLast90].
  static double computeAdherenceTrend(List<StreakEntry> history) {
    if (history.isEmpty) return 0.0;
    final currentStreak = computeCurrentStreak(history);
    final activeDays90 = computeActiveDaysLast90(history);
    final streakNorm = (currentStreak / 14.0).clamp(0.0, 1.0);
    final activeFrac = (activeDays90 / 90.0).clamp(0.0, 1.0);
    final raw = 0.55 * streakNorm + 0.45 * activeFrac;
    return raw.clamp(0.0, 1.0);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Reconciliación de HOY contra snapshots desactualizados de Firestore
  // ─────────────────────────────────────────────────────────────────────────

  /// 17-jul (Carlos: "llevaba 2, cerré el día, me devolvió a uno"): protege
  /// el conteo de racha contra una foto de Firestore de HOY más vieja que
  /// la que ya se calculó en memoria.
  ///
  /// `StreakNotifier.watchHistory` puede reemitir una versión de la
  /// entrada de hoy desactualizada — Firestore no garantiza que los acks
  /// de escrituras rápidas y consecutivas al mismo documento lleguen al
  /// listener en el mismo orden en que se hicieron. Es exactamente el
  /// mismo tipo de carrera que documenta el comentario SPEC-227 en
  /// `metabolic_cycle_service.dart` ("StreakNotifier reseteando
  /// fastingMagnitude antes de que el evaluador capture el snapshot"),
  /// pero afectando la propia racha en vez del daily score del ciclo.
  ///
  /// Reproducible: completar un ayuno (fastingCompleted:true persiste),
  /// arrancar el siguiente ayuno el mismo día calendario (Día Metabólico
  /// multi-ciclo) — si el ack de la escritura del primer ayuno llega
  /// desordenado, `_rebuildState` puede recibir un `history` donde HOY
  /// todavía figura `fastingCompleted:false`. Como
  /// `computeCurrentStreakWithFreezes` lee de `history` directo (no de
  /// `state.todayEntry`), ese retroceso descalifica el día y la racha cae.
  ///
  /// Solo `fastingCompleted`/`fastingMagnitude` tienen garantía de
  /// monotonía dentro del día calendario — ver el comentario extenso en
  /// `StreakNotifier._evaluateToday` sobre por qué un día puede tener 2+
  /// ciclos de ayuno. Los demás 4 pilares son deliberadamente "vivos"
  /// (SPEC-242: si el usuario borra un vaso de agua, el score debe bajar
  /// de inmediato) — esta función NO los toca, para no enmascarar una
  /// eliminación real del usuario como si fuera un snapshot viejo.
  ///
  /// Si [history] no trae ninguna entrada de hoy (el doc recién creado
  /// aún no llegó al snapshot local), se inyecta [localToday]. En
  /// cualquier otro caso [history] se devuelve tal cual — sin copias
  /// innecesarias cuando no hace falta reconciliar nada.
  static List<StreakEntry> reconcileTodayWithLocal({
    required List<StreakEntry> history,
    required StreakEntry? localToday,
    required String todayKey,
  }) {
    if (localToday == null || localToday.date != todayKey) return history;
    if (!localToday.fastingCompleted) return history;

    final idx = history.indexWhere((e) => e.date == todayKey);
    if (idx == -1) {
      return [localToday, ...history];
    }
    final incoming = history[idx];
    if (incoming.fastingCompleted) return history;

    final patched = incoming.copyWith(
      fastingCompleted: true,
      fastingMagnitude: localToday.fastingMagnitude,
    );
    final out = [...history];
    out[idx] = patched;
    return out;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Helpers privados
  // ─────────────────────────────────────────────────────────────────────────

  static List<StreakEntry> _sortedDescending(List<StreakEntry> history) =>
      [...history]..sort((a, b) => b.date.compareTo(a.date));

  static List<StreakEntry> _sortedAscending(List<StreakEntry> history) =>
      [...history]..sort((a, b) => a.date.compareTo(b.date));

  static String _todayKey() => _dateKey(DateTime.now());

  /// SPEC-138: delega en la fuente única del día (formato ISO `YYYY-MM-DD`).
  static String _dateKey(DateTime d) => DayBoundaryResolver.dayKeyIso(d);
}
