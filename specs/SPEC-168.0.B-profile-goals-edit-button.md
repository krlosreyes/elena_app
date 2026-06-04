# SPEC-168.0.B — Botón "Editar mis objetivos" en Perfil

**Estado:** PROPOSED 2026-06-03
**Versión:** 1.0
**Tipo:** Integración UX — sección Perfil
**Líder:** Carlos
**Implementación:** Claude
**Estimación:** ~30 minutos
**Padre:** SPEC-168.0

---

## 1. Contexto

`/goals/setup` existe como ruta pero no hay forma de llegar ahí desde la app. Esta SPEC agrega entrada visible en Perfil con preview de goals activos.

## 2. Decisiones de diseño

### 2.1 — Sección "Mis objetivos" en ProfileScreen

Posición: debajo de las cards de biometría, antes del logout. Estructura:

```
┌─ Mis objetivos ────────────────────┐
│ ⏱️  5 días de ayuno/sem   ✓ activo │
│ 💧  2.8 L de agua/día    ✓ activo │
│ 💪  30 min de ejercicio   ✓ activo │
│ 🌙  8 h de sueño         ─       │
│ ⚖️  78 kg                ✓ activo │
│                                    │
│           [ Editar objetivos ]    │
└────────────────────────────────────┘
```

- Lee `goalsProvider`.
- Para cada `UserGoal` activo, muestra emoji + valor + unit + estado.
- Goals inactivos (toggle OFF) se muestran en gris con `─` en lugar de check.
- Si NO hay goals (usuario que omitió onboarding): muestra estado vacío con copy "Aún no configuraste tus objetivos." y botón "Configurar objetivos".

### 2.2 — Botón principal

`OutlinedButton.icon` con label "Editar objetivos" y `Icons.tune`. Tap navega a `/goals/setup` (modo standalone con AppBar, no embedded).

### 2.3 — Estado vacío

Si `goalsProvider` value isEmpty:

```
🎯
Aún no configuraste tus objetivos.

Elena tiene recomendaciones listas
basadas en tus datos.

      [ Configurar objetivos ]
```

Tap mismo destino `/goals/setup`.

## 3. Cambios concretos

### 3.1 — `profile_screen.dart`

- Nuevo método `Widget _buildGoalsSection(WidgetRef ref)`.
- Watch `goalsProvider`.
- Render lista de preview o estado vacío según data.
- Botón con `context.push('/goals/setup')` (go_router).

### 3.2 — `app_router.dart`

Verificar que `/goals/setup` esté registrado con transición que permita volver al perfil con back gesture. Si la ruta no está marcada como modal, mejor agregar `fullscreenDialog: true` para que iOS la presente como hoja modal.

### 3.3 — `goal_setup_screen.dart`

Modo standalone (AppBar con "Mis objetivos" + botón "Guardar" en bottom). Ya existe — solo validar copy.

## 4. Validación

### 4.1 — Manual en device
- Usuario con goals → ve preview correcto en Perfil.
- Tap "Editar" → modal con `GoalSetupScreen` aparece.
- Ajustar slider → tap "Guardar" → vuelve a Perfil → preview refleja cambio.
- Usuario sin goals → ve estado vacío → tap "Configurar" → flujo idéntico.

### 4.2 — No-regresión
- Resto de ProfileScreen sigue funcionando idéntico.

## 5. Riesgo

- **Overflow visual** si hay 7 goals y todos con copy largo: usar `ListTile` compacto con `dense: true`. Ya el patrón existe en otros cards de Profile.

## 6. Cierre

- [ ] `_buildGoalsSection` implementado en ProfileScreen
- [ ] Ruta `/goals/setup` accesible desde botón
- [ ] Estado vacío con copy correcto
- [ ] Validación visual Carlos
