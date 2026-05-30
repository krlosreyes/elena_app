// ─────────────────────────────────────────────────────────────────────────────
// SPEC-138: DayBoundaryResolver — Fuente única de verdad sobre el límite del día
// ─────────────────────────────────────────────────────────────────────────────
//
// Antes de SPEC-138 la noción de "qué día es hoy" vivía duplicada en al menos
// ocho lugares (daily_reset, los data sources de los 5 pilares, streak_engine y
// daily_summary_mapper), cada uno derivando la fecha desde DateTime.now() local
// con la expresión `DateTime(now.year, now.month, now.day)`. Sin fuente única,
// cualquier ajuste de zona horaria o de regla de corte había que replicarlo en
// todos lados, y de ahí nacían los bugs de atribución (sueño/ayuno que cruzan
// medianoche) y de contaminación post-medianoche.
//
// DayBoundaryResolver consolida esa lógica. Decisión de producto SPEC-138:
// el límite nominal del día es la MEDIANOCHE LOCAL (00:00). No hay rollover
// circadiano ni anclaje a hora de despertar.
//
// Reglas (alineadas con SPEC-60):
// - Dart puro: sin Flutter, sin Riverpod, sin Firestore.
// - Determinista: ningún método llama DateTime.now(); el `now`/los timestamps
//   se pasan siempre desde fuera. Mismo input → mismo output.
// - Sin estado mutable.

/// Motor puro del límite del día. Fuente única de verdad sobre cuándo empieza
/// y termina el día y a qué día pertenece un evento.
class DayBoundaryResolver {
  DayBoundaryResolver._();

  /// Hora de inicio del día. Constante por decisión de producto SPEC-138
  /// (medianoche local). Cualquier cambio futuro del límite se hace AQUÍ y se
  /// propaga a todos los consumidores.
  static const int dayStartHour = 0;

  // ── Claves de día ────────────────────────────────────────────────────────

  /// Clave canónica compacta `YYYYMMDD` del día calendario al que pertenece
  /// `t`. Usada por `daily_summary` (docId) y por el id de sueño
  /// (`sleep_YYYYMMDD`).
  static String dayKey(DateTime t) {
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '$y$m$d';
  }

  /// Clave ISO `YYYY-MM-DD` del día calendario al que pertenece `t`. Usada por
  /// `streak_engine`, `daily_reset_service` y `period_comparison_service`.
  static String dayKeyIso(DateTime t) {
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  // ── Límites del día ──────────────────────────────────────────────────────

  /// Inicio (inclusive) del día calendario de `t` → 00:00:00.000 local.
  static DateTime startOfDay(DateTime t) =>
      DateTime(t.year, t.month, t.day, dayStartHour);

  /// Fin (exclusivo) del día calendario de `t` → 00:00 del día siguiente.
  /// Usa `t.day + 1`, que resuelve correctamente fin de mes/año y respeta DST
  /// local (igual que el timer de SPEC-58).
  static DateTime endOfDay(DateTime t) =>
      DateTime(t.year, t.month, t.day + 1, dayStartHour);

  /// True si `a` y `b` caen en el mismo día calendario local.
  static bool isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  /// True si `t` cae dentro del día calendario de `reference`
  /// (`startOfDay <= t < endOfDay`).
  static bool isInDayOf(DateTime t, DateTime reference) {
    final start = startOfDay(reference);
    final end = endOfDay(reference);
    return !t.isBefore(start) && t.isBefore(end);
  }

  // ── Atribución de eventos que cruzan medianoche (sueño / ayuno) ───────────

  /// Punto medio del intervalo `[start, end]`. Determinista y simétrico.
  static DateTime midpoint(DateTime start, DateTime end) {
    final halfMs = end.difference(start).inMilliseconds ~/ 2;
    return start.add(Duration(milliseconds: halfMs));
  }

  /// Día calendario (clave compacta `YYYYMMDD`) al que se ATRIBUYE un evento
  /// que puede cruzar medianoche (sueño, ayuno).
  ///
  /// Regla SPEC-138: el evento pertenece al día donde transcurre la MAYOR parte
  /// de su duración → el día del punto medio del intervalo.
  /// - Sueño 23:00 → 07:00: punto medio 03:00 → día del despertar.
  /// - Sueño 23:00 → 00:30: punto medio 23:45 → día anterior.
  /// - Ayuno 16:8 que cierra 00:30: punto medio cae el día previo.
  ///
  /// Si `end` precede a `start` (datos malformados) se ancla a `start`.
  static String attributionDayKey({
    required DateTime start,
    required DateTime end,
  }) {
    if (end.isBefore(start)) return dayKey(start);
    return dayKey(midpoint(start, end));
  }

  /// Variante ISO `YYYY-MM-DD` de [attributionDayKey].
  static String attributionDayKeyIso({
    required DateTime start,
    required DateTime end,
  }) {
    if (end.isBefore(start)) return dayKeyIso(start);
    return dayKeyIso(midpoint(start, end));
  }

  // ── Zona horaria ─────────────────────────────────────────────────────────

  /// Offset de zona horaria de `t` en minutos (negativo al oeste de UTC).
  /// SPEC-138 §4.5: se persiste junto a cada DailySummary para poder
  /// reconstruir el día local correcto aunque el dispositivo cambie de huso.
  static int tzOffsetMinutes(DateTime t) => t.timeZoneOffset.inMinutes;
}
