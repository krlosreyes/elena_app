// SPEC-132.next — Observers de HealthKit + background delivery.
//
// Registra un HKObserverQuery por tipo (peso, pasos, sueño) y habilita
// background delivery para que iOS despierte la app cuando HealthKit recibe
// data nueva. El handler NO lee data: solo notifica al MethodChannel Dart con
// un mensaje liviano `{ type }`. El sync completo (dedup, "manual wins over
// auto") sigue en Dart (HealthAutoSyncController).

import Foundation
import HealthKit
import Flutter

final class HealthKitObserver {
  private let healthStore = HKHealthStore()
  private let channel: FlutterMethodChannel
  private var activeQueries: [HKObserverQuery] = []
  private var observing = false

  init(channel: FlutterMethodChannel) {
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
      // Peso: inmediato — evento puntual, sin samples a alta frecuencia.
      out.append(Watched(type: weight, key: "weight", frequency: .immediate))
    }
    if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
      out.append(Watched(type: steps, key: "steps", frequency: .hourly))
    }
    if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) {
      out.append(Watched(type: sleep, key: "sleep", frequency: .hourly))
    }
    return out
  }

  /// Idempotente: si ya hay observers activos, no hace nada.
  func startObserving() {
    guard HKHealthStore.isHealthDataAvailable() else { return }
    if observing { return }
    observing = true

    for watched in watchedTypes() {
      let query = HKObserverQuery(
        sampleType: watched.type,
        predicate: nil
      ) { [weak self] _, completionHandler, error in
        if error == nil {
          DispatchQueue.main.async {
            self?.channel.invokeMethod(
              "healthDataChanged",
              arguments: ["type": watched.key]
            )
          }
        } else {
          NSLog("[HealthKitObserver] observer error (\(watched.key)): "
            + (error?.localizedDescription ?? "desconocido"))
        }
        // OBLIGATORIO: sin llamar al completionHandler, iOS deja de
        // despachar eventos para este observer.
        completionHandler()
      }
      healthStore.execute(query)
      activeQueries.append(query)

      healthStore.enableBackgroundDelivery(
        for: watched.type,
        frequency: watched.frequency
      ) { success, error in
        if let error = error {
          NSLog("[HealthKitObserver] enableBackgroundDelivery falló (\(watched.key)): "
            + error.localizedDescription)
        }
      }
    }
  }

  func stopObserving() {
    for query in activeQueries {
      healthStore.stop(query)
    }
    activeQueries.removeAll()
    observing = false
    healthStore.disableAllBackgroundDelivery { _, _ in }
  }
}
