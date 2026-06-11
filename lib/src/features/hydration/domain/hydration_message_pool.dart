// SPEC-150 §RF-150-02 + §RF-150-03: pool curado de mensajes de hidratación.
//
// Tono (audit notif 2026-06-10): humano, cálido y simple — sin datos
// científicos ni fuentes en el cuerpo del mensaje. La ciencia vive en la app,
// no en la notificación. El campo `citation` se conserva en el modelo pero ya
// NO se muestra (el scheduler dejó de anexarlo).
//
// 3 mensajes por DayPeriod (12 total). El selector es determinístico y rota
// por día del año para evitar repetición día a día.

import 'package:elena_app/src/features/hydration/domain/hydration_message.dart';

class HydrationMessagePool {
  HydrationMessagePool._();

  /// Los 12 mensajes curados, indexados por período.
  static const Map<DayPeriod, List<HydrationMessage>> _pool = {
    // ─── MORNING ──────────────────────────────────────────────────────────
    DayPeriod.morning: [
      HydrationMessage(
        id: 'hyd-morning-00',
        period: DayPeriod.morning,
        title: '💧 Un vaso para arrancar',
        body: 'Tu cuerpo pasó la noche sin agua. Un vaso ahora y arrancás '
            'mejor.',
        citation: '',
      ),
      HydrationMessage(
        id: 'hyd-morning-01',
        period: DayPeriod.morning,
        title: '💧 Hidratate apenas despiertes',
        body: 'Tomar agua temprano te despeja y te pone en marcha.',
        citation: '',
      ),
      HydrationMessage(
        id: 'hyd-morning-02',
        period: DayPeriod.morning,
        title: '💧 Despertá tu cuerpo',
        body: 'Un vaso de agua ahora ayuda a poner todo en movimiento.',
        citation: '',
      ),
    ],

    // ─── MIDDAY ───────────────────────────────────────────────────────────
    DayPeriod.midday: [
      HydrationMessage(
        id: 'hyd-midday-00',
        period: DayPeriod.midday,
        title: '💧 Una pausa para tomar agua',
        body: 'Un vaso a media mañana te mantiene con energía.',
        citation: '',
      ),
      HydrationMessage(
        id: 'hyd-midday-01',
        period: DayPeriod.midday,
        title: '💧 De a sorbos, sin apuro',
        body: 'Tomá de a poco a lo largo del día; te sienta mejor.',
        citation: '',
      ),
      HydrationMessage(
        id: 'hyd-midday-02',
        period: DayPeriod.midday,
        title: '💧 Agua antes de comer',
        body: 'Un vaso antes del almuerzo te cae bien y te deja liviano.',
        citation: '',
      ),
    ],

    // ─── AFTERNOON ────────────────────────────────────────────────────────
    DayPeriod.afternoon: [
      HydrationMessage(
        id: 'hyd-afternoon-00',
        period: DayPeriod.afternoon,
        title: '💧 Energía sin café',
        body: 'Mucho cansancio de la tarde es solo falta de agua. Probá un '
            'vaso.',
        citation: '',
      ),
      HydrationMessage(
        id: 'hyd-afternoon-01',
        period: DayPeriod.afternoon,
        title: '💧 Tu cuerpo te lo agradece',
        body: 'Un vaso ahora y seguís bien el resto de la tarde.',
        citation: '',
      ),
      HydrationMessage(
        id: 'hyd-afternoon-02',
        period: DayPeriod.afternoon,
        title: '💧 No esperes a tener sed',
        body: 'Cuando llega la sed ya vas tarde. Adelantate con un vaso.',
        citation: '',
      ),
    ],

    // ─── EVENING ──────────────────────────────────────────────────────────
    DayPeriod.evening: [
      HydrationMessage(
        id: 'hyd-evening-00',
        period: DayPeriod.evening,
        title: '💧 Hidratate, con calma',
        body: 'Un poco de agua ahora, sin exagerar para no cortar el sueño.',
        citation: '',
      ),
      HydrationMessage(
        id: 'hyd-evening-01',
        period: DayPeriod.evening,
        title: '💧 Agua para los antojos',
        body: 'A veces el antojo de la noche es sed disfrazada. Probá un '
            'vaso.',
        citation: '',
      ),
      HydrationMessage(
        id: 'hyd-evening-02',
        period: DayPeriod.evening,
        title: '💧 Tu último vaso del día',
        body: 'Buen momento para tomar agua antes de cerrar el día.',
        citation: '',
      ),
    ],
  };

  /// Resuelve a qué DayPeriod corresponde una hora del día.
  /// Reglas: 5-11 morning, 11-14 midday, 14-18 afternoon, 18-21 evening.
  static DayPeriod periodFor(int hour) {
    if (hour >= 5 && hour < 11) return DayPeriod.morning;
    if (hour >= 11 && hour < 14) return DayPeriod.midday;
    if (hour >= 14 && hour < 18) return DayPeriod.afternoon;
    if (hour >= 18 && hour < 21) return DayPeriod.evening;
    return DayPeriod.evening;
  }

  /// Lista de mensajes para un período. Siempre 3 elementos.
  static List<HydrationMessage> messagesFor(DayPeriod period) {
    return _pool[period]!;
  }

  /// Selecciona un mensaje del pool de manera determinística para un
  /// momento dado + un slot dentro del día.
  static HydrationMessage selectFor({
    required DateTime scheduledTime,
    required int slotIndex,
  }) {
    final period = periodFor(scheduledTime.hour);
    final messages = messagesFor(period);
    final dayOfYear = _dayOfYear(scheduledTime);
    final index = (dayOfYear + slotIndex) % messages.length;
    return messages[index];
  }

  /// Total de mensajes en el pool (útil para tests).
  static int get totalMessages =>
      _pool.values.fold(0, (acc, list) => acc + list.length);

  static int _dayOfYear(DateTime t) {
    final start = DateTime(t.year);
    return t.difference(start).inDays + 1;
  }
}
