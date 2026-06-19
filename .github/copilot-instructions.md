# Instrucciones rápidas para agentes de IA

Propósito: entregar al agente la información mínima y accionable para ser productivo con cambios en este repositorio Flutter (ElenaApp).

- Stack y patrones clave
  - Flutter (3.x), Riverpod 2.x para estado, go_router para navegación, freezed/json_serializable para modelos.
  - Spec-Driven Development: cada cambio funcional importante debe vincularse a `specs/SPEC-XXX-*.md` y el PR debe usar el prefijo `SPEC-XXX:`.
  - Estructura importante: el código está en `lib/src/` con `core/` (servicios, providers, orchestrator) y `features/` (dominio por pilar).

- Dónde mirar primero (alta prioridad)
  - `lib/src/core/services/notification_service_mobile.dart` — lógica de notificaciones accionables (Android/iOS), categorías y detalles. Muchas integraciones iOS/Android requieren constantes compartidas.
  - `lib/src/core/services/pending_action_queue.dart` — cola persistente (SharedPreferences) para acciones de notificación; contiene constantes de action/category (p. ej. `kHydrationYesActionId`, `kCheckIn*`).
  - `lib/src/core/orchestrator/` — motor que orquesta fases biológicas y decisiones de scheduling.
  - `lib/src/features/*` — cada pilar (fasting, hydration, exercise, nutrition, etc.) implementa notifiers, servicios y pantalla. Buscar `application/`, `domain/`, `presentation/`.
  - `specs/` y `CONSTITUTION.md` — documentación SDD y decisiones arquitectónicas que deben respetarse.

- Convenciones relevantes (ediciones y refactors)
  - Constantes compartidas entre `NotificationService` y la cola de acciones viven en `pending_action_queue.dart`. Si añades IDs de acción, actualiza ambas ubicaciones o exporta las constantes para evitar referencias indefinidas.
  - No escribir Firestore desde callbacks de notificación: las acciones se encolan (SharedPreferences) y se procesan en foreground por `CoachingActionRouter.flush`.
  - When adding platform background handlers (iOS), confirm that native registrant en `ios/Runner/AppDelegate` está configurado para ejecutar handlers en isolates.
  - PR title/commit message: incluir el SPEC correspondiente y un resumen breve. Mantener la rama basada en `mvp-core-clean` para cambios core.

- Comandos útiles (rápidos)
  - Preparar: `flutter pub get`
  - Generar código: `dart run build_runner build --delete-conflicting-outputs`
  - Analizar estático: `flutter analyze` (o `dart analyze` en CI)
  - Tests: `flutter test`
  - Ejecutar en dispositivo: `flutter run`
  - iOS: usar Xcode si hay errores nativos; para notificaciones background revisar `AppDelegate` y entitlements (Time Sensitive notifications).

- Integraciones y puntos frágiles
  - Firebase (auth, firestore, analytics), RevenueCat/Purchases y varios plugins nativos. Revisa `pubspec.yaml` y `ios/Podfile` para versiones; los problemas de linking o advertencias nativas aparecen en builds Xcode.
  - Notificaciones: iOS requiere categorías/acciones declaradas en `DarwinNotificationCategory` y constantes compartidas. Android usa `AndroidNotificationAction` en `NotificationDetails`.
  - Health / device plugins (Health, device_info_plus): prestá atención a warnings Swift/ObjC en iOS (pueden romper builds en versiones SDK recientes).

- Cómo hacer cambios seguros (checklist rápido)
  1. Localiza el SPEC y actualízalo si añades comportamiento nuevo.
  2. Añade constantes en `pending_action_queue.dart` y exporta si son consumidas por `notification_service_mobile.dart`.
  3. Ejecuta `dart run build_runner build` si tocas modelos/freezed.
  4. Corre `flutter analyze` y `flutter test` antes de abrir PR.
  5. En PR description: listar archivos clave tocados y justificar desviaciones de los SPECs.

Si falta algo, dame retroalimentación y ajusto estas instrucciones.
