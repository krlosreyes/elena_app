import Flutter
import UIKit
import UserNotifications
// import BackgroundTasks  // SPEC-223: descomentar con BackgroundTaskHandler
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // SPEC-132.next: observer de HealthKit (background delivery). Se conserva
  // como propiedad para que ARC no lo libere.
  private var healthObserver: HealthKitObserver?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // SPEC-224 (A1b): registrar plugins en el isolate de background para que
    // SharedPreferences esté disponible cuando el handler de notificación corra
    // sin que la app esté en foreground. Debe ir ANTES de super.application.
    // Ref: https://pub.dev/packages/flutter_local_notifications#-ios-setup-background
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }

    // SPEC-223 Fase 2: BGAppRefreshTask — BLOCKED hasta entitlement en
    // Apple Developer Portal. Descomentar cuando esté disponible:
    // BackgroundTaskHandler.register()
    // BackgroundTaskHandler.scheduleNotificationRefresh()

    // SPEC-172 (2026-06-04): banner + sonido en foreground.
    // Sin esto, las notifs locales NO se muestran cuando la app está
    // abierta — iOS las silencia por default. `flutter_local_notifications`
    // requiere el delegate seteado al AppDelegate.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    let result = super.application(
      application, didFinishLaunchingWithOptions: launchOptions)

    // SPEC-132.next / 2026-11-04: los observers de HealthKit se registran
    // aquí — sin esperar a Flutter — si el usuario ya los activó. Así un
    // arranque en segundo plano por background delivery encuentra las
    // queries vivas. El canal con Dart se conecta en
    // `didInitializeImplicitFlutterEngine` (con escenas, `window` es nil
    // en este punto).
    // El motor implícito puede inicializarse dentro de super.application y
    // haber creado ya el observer: reutilizarlo para no perder el canal.
    let observer = healthObserver ?? HealthKitObserver()
    self.healthObserver = observer
    if UserDefaults.standard.bool(forKey: HealthKitObserver.enabledKey) {
      observer.startObserving(fromDart: false)
    }

    return result
  }

  // SPEC-172: forzar presentación de banner + sonido cuando la app está
  // en foreground. iOS 14+ usa .banner / .list; iOS pre-14 usa .alert.
  @available(iOS 10.0, *)
  override func userNotificationCenter(
    _ center: UNUserNotificationCenter,
    willPresent notification: UNNotification,
    withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
  ) {
    if #available(iOS 14.0, *) {
      completionHandler([.banner, .sound, .list])
    } else {
      completionHandler([.alert, .sound])
    }
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // 2026-11-04: canal de los observers de HealthKit. Antes se creaba con
    // `window?.rootViewController`, que es nil con FlutterSceneDelegate →
    // el canal nunca existía y los observers jamás arrancaban.
    guard
      let registrar = engineBridge.pluginRegistry.registrar(
        forPlugin: "ElenaHealthKitObserver")
    else { return }
    let channel = FlutterMethodChannel(
      name: "com.metamorfosis.elena/healthkit_observer",
      binaryMessenger: registrar.messenger()
    )
    let observer = healthObserver ?? HealthKitObserver()
    healthObserver = observer
    observer.attach(channel: channel)
    channel.setMethodCallHandler { call, resultCb in
      switch call.method {
      case "startObserving":
        observer.startObserving(fromDart: true)
        resultCb(nil)
      case "stopObserving":
        observer.stopObserving()
        resultCb(nil)
      default:
        resultCb(FlutterMethodNotImplemented)
      }
    }
  }
}
