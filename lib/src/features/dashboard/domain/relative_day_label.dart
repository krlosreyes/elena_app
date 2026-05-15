// SPEC-102.1: helper puro para describir relación de una fecha con
// "hoy" desde la perspectiva del usuario. Sin dependencias de Flutter.
//
// Reglas:
//   diff == 0  → '' (hoy implícito, no se muestra sufijo)
//   diff == +1 → 'mañana'
//   diff == -1 → 'ayer'
//   diff == +N → 'en N días' (raro)
//   diff == -N → 'hace N días' (raro)
//
// La diferencia se mide en días calendario (ignorando hora), para
// evitar inconsistencias por timezones o por ayunos que cruzan
// medianoche apenas.

class RelativeDayLabel {
  RelativeDayLabel._();

  /// Calcula el sufijo descriptivo. Vacío para "hoy".
  static String qualifier(DateTime target, DateTime now) {
    final int diff = _daysBetweenCalendar(now, target);
    if (diff == 0) return '';
    if (diff == 1) return 'mañana';
    if (diff == -1) return 'ayer';
    if (diff > 1) return 'en $diff días';
    return 'hace ${-diff} días';
  }

  /// Diferencia en días calendario entre `from` y `to` (positivo si
  /// `to` es posterior). Trunca la hora — solo cuenta el día.
  static int _daysBetweenCalendar(DateTime from, DateTime to) {
    final fromDay = DateTime(from.year, from.month, from.day);
    final toDay = DateTime(to.year, to.month, to.day);
    return toDay.difference(fromDay).inDays;
  }
}
