// SPEC-132.next — Observers de HealthKit + background delivery.
//
// 2026-11-04 (auditoría Apple Salud, Fase 2). Tres fallas corregidas:
//
//   1. El canal se creaba en didFinishLaunching con `window?.rootViewController`,
//      pero la app usa escenas (FlutterSceneDelegate): ahí `window` es nil,
//      el canal nunca existía y los observers jamás arrancaban. Ahora el
//      canal se crea en `didInitializeImplicitFlutterEngine` (AppDelegate).
//   2. El `completionHandler` de HKObserverQuery se llamaba al instante, antes
//      de que Dart leyera nada: iOS podía suspender la app de inmediato. Ahora
//      se llama cuando Dart responde que terminó el sync (máx. 25 s).
//   3. En un arranque en segundo plano los eventos llegaban antes de que Dart
//      estuviera listo y se perdían. Ahora se encolan hasta que Dart llama a
//      `startObserving` y se entregan entonces.
//
// Los observers se registran también al arrancar la app (didFinishLaunching)
// si el usuario ya los había activado: background delivery exige que las
// queries existan antes de que iOS entregue el evento.

import Foundation
import HealthKit
import Flutter

final class HealthKitObserver {
  static let enabledKey = "elena.healthkit.observing"

  /// Tiempo máximo que retenemos el completionHandler de iOS esperando a Dart.
  private static let completionTimeout: TimeInterval = 25

  private let healthStore = HKHealthStore()
  private var channel: FlutterMethodChannel?
  private var activeQueries: [HKObserverQuery] = []
  private var observing = false
  private var dartReady = false
  private var pending: [(key: String, done: OnceCompletion)] = []

  /// Envuelve el completionHandler de HealthKit para llamarlo una sola vez.
  final class OnceCompletion {
    private var handler: (() -> Void)?
    init(_ handler: @escaping () -> Void) { self.handler = handler }
    func call() {
      if let h = handler {
        handler = nil
        h()
      }
    }
  }

  func attach(channel: FlutterMethodChannel) {
    self.channel = channel
  }

  private struct Watched {
    let type: HKSampleType
    let key: String
    let frequency: HKUpdateFrequency
  }

  private func watchedTypes() -> [Watched] {
    var out: [Watched] = []
    if let weight = HKObjectType.quantityType(forIdentifier: .bodyMass) {
      out.append(Watched(type: weight, key: "weight", frequency: .immediate))
    }
    if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
      out.append(Watched(type: steps, key: "steps", frequency: .hourly))
    }
    if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
      out.append(Watched(type: sleep, key: "sleep", frequency: .hourly))
    }
    if let exercise = HKObjectType.quantityType(forIdentifier: .appleExerciseTime) {
      out.append(Watched(type: exercise, key: "activeMinutes", frequency: .hourly))
    }
    out.append(Watched(type: HKObjectType.workoutType(), key: "workout",
                       frequency: .immediate))
    return out
  }

  /// Registra observers + background delivery. Idempotente.
  /// `fromDart = true` también marca a Dart como listo y entrega lo encolado.
  func startObserving(fromDart: Bool) {
    if fromDart {
      UserDefaults.standard.set(true, forKey: HealthKitObserver.enabledKey)
      dartReady = true
      flushPending()
    }
    guard HKHealthStore.isHealthDataAvailable() else { return }
    if observing { return }
    observing = true

    for watched in watchedTypes() {
      let query = HKObserverQuery(
        sampleType: watched.type,
        predicate: nil
      ) { [weak self] _, completionHandler, error in
        let done = OnceCompletion(completionHandler)
        if let error = error {
          NSLog("[HealthKitObserver] observer error (\(watched.key)): "
            + error.localizedDescription)
          done.call()
          return
        }
        DispatchQueue.main.async {
          guard let self = self else { done.call(); return }
          self.deliver(key: watched.key, done: done)
        }
      }
      healthStore.execute(query)
      activeQueries.append(query)

      healthStore.enableBackgroundDelivery(
        for: watched.type,
        frequency: watched.frequency
      ) { _, error in
        if let error = error {
          NSLog("[HealthKitObserver] enableBackgroundDelivery falló (\(watched.key)): "
            + error.localizedDescription)
        }
      }
    }
  }

  func stopObserving() {
    UserDefaults.standard.set(false, forKey: HealthKitObserver.enabledKey)
    for query in activeQueries {
      healthStore.stop(query)
    }
    activeQueries.removeAll()
    observing = false
    healthStore.disableAllBackgroundDelivery { _, _ in }
    for item in pending { item.done.call() }
    pending.removeAll()
  }

  // MARK: - Entrega a Dart (siempre en main)

  private func deliver(key: String, done: OnceCompletion) {
    // Red de seguridad: nunca retener el handler de iOS más de 25 s.
    DispatchQueue.main.asyncAfter(deadline: .now() + HealthKitObserver.completionTimeout) {
      done.call()
    }
    guard dartReady, let channel = channel else {
      pending.append((key: key, done: done))
      return
    }
    channel.invokeMethod("healthDataChanged", arguments: ["type": key]) { _ in
      // Dart responde cuando terminó el sync (o lo descartó).
      done.call()
    }
  }

  private func flushPending() {
    guard dartReady, let channel = channel, !pending.isEmpty else { return }
    let batch = pending
    pending.removeAll()
    // Un solo sync cubre todos los tipos: se avisa una vez y se liberan
    // todos los handlers cuando Dart termina.
    let keys = batch.map { $0.key }.joined(separator: ",")
    channel.invokeMethod("healthDataChanged", arguments: ["type": keys]) { _ in
      for item in batch { item.done.call() }
    }
  }
}
