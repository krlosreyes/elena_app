package com.metamorfosis.elena.elena_app

// SPEC-239: Lectura directa de Samsung Health sin pasar por Health Connect.
// Arquitectura:
//   - FlutterMethodChannel "com.metamorfosisreal.elena/samsung_health"
//   - Samsung Health Data SDK 1.1.0
//   - Convierte SleepSession → Map para consumo en Dart
//
// Flujo:
//   1. connect()    — establece conexión con Samsung Health (necesita SH instalado)
//   2. hasPermissions() — consulta si ya tenemos acceso
//   3. requestPermissions() — pide acceso al usuario vía diálogo de SH
//   4. readSleep(startMs, endMs) — devuelve lista de sesiones de sueño
//
// En Dart: health_sync_service.dart llama este channel cuando Health Connect
// devuelve 0 sesiones de sueño en Android.

import android.app.Activity
import android.content.Context
import com.samsung.android.sdk.health.data.HealthDataService
import com.samsung.android.sdk.health.data.HealthDataStore
import com.samsung.android.sdk.health.data.error.HealthDataException
import com.samsung.android.sdk.health.data.permission.Permission
import com.samsung.android.sdk.health.data.request.DataType
import com.samsung.android.sdk.health.data.request.InstantTimeFilter
import com.samsung.android.sdk.health.data.request.ReadDataRequest
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.time.Instant

class SamsungHealthBridge(private val activity: FlutterFragmentActivity) {

    companion object {
        const val CHANNEL = "com.metamorfosisreal.elena/samsung_health"
    }

    private var store: HealthDataStore? = null

    // Permisos que pedimos: solo lectura de Sueño.
    // Steps llegan vía Health Connect (funcionan bien). Weight también.
    private val requiredPermissions = setOf(
        Permission.of(DataType.SleepType, Permission.AccessType.READ),
    )

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "isSamsungHealthAvailable" -> checkAvailable(result)
            "connect"                  -> connect(result)
            "hasPermissions"           -> hasPermissions(result)
            "requestPermissions"       -> requestPermissions(result)
            "readSleep"                -> readSleep(call, result)
            else                       -> result.notImplemented()
        }
    }

    // ─── Disponibilidad ──────────────────────────────────────────────

    private fun checkAvailable(result: MethodChannel.Result) {
        val pm = activity.packageManager
        val available = try {
            pm.getPackageInfo("com.sec.android.app.shealth", 0)
            true
        } catch (_: Exception) { false }
        result.success(available)
    }

    // ─── Conexión ────────────────────────────────────────────────────

    private fun connect(result: MethodChannel.Result) {
        try {
            HealthDataService.getStore(
                activity,
                object : HealthDataStore.ConnectionListener {
                    override fun onConnected(healthDataStore: HealthDataStore) {
                        store = healthDataStore
                        android.util.Log.d("SamsungHealth", "🩺 SH conectado")
                        result.success(true)
                    }
                    override fun onConnectionFailed(e: HealthDataException) {
                        android.util.Log.e("SamsungHealth", "🩺 SH conexión falló: ${e.message}")
                        result.error("SH_CONNECTION_FAILED", e.message, null)
                    }
                    override fun onDisconnected() {
                        android.util.Log.d("SamsungHealth", "🩺 SH desconectado")
                        store = null
                    }
                }
            )
        } catch (e: Exception) {
            result.error("SH_CONNECT_EXCEPTION", e.message, null)
        }
    }

    // ─── Permisos ────────────────────────────────────────────────────

    private fun hasPermissions(result: MethodChannel.Result) {
        val s = store ?: run { result.success(false); return }
        try {
            s.getGrantedPermissions(requiredPermissions)
                .addOnSuccessListener { granted ->
                    result.success(granted.containsAll(requiredPermissions))
                }
                .addOnFailureListener { e ->
                    result.error("SH_PERM_CHECK_FAILED", e.message, null)
                }
        } catch (e: Exception) {
            result.error("SH_PERM_CHECK_EXCEPTION", e.message, null)
        }
    }

    private fun requestPermissions(result: MethodChannel.Result) {
        val s = store ?: run {
            result.error("SH_NOT_CONNECTED", "Llama connect() primero", null)
            return
        }
        try {
            s.requestPermissions(requiredPermissions, activity)
                .addOnSuccessListener { granted ->
                    result.success(granted.containsAll(requiredPermissions))
                }
                .addOnFailureListener { e ->
                    result.error("SH_PERM_REQUEST_FAILED", e.message, null)
                }
        } catch (e: Exception) {
            result.error("SH_PERM_REQUEST_EXCEPTION", e.message, null)
        }
    }

    // ─── Lectura de datos ────────────────────────────────────────────

    private fun readSleep(call: MethodCall, result: MethodChannel.Result) {
        val s = store ?: run {
            result.error("SH_NOT_CONNECTED", "Llama connect() primero", null)
            return
        }

        val startMs = call.argument<Long>("startMs")
            ?: run { result.error("SH_BAD_ARGS", "falta startMs", null); return }
        val endMs = call.argument<Long>("endMs")
            ?: run { result.error("SH_BAD_ARGS", "falta endMs", null); return }

        android.util.Log.d("SamsungHealth",
            "🩺 SH readSleep: ${Instant.ofEpochMilli(startMs)} → ${Instant.ofEpochMilli(endMs)}")

        try {
            val timeFilter = InstantTimeFilter.of(
                Instant.ofEpochMilli(startMs),
                Instant.ofEpochMilli(endMs),
            )
            val request = ReadDataRequest.builder(DataType.SleepType, timeFilter).build()

            s.readData(request)
                .addOnSuccessListener { dataSet ->
                    val sessions = mutableListOf<Map<String, Any>>()
                    for (point in dataSet.dataPoints) {
                        // SleepSession extiende HealthDataPoint — campos
                        // startTime/endTime son instantes en epoch ms.
                        val startEpoch = point.startTime.toEpochMilli()
                        val endEpoch   = point.endTime.toEpochMilli()
                        val durationMs = endEpoch - startEpoch
                        val durationMin = durationMs / 60_000L

                        android.util.Log.d("SamsungHealth",
                            "🩺 SH sleep: ${durationMin}min")

                        sessions.add(mapOf(
                            "startMs"     to startEpoch,
                            "endMs"       to endEpoch,
                            "durationMin" to durationMin,
                        ))
                    }
                    android.util.Log.d("SamsungHealth",
                        "🩺 SH readSleep: ${sessions.size} sesiones encontradas")
                    result.success(sessions)
                }
                .addOnFailureListener { e ->
                    android.util.Log.e("SamsungHealth", "🩺 SH readData falló: ${e.message}")
                    result.error("SH_READ_FAILED", e.message, null)
                }
        } catch (e: Exception) {
            result.error("SH_READ_EXCEPTION", e.message, null)
        }
    }
}
