# SPEC-182 — Onboarding redefinido: coach, no cuaderno

**Estado:** CLOSED 2026-06-05
**Versión:** 1.0
**Tipo:** Re-tone + 2 pantallas nuevas en onboarding cold install. Reusa todos los pasos de captura existentes sin tocar formularios.
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** Ola 3 (`docs/PLAN_DELIVERY_2026_06_04.md` §4 + memoria `strategic-pivot-passive-to-active-coaching` decisión "Onboarding redefinido para reflejar la promesa de coach")
**Estimación:** ~3 horas (re-tono 3 pantallas + 2 nuevas + tests + mover requestPermissions)
**Marco normativo:** memoria `notification-tone-human-not-clinical`, IMR_BIBLIOGRAPHY §13 (Día Metabólico), SPEC-131 (introScreens base), SPEC-170 (dual scores), SPEC-148 (Transformation 30d).
**Depende de:** SPEC-131 (intro screens existentes), SPEC-149 (Día Metabólico), SPEC-170 (dual scores), SPEC-172 (permisos notifs en main.dart).
**Bloquea:** nada inmediato. Mejora la UX percibida del primer día.

---

## 1. Contexto

El pivot 2026-06-01 estableció que ElenaApp es **active coaching**, no passive logging. El onboarding actual contradice eso en 3 puntos:

1. **Copy "Hoy registramos para que mañana puedas mejorar"** (`IntroImrStep:56`) suena a cuaderno digital. El usuario sale con la mentalidad equivocada.
2. **Solo se explica el IMR** (singular). Pero el usuario va a ver dos números (HOY + IMR longitudinal de fondo) desde la primera vez que abre el Dashboard tras SPEC-170. Sin contexto previo, se confunde.
3. **No se explica el Día Metabólico** (SPEC-149). El usuario espera que la app funcione a calendario; cuando ve el cierre cíclico a las 21:00, no entiende.

Además, **el permiso de notificaciones** se solicita en cold start (`main.dart:98`) **antes de que el usuario sepa qué notifs va a recibir**. Esto produce rechazo y la SPEC-169 queda inerte para esos usuarios.

### 1.1 — El test de Carlos para "esto está bien"

Después del onboarding, el usuario debe poder responder estas 3 preguntas sin abrir la app de nuevo:
- *"¿Por qué hay dos números en el Dashboard?"* → HOY motivacional + IMR de fondo.
- *"¿Por qué el día se cierra a las 21:00 y no a las 23:59?"* → Día Metabólico.
- *"¿Por qué la app me va a mandar notificaciones?"* → coaching, no recordatorios vacíos, con respaldo bibliográfico.

Si no puede responder, el onboarding falló.

## 2. Decisión de producto

### 2.1 — Re-tono de las 3 pantallas intro existentes (SPEC-131)

| ID | Título actual | Título nuevo | Cambio de cuerpo |
|---|---|---|---|
| 100 | "Te damos la bienvenida" | "Te acompañamos a leer tu cuerpo" | Quitar "compañera para entender y mejorar". Reemplazar por "ElenaApp lee tu día y te da feedback con respaldo científico. No es un cuaderno. Es un coach." |
| 101 | "Tu IMR es un número que resume tu día" | "Tus dos números" | Reescribir completo: HOY (0-100, motivacional, se mueve a diario) + IMR (perfil de fondo, se mueve en semanas). Cita IMR_BIBLIOGRAPHY §13. |
| 102 | "Datos que pedimos, y por qué" | "Tus datos son tuyos" | Mantener fondo pero reordenar: primero qué hacemos CON los datos (coaching), después qué guardamos. Sin lista clínica. |

### 2.2 — 2 pantallas nuevas

**`103` — "Tu día metabólico"** (entre 102 y disclaimer)
- Headline: *"El día empieza cuando empezás a ayunar."*
- Body: 2 párrafos cortos. Explica que el cierre del día no es a medianoche calendárica; es cuando termina la ventana de comida y comienza el próximo ayuno. Cita IMR_BIBLIOGRAPHY §13.
- Icono: `Icons.brightness_3_outlined` (luna creciente).
- Sin botones especiales — flow normal con `_handleNext`.

**`104` — "Te vamos a hablar"** (después del paso 3 hábitos, antes de Health Sync)
- Headline: *"Te vamos a mandar mensajes con respaldo, no recordatorios vacíos."*
- Body: 1 párrafo + 3 ejemplos breves de notificación con cita (autofagia 16h · Levine 2017, eTRF · Sutton 2018, hidratación cíclica · Maughan 2003).
- **CTA central**: botón verde "Activar coaching por notificaciones". Al tap → `NotificationService.requestPermissions()` → avanza al paso siguiente sin importar la respuesta.
- Sub-CTA gris "Más tarde" → avanza sin solicitar permisos. El usuario los puede activar luego desde Perfil.
- Icono: `Icons.notifications_active_outlined`.

### 2.3 — Quitar `requestPermissions` de `main.dart`

La línea `await NotificationService.requestPermissions();` en `main.dart` post-init pasa al paso `104` del onboarding. Para usuarios que YA pasaron el onboarding (perfilStatus partial/complete), seguimos disparando en `main.dart` con un guard: si `prefs.getBool('onboardingCompleted') == true` → mantenemos el comportamiento actual (compat con usuarios existentes). Si es nuevo onboarding → lo solicita el paso 104.

### 2.4 — Sin cambios en pasos de captura (1, 2, 3)

Los formularios (biometría, circadiano, hábitos) NO se tocan en v1.0. SPEC-182.1 puede iterar el copy de cada uno si telemetría de drop-off lo justifica. v1.0 se concentra en el ANTES y DESPUÉS de la captura — donde el usuario forma su mental model.

### 2.5 — Sin paso final nuevo

La idea de un paso 5 "Tu primer 30 días con preview de TransformationCard" queda en SPEC-182.next. Tiene riesgo de prometer demasiado para un usuario que aún no entregó datos.

## 3. Lo que NO se hace (límites duros)

- **NO se cambia el orden de captura** (biometría → circadiano → hábitos → health → goals).
- **NO se introducen ilustraciones nuevas** (decisión Carlos SPEC-131: cero diseñador, solo iconos Material).
- **NO se cambia el wording legal** (privacidad, terms). Eso vive en SPEC-117 footer.
- **NO se persiste qué pantalla intro vio el usuario.** El gate sigue siendo `profileStatus == newProfile` (compat con SPEC-131 existente).
- **NO se solicita permiso de HealthKit en `104`.** HealthKit tiene su propio paso `200` con el sheet nativo.
- **NO se eliminan los pasos intro para usuarios MR** (partial profile). Conservan el gate de SPEC-131.

## 4. Requisitos funcionales

### RF-182-01 — Re-tono `IntroWelcomeStep`

`lib/src/features/onboarding/presentation/widgets/intro_screens.dart` — reemplazar `title` y `bodyParagraphs`:

```dart
title: 'Te acompañamos a leer tu cuerpo',
bodyParagraphs: const [
  'ElenaApp lee tu día y te devuelve coaching con respaldo científico. '
      'No es un cuaderno digital — es un coach.',
  'Cada notificación, cada número, cada gráfica trae una cita '
      'bibliográfica. Vas a saber por qué te decimos lo que te decimos.',
],
```

Icono cambia de `Icons.eco_outlined` a `Icons.menu_book_outlined` (libro abierto — lectura).

### RF-182-02 — Re-tono `IntroImrStep` (rebautizada conceptualmente como dual scores)

```dart
title: 'Tus dos números',
bodyParagraphs: const [
  'En el Dashboard vas a ver dos números: HOY e IMR. '
      'HOY es cómo viviste hoy — puede llegar a 100 cuando cumplís '
      'tus 5 pilares.',
  'IMR es tu base metabólica de fondo. Se mueve más lento, en semanas '
      'y meses. Esto es lo que importa cuando hablamos de cambios '
      'reales en tu cuerpo.',
  'Los dos son tuyos. Uno te empuja cada día, el otro te muestra el '
      'camino largo.',
],
```

Icono: `Icons.donut_small_outlined` (dos círculos juntos).

### RF-182-03 — Re-tono `IntroDataStep`

```dart
title: 'Tus datos son tuyos',
bodyParagraphs: const [
  'Te vamos a pedir peso, altura, edad, cintura y tus horarios de '
      'descanso. Con eso calculamos tu base y armamos tu coaching.',
  'Todo queda en tu cuenta privada. No vendemos ni compartimos. '
      'Podés borrar tu cuenta cuando quieras desde Perfil.',
],
```

Sin cambio de icono (mantener escudo).

### RF-182-04 — Nuevo paso `103` Día Metabólico

Agregar a `intro_screens.dart`:

```dart
class IntroMetabolicDayStep extends StatelessWidget {
  final bool isDark;
  const IntroMetabolicDayStep({super.key, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _IntroLayout(
      isDark: isDark,
      icon: Icons.brightness_3_outlined,
      title: 'El día empieza cuando empezás a ayunar',
      bodyParagraphs: const [
        'Tu día metabólico no se cierra a medianoche calendárica. '
            'Se cierra cuando termina tu ventana de comida y empezás '
            'tu próximo ayuno.',
        'Cuando eso pasa, te entregamos tu feedback del día con cita '
            'bibliográfica. Es el momento donde el coaching tiene '
            'sentido — no a las 23:59 cuando estás durmiendo.',
      ],
    );
  }
}
```

Agregar `_kIntroMetabolicDayId = 103` al `onboarding_screen.dart` y wireing en el switch.

### RF-182-05 — Nuevo paso `104` Notificaciones con respaldo

Nuevo widget en `intro_screens.dart`:

```dart
class IntroNotificationsStep extends StatelessWidget {
  final bool isDark;
  final VoidCallback onActivate; // → requestPermissions + next
  final VoidCallback onSkip;     // → next sin pedir permisos
  const IntroNotificationsStep({
    super.key,
    required this.isDark,
    required this.onActivate,
    required this.onSkip,
  });
  // ... layout custom (no usa _IntroLayout porque tiene 2 CTAs)
}
```

Body: 1 párrafo + lista visual con 3 ejemplos:
- `✨` *"16 horas — Limpieza profunda"* — Levine 2017
- `🌙` *"3 horas antes de dormir"* — Sutton 2018
- `💧` *"Cortisol peak: hora ideal para hidratarte"* — Maughan 2003

2 botones apilados:
- Primario verde `Activar coaching por notificaciones` → `NotificationService.requestPermissions()` → `_handleNext`.
- Secundario texto gris `Más tarde` → `_handleNext`.

Agregar `_kIntroNotificationsId = 104`. Posición en `activeSteps`: **después de `_kStepHabits` (3), antes de `_kHealthSyncStepId` (200)**.

### RF-182-06 — Mover `requestPermissions` de `main.dart` al paso 104

`main.dart:98-105` — envolver con guard:

```dart
final onboardingCompleted = sharedPreferences.getBool('onboardingCompleted') ?? false;
if (onboardingCompleted) {
  await NotificationService.requestPermissions();
}
```

El paso 104 hace el call para nuevos usuarios. Carlos (y todos los actuales) ya tienen `onboardingCompleted=true` → siguen recibiendo el prompt en cold start, sin breaking change.

Persistir `onboardingCompleted=true` al cerrar el flujo (paso final goals). Verificar si ya se persiste — si no, agregar.

### RF-182-07 — Wireing en `onboarding_screen.dart`

Constantes nuevas:
```dart
static const int _kIntroMetabolicDayId = 103;
static const int _kIntroNotificationsId = 104;
static const List<int> _kIntroStepIds = [100, 101, 102, _kIntroMetabolicDayId];
```

`activeSteps` builder:
```dart
final activeSteps = <int>[
  if (isColdInstall) ..._kIntroStepIds,
  0, 1, 2, 3,
  if (isColdInstall) _kIntroNotificationsId, // 104 antes de health
  if (showHealthStep) _kHealthSyncStepId,
  _kGoalsStepId,
];
```

Switch case 103 → IntroMetabolicDayStep. Case 104 → IntroNotificationsStep con `onActivate: _activateNotifications` y `onSkip: _handleNext`.

```dart
Future<void> _activateNotifications() async {
  try {
    await NotificationService.requestPermissions();
  } catch (_) {}
  _handleNext();
}
```

## 5. Cambios en código

| # | Acción | Archivo |
|---|---|---|
| 1 | Re-tono 3 IntroSteps existentes | `lib/.../intro_screens.dart` (líneas 18-84) |
| 2 | Agregar `IntroMetabolicDayStep` | `lib/.../intro_screens.dart` (clase nueva) |
| 3 | Agregar `IntroNotificationsStep` con 2 CTAs | `lib/.../intro_screens.dart` (clase nueva) |
| 4 | Wireing 103 + 104 en switch + activeSteps | `lib/.../onboarding_screen.dart` |
| 5 | Helper `_activateNotifications` | `lib/.../onboarding_screen.dart` |
| 6 | Guard `onboardingCompleted` en `requestPermissions` | `lib/main.dart` |
| 7 | Persistir `onboardingCompleted=true` al cierre | `lib/.../onboarding_controller.dart` (verificar/agregar) |
| 8 | Widget tests de cada IntroStep + flujo de notif activation | `test/features/onboarding/intro_screens_test.dart` (nuevo) |

## 6. Criterios de aceptación

1. Usuario nuevo (cold install) ve 4 pantallas intro: bienvenida, dos números, datos, día metabólico — antes del disclaimer.
2. Después de capturar hábitos, ve la pantalla 104 con los 3 ejemplos y los 2 CTAs.
3. Tap en "Activar coaching" dispara el modal nativo iOS de permisos.
4. Tap en "Más tarde" avanza sin disparar el modal.
5. En el flujo completo, el usuario llega a goals sin haber visto el modal de notifs en cold start.
6. Usuario existente con `onboardingCompleted=true` SIGUE recibiendo el modal en cold start (compat).
7. `flutter analyze` sin warnings nuevos.
8. ≥6 widget tests verdes.

## 7. Riesgos y mitigaciones

| # | Riesgo | Severidad | Mitigación |
|---|---|---|---|
| R-01 | Usuario rechaza notifs en paso 104 → no podemos volver a preguntar fácilmente | Media | Aceptado. Iteración SPEC-182.1 puede agregar prompt blando "configurá notifs desde Perfil" en el dashboard si telemetría detecta drop. |
| R-02 | Onboarding queda largo (4 intros + 4 pasos + health + goals = 10+ pantallas) | Media | El progreso lineal con bar visible mantiene la sensación. Pantallas intro son scrolleables si overflow. |
| R-03 | Copy de "dos números" en intro no coincide exactamente con el ExplainerSheet del Dashboard (SPEC-170) | Baja | Reusar el mismo copy `'Tus dos números'` en ambos. Documentar en bibliografía interna. |
| R-04 | Usuario MR (partial profile) NO ve pantallas intro nuevas y queda fuera del re-tono | Baja | El gate sigue siendo `isColdInstall`. Para SPEC-182.next se evalúa si extender al modo partial. |

## 8. Out of scope (explícito)

- Paso "Tu primer 30 días" con preview de TransformationCard → SPEC-182.next.
- Onboarding incremental para usuarios existentes (post-Ola 3 que muestre las novedades de SPEC-149/170/148 a quien ya tiene cuenta) → SPEC-183 si Carlos lo prioriza.
- Localización a otros idiomas → fuera de scope general v1.0.
- A/B testing de copies → fuera de scope.

## 9. Cierre

- [ ] Re-tono de las 3 IntroSteps existentes con copy nuevo.
- [ ] `IntroMetabolicDayStep` (paso 103) implementado.
- [ ] `IntroNotificationsStep` (paso 104) con 2 CTAs + activation flow.
- [ ] `main.dart` `requestPermissions` con guard `onboardingCompleted`.
- [ ] Persistencia `onboardingCompleted` al cierre del flujo.
- [ ] Widget tests verdes.
- [ ] Memoria proyecto actualizada con SPEC-182 CLOSED.
- [ ] Validación visual Carlos (correr `flutter run` con perfil clean).

## 10. Cierre 2026-06-05

Implementación entregada en una sesión (~1.5h reales vs 3h estimadas):

- [x] Re-tono `IntroWelcomeStep` ("Te acompañamos a leer tu cuerpo"), `IntroImrStep` ("Tus dos números"), `IntroDataStep` ("Tus datos son tuyos"). Iconos coherentes (book / donut / shield).
- [x] `IntroMetabolicDayStep` (id 103) con copy alineado a SPEC-149.
- [x] `IntroNotificationsStep` (id 104) con 3 pills de ejemplo + 2 CTAs. `_ExamplePill` helper interno.
- [x] Wireing: `_kIntroMetabolicDayId=103`, `_kIntroNotificationsId=104`, `_kIntroStepIds` extendido. Paso 104 inyectado en `activeSteps` después de hábitos y antes de Health.
- [x] Helper `_activateNotifications` dispara `NotificationService.requestPermissions()` con try/catch y avanza vía `_handleNext`.
- [x] `main.dart` guard `onboardingCompleted` → usuarios existentes mantienen el prompt en cold start; nuevos lo reciben en paso 104.
- [x] Persistencia `prefs.setBool('onboardingCompleted', true)` al cerrar el flow.
- [x] 8 widget tests verdes en `test/features/onboarding/intro_screens_test.dart`.

**Validación pendiente:** visual Carlos — correr `flutter run` con perfil nuevo o `prefs.remove('onboardingCompleted')` para ver el flujo coach-first.

## 11. Changelog

### v1.0 — 2026-06-05

Documento inicial. Re-tono 3 pantallas intro + 2 nuevas + mover requestPermissions de main al paso 104. Sin cambios en formularios de captura. Estimación 3 horas.
