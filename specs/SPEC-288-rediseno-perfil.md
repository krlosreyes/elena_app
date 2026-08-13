# SPEC-288 — Rediseño del Perfil (jerarquía + menos ruido)

**Estado:** IMPLEMENTED (UI). PENDIENTE analyze/simulador de Carlos.
**Fecha:** 2026-08-12
**Rama:** `feat/pilar-alimentacion-minuta`
**Origen:** revisión en simulador + investigación de patrones (lista agrupada iOS).

## 1. Diagnóstico (visto en el simulador)

- **Arcoíris de íconos:** 7 tarjetas de "Configuración", cada una con ícono de un color distinto (azul, morado, verde, rosa, naranja, teal, marrón) → ruido, nada resalta.
- **14+ tarjetas sueltas con borde** (Config + Salud + Legal + Ayuda) en vez de listas agrupadas → mucho peso visual.
- **Card de transformación vacía:** cajón grande con spinner cuando no hay datos de 30 días; además causaba el "scroll que no responde" (la card recarga y descarta el gesto).
- **Sin jerarquía:** identidad, logros, composición, ajustes, salud, legal y ayuda con el mismo peso.

## 2. Cambio

- **Nuevo `profile_settings_group.dart`**: `ProfileRow` (ícono monocromático + título + valor a la derecha + chevron) y `ProfileSettingsGroup` (una superficie, filas con hairline). Patrón inset grouped list de iOS.
- **Entry cards → filas:** biométricos, ritmos, protocolo de ayuno, objetivos, alimentación, ejercicio, consumo consciente, glucosa, condiciones médicas, guía — todas devuelven `ProfileRow` (conservan su lógica de subtítulo desde providers). Se quitó el `_color`/borde por card.
- **`profile_screen.dart`:** héroe (identidad + IMR, logros, composición) y debajo tres grupos: **Tus datos** (7 filas), **Salud** (HealthSync + grupo glucosa/condiciones), **Legal y ayuda** (privacidad, términos, guía). Se **retira** `TransformationCardLive` (card vacía + bug de scroll).

## 3. Archivos

- `lib/src/features/auth/presentation/widgets/profile_settings_group.dart` (nuevo)
- `.../widgets/{biometricos,ritmos,protocolo,objetivos,exercise_habits,alcohol_protocol,glucose_protocol}_entry_card.dart`
- `.../widgets/profile_legal_section.dart` (condiciones + guía como filas; se retira `ProfileLegalSection`/`_LegalEntryCard`)
- `lib/src/features/nutrition/presentation/widgets/alimentacion_minuta_entry_card.dart`
- `lib/src/features/auth/presentation/profile_screen.dart`

## 4. Verificación (Carlos)

```
cd /Users/carlosreyes/Proyectos/ElenaApp/elena_app
flutter analyze lib/src/features/auth/presentation lib/src/features/nutrition/presentation/widgets/alimentacion_minuta_entry_card.dart
```

Simulador: Perfil → héroe compacto; "Tus datos" como lista agrupada monocromática; secciones Salud y Legal y ayuda igual; sin card vacía; el scroll ya no se pierde.

## 5. Sigue (opcional)

- Héroe aún más compacto (tira de 3 stats en vez de 3 cards).
- HealthSync como fila cuando esté sincronizado (hoy sigue como card por su CTA).
