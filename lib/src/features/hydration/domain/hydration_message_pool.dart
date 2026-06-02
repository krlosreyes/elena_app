// SPEC-150 §RF-150-02 + §RF-150-03: pool curado de mensajes de
// hidratación con citas bibliográficas reales del proyecto.
//
// El pool tiene exactamente 3 mensajes por DayPeriod (12 total).
// El selector es determinístico — mismo slot en el mismo día rinde
// el mismo mensaje, pero rota por día del año para evitar repetición
// día a día.

import 'package:elena_app/src/features/hydration/domain/hydration_message.dart';

class HydrationMessagePool {
  HydrationMessagePool._();

  /// Los 12 mensajes curados, indexados por período.
  static const Map<DayPeriod, List<HydrationMessage>> _pool = {
    // ─── MORNING (5-11h) ──────────────────────────────────────────────────
    DayPeriod.morning: [
      HydrationMessage(
        id: 'hyd-morning-00',
        period: DayPeriod.morning,
        title: 'Rehidratá tu cerebro',
        body: 'Perdiste ~1% de agua durante la noche. Empezá hidratado.',
        citation: 'Popkin 2010',
      ),
      HydrationMessage(
        id: 'hyd-morning-01',
        period: DayPeriod.morning,
        title: 'Cortisol peak: hora ideal',
        body: 'Hidratar durante el pico de cortisol mejora claridad mental.',
        citation: 'Adan 2012',
      ),
      HydrationMessage(
        id: 'hyd-morning-02',
        period: DayPeriod.morning,
        title: 'Despertá tu metabolismo',
        body: '200-300ml ahora activan termorregulación y digestión.',
        citation: 'EFSA 2010',
      ),
    ],

    // ─── MIDDAY (11-14h) ──────────────────────────────────────────────────
    DayPeriod.midday: [
      HydrationMessage(
        id: 'hyd-midday-00',
        period: DayPeriod.midday,
        title: 'Tu rendimiento depende del agua',
        body: '1.4% de deshidratación = 12% de caída en atención.',
        citation: 'Adan 2012',
      ),
      HydrationMessage(
        id: 'hyd-midday-01',
        period: DayPeriod.midday,
        title: 'Sorbé en lugar de tragar',
        body: 'Hidratación uniforme maximiza absorción intestinal.',
        citation: 'Maughan 2003',
      ),
      HydrationMessage(
        id: 'hyd-midday-02',
        period: DayPeriod.midday,
        title: 'Pre-comida: agua antes que sed',
        body: '200ml antes de almorzar reducen el pico glucémico.',
        citation: 'Davy 2008',
      ),
    ],

    // ─── AFTERNOON (14-18h) ───────────────────────────────────────────────
    DayPeriod.afternoon: [
      HydrationMessage(
        id: 'hyd-afternoon-00',
        period: DayPeriod.afternoon,
        title: 'Energía sin cafeína',
        body:
            'Mucha fatiga vespertina es deshidratación leve, no sueño faltante.',
        citation: 'Popkin 2010',
      ),
      HydrationMessage(
        id: 'hyd-afternoon-01',
        period: DayPeriod.afternoon,
        title: 'Tu agua regula 100+ procesos',
        body: 'Metabolismo, presión arterial, transporte de nutrientes.',
        citation: 'EFSA 2010',
      ),
      HydrationMessage(
        id: 'hyd-afternoon-02',
        period: DayPeriod.afternoon,
        title: 'La sed llega tarde',
        body: 'Cuando sentís sed, ya hay 1-2% de deshidratación.',
        citation: 'Maughan 2003',
      ),
    ],

    // ─── EVENING (18-21h) ─────────────────────────────────────────────────
    DayPeriod.evening: [
      HydrationMessage(
        id: 'hyd-evening-00',
        period: DayPeriod.evening,
        title: 'Hidratación sin sobrecargar',
        body: 'Moderá el volumen ahora para no fragmentar el sueño.',
        citation: 'AASM clinical guidance',
      ),
      HydrationMessage(
        id: 'hyd-evening-01',
        period: DayPeriod.evening,
        title: 'Agua reduce hambre nocturna',
        body: 'La deshidratación leve eleva grelina y dispara antojos.',
        citation: 'Stookey 2008',
      ),
      HydrationMessage(
        id: 'hyd-evening-02',
        period: DayPeriod.evening,
        title: 'Última ventana antes del bloqueo',
        body:
            'Hidratá antes de las 21:00 para respetar el ciclo de reparación.',
        citation: 'Lopez-Minguez 2018',
      ),
    ],
  };

  /// Resuelve a qué DayPeriod corresponde una hora del día.
  /// Reglas: 5-11 morning, 11-14 midday, 14-18 afternoon, 18-21 evening.
  /// Para horas fuera de esos rangos (3-5 madrugada, 21-3 noche) cae al
  /// período más cercano — evening si ya pasó el bloqueo intestinal.
  static DayPeriod periodFor(int hour) {
    if (hour >= 5 && hour < 11) return DayPeriod.morning;
    if (hour >= 11 && hour < 14) return DayPeriod.midday;
    if (hour >= 14 && hour < 18) return DayPeriod.afternoon;
    if (hour >= 18 && hour < 21) return DayPeriod.evening;
    // Fuera de la ventana activa — caer a evening por defecto.
    return DayPeriod.evening;
  }

  /// Lista de mensajes para un período. Siempre 3 elementos.
  static List<HydrationMessage> messagesFor(DayPeriod period) {
    return _pool[period]!;
  }

  /// Selecciona un mensaje del pool de manera determinística para un
  /// momento dado + un slot dentro del día.
  ///
  /// La fórmula `(day_of_year + slot_index) % 3` garantiza que:
  /// - el mismo slot en el mismo día siempre rinde el mismo mensaje
  ///   (útil para tests y para que el usuario no vea sorpresas);
  /// - día a día el mismo slot rinde mensajes distintos (rotación,
  ///   evita la repetición).
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
