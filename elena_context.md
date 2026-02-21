# 🧬 ElenaApp - Contexto Técnico y Arquitectura

## 1. Stack Tecnológico Core
* **Framework:** Flutter / Dart
* **State Management:** Riverpod (con Codegen)
* **Generación de Modelos:** Freezed + JsonSerializable
* **Navegación:** GoRouter (con ShellRoute para BottomNavBar)
* **Backend & Persistencia:** Firebase (Auth, Firestore)

## 2. Arquitectura (Clean Architecture Orientada a Features)
El proyecto sigue una estricta separación de responsabilidades dentro de `lib/src/features/`:
* **Domain (`/domain`):** Entidades (modeladas con `@freezed`) y lógica de negocio pura (ej. cálculo de calorías con MET).
* **Application (`/application`):** Providers y Notifiers (ej. `TrainingEngine`). Orquestan el estado y conectan UI con Data.
* **Data (`/data`):** Repositorios y llamadas a Firebase.
* **Presentation (`/presentation`):** UI (Screens y Widgets). Debe ser "tonta", solo reacciona al estado.
* **Diseño Centralizado:** Todo componente debe respetar `src/config/theme/`.

## 3. Reglas de Oro (Plantilla Antigravity)
1. **NO romper funcionalidad existente.** Todo refactor debe ser incremental.
2. **Performance-First:** Minimizar *rebuilds* usando `ConsumerWidget` y `ref.watch(provider.select(...))` de forma granular.
3. **Control de Versiones:** Antes de un cambio grande, ejecutar: `git add . && git commit -m "chore: backup..."`
4. **Cero Dependencias Ocultas:** No añadir paquetes al `pubspec.yaml` sin justificación estricta.
5. **Precaución Local (iCloud Bug):** Revisar periódicamente que el sync de Mac no genere archivos duplicados `* 2.dart` que rompan el `build_runner`.

## 4. Glosario de Módulos (Features)
* `training`: Motor principal de entrenamiento.
* `history`: Historial de sesiones y cálculo de volumen/calorías.
* `dashboard`, `fasting`, `nutrition`, `metabolic_health`, `glucose`, `plan`, `profile`, `progress`, `coaching`, `authentication`, `onboarding`.

## 5. Foco Actual: Módulo "Training"
* **`TrainingEngine` (Provider):** Orquesta el estado de la sesión activa, maneja el flujo de los ejercicios.
* **`StrengthWorkoutView` (UI):** Pantalla principal de ejecución. Estructurada con un `Stack` y un `Column` (Header, Body, Footer).
* **`TrainingFeedbackCard` (UI):** Tarjeta azul de contexto/feedback que debe ocultarse dinámicamente o convivir sin superponerse al ejercicio.

## 6. Hito Actual (En Progreso)
**Refactorización de UI/UX en `StrengthWorkoutView`:**
1. **Z-Index Fix:** Evitar que la imagen del ejercicio (SVG/PNG) se oculte detrás del `TrainingFeedbackCard`.
2. **Inputs Condicionales:** Ocultar la columna de "Peso" si el ejercicio es de tipo peso corporal (`bodyweight`).
3. **Timer de Descanso:** Al completar un set intermedio, mostrar un contador de 30s de descanso sin bloquear la UI principal.
4. **Desafío Final:** Al marcar el último set, mostrar modal: "Vas muy bien Charlie, ¿crees que puedes hacer una serie más?". (Sí = añade serie al final; No = pasa de ejercicio).
