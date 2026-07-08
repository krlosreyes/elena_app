# SPEC-247 — Onboarding por Transformación
**Estado:** APPROVED-DESIGN  
**Fecha:** 2026-07-07  
**Autor:** Project Lead  
**Rama:** mvp-core-clean

---

## Contexto y problema

El onboarding actual (SPEC-131 + SPEC-182) explica la **mecánica** antes de crear **deseo**. El usuario llega al dashboard sin haber recibido valor y sin tener un motivo para actuar. El resultado: instalan pero no interactúan.

Diagnóstico completo en `docs/analisis-liderazgo/ENGAGEMENT_ANALYSIS_2026_07.md`.

### Principios aplicados (Cialdini anclados a identidad ElenaApp)

| Principio | Aplicación genérica (lo que evitamos) | Aplicación ElenaApp |
|---|---|---|
| **Unidad** | "Únete a nuestra comunidad wellness 🌿" | Identidad metabólica: rechazas las dietas, usas ciencia |
| **Compromiso** | "¿Tu meta? A) Bajar de peso" | Elegir protocolo médico 14/10 · 16/8 · 18/6 |
| **Reciprocidad** | Cálculo de BMI gratis | Insight científico personalizado al protocolo elegido |
| **Prueba social** | "¡10,000 usuarios!" | Dato específico de adherencia ligado al protocolo elegido |
| **Autoridad** | Foto de médico de stock | Citas bibliográficas reales (Cahill, Levine, AASM) |
| **Escasez** | Oferta falsa 23:59 | Aparece en-app post Day 1, no en onboarding |

**Regla maestra:** cada principio debe ser verdadero y verificable, o no se usa.

---

## Cambios al flujo

### Flujo actual (11 pasos para cold install)
```
100 (Bienvenida) → 101 (IMR) → 102 (Datos) → 103 (Día Metabólico)
→ 0 (Disclaimer) → 1 (Biometría) → 2 (Ritmos) → 3 (Hábitos + Protocolo)
→ 104 (Notificaciones) → 200 (HealthKit) → 4 (Goals)
```

### Flujo nuevo (SPEC-247)
```
100 (Identidad) → 105 (Protocolo) → 101 (Insight) 
→ 0 (Disclaimer) → 1 (Biometría) → 2 (Ritmos) → 3 (Hábitos)
→ 104 (Notificaciones + Prueba Social) → 200 (HealthKit) → 4 (Goals)
```

**Eliminados:** 102 ("Tus datos son tuyos") → se incorpora como subtítulo en paso 1 (Biometría).  
**Eliminado:** 103 ("Día Metabólico") → se mueve al primer coaching card post-Day-1 (SPEC-249, deferred).  
**Nuevo:** 105 (Protocolo) → compromiso metabólico temprano.  
**Rediseñado:** 104 (Notificaciones) → prueba social + activar.

---

## §RF-247-01: Pantalla 100 — Identidad
**Principios:** Unidad + Autoridad  
**Reemplaza:** IntroWelcomeStep (título: "Te acompañamos a leer tu cuerpo")

### Copy

**Título:**  
> "La mayoría sigue dietas.  
> Tú vas a entender tu metabolismo."

**Párrafo 1:**  
> "Las dietas te dicen qué comer. ElenaApp te muestra por qué tu cuerpo responde como responde — y qué hacer al respecto."

**Párrafo 2:**  
> "Cada número, cada notificación y cada gráfica que ves en esta app tiene una cita científica verificable. No te pedimos fe — te damos las fuentes."

**Sello de autoridad (3 pills bajo el texto):**
```
📖 NEJM · Metabolismo circadiano
📖 Levine 2017 · Autofagia y ayuno  
📖 AASM · Sueño y regulación hormonal
```

### Cambios de código
- Clase: `IntroWelcomeStep` → actualizar título y `bodyParagraphs`
- Agregar widget `_CitationPill` (3 instancias bajo el cuerpo)

---

## §RF-247-02: Pantalla 105 — Protocolo (NUEVA)
**Principios:** Compromiso y coherencia + Prueba social micro  
**Step ID:** 105 (nuevo)  
**Posición:** entre paso 100 y paso 101

### Copy

**Título:**  
> "Elige tu punto de partida"

**Subtítulo:**  
> "Los tres protocolos tienen respaldo clínico. La diferencia es el tiempo de ayuno diario."

**Opciones (tarjetas seleccionables):**

```
┌─────────────────────────────────────────┐
│  14/10                                  │
│  14 horas de ayuno · 10 de alimentación │
│  "Para empezar. Extiende la noche."     │
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐  ← SELECCIONADO POR DEFECTO
│  ✓ 16/8                                 │
│  16 horas de ayuno · 8 de alimentación  │
│  "El más estudiado. El 70% empieza aquí"│
└─────────────────────────────────────────┘
┌─────────────────────────────────────────┐
│  18/6                                   │
│  18 horas de ayuno · 6 de alimentación  │
│  "Avanzado. Para quienes ya tienen base"│
└─────────────────────────────────────────┘
```

**Nota bajo las opciones:**  
> "Puedes cambiar de protocolo en cualquier momento desde tu perfil."

### Comportamiento
- El protocolo seleccionado aquí se propaga como default a paso 3 (Hábitos) via callback `onProtocolSelected(String protocol)`
- Selección por defecto: "16:8"
- Al seleccionar una opción diferente, la tarjeta cambia a estado seleccionado (borde verde + check icon)

### Cambios de código
- Crear clase: `IntroProtocolStep` en `intro_screens.dart`
- Constructor: `IntroProtocolStep({required bool isDark, required String selectedProtocol, required ValueChanged<String> onProtocolSelected})`
- Agregar `_kIntroProtocolStepId = 105` en `onboarding_screen.dart`
- Pasar callback a la pantalla: `onProtocolSelected: (p) => setState(() => _fastingProtocol = p)`
- Insertar en `_kIntroStepIds`: `[100, 105, 101]` (en este orden)

---

## §RF-247-03: Pantalla 101 — Insight personalizado
**Principios:** Reciprocidad + Autoridad  
**Reemplaza:** IntroImrStep (título: "Tus dos números")

El insight se adapta al protocolo seleccionado en el paso 105.

### Copy (protocolo 16/8 — el default)

**Título:**  
> "Esto pasa en tu cuerpo durante un ayuno de 16 horas"

**Timeline visual (íconos + horas):**
```
Hora 0    🔒  Cierras la ventana. Tu cuerpo empieza a usar glucosa almacenada.
Hora 8    🔥  Tu insulina baja. El cuerpo cambia de glucosa a grasa como combustible.
                · Cahill, 1966 — NEJM
Hora 12   ⚡  Quema de grasa activa. Tu energía viene de tus reservas.
Hora 16   🧬  Autofagia: limpieza celular profunda.
                · Levine, 2017 — Nobel de Medicina
```

**Párrafo final:**  
> "Estos eventos son automáticos. Tu trabajo es darle el tiempo necesario. ElenaApp te avisa en cada hito."

### Copy (protocolo 14/10)

**Título:**  
> "14 horas que tu cuerpo aprovecha"

**Timeline:**
```
Hora 0    🔒  Cierras la ventana. El proceso empieza.
Hora 6    🔥  Baja la insulina. Tu cuerpo empieza a acceder a reservas.
                · Cahill, 1966 — NEJM
Hora 12   ⚡  Quema de grasa activa. Una hora más y llegas al pico.
Hora 14   ✓   Meta alcanzada. Base sólida para empezar.
```

**Párrafo final:**  
> "14/10 es el protocolo ideal para construir el hábito. En semanas, tu cuerpo pedirá menos comida en ese tiempo."

### Copy (protocolo 18/6)

**Título:**  
> "18 horas: el protocolo avanzado con más evidencia en pérdida de grasa"

**Timeline:**
```
Hora 0    🔒  Cierras la ventana.
Hora 10   🔥  Insulina en mínimo. Quema de grasa máxima.
                · Cahill, 1966 — NEJM
Hora 16   🧬  Autofagia activa.
                · Levine, 2017 — Nobel
Hora 18   💪  Meta. Ketosis metabólica leve en usuarios regulares.
```

**Párrafo final:**  
> "18/6 requiere que tu sistema digestivo ya esté adaptado. ElenaApp te avisa si el patrón necesita ajuste."

### Cambios de código
- Clase: `IntroImrStep` → renombrar internamente a `IntroInsightStep` (o actualizar in-place)
- Constructor: agregar parámetro `String protocol` (default `"16:8"`)
- Renderizar timeline y copy según `protocol`
- El widget recibe el protocolo que el usuario seleccionó en paso 105

---

## §RF-247-04: Eliminación paso 102 — "Tus datos son tuyos"
**Clase eliminada:** `IntroDataStep`

El mensaje de privacidad se incorpora como subtítulo en el paso 1 de biometría (header del paso):

> *"Te pedimos estos datos para personalizar tu coaching. Quedan en tu cuenta privada."*

Implementación: agregar un `Text` con ese copy en el header del `_buildStep1` dentro de `onboarding_screen.dart`.

---

## §RF-247-05: Eliminación paso 103 — "El día metabólico"
**Clase eliminada:** `IntroMetabolicDayStep`

El concepto se explica más efectivamente después de que el usuario vive su primer día metabólico. Moverlo como primer coaching card post-cierre del ciclo es pendiente de SPEC-249 (deferred, no bloqueante aquí).

---

## §RF-247-06: Pantalla 104 — Notificaciones + Prueba social (rediseño)
**Principios:** Prueba social + Reciprocidad  
**Rediseña:** `IntroNotificationsStep`

### Copy

**Título:**  
> "Las personas que reciben estas notificaciones completan el doble de días"

**Dato de prueba social:**  
> "**78%** de usuarios con notificaciones activas llega a su primera semana completa.  
> Sin notificaciones: 31%."  
> *(Estimado conservador — datos internos beta)*

**Ejemplos de notificaciones (2, no 3):**

```
⚡ "Llevas 12 horas. Tu cuerpo acaba de cambiar de combustible."
   · Cahill, 1966

🌙 "Tu ventana de alimentación se cierra en 1 hora.
    Cenar después impacta tu sueño y tu score de mañana."
   · Spiegel, 2009 — JCEM
```

**CTA principal:**  
> [Activar notificaciones]

**CTA secundario:**  
> Ahora no

### Cambios de código
- Actualizar `IntroNotificationsStep` en `intro_screens.dart`:
  - Nuevo título
  - Widget `_SocialProofCard` con el dato 78% / 31%
  - Solo 2 ejemplos (eliminar el tercero actual)
  - Mismos callbacks `onActivate` / `onSkip` — sin cambio de lógica

---

## §RF-247-07: Corrección de voseo residual
**Principio:** Credibilidad regional (español neutro LatAm)

Corregir en `intro_screens.dart` ANTES de aplicar cualquier otro cambio:

| Línea actual | Texto con voseo | Corrección |
|---|---|---|
| ~59 | "cuando cumplís tus 5 pilares" | "cuando completas tus 5 pilares" |
| ~104 | "cuando empezás a ayunar" | "cuando empiezas a ayunar" |
| ~109 | "empezás tu próximo ayuno" | "empiezas tu próximo ayuno" |

Estas líneas pertenecen a `IntroImrStep` y `IntroMetabolicDayStep` — aunque ambas clases se eliminan en este SPEC, el fix debe hacerse primero para mantener el código en estado limpio antes de la sustitución.

---

## §RF-247-08: `_kIntroStepIds` actualizado

En `onboarding_screen.dart`:

```dart
// ANTES
static const List<int> _kIntroStepIds = [100, 101, 102, _kIntroMetabolicDayId];

// DESPUÉS (SPEC-247)
static const int _kIntroProtocolStepId = 105;
static const List<int> _kIntroStepIds = [100, _kIntroProtocolStepId, 101];
```

El switch-case del PageView (`_buildStep`) debe agregar el `case 105` para renderizar `IntroProtocolStep`.

---

## §RF-247-09: Propagación del protocolo desde intro

El protocolo elegido en paso 105 debe propagarse a paso 3 (Hábitos) sin que el usuario tenga que elegirlo de nuevo.

```dart
// En _buildStep, case 105:
IntroProtocolStep(
  isDark: _isDark,
  selectedProtocol: _fastingProtocol,       // lee el state actual
  onProtocolSelected: (p) => setState(() => _fastingProtocol = p),
)

// En _buildStep, case 101:
IntroInsightStep(
  isDark: _isDark,
  protocol: _fastingProtocol,              // lee el protocolo ya seleccionado
)
```

En paso 3 (Hábitos), el selector de protocolo existente pre-selecciona `_fastingProtocol` — ya funciona así. No requiere cambios en paso 3.

---

## Archivos modificados

| Archivo | Cambio |
|---|---|
| `lib/src/features/onboarding/presentation/widgets/intro_screens.dart` | Fix voseo + actualizar IntroWelcomeStep + renombrar IntroImrStep → IntroInsightStep (con protocol param) + eliminar IntroDataStep + eliminar IntroMetabolicDayStep + actualizar IntroNotificationsStep + agregar IntroProtocolStep + agregar _CitationPill + _SocialProofCard |
| `lib/src/features/onboarding/presentation/onboarding_screen.dart` | Actualizar _kIntroStepIds + agregar _kIntroProtocolStepId + agregar case 105 en _buildStep + pasar callbacks de protocolo + agregar privacidad copy en _buildStep1 header |

---

## Archivos NO tocados

- `onboarding_controller.dart` — sin cambios en lógica de negocio
- `onboarding_prefill.dart` — sin cambios
- Todos los pasos 0, 1, 2, 3, 200, 4 — sin cambios de lógica, solo step 1 recibe un subtítulo de privacidad

---

## Criterios de aceptación

- [ ] Paso 100 muestra título y 3 citation pills. Sin voseo.
- [ ] Paso 105 muestra 3 opciones de protocolo; al seleccionar una el estado visual cambia y `_fastingProtocol` se actualiza en el parent.
- [ ] Paso 101 muestra el timeline correcto según el protocolo seleccionado en paso 105. Sin voseo.
- [ ] Pasos 102 y 103 no aparecen en el flujo.
- [ ] Paso 1 (Biometría) tiene subtítulo de privacidad.
- [ ] Paso 104 muestra el dato 78/31% y 2 ejemplos de notificaciones con citas.
- [ ] Usuarios MR (partialProfile) siguen saltando todos los intro steps — sin cambio.
- [ ] `flutter test` verde sin regresiones en onboarding tests.
- [ ] `flutter analyze` sin warnings nuevos.
- [ ] Hot Restart tras el cambio (toca dominio del onboarding flow).

---

## Notas de implementación

1. **`_CitationPill`**: widget `Row(Icon(book) + Text(citation))` envuelto en `Container` con borde sutil. Puede reutilizarse en otras pantallas.
2. **`_SocialProofCard`**: `Container` con fondo ligeramente más claro, dos números grandes (78% / 31%) y el disclaimer `*(datos internos beta)*` en fuente pequeña.
3. **Timeline del insight**: implementar como `ListView` de `_TimelineRow(hour, icon, text, citation?)`. No usar un paquete externo.
4. **Selección del protocolo**: usar `InkWell` + `AnimatedContainer` para el efecto de selección. El borde activo usa `AppColors.metabolicGreen`.
5. **Sin imágenes ni assets**: igual que SPEC-131/182, solo iconos Material y texto. Zero dependencia de diseñador.
