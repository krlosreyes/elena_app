package com.metamorfosis.elena.elena_app

// SPEC-239: Samsung Health Data SDK 1.1.0 — lectura directa de sueño sin Health Connect.
//
// API verificada contra bytecode del AAR (R8 full obfuscation):
//   - HealthDataService(Context)                → instancia del servicio
//   - service.getStore(Context)                 → HealthDataStore (síncrono)
//   - store.getGrantedPermissionsAsync(perms)   → AsyncSingleFuture<Set<Permission>>
//   - store.requestPermissionsAsync(perms, act) → AsyncSingleFuture<Set<Permission>>
//   - store.readDataAsync(request)              → AsyncSingleFuture<DataResponse<HealthDataPoint>>
//   - AsyncSingleFuture.setCallback(Executor, Consumer<T>, Consumer<Throwable>)
//   - InstantTimeFilter.since(startInstant)     ← único factory con nombre JVM preservado
//   - DataType.SleepType()                      ← no-arg constructor; es un DataType
//   - sleepType.readDataRequestBuilder          ← DualTimeBuilder pre-configurado
//   - dataPoint.startTime / dataPoint.endTime   ← Instant

import android.app.Activity
import com.samsung.android.sdk.health.data.HealthDataService
import com.samsung.android.sdk.health.data.HealthDataStore
import com.samsung.android.sdk.health.data.permission.AccessType
import com.samsung.android.sdk.health.data.permission.Permission
import com.samsung.android.sdk.health.data.request.DataType
import com.samsung.android.sdk.health.data.request.DataTypes
import com.samsung.android.sdk.health.data.request.InstantTimeFilter
import com.samsung.android.sdk.health.data.response.AsyncSingleFuture
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.launch
import java.time.Instant
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import java.util.function.Consumer
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.coroutines.suspendCoroutine

class SamsungHealthBridge(private val activity: Activity) {

    companion object {
        const val CHANNEL = "com.metamorfosisreal.elena/samsung_health"
    }

    // Scope principal: Main para que result.success/.error lleguen al hilo UI.
    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())

    // Executor para callbacks de AsyncSingleFuture (no bloquea Main).
    private val executor: Executor = Executors.newSingleThreadExecutor()

    // Store: se inicializa al llamar "connect".
    private var store: HealthDataStore? = null

    // DataTypes.SLEEP es el singleton pre-instanciado de DataType.SleepType
    // que expone Samsung a través de DataTypes (@JvmField, verificado en bytecode).
    // NUNCA usar DataType.SleepType() — constructor es internal en el SDK.
    private val sleepPermissions: Set<Permission> = setOf(
        Permission.of(DataTypes.SLEEP, AccessType.READ),
    )

    // ─── Dispatcher ──────────────────────────────────────────────────────────

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        scope.launch {
            try {
                when (call.method) {
                    "isSamsungHealthAvailable" ->
                        result.success(isSamsungHealthAvailable())

                    "connect" ->
                        result.success(connect())

                    "hasPermissions" ->
                        result.success(hasPermissions())

                    "requestPermissions" ->
                        result.success(requestPermissions())

                    "readSleep" -> {
                        // Flutter puede enviar Int o Long; normalizamos a Long.
                        val startMs = (call.argument<Any>("startMs") as Number).toLong()
                        val endMs   = (call.argument<Any>("endMs")   as Number).toLong()
                        result.success(readSleep(startMs, endMs))
                    }

                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                println("🩺 SH BRIDGE ERROR [${call.method}]: ${e.message}")
                result.error("SAMSUNG_HEALTH_ERROR", e.message, null)
            }
        }
    }

    // ─── ¿Instalado? ─────────────────────────────────────────────────────────

    private fun isSamsungHealthAvailable(): Boolean {
        return try {
            activity.packageManager.getPackageInfo("com.sec.android.app.shealth", 0)
            println("🩺 SH BRIDGE: Samsung Health instalado")
            true
        } catch (_: Exception) {
            println("🩺 SH BRIDGE: Samsung Health NO instalado")
            false
        }
    }

    // ─── Conexión ────────────────────────────────────────────────────────────

    /**
     * Inicializa el HealthDataStore.
     * HealthDataService es un Kotlin object (singleton con INSTANCE),
     * no se instancia — se llama HealthDataService.getStore() directo.
     */
    private fun connect(): Boolean {
        return try {
            store = HealthDataService.getStore(activity)
            println("🩺 SH BRIDGE: connect OK")
            true
        } catch (e: Exception) {
            println("🩺 SH BRIDGE: connect ERROR — ${e.message}")
            false
        }
    }

    // ─── Permisos ────────────────────────────────────────────────────────────

    private suspend fun hasPermissions(): Boolean {
        val s = store ?: return false
        return try {
            val granted = awaitFuture(s.getGrantedPermissionsAsync(sleepPermissions))
            val has = granted.containsAll(sleepPermissions)
            println("🩺 SH BRIDGE: hasPermissions=$has")
            has
        } catch (e: Exception) {
            println("🩺 SH BRIDGE: hasPermissions ERROR — ${e.message}")
            false
        }
    }

    private suspend fun requestPermissions(): Boolean {
        val s = store ?: return false
        return try {
            val granted = awaitFuture(s.requestPermissionsAsync(sleepPermissions, activity))
            val has = granted.containsAll(sleepPermissions)
            println("🩺 SH BRIDGE: requestPermissions → $has")
            has
        } catch (e: Exception) {
            println("🩺 SH BRIDGE: requestPermissions ERROR — ${e.message}")
            false
        }
    }

    // ─── Lectura de sueño ────────────────────────────────────────────────────

    /**
     * Lee sesiones de sueño en [startMs, endMs].
     * Devuelve lista de maps: { startMs, endMs, durationMin }.
     * Filtra sesiones < 30 min (ruido).
     *
     * Nota: InstantTimeFilter.since(startInstant) es la única factory
     * con nombre JVM preservado tras R8 en el AAR. La cota de fin
     * se aplica manualmente en el bucle.
     */
    private suspend fun readSleep(startMs: Long, endMs: Long): List<Map<String, Any>> {
        val s = store ?: return emptyList()

        val startInstant = Instant.ofEpochMilli(startMs)
        val endInstant   = Instant.ofEpochMilli(endMs)

        println("🩺 SH BRIDGE: readSleep $startInstant → $endInstant")

        val timeFilter = InstantTimeFilter.since(startInstant)
        // DataTypes.SLEEP: instancia singleton de DataType.SleepType provista por el SDK.
        // readDataRequestBuilder devuelve DualTimeBuilder<HealthDataPoint> tipado.
        val request    = DataTypes.SLEEP.readDataRequestBuilder
            .setInstantTimeFilter(timeFilter)
            .build()

        val response = awaitFuture(s.readDataAsync(request))
        val sessions = mutableListOf<Map<String, Any>>()

        for (dataPoint in response.dataList) {
            // startTime/endTime son Instant? (nullable) según bytecode del AAR
            val pStartMs = dataPoint.startTime?.toEpochMilli() ?: continue
            val pEndMs   = dataPoint.endTime?.toEpochMilli()   ?: continue

            // Excluir sesiones que empiezan fuera del rango solicitado.
            if (pStartMs >= endInstant.toEpochMilli()) continue

            val durationMin = ((pEndMs - pStartMs) / 60_000L).toInt()

            // Descartar ruido (naps muy cortos, interrupciones).
            if (durationMin < 30) continue

            println("🩺 SH BRIDGE: sesión sueño ${durationMin}min")
            sessions += mapOf(
                "startMs"     to pStartMs,
                "endMs"       to pEndMs,
                "durationMin" to durationMin,
            )
        }

        println("🩺 SH BRIDGE: ${sessions.size} sesiones de sueño leídas")
        return sessions
    }

    // ─── AsyncSingleFuture → suspend ─────────────────────────────────────────

    /**
     * Convierte AsyncSingleFuture<T> en suspend fun usando
     * setCallback(Executor, Consumer<T>, Consumer<Throwable>).
     *
     * El método setCallback tiene nombre JVM preservado en el AAR
     * (verificado en bytecode). java.util.function.Consumer es
     * compatible con SAM conversion de Kotlin.
     */
    @Suppress("UNCHECKED_CAST")
    private suspend fun <T> awaitFuture(future: AsyncSingleFuture<T>): T =
        suspendCoroutine { cont ->
            future.setCallback(
                executor,
                Consumer { value: T        -> cont.resume(value) },
                Consumer { err: Throwable  -> cont.resumeWithException(err) },
            )
        }
}
