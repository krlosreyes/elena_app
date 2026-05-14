# SPEC-89 — Paleta canónica Metamorfosis Real aplicada a ElenaApp

**Estado:** ✅ VERIFIED (13-may-2026, pending push)
**Versión:** 1.0
**Fecha:** 2026-05-13
**Tipo:** UI / Theming
**Marco normativo:** `CONSTITUTION.md` §3.4 (presentation).
**Antecedente:** documento entregado por Carlos `PALETTE-FOR-ELENAAPP.md` (fuente única de verdad sincronizada con `metamorfosis-web/src/styles/global.css → @theme`).

---

# 1. Contexto

La app móvil y el sitio web Metamorfosis Real comparten Firebase, pero hasta hoy NO compartían identidad visual. El sitio adoptó una paleta única (dark-only, accent teal `#00C49A`, navy `#020617`) y Carlos pidió replicarla literalmente en la app para coherencia entre ambas superficies.

# 2. Problema

`lib/src/core/theme/app_theme.dart` definía 9 tokens con valores que no coinciden con la paleta del sitio:

- `metabolicGreen = #2D5A47` (verde oscuro saturado, ≠ accent teal canónico).
- `backgroundDark = Colors.black` (negro puro, ≠ navy `#020617`).
- `surfaceDark = #111827` (gris muy oscuro, ≠ surface `#0C1422`).
- `textPrimary = #0F172A` (oscuro pensado para light theme).
- 21 archivos consumen `AppColors.*` con 73 ocurrencias.

Adicionalmente, `app_typography.dart` usaba `GoogleFonts.publicSans`, mientras el sitio especifica Inter para body y Space Grotesk para headlines.

# 3. Solución propuesta

**3.1 `AppColors` migrado in-place.** Misma clase, mismos nombres legacy, valores subyacentes apuntados a los tokens canónicos. Aliases:
- `metabolicGreen → accent (#00C49A)`
- `backgroundDark → bgBase (#020617)`
- `surfaceDark → bgSurface (#0C1422)`
- `optimalCyan → accent`
- `circadianAmber → statusWarn (#F59E0B)`
- `background → bgBase`, `surface → bgSurface`, `border → borderDefault`
- `textPrimary` y `textSecondary` cambian a los valores canónicos `#F1F5F9` / `#94A3B8` (claro sobre dark).

**3.2 Tokens canónicos nuevos.** `bgBase, bgSurface, bgElevated, textPrimary, textSecondary, textMuted, accent, accentStrong, statusGood, statusWarn, statusBad, borderSubtle, borderDefault, borderStrong`. Código nuevo los referencia directamente.

**3.3 `AppTheme.dark` único.** Eliminamos `lightTheme`. Mantenemos `darkTheme` y `lightTheme` getters como alias de `dark` para no romper `app.dart` u otros consumidores. La app es dark-only por decisión de diseño del sitio.

**3.4 ThemeData global.** Configuración completa de `colorScheme, cardTheme, elevatedButtonTheme, outlinedButtonTheme, textButtonTheme, dividerTheme, inputDecorationTheme, appBarTheme, bottomSheetTheme, dialogTheme`. Esto garantiza que widgets que confíen en el theme (sin hardcoded colors) hereden la paleta automáticamente.

**3.5 Tipografía Inter + Space Grotesk** vía `google_fonts` (ya en pubspec). Inter para body/UI/labels, Space Grotesk para títulos.

**3.6 `MaterialApp.router` con `darkTheme: AppTheme.dark, themeMode: ThemeMode.dark`** para evitar flash de light durante transiciones del sistema.

**3.7 Test de paridad** que falla si algún token canónico se desvía del hex documentado en `PALETTE-FOR-ELENAAPP.md`.

# 4. Plan

| Archivo | Cambio |
|---|---|
| `lib/src/core/theme/app_theme.dart` | Reescrito. `AppColors` con tokens canónicos + aliases legacy. `AppTheme.dark` con ThemeData global completo. |
| `lib/src/core/theme/app_typography.dart` | Migrado de Public Sans a Inter + Space Grotesk. Mantiene los mismos nombres de slots del `TextTheme`. |
| `lib/src/app.dart` | `theme + darkTheme + themeMode: ThemeMode.dark`. |
| `test/core/theme/app_colors_parity_test.dart` (nuevo) | Test de paridad de hex con la paleta documentada. |

# 5. Criterios de aceptación

- `flutter analyze` sin issues nuevos sobre baseline.
- `flutter test` con el nuevo test de paridad en verde (4 grupos: backgrounds, text, accent, status).
- 21 archivos consumidores de `AppColors.metabolicGreen, backgroundDark, surfaceDark, ...` siguen compilando — los valores subyacentes cambian, los nombres no.
- App arranca y se mantiene en dark sin flash de light al rotar o cambiar el modo del sistema.
- El verde de los CTAs principales (`AppColors.metabolicGreen`) ahora es teal `#00C49A` (cambio visual deseado).
- Inputs, BottomSheets y Dialogs heredan el theme automáticamente.

# 6. Pruebas

Test nuevo `app_colors_parity_test.dart` con 4 grupos según §6 del documento canónico:

1. Backgrounds matchean los hex (`#020617, #0C1422, #1A2332`).
2. Text matchea (`#F1F5F9, #94A3B8, #64748B`).
3. Accent matchea (`#00C49A, #00B389`).
4. Status matchea (`#10B981, #F59E0B, #EF4444`).

# 7. Riesgos

- **Algunos widgets pueden tener desfase visual menor** por el cambio de hex en aliases legacy. Es deseado (acerca la app al sitio). Si algún componente queda ilegible — texto blanco sobre fondo blanco, por ejemplo — se ajusta puntualmente en SPEC siguiente.
- **Hardcoded colors fuera de `AppColors`.** Hay widgets que usan `Color(0xFF...)` literal. SPEC-89 NO los migra (alcance: theme y AppColors). Migración masiva queda como deuda técnica (`SPEC-90` futura): convertir hardcoded a tokens donde aplique.
- **Tokens canónicos vs legacy coexistiendo.** Riesgo de divergencia futura si alguien agrega un valor a aliases. Mitigación: regla en SPEC + revisión de PR. Comentario explícito en el archivo.

# 8. Out of scope

- Migración de los 73 call sites legacy a tokens canónicos directos (SPEC-90).
- Auditoría exhaustiva de hardcoded `Color(0xFF...)` en widgets (SPEC-90).
- Cambios en el sitio web (es repo separado).
- Variante light theme (decisión de diseño: la app es dark-only).
- Playfair Display (es solo para artículos del sitio, no se usa en la app).

# 9. Resultado

**Verificación local (13-may-2026):** suite verde tras la migración. Tests de paridad de la paleta + aliases legacy pasan. Los 21 archivos consumidores de `AppColors.*` siguen compilando sin cambio porque los aliases preservan los nombres aunque los valores subyacentes apunten a la paleta canónica.

**Cambios visuales esperados al smoke test en device:**
- CTAs principales (botones "INICIAR METAMORFOSIS", "SIGUIENTE", "GUARDAR"): verde oscuro → teal saturado.
- Fondo de Scaffolds: negro puro → midnight navy (`#020617`).
- Surface de cards: gris muy oscuro → navy un nivel arriba (`#0C1422`).
- Tipografía cambia de Public Sans a Inter (body) + Space Grotesk (títulos).
- BottomSheets, Dialogs y inputs heredan `bgElevated` (`#1A2332`) automáticamente.

**Sin desviaciones del plan.** Próximo paso natural: SPEC-90 (migración progresiva de hardcoded `Color(0xFF...)` en widgets a tokens canónicos). No bloqueante.
