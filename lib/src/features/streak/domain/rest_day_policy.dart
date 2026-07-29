// Día de descanso planificado (2026-07-28).
//
// POR QUÉ EXISTE
// --------------
// Elena ya tenía protección de racha desde SPEC-255: cada 7 días reales
// seguidos se gana 1 reserva (tope 2) que perdona automáticamente un día
// fallado. Eso cubre el OLVIDO.
//
// No cubría el otro caso, que es distinto y mucho más común: el usuario
// que DECIDE descansar. Hasta ahora la app trataba los dos como el mismo
// fracaso y gastaba una reserva en ambos — es decir, le cobraba por
// descansar bien.
//
// La distinción no es cosmética, y es algo que Duolingo no puede hacer y
// Fastic solo insinúa: en salud metabólica **el descanso está prescrito**,
// no tolerado. No existe "descansar del español", pero sí existe el día
// de descanso en un plan de ejercicio y sí existe la comida social que
// rompe la ventana a propósito. Un día de descanso declarado no es un día
// perdonado: es una forma legítima de cumplir el protocolo.
//
// De ahí las dos reglas que definen este archivo:
//
//   1. SE DECLARA POR ADELANTADO. Eso es lo único que separa un plan de
//      una excusa. Declarar "hoy descanso" a las 23:00 cuando ya se falló
//      no es descansar, es racionalizar. Ver [canDeclare].
//
//   2. TIENE SUELO. Descansar es dormir y beber agua, no desaparecer. El
//      suelo son los dos pilares PASIVOS (hidratación y sueño): no exigen
//      disciplina ni esfuerzo, y son justo los que sostienen la
//      recuperación. Ver [meetsRestFloor].
//
// Si el suelo no se cumple, el día no es descanso: es un día fallado
// normal, y ahí sí puede entrar una reserva a perdonarlo. La degradación
// es limpia y no hace falta un caso especial.
//
// LO QUE ESTE ARCHIVO NO HACE
// ---------------------------
// No toca el IMR. Igual que las reservas (ver el doc de
// [StreakFreezeState]), el descanso solo afecta al número que ve el
// usuario — nunca a `computeCurrentStreak`, `computeAdherenceTrend` ni al
// IMR longitudinal. Esa separación es la que nos permite ser generosos
// con la racha sin mentir en la métrica: Duolingo no puede permitírselo
// porque su racha ES su única métrica; Elena tiene una honesta debajo.

import 'package:elena_app/src/core/services/day_boundary_resolver.dart';
import 'package:elena_app/src/features/streak/domain/streak_entry.dart';

/// Cuántos descansos planificados se permiten por semana.
///
/// Uno. El tope no es tacañería: es lo que mantiene el descanso dentro de
/// un ritmo semanal en vez de convertirlo en un saldo que se acumula. La
/// misma lógica por la que Duolingo topa las reservas en 2 — un colchón
/// sin techo deja de ser colchón y pasa a sustituir la conducta.
const int kMaxRestDaysPerWeek = 1;

/// Política de descanso declarada por el usuario.
///
/// Inmutable y serializable a mano (sin Freezed, igual que [StreakEntry],
/// para no depender de build_runner).
///
/// Dos formas de declarar, que conviven:
///
/// - [weeklyRestWeekday] — el día fijo de la semana. Es el modo por
///   defecto y el que construye ritmo.
/// - [movedDates] — mover el descanso de UNA semana concreta a otra
///   fecha, sin cambiar el día fijo. Para el compromiso social que cae en
///   jueves cuando tu descanso es domingo.
///
/// Una fecha declarada en [movedDates] **reemplaza** al día fijo de esa
/// semana; no se suma. Es un descanso por semana, se mueva o no.
class RestDayPolicy {
  /// Día fijo de descanso en formato ISO (1 = lunes … 7 = domingo).
  /// `null` = el usuario no ha elegido día fijo (descanso desactivado
  /// salvo declaraciones puntuales).
  final int? weeklyRestWeekday;

  /// Fechas 'yyyy-MM-dd' declaradas puntualmente. Cada una desplaza el
  /// descanso de SU semana.
  final Set<String> movedDates;

  const RestDayPolicy({
    this.weeklyRestWeekday,
    this.movedDates = const {},
  });

  /// Sin descanso configurado. Es el estado de todo usuario existente
  /// hasta que elija: la funcionalidad es opt-in, no aparece sola.
  static const RestDayPolicy disabled = RestDayPolicy();

  bool get isEnabled => weeklyRestWeekday != null || movedDates.isNotEmpty;

  RestDayPolicy copyWith({
    int? weeklyRestWeekday,
    bool clearWeekly = false,
    Set<String>? movedDates,
  }) =>
      RestDayPolicy(
        weeklyRestWeekday:
            clearWeekly ? null : (weeklyRestWeekday ?? this.weeklyRestWeekday),
        movedDates: movedDates ?? this.movedDates,
      );

  // ── Qué día es el descanso ────────────────────────────────────────────

  /// Clave 'yyyy-Www' de la semana ISO a la que pertenece [day]. Se usa
  /// para agrupar: el tope de [kMaxRestDaysPerWeek] es por semana, y una
  /// fecha movida solo desplaza el descanso de su propia semana.
  ///
  /// Semana de lunes a domingo (ISO 8601), coherente con
  /// [weeklyRestWeekday], que también es ISO.
  static String weekKey(DateTime day) {
    final d = DateTime(day.year, day.month, day.day);
    final monday = d.subtract(Duration(days: d.weekday - 1));
    return DayBoundaryResolver.dayKeyIso(monday);
  }

  /// Fecha de descanso que corresponde a la semana de [day], o `null` si
  /// esa semana no tiene ninguna.
  ///
  /// Una fecha movida gana al día fijo. Si por algún motivo hubiera más
  /// de una movida en la misma semana (no debería: la UI lo impide, pero
  /// el dominio tiene que ser total), gana la más temprana — la primera
  /// que el usuario declaró para esa semana.
  String? restDateForWeekOf(DateTime day) {
    final week = weekKey(day);

    final movedThisWeek = movedDates
        .where((k) => _weekKeyOfDateString(k) == week)
        .toList()
      ..sort();
    if (movedThisWeek.isNotEmpty) return movedThisWeek.first;

    final weekday = weeklyRestWeekday;
    if (weekday == null) return null;

    final d = DateTime(day.year, day.month, day.day);
    final monday = d.subtract(Duration(days: d.weekday - 1));
    return DayBoundaryResolver.dayKeyIso(
      monday.add(Duration(days: weekday - 1)),
    );
  }

  /// True si [dateKey] ('yyyy-MM-dd') es el descanso planificado de su
  /// semana.
  bool isRestDay(String dateKey) {
    final d = DateTime.tryParse(dateKey);
    if (d == null) return false;
    return restDateForWeekOf(d) == dateKey;
  }

  // ── Declarar ──────────────────────────────────────────────────────────

  /// True si [dateKey] puede declararse como descanso puntual estando
  /// [now] en curso.
  ///
  /// La regla es una sola y es la que sostiene todo el mecanismo: **tiene
  /// que ser un día futuro**. Ni hoy ni ayer.
  ///
  /// Excluir "hoy" es deliberado y va a incomodar a alguien, así que
  /// conviene dejar escrito el porqué: si se pudiera declarar el mismo
  /// día, la función dejaría de ser planificar el descanso y pasaría a
  /// ser deshacer un fallo. El usuario que a las 22:00 ve que no llega
  /// marcaría "hoy descanso" y la racha perdería su significado — sería
  /// imposible fallar. Para ese caso ya existe la reserva, que es
  /// retroactiva a propósito y está topada.
  bool canDeclare(String dateKey, {required DateTime now}) {
    final d = DateTime.tryParse(dateKey);
    if (d == null) return false;
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(d.year, d.month, d.day);
    return target.isAfter(today);
  }

  /// Declara [dateKey] como descanso, desplazando el de su semana.
  ///
  /// Devuelve `this` sin cambios si [canDeclare] es false — declarar
  /// tarde no falla ruidosamente, simplemente no hace nada; la UI ya
  /// impide llegar aquí y no queremos que un reloj desincronizado tumbe
  /// la pantalla.
  RestDayPolicy declare(String dateKey, {required DateTime now}) {
    if (!canDeclare(dateKey, now: now)) return this;

    final week = _weekKeyOfDateString(dateKey);
    if (week == null) return this;

    // Una fecha movida por semana: las anteriores de esa misma semana se
    // reemplazan, no se acumulan.
    final next = movedDates
        .where((k) => _weekKeyOfDateString(k) != week)
        .toSet()
      ..add(dateKey);
    return copyWith(movedDates: next);
  }

  /// Fechas de la semana de [day] a las que se puede mover el descanso
  /// estando [now] en curso, en orden cronológico.
  ///
  /// Son los días de esa semana ISO que pasan [canDeclare] — es decir,
  /// los que todavía no llegaron. Devuelve vacío si esa semana ya no
  /// admite cambios (porque terminó, o porque solo queda hoy).
  ///
  /// Existe en el dominio y no en la UI a propósito: la regla de "solo
  /// hacia adelante" es la que sostiene todo el mecanismo, y si la
  /// pantalla construyera su propia lista de candidatos podría ofrecer un
  /// día que `declare` va a rechazar en silencio. El usuario tocaría una
  /// opción y no pasaría nada.
  List<String> movableDatesInWeekOf(DateTime day, {required DateTime now}) {
    final d = DateTime(day.year, day.month, day.day);
    final monday = d.subtract(Duration(days: d.weekday - 1));
    return [
      for (var i = 0; i < 7; i++)
        DayBoundaryResolver.dayKeyIso(monday.add(Duration(days: i))),
    ].where((k) => canDeclare(k, now: now)).toList();
  }

  /// True si el descanso de la semana de [dateKey] está movido respecto
  /// del día fijo. `false` si no hay día fijo (no hay de qué moverse).
  bool isMovedWeekOf(String dateKey) {
    final week = _weekKeyOfDateString(dateKey);
    if (week == null) return false;
    return movedDates.any((k) => _weekKeyOfDateString(k) == week);
  }

  /// Cancela el descanso puntual de la semana de [dateKey]. El día fijo,
  /// si lo hay, vuelve a aplicar.
  RestDayPolicy cancelMoveForWeekOf(String dateKey) {
    final week = _weekKeyOfDateString(dateKey);
    if (week == null) return this;
    return copyWith(
      movedDates:
          movedDates.where((k) => _weekKeyOfDateString(k) != week).toSet(),
    );
  }

  /// Poda las fechas movidas anteriores a [before]. Sin esto el set
  /// crecería sin límite: una fecha movida solo importa mientras su
  /// semana esté dentro de la ventana de historial que la racha mira.
  RestDayPolicy pruneBefore(DateTime before) {
    final cutoff = DayBoundaryResolver.dayKeyIso(before);
    return copyWith(
      movedDates: movedDates.where((k) => k.compareTo(cutoff) >= 0).toSet(),
    );
  }

  static String? _weekKeyOfDateString(String dateKey) {
    final d = DateTime.tryParse(dateKey);
    return d == null ? null : weekKey(d);
  }

  // ── Suelo mínimo ──────────────────────────────────────────────────────

  /// Qué hay que cumplir para que un día declarado cuente como descanso:
  /// hidratación y sueño.
  ///
  /// Son los dos pilares pasivos — no exigen disciplina ni una sesión, y
  /// son precisamente los que sostienen la recuperación. Exigirlos
  /// mantiene la diferencia entre descansar y desaparecer, y de paso
  /// conserva el dato del día (un descanso sin ningún registro sería un
  /// agujero en el histórico y en el IMR).
  ///
  /// Nota sobre el pilar sueño: [StreakEntry.qualifiesForStreak] ya lo
  /// trata como una de las dos anclas metabólicas junto al ayuno, así que
  /// pedirlo aquí no introduce un criterio nuevo, reutiliza el que ya
  /// gobierna la racha.
  static bool meetsRestFloor(StreakEntry entry) =>
      entry.hydrationCompleted && entry.sleepCompleted;

  /// Por qué un día de descanso declarado no llegó a contar, o `null` si
  /// sí contó. Estructurado (no redactado) por la misma razón que
  /// [StreakEntry.missReason]: cada UI necesita su tiempo verbal.
  static RestFloorMiss? restFloorMiss(StreakEntry entry) {
    if (meetsRestFloor(entry)) return null;
    return RestFloorMiss(
      missingHydration: !entry.hydrationCompleted,
      missingSleep: !entry.sleepCompleted,
    );
  }

  // ── Serialización ─────────────────────────────────────────────────────

  Map<String, dynamic> toMap() => {
        'weeklyRestWeekday': weeklyRestWeekday,
        'movedDates': movedDates.toList()..sort(),
      };

  factory RestDayPolicy.fromMap(Map<String, dynamic> map) {
    final raw = map['weeklyRestWeekday'];
    final weekday = raw is num ? raw.toInt() : null;
    return RestDayPolicy(
      // Un weekday fuera de 1..7 (dato corrupto o de otra convención) se
      // descarta en vez de propagarse: el peor resultado posible sería
      // marcar como descanso un día que el usuario nunca eligió.
      weeklyRestWeekday:
          (weekday != null && weekday >= 1 && weekday <= 7) ? weekday : null,
      movedDates: ((map['movedDates'] as List?) ?? const [])
          .whereType<String>()
          .where((k) => DateTime.tryParse(k) != null)
          .toSet(),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is RestDayPolicy &&
      other.weeklyRestWeekday == weeklyRestWeekday &&
      other.movedDates.length == movedDates.length &&
      other.movedDates.containsAll(movedDates);

  @override
  int get hashCode => Object.hash(
        weeklyRestWeekday,
        Object.hashAllUnordered(movedDates),
      );
}

/// Qué le faltó a un día de descanso para cumplir el suelo.
class RestFloorMiss {
  final bool missingHydration;
  final bool missingSleep;

  const RestFloorMiss({
    required this.missingHydration,
    required this.missingSleep,
  });

  bool get missingBoth => missingHydration && missingSleep;

  @override
  bool operator ==(Object other) =>
      other is RestFloorMiss &&
      other.missingHydration == missingHydration &&
      other.missingSleep == missingSleep;

  @override
  int get hashCode => Object.hash(missingHydration, missingSleep);
}
