# SPEC-119 — Rediseño de "Ayuno Consciente" (eliminar cronómetro redundante)

**Estado:** Cerrado · 2026-05-16
**Fecha:** 2026-05-16
**Líder:** Carlos
**Implementación:** Claude
**Fase del roadmap:** 1 (Pre-MVP shippable) — calidad de producto
**Estimación:** 0.5 días Carlos+Claude
**Depende de:** SPEC-115 (FastingHeroDisplay) — cerrado.

---

## Motivación

La pantalla Hoy mostraba el cronómetro HH:MM:SS del ayuno activo en **dos lugares simultáneos**:
1. **Hero del CircadianClock** (`FastingHeroDisplay`) en el centro del reloj.
2. **Tarjeta inferior "Ayuno Consciente"** (`LiveFastingClock`) como display grande.

Además de ocupar espacio dos veces, los dos cronómetros corren con tickers independientes (1s cada uno) y pueden quedar visualmente desfasados ~10s entre sí, generando incongruencia perceptiva ("¿por qué dicen tiempos distintos?").

Carlos observó la redundancia en captura del 16-may-2026 y pidió rediseñar la tarjeta inferior de modo que **no pierda valor** para el usuario.

## Decisión

Reasignar la identidad de la tarjeta: deja de ser "cronómetro grande con metadatos" y pasa a ser **panel de control + contexto del protocolo**. El cronómetro vivo queda exclusivo del hero (es su trabajo).

## Cambios concretos

### `dashboard_screen.dart`

1. **Quitar** el `LiveFastingClock` y la `Row` que lo contenía (líneas 482-505 originales).
2. **Insertar** en su lugar una fila de dos columnas:
   - **PROTOCOLO** (eyebrow label) + chip clickable existente (`_buildProtocolChip`) — siempre visible.
   - **HITO SIGUIENTE** (eyebrow label) + texto formato "Quema de grasa en 7h 48m" — solo si `isActive`.
3. **Helper nuevo** `_formatNextMilestone(state)` que produce el texto compacto del próximo hito metabólico (insulina 12h, quema de grasa 18h, autofagia 24h, regeneración).
4. **Enriquecer** el texto bajo la barra de progreso: pasa de `'$pct% completado'` a `'$pct% completado · faltan Xh Ym'` cuando hay ayuno activo. Si el target ya se alcanzó: `'$pct% completado · objetivo cumplido'`.
5. **Helper nuevo** `_formatTargetRemaining(state)` que produce el sufijo "· faltan Xh Ym" o "· objetivo cumplido".
6. **Eliminar** import `live_fasting_clock.dart` (ya no se usa en este archivo).
7. **Eliminar** comentario SPEC-61 obsoleto sobre el display HH:MM:SS local.

### Archivos NO modificados

- `live_fasting_clock.dart`: se mantiene como widget público en el repo. Puede usarse en futuras pantallas (p.ej. una vista detalle del ayuno). Su comportamiento es correcto y está cubierto por SPEC-61.
- `fasting_hero_display.dart`: sin cambios (es el cronómetro canónico).
- Tests existentes: el rediseño no cambia la API pública de `FastingState` ni rompe ningún test de SPEC-117 / SPEC-118.

## Criterios de éxito

1. La pantalla Hoy NO muestra el cronómetro HH:MM:SS en dos lugares.
2. La tarjeta "Ayuno Consciente" sigue mostrando: protocolo + estado + barra de progreso + timeline temporal + beneficios + botones de acción.
3. La tarjeta gana: hito metabólico próximo + residual hasta el target.
4. `flutter analyze` clean. `flutter test` mantiene el conteo actual sin regresiones (`+650 ~3`).

## Riesgos

| Riesgo | Mitigación |
|---|---|
| "HITO SIGUIENTE" duplica el subtexto del hero ("Quema de grasa en 7h 48m") | El del hero es muy compacto y acoplado al gráfico; el de la tarjeta da contexto explícito sin tener que mirar arriba. Si en uso real se ve repetitivo, lo reemplazamos por "VENTANA DE COMIDA: HH:MM–HH:MM" en SPEC-119.bugfix. |
| Cuando el ayuno está inactivo, la columna HITO SIGUIENTE no aparece y la fila queda asimétrica | Usamos `if (isActive)` condicional. La columna PROTOCOLO ocupa la mitad izquierda igualmente — ligera asimetría aceptable porque la jerarquía visual sigue siendo "protocolo primero". |
| El cálculo "faltan Xh Ym" depende de `state.duration` que solo se actualiza al pulso de 10s | Granularidad aceptable: el residual no necesita precisión segundo a segundo (el cronómetro del hero ya cubre eso). El texto se refresca cada 10s, error máximo 10s. |

## Verificación

**Resultado:**
- `dashboard_screen.dart` compila sin warnings nuevos.
- Suite global mantiene `+650 ~3`.
- Visual confirmado por Carlos en pantalla real.

**Próximo:** retomar SPEC-81 (firestore.rules hardening + reCAPTCHA v3) que sigue en `in_progress` histórico.
