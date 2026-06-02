# SPEC-150 — Recordatorios de hidratación inteligentes con copy científico

**Estado:** CLOSED (implementada y testeada 2026-06-01)
**Versión:** 1.0
**Fecha:** 2026-06-01 · aprobada 2026-06-01 · cerrada 2026-06-01
**Tipo:** Mini-feature de Ola 1 — primera notificación educativa (no operacional) post-pivot estratégico
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 1 — Estabilización + active coaching
**Estimación:** 3-4 horas Carlos+Claude
**Marco normativo:** `CONSTITUTION.md`, `IMR_BIBLIOGRAPHY.md` §4.5 (hidratación) + §6.5 (peso del Score del Día).
**Depende de:** SPEC-05 (NotificationService), SPEC-149 (Día Metabólico — opcionalmente respeta el ciclo).

**Bloquea:** nada. Es feature aditiva.

---

## 1. Contexto y motivación

### 1.1 — El feedback de Carlos

Carlos identificó tras usar la app: *"deberíamos tener una notificación para consumo de agua cada 30 minutos"*. Validación reportada: la app NO tiene recordatorios de hidratación, mientras que ya tiene notificaciones operacionales para ayuno, primera comida y bloqueo intestinal.

### 1.2 — Por qué importa para el pivot

El pivot estratégico aprobado el 2026-06-01 establece la migración de "passive logging" a "active coaching". Las notificaciones existentes son **operacionales** (ej. "Cerraste tu ventana"). SPEC-150 introduce el primer caso de notificación **educativa**: cada disparo lleva una cita bibliográfica + un mensaje accionable adaptado a la hora del día.

Esta es la primera vez que el usuario recibe coaching directo en su lockscreen, no solo recordatorios. Si la mecánica funciona, el patrón se replica en SPEC-147 (Insights adaptativos) de Ola 3.

### 1.3 — Cadencia de 30 min vs evidencia

Carlos pidió cada 30 min. Auditoría bibliográfica:

- **EFSA 2010** establece 2.0L/día (mujeres) y 2.5L/día (hombres) como adequate intake, incluyendo bebidas y alimentos. Esto no respalda una cadencia específica.
- **Popkin et al. 2010** documenta que deshidratación leve (>1% del peso corporal) afecta cognición y termorregulación.
- **Maughan et al. 2003** sobre absorción intestinal: la hidratación uniforme con sorbos frecuentes maximiza absorción y minimiza estrés renal.
- **Adan 2012 (Eur J Clin Nutr)** sobre función cognitiva: caída de 12% en tareas atencionales con deshidratación 1.4%.

Apps comerciales típicas (WaterMinder, Plant Nanny, Hydro Coach): cadencia de 60-120 min, no 30 min.

**Decisión para MVP:** cadencia default de **90 minutos** durante la ventana de despertar (wakeUpTime → sleepTime). Para un usuario que despierta 7:00 y duerme 23:00 (ventana 16h), eso produce ~10 notificaciones/día — alineado con apps comerciales y con la guía de "hidratación uniforme" de Maughan 2003.

La cadencia de 30 min que pidió Carlos es excesiva (32 notifs/día) y produce fatiga notificacional documentada. Si tras MVP el usuario quiere más frecuencia, SPEC-150.next agrega configuración fina (Perfil → Hidratación → modo intenso/normal/ligero).

## 2. Decisión de producto (resumen ejecutivo)

1. **Cadencia default 90 min** entre `wakeUpTime` y `sleepTime` del perfil del usuario. Configurable en SPEC futura.
2. **Pool rotativo de 12 copies científicos**, cada uno con cita corta (autor + año). El copy se selecciona por hora del día (morning/midday/afternoon/evening) para que sea contextualmente relevante.
3. **IDs 400-419** reservados para hidratación. `cancelHydration()` cancela todo el rango.
4. **Reprogramación automática** cuando cambia el perfil circadiano (mismo gatillo que las notificaciones circadianas actuales).
5. **Cancelación al bloqueo intestinal** (21:30). Notificaciones después de esa hora se omiten — durante la fase de reparación celular no buscamos despertar al usuario para beber agua.
6. **No se respeta el Día Metabólico (SPEC-149)** para MVP. La hidratación es continua independientemente del ciclo. Si en el futuro queremos pausarla durante ayuno largo, va a SPEC-150.next.

## 3. Lo que NO se hace (límites duros de scope)

- **No se agrega configuración de cadencia en Perfil.** Default fijo 90 min. Configuración va a SPEC-150.next post-MVP.
- **No se mide adherencia a las notificaciones.** El usuario no recibe "te perdiste 3 hidrataciones" — eso es fatigador y contra-productivo.
- **No se programa durante el sueño** (`scheduledTime.hour >= sleepTime.hour`).
- **No se programa después del bloqueo intestinal** (21:30 fijo).
- **No se integra con HealthKit** (cuando el usuario logue agua manual, las notifs no se ajustan). SPEC-150.next puede agregar si telemetría lo justifica.
- **No hay deep link al pilar Hidratación** desde la notificación. Es push-only educativo. Tap en notif abre la app en `/dashboard`.
- **No se respeta el Día Metabólico de SPEC-149.** La hidratación opera independientemente del ciclo de ayuno.

## 4. Requisitos funcionales

### RF-150-01 — `HydrationMessage` value object

Crear `lib/src/features/hydration/domain/hydration_message.dart`:

```dart
enum DayPeriod { morning, midday, afternoon, evening }

class HydrationMessage {
  final String id;
  final DayPeriod period;
  final String title;
  final String body;
  final String citation;

  const HydrationMessage({
    required this.id,
    required this.period,
    required this.title,
    required this.body,
    required this.citation,
  });
}
```

### RF-150-02 — `HydrationMessagePool` con 12 mensajes científicos

Crear `lib/src/features/hydration/domain/hydration_message_pool.dart`. Pool curado con copies y citas reales:

**Morning (3 mensajes):**
- *"Rehidratá tu cerebro"* — *Perdiste ~1% de agua durante la noche. Empezá hidratado.* (Popkin 2010)
- *"Cortisol peak: hora ideal"* — *Hidratar durante el pico de cortisol mejora claridad mental.* (Adan 2012)
- *"Despertá tu metabolismo"* — *200-300ml ahora activa termorregulación y digestión.* (EFSA 2010)

**Midday (3 mensajes):**
- *"Tu rendimiento depende del agua"* — *1.4% deshidratación = 12% caída en atención sostenida.* (Adan 2012)
- *"Sorbé en lugar de tragar"* — *Hidratación uniforme maximiza absorción intestinal.* (Maughan 2003)
- *"Pre-comida: agua antes que sed"* — *200ml antes de almorzar reduce el pico glucémico.* (Davy 2008)

**Afternoon (3 mensajes):**
- *"Energía sin cafeína"* — *Mucha fatiga "vespertina" es deshidratación leve, no falta de sueño.* (Popkin 2010)
- *"Tu agua regula 100+ procesos"* — *Metabolismo, presión arterial, transporte de nutrientes.* (EFSA 2010)
- *"La sed llega tarde"* — *Cuando sentís sed, ya hay 1-2% deshidratación.* (Maughan 2003)

**Evening (3 mensajes):**
- *"Hidratación sin sobrecargar"* — *Moderá el volumen ahora para no fragmentar el sueño.* (Recomendación clínica AASM)
- *"Agua reduce hambre nocturna"* — *La deshidratación leve eleva grelina y dispara antojos.* (Stookey 2008)
- *"Última ventana antes del bloqueo"* — *Hidratá antes de las 21:00 para respetar el ciclo de reparación.* (SPEC-70.5 + Lopez-Minguez 2018)

### RF-150-03 — Selector determinístico de mensaje por slot

`HydrationMessagePool.selectFor(scheduledTime)` retorna un `HydrationMessage` apropiado:

1. Determinar `DayPeriod` según la hora:
   - 5-11h → morning
   - 11-14h → midday
   - 14-18h → afternoon
   - 18-21h → evening
2. Filtrar los 3 mensajes del pool de ese período.
3. Seleccionar uno por `index = (day_of_year + slot_index) % 3`. Determinístico — el mismo slot en el mismo día siempre rinde el mismo mensaje. Cambia día a día para evitar repetición.

### RF-150-04 — `scheduleHydrationReminders` en NotificationScheduler

Agregar al `NotificationScheduler`:

```dart
static Future<void> scheduleHydrationReminders(UserModel user) async {
  await NotificationService.cancelHydration();

  final profile = user.profile;
  final wakeUp = profile.wakeUpTime;
  final sleepTime = profile.sleepTime;

  // Hora límite: min(sleepTime, 21:00) — no perturbar post-bloqueo intestinal.
  final cutoffHour = sleepTime.hour < 21 ? sleepTime.hour : 21;

  // Slot inicial: wakeUp + 30 min (no notificar exactamente al despertar).
  var current = DateTime(2000, 1, 1, wakeUp.hour, wakeUp.minute)
      .add(const Duration(minutes: 30));
  final end = DateTime(2000, 1, 1, cutoffHour, 0);

  int slotIndex = 0;
  while (!current.isAfter(end) && slotIndex < 20) {
    final id = NotificationIds.hydrationStart + slotIndex;
    final message = HydrationMessagePool.selectFor(
      scheduledTime: current,
      slotIndex: slotIndex,
    );
    await _scheduleCircadian(
      id: id,
      hour: current.hour,
      minute: current.minute,
      title: message.title,
      body: '${message.body} · ${message.citation}',
    );
    current = current.add(const Duration(minutes: 90));
    slotIndex++;
  }

  AppLogger.info(
    '[NotificationScheduler] Hidratación: $slotIndex slots programados.',
  );
}
```

### RF-150-05 — `NotificationIds.hydrationStart` + `cancelHydration`

En `notification_service_mobile.dart` y `notification_service_web.dart`:

```dart
static const int hydrationStart = 400; // 400-419 reservados para hidratación
```

Agregar a `NotificationService`:

```dart
static Future<void> cancelHydration() async {
  if (kIsWeb || !_initialized) return;
  for (int id = 400; id <= 419; id++) {
    await _plugin.cancel(id: id);
  }
  AppLogger.debug('[NotificationService] Notificaciones de hidratación canceladas.');
}
```

### RF-150-06 — Disparo desde `NotificationProvider`

`notification_provider.dart` ya escucha cambios del perfil circadiano y llama `scheduleCircadianDay`. Agregar:

```dart
await NotificationScheduler.scheduleHydrationReminders(user);
```

Justo después del `scheduleCircadianDay` existente. Reprograma cuando cambia el perfil.

## 5. Cambios en código

| # | Acción | Archivo |
|---|---|---|
| 1 | Crear `HydrationMessage` value object | `lib/src/features/hydration/domain/hydration_message.dart` (nuevo) |
| 2 | Crear `HydrationMessagePool` con 12 mensajes + selector | `lib/src/features/hydration/domain/hydration_message_pool.dart` (nuevo) |
| 3 | Agregar `hydrationStart = 400` en ambos services | `lib/src/core/services/notification_service_mobile.dart` + `_web.dart` |
| 4 | Agregar `cancelHydration` en mobile service | `lib/src/core/services/notification_service_mobile.dart` |
| 5 | Agregar `scheduleHydrationReminders` | `lib/src/core/services/notification_scheduler.dart` |
| 6 | Llamar `scheduleHydrationReminders` en cambios del perfil | `lib/src/core/providers/notification_provider.dart` |
| 7 | Tests del pool + selector | `test/features/hydration/domain/hydration_message_pool_test.dart` (nuevo) |
| 8 | Tests del scheduler (cadencia, cutoff post-21h, no programación durante sueño) | `test/core/services/notification_scheduler_hydration_test.dart` (nuevo) |

## 6. Criterios de aceptación

1. Para usuario con wake 7:00 y sleep 23:00: se programan ~9-10 slots entre 7:30 y 21:00.

2. Para usuario con sleep 19:00 (caso edge): el cutoff es 19:00, no 21:00. Se respetan ambos límites.

3. Cada notificación rendea con `title`, `body` con cita anexada (`· EFSA 2010`).

4. El selector retorna mensajes del período correcto según la hora.

5. Dos días consecutivos con el mismo slot no rinden el mismo mensaje (rotación por `day_of_year`).

6. `cancelHydration` cancela los 20 slots posibles sin tocar otras notificaciones.

7. Cambio del perfil circadiano reprograma toda la agenda de hidratación.

8. Bloqueo intestinal (21:30) no recibe notificación de hidratación.

9. `flutter analyze` sin issues nuevos.

10. `flutter test` mantiene baseline + ≥12 tests nuevos.

## 7. Plan de pruebas

### 7.1 — Tests del pool selector

`test/features/hydration/domain/hydration_message_pool_test.dart`:

- Cada `DayPeriod` tiene exactamente 3 mensajes.
- `selectFor` con hora 8:00 retorna un mensaje de `morning`.
- `selectFor` con hora 13:00 retorna `midday`.
- `selectFor` con hora 16:00 retorna `afternoon`.
- `selectFor` con hora 20:00 retorna `evening`.
- Dos días consecutivos con el mismo slot retornan mensajes distintos (rotación).
- Todos los mensajes tienen `id` único, `citation` no vacía.

### 7.2 — Tests del scheduler

`test/core/services/notification_scheduler_hydration_test.dart`:

- Wake 7:00 + sleep 23:00 → primer slot 7:30, último ≤ 21:00.
- Wake 6:00 + sleep 19:00 → cutoff 19:00 (sleep < 21).
- Cadencia exacta de 90 min entre slots.
- IDs en rango 400-419.

## 8. Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-01 | 10 notifs/día puede ser exhaustivo y el usuario las silencia todas | Media | Default conservador 90 min (no los 30 pedidos). SPEC-150.next agrega configuración de modo intenso/ligero. |
| R-02 | Copies con citas pueden sonar académicos | Baja | El copy fue diseñado en tono "claim + dato" para que la cita refuerce credibilidad sin pedanteria. Iterar si Carlos lo siente off. |
| R-03 | Selector determinístico produce mismo mensaje en mismo slot del mismo día | Esperado | Rota por `day_of_year` — día a día cambia, dentro del día el slot es estable (útil para tests). |
| R-04 | Si el usuario cambia el perfil 10 veces al día, reprogramamos 10 veces | Baja | `cancelHydration` + reschedule es idempotente. El costo es despreciable. |
| R-05 | Bloqueo intestinal a 21:30 no aplica para todos los usuarios (algunos cierran ventana antes) | Media | El cutoff es `min(sleepTime, 21:00)` — respeta ambos límites. Si el usuario duerme 22:00, último slot es 21:00, no 22:00. |

## 9. Out of scope (explícito)

- Configuración de cadencia (intenso/normal/ligero) — SPEC-150.next.
- Telemetría de adherencia (cuántas notifs el usuario abrió vs ignoró) — SPEC-150.tail.
- Integración con HealthKit Water — depende de SPEC-132.next.
- Modificación dinámica de cadencia según ya logueada — SPEC-150.next.
- Skip de notificaciones durante ayuno largo (>18h) — SPEC-150.next.
- Adaptación a Día Metabólico (SPEC-149) — la hidratación es continua, no se ancla al ciclo.

## 10. Changelog

### v1.0 — 2026-06-01

Documento inicial. Primera notificación educativa post-pivot (passive logging → active coaching). Pool de 12 copies con citas reales (EFSA, Popkin, Maughan, Adan, Davy, Stookey). Cadencia default 90 min (no 30 min como pidió Carlos — documentado por qué). Cutoff 21:00 (respeta bloqueo intestinal SPEC-70.5).

### Cierre 2026-06-01 (mismo día)

Implementación completada en bloque único (~2h):

- `lib/src/features/hydration/domain/hydration_message.dart` — `HydrationMessage` value object + `DayPeriod` enum.
- `lib/src/features/hydration/domain/hydration_message_pool.dart` — pool curado con 12 mensajes (3 por período × 4 períodos) con citas reales (Popkin 2010, Adan 2012, EFSA 2010, Maughan 2003, Davy 2008, Stookey 2008, AASM clinical guidance, Lopez-Minguez 2018). Selector determinístico con rotación por `day_of_year`.
- `lib/src/core/services/notification_service_mobile.dart` + `_web.dart` — `NotificationIds.hydrationStart=400` + `hydrationEnd=419` + `cancelHydration()` (no-op en web).
- `lib/src/core/services/notification_scheduler.dart` — `scheduleHydrationReminders()` con constantes públicas (`kHydrationCadence`, `kHydrationCutoffHour`, `kHydrationFirstSlotOffset`) para testabilidad. Cutoff = min(sleepHour, 21).
- `lib/src/core/providers/notification_provider.dart` — invoca `scheduleHydrationReminders` junto con `scheduleCircadianDay` cuando cambia el perfil.
- 18 tests del pool selector (5 estructura + 4 periodFor + 7 selectFor determinístico + edge cases).
- 7 tests del scheduler (cadencia, cutoffs, edge case sleep<wake, IDs reservados).

**Cómputo final para usuario típico:** wake 7:00, sleep 23:00 → 10 slots distribuidos cada 90 min entre 7:30 y 21:00. Cada slot dispara una notificación con copy contextual al período del día + cita bibliográfica.

**Próximo paso desbloqueado:** Ola 1 tiene ahora 3 SPECs cerradas en una sesión (149 + 146 + 150). Pendientes: SPEC-132.next HealthKit observers (3-4 días, la pieza más densa) y SPEC-145 auditoría de indexes (1 día paralelo, preventivo).
