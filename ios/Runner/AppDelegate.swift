import Flutter
import UIKit
import UserNotifications
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

    // SPEC-172 (2026-06-04): banner + sonido en foreground.
    // Sin esto, las notifs locales NO se muestran cuando la app está
    // abierta — iOS las silencia por default. `flutter_local_notifications`
    // requiere el delegate seteado al AppDelegate.
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }

    let result = super.application(
      application, didFinishLaunchingWithOptions: launchOptions)

    // SPEC-132.next: MethodChannel para arrancar/parar los observers de
    // HealthKit desde Dart y recibir los eventos de cambio.
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.metamorfosis.elena/healthkit_observer",
        binaryMessenger: controller.binaryMessenger
      )
      let observer = HealthKitObserver(channel: channel)
      self.healthObserver = observer
      channel.setMethodCallHandler { call, resultCb in
        switch call.method {
        case "startObserving":
          observer.startObserving()
          resultCb(nil)
        case "stopObserving":
          observer.stopObserving()
          resultCb(nil)
        default:
          resultCb(FlutterMethodNotImplemented)
        }
      }
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
  }
}
