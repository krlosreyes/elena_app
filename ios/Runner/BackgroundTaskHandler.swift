import BackgroundTasks
import Flutter
import UIKit
import flutter_local_notifications

// ─────────────────────────────────────────────────────────────────────────────
// SPEC-223 Fase 2: BGAppRefreshTask — recálculo de notificaciones
// ─────────────────────────────────────────────────────────────────────────────
//
// iOS concede ~30s de CPU. El handler arranca un FlutterEngine headless,
// invoca el entrypoint Dart `backgroundNotificationRefresh`, espera a que
// Dart señale "done" via MethodChannel, y completa la tarea.
//
// Frecuencia: `earliestBeginDate` = 4 horas. iOS decide cuándo ejecutar.
// Típicamente 2-3 veces/día en uso normal.

class BackgroundTaskHandler {
  static let notificationRefreshId = "com.metamorfosis.elena.notification-refresh"

  /// Registra los handlers de BGTaskScheduler.
  /// Llamar desde `AppDelegate.didFinishLaunchingWithOptions` ANTES de
  /// `super.application(...)`.
  static func register() {
    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: notificationRefreshId,
      using: nil
    ) { task in
      handleNotificationRefresh(task: task as! BGAppRefreshTask)
    }
  }

  /// Programa la próxima ejecución del refresh de notificaciones.
  /// Llamar después de cada ejecución exitosa y en `didFinishLaunching`.
  static func scheduleNotificationRefresh() {
    let request = BGAppRefreshTaskRequest(
      identifier: notificationRefreshId
    )
    // Pedimos no antes de 4 horas. iOS decide el momento exacto.
    request.earliestBeginDate = Date(timeIntervalSinceNow: 4 * 60 * 60)

    do {
      try BGTaskScheduler.shared.submit(request)
      print("[BackgroundTaskHandler] Notification refresh scheduled")
    } catch {
      print("[BackgroundTaskHandler] Failed to schedule: \(error)")
    }
  }

  // ── Handler interno ──────────────────────────────────────────────────────

  private static func handleNotificationRefresh(task: BGAppRefreshTask) {
    // Reprogramar la siguiente ejecución inmediatamente.
    scheduleNotificationRefresh()

    // Crear un FlutterEngine headless para ejecutar Dart en background.
    let engine = FlutterEngine(
      name: "bg_notification_refresh",
      project: nil,
      allowHeadlessExecution: true
    )

    // Registrar plugins (necesario para flutter_local_notifications).
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // Arrancar el engine con el entrypoint Dart dedicado.
    let success = engine.run(
      withEntrypoint: "backgroundNotificationRefresh"
    )

    if !success {
      print("[BackgroundTaskHandler] Failed to start Flutter engine")
      task.setTaskCompleted(success: false)
      return
    }

    GeneratedPluginRegistrant.register(with: engine)

    // MethodChannel para que Dart señale "done".
    let channel = FlutterMethodChannel(
      name: "com.metamorfosis.elena/background_refresh",
      binaryMessenger: engine.binaryMessenger
    )

    // Timeout: si Dart no responde en 25s, completar con failure.
    let timeoutWork = DispatchWorkItem {
      print("[BackgroundTaskHandler] Timeout — completing task")
      engine.destroyContext()
      task.setTaskCompleted(success: false)
    }
    DispatchQueue.main.asyncAfter(deadline: .now() + 25, execute: timeoutWork)

    channel.setMethodCallHandler { call, result in
      if call.method == "refreshComplete" {
        timeoutWork.cancel()
        let success = (call.arguments as? Bool) ?? true
        print("[BackgroundTaskHandler] Dart completed: \(success)")
        engine.destroyContext()
        task.setTaskCompleted(success: success)
        result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    }

    // Manejo de expiración (iOS quiere cerrar antes del timeout).
    task.expirationHandler = {
      timeoutWork.cancel()
      print("[BackgroundTaskHandler] Task expired by system")
      engine.destroyContext()
    }
  }
}
