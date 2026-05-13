# SPEC-88 — Redistribución UI Profile + ajustes Dashboard

**Estado:** ✅ VERIFIED (13-may-2026, pending push)
**Versión:** 1.0
**Fecha:** 2026-05-13
**Tipo:** UI / Presentation
**Marco normativo:** `CONSTITUTION.md` §3.4 (presentation), §3.2 (application — orquestación permitida).

---

# 1. Contexto

Carlos entregó 5 screenshots con la distribución final de UI para Profile y Dashboard. La implementación actual tiene la misma información pero con jerarquías visuales distintas: la tarjeta "Composición Corporal" no aparece en Profile, el protocolo de ayuno usa segmented horizontal en lugar de grid, los tiles biométricos no tienen íconos ni edición rápida, y los botones de cuenta tienen distinto estilo.

Esta SPEC alinea el código a los screenshots **sin tocar lógica de negocio**: fórmulas, modelos, repositories, mappers, validators y data sources permanecen intactos. Se agregan widgets de presentación y un único método de orquestación al `ProfileController` (alineado con CONSTITUTION §3.2 que permite "casos de uso, orquestación" en application layer).

# 2. Problema

La UI actual NO refleja los screenshots aprobados en:

- **Profile**: falta la tarjeta "Composición Corporal" (% grasa, masa magra, WHTR + slider ICA con gradient). Los tiles del bloque "HARDWARE BIOLÓGICO" no tienen íconos a la izquierda para los campos biométricos y no permiten edición rápida (peso, cintura, cuello, % grasa). El protocolo de ayuno usa un segmented compacto en lugar del grid 2×4 con tarjeta "RECOMENDADO PARA TI". Los botones de "CERRAR SESIÓN" y "ELIMINAR CUENTA" tienen estilo distinto del aprobado.
- **Dashboard**: posible falta del badge "0 DÍAS 🔥" junto al nombre del usuario en el header. Por verificar al implementar.

# 3. Solución propuesta

Seis cambios estrictamente de presentación + un método nuevo de orquestación en application:

**3.1 Nuevo widget `BodyCompositionPanel`** (`features/auth/presentation/widgets/body_composition_panel.dart`):
- 3 columnas con ícono superior + valor coloreado + label + interpretación textual.
- Slider visual ICA con `LinearGradient` (azul → verde → amarillo → naranja → rojo).
- Marker blanco posicionado según el valor real de `whtr` del `displayedImrProvider`.
- `onTap` → `context.push('/profile/body-composition')` (ruta SPEC-12 ya existente).
- Lee `imrProvider` para `bodyFatPercentage`, `ffmi`, `whtr`, y `currentUserStreamProvider` para género/altura. Cero llamadas directas a repositorios.

**3.2 Helper de presentación `BodyCompositionLabels`** puro:
- `bodyFatLabel(double pct, String gender)` → "Bajo", "Óptimo", "Promedio", "Alto", "Muy alto". Rangos provisionales basados en ACSM (masculino: <11/11-21/21-25/25-30/>30; femenino: <14/14-24/24-29/29-35/>35). Marcado `// PROVISIONAL — pendiente validación clínica externa`.
- `whtrLabel(double whtr)` → "Saludable", "Elevado", "Riesgo alto". Basado en Browning 2010 (`IMR_BIBLIOGRAPHY.md §2.3`).
- `leanMassLabel(double kg, String gender, int heightCm)` → "Por debajo del promedio", "En rango", "Por encima del promedio". Provisional.
- Cero estado, cero IO. Test puro.

**3.3 Refactor de tiles biométricos en Profile**:
- Crear helper `_BiometryTile` con `IconData icon`, `String label`, `String value`, `VoidCallback? onEdit`.
- Las filas Peso, Cintura, Cuello, %Grasa Est. cambian al nuevo tile (con ícono + valor verde + ícono lápiz + tap abre bottom sheet).
- Las filas Nombre, Edad, Género, Estatura mantienen `_readOnlyTile` actual (sin ícono).

**3.4 Bottom sheet `EditBiometryValueSheet`**:
- Recibe `String fieldLabel, String currentValue, String unit, double min, double max, ValueChanged<double> onSave`.
- Validación de rango en presentación (no de dominio): si el valor está fuera de min/max, muestra error inline.
- Sin dependencias de Firestore — solo dispara el callback que el llamador implementa.
- Reutilizable para los 4 campos biométricos.

**3.5 Nuevo método `ProfileController.updateBiometry`** (orquestación, NO lógica de negocio):
- Recibe `UserModel currentUser` + campos opcionales (`weight?, waistCircumference?, neckCircumference?, bodyFatPercentage?`).
- Hace `currentUser.copyWith(...)` con los campos pasados y delega a `_repository.saveProfile(updatedUser)`.
- Sigue el patrón exacto de `updateCircadianProfile` que ya existe en el mismo controller.
- NO valida rangos clínicos (eso vive en `UserProfileMapper._validate` y se ejecuta en el save).

**3.6 Refactor de `_buildProtocolSelector` a `_buildProtocolSelectorGrid`**:
- `GridView.count(crossAxisCount: 4, ...)` con 8 botones cuadrados (Ninguno, 12:12, 14:10, 16:8, 18:6, 20:4, 22:2, OMAD).
- Tarjeta "RECOMENDADO PARA TI" arriba con copy por protocolo recomendado. Lógica de recomendación: usar el `fastingProtocol` actual del user como recomendado (más simple posible; nada de IA). Si en el futuro hay un servicio de recomendación, se inyecta.
- Botón seleccionado con glow verde (color `AppColors.metabolicGreen` con `boxShadow`).
- Tap dispara el mismo `_selectFastingProtocol` que ya existe.

**3.7 Restilo botones de Cuenta**:
- "CERRAR SESIÓN": `ElevatedButton` verde sólido ancho completo + ícono `Icons.logout_rounded`.
- "ELIMINAR CUENTA": `OutlinedButton` rojo ancho completo + ícono `Icons.delete_forever_rounded`.
- Acciones `onPressed` sin cambio (siguen disparando `_confirmLogout` y `_confirmDeleteAccount`).

**3.8 Dashboard header: badge "N DÍAS 🔥"**:
- Verificar primero si ya existe widget de streak en el header (`elena_header.dart` u otro).
- Si no existe, crear `_StreakBadge` que lee `streakProvider.currentStreak`. Color naranja para activo, gris para 0.
- Subtitle "Metamorfosis Real" como `Text` estático bajo el nombre.
- Cero cambios a `streakProvider` ni a `StreakEngine`.

# 4. Plan de implementación

| Paso | Archivo | Cambio |
|---|---|---|
| 1 | `features/auth/presentation/widgets/body_composition_labels.dart` (nuevo) | Helpers puros de clasificación |
| 2 | `features/auth/presentation/widgets/body_composition_panel.dart` (nuevo) | Tarjeta principal |
| 3 | `features/auth/presentation/widgets/edit_biometry_value_sheet.dart` (nuevo) | Bottom sheet reutilizable |
| 4 | `features/auth/application/profile_controller.dart` | + método `updateBiometry` |
| 5 | `features/auth/presentation/profile_screen.dart` | Insertar `BodyCompositionPanel`, refactor tiles biométricos, refactor protocolo, restilo botones cuenta |
| 6 | `features/dashboard/presentation/dashboard_screen.dart` o `core/widgets/elena_header.dart` | Badge streak + subtitle MR |

# 5. Criterios de aceptación

- Profile renderiza `BodyCompositionPanel` debajo de la tarjeta de identidad.
- Tap en el panel navega a `/profile/body-composition`.
- Las 4 filas biométricas (Peso, Cintura, Cuello, %Grasa) tienen ícono a la izquierda y lápiz a la derecha.
- Tap en cualquiera abre `EditBiometryValueSheet`. Aceptar dispara `ProfileController.updateBiometry`. El valor se actualiza en pantalla tras el save (vía rebuild de `currentUserStreamProvider`).
- Protocolo de ayuno se muestra como grid 2×4 con 8 opciones. Selección actual con glow verde. Tap dispara el mismo flujo de hoy.
- Tarjeta "RECOMENDADO PARA TI" arriba del grid con copy por protocolo.
- Botones "CERRAR SESIÓN" verde sólido y "ELIMINAR CUENTA" rojo outlined, ambos ancho completo.
- Dashboard header tiene badge "N DÍAS 🔥" junto al nombre. Subtitle "Metamorfosis Real" bajo el nombre.
- `flutter analyze` sin issues nuevos sobre baseline.
- `flutter test` 420+ verdes / 3 skipped / 0 rojos.
- Ningún cambio en: `ScoreEngine`, `MetabolicStateBuilder`, `imrProvider`, `displayedImrProvider`, `UserModel` (Freezed), repositorios, data sources, mappers, validators, reglas Firestore.

# 6. Pruebas

- **`body_composition_labels_test.dart`** — helpers puros. Casos por género + valores en cada banda. 10-12 casos.
- **`body_composition_panel_test.dart`** — widget test (golden no necesario; verificación estructural). Renderiza con datos mock, verifica que los 3 valores aparecen y el slider tiene el marker en posición correcta.
- **`edit_biometry_value_sheet_test.dart`** — widget test. Validación de rango UI, callback dispara con valor correcto.
- **`profile_controller_update_biometry_test.dart`** — test del nuevo método. Verifica que llama a `saveProfile` con el `UserModel.copyWith` esperado.

# 7. Riesgos

- **Bottom sheet vs dialog**: usé bottom sheet por convención mobile-first. Si Carlos prefiere `AlertDialog`, es cambio cosmético en una línea (`showModalBottomSheet` ↔ `showDialog`).
- **Rangos provisionales**: marcados explícitamente como tales en código + comentarios. Validación clínica externa pendiente — no bloqueante para la SPEC.
- **Edge case del slider ICA**: si `user.height` es 0 (improbable post-onboarding) el slider no renderiza. Fallback: ocultar el slider y mostrar "Datos insuficientes".
- **Streak badge**: si el dashboard ya tiene el chip, no creamos uno duplicado. Verificación primer paso de implementación.

# 8. Out of scope

- Cambios en cálculo de IMR.
- Cambios en validación de rangos biométricos (vive en `UserProfileMapper._validate`).
- Edición de los ritmos circadianos via bottom sheet (ya editables vía time picker actual).
- Edición de campos read-only (Nombre, Edad, Género, Estatura).
- Servicio de recomendación de protocolo de ayuno (usamos el valor actual del user como "recomendado" — placeholder).
- Reorganización del Dashboard fuera del header.
- Animaciones nuevas más allá de las que ya tiene el repo.

# 9. Resultado

**Verificación local (13-may-2026):** `flutter test` 425 verdes / 3 skipped / 0 rojos. Subió +5 tests (los nuevos de `updateBiometry`) sobre la base 420 de SPEC-87.

**Desviaciones del plan:**

- No fue necesario crear `BodyCompositionPanel` ni `BodyCompositionLabels`: el widget `BodyCompositionCard` ya existía en `features/profile/presentation/widgets/` y coincide con el screenshot. Helpers de clasificación (whtrLabel, fatZoneLabel, ffmiLabel) ya estaban en `BodyCompositionCalc`. Reutilizo todo.
- No fue necesario tocar Dashboard ni `ElenaHeader`: el header ya muestra streak badge y subtitle (verificado en `elena_header.dart:47-76`, llamado desde `dashboard_screen.dart:85` con `title: "Metamorfosis Real"`).
- Botones "CERRAR SESIÓN" y "ELIMINAR CUENTA" ya tenían el estilo del screenshot. No fue necesario cambiarlos.

**Cambios finales:**
- 2 archivos modificados (`profile_controller.dart`, `profile_screen.dart`).
- 1 archivo nuevo (`edit_biometry_value_sheet.dart`).
- 1 test nuevo (`profile_controller_update_biometry_test.dart` con 5 casos).

**Smoke test pendiente:** Carlos verifica en device que (1) la tarjeta de Composición Corporal aparece bajo el badge IMR, (2) los 4 tiles biométricos abren el sheet de edición y persisten cambios, (3) el grid 2×4 de protocolos renderiza correctamente con glow en la selección.
