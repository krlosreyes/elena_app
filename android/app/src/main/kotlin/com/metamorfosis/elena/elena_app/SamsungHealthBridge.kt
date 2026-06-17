package com.metamorfosis.elena.elena_app

// SPEC-239: Samsung Health Data SDK 1.1.0 — lectura directa de sueño sin Health Connect.
//
// API verificada contra bytecode del AAR (R8 full obfuscation):
//   - HealthDataService   → Kotlin object (singleton INSTANCE); getStore(Context) @JvmStatic
//   - DataTypes.SLEEP     → singleton pre-instanciado de DataType.SleepType (@JvmField)
//   - Permission.of(DataType, AccessType.READ) en companion de Permission
//   - AsyncSingleFuture.setCallback(Executor, Consumer<T>, Consumer<Throwable>)
//   - InstantTimeFilter.since(startInstant) ← único factory con nombre JVM preservado (R8)
//   - DataTypes.SLEEP.readDataRequestBuilder → DualTimeBuilder<HealthDataPoint>
//   - dataPoint.startTime? / dataPoint.endTime? → Instant? (nullable)

import android.app.Activity
import android.util.Log
import com.samsung.android.sdk.health.data.HealthDataService
import com.samsung.android.sdk.health.data.HealthDataStore
import com.samsung.android.sdk.health.data.permission.AccessType
import com.samsung.android.sdk.health.data.permission.Permission
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
        private const val TAG = "SH_BRIDGE"
    }

    private val scope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val executor: Executor = Executors.newSingleThreadExecutor()
    private var store: HealthDataStore? = null

    // Lazy para que los errores de init del SDK no rompan el constructor.
    // DataTypes.SLEEP es el singleton @JvmField de DataType.SleepType.
    private val sleepPermissions: Set<Permission> by lazy {
        try {
            setOf(Permission.of(DataTypes.SLEEP, AccessType.READ))
        } catch (e: Exception) {
            Log.e(TAG, "Error creando sleepPermissions: ${e.message}", e)
            emptySet()
        }
    }

    // ─── Dispatcher ──────────────────────────────────────────────────────────

    fun handle(call: MethodCall, result: MethodChannel.Result) {
        Log.d(TAG, "handle: ${call.method}")
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
                        val startMs = (call.argument<Any>("startMs") as Number).toLong()
                        val endMs   = (call.argument<Any>("endMs")   as Number).toLong()
                        result.success(readSleep(startMs, endMs))
                    }

                    else -> result.notImplemented()
                }
            } catch (e: Exception) {
                Log.e(TAG, "ERROR [${call.method}]: ${e.message}", e)
                result.error("SAMSUNG_HEALTH_ERROR", e.message, null)
            }
        }
    }

    // ─── ¿Instalado? ─────────────────────────────────────────────────────────

    private fun isSamsungHealthAvailable(): Boolean {
        return try {
            activity.packageManager.getPackageInfo("com.sec.android.app.shealth", 0)
            Log.d(TAG, "🩺 Samsung Health instalado")
            true
        } catch (_: Exception) {
            Log.d(TAG, "🩺 Samsung Health NO instalado")
            false
        }
    }

    // ─── Conexión ────────────────────────────────────────────────────────────

    /**
     * Obtiene el HealthDataStore.
     * HealthDataService es un Kotlin object; getStore(@JvmStatic) toma un Context.
     */
    private fun connect(): Boolean {
        return try {
            store = HealthDataService.getStore(activity)
            Log.d(TAG, "🩺 connect OK — store=$store")
            store != null
        } catch (e: Exception) {
            Log.e(TAG, "🩺 connect ERROR: ${e.message}", e)
            false
        }
    }

    // ─── Permisos ────────────────────────────────────────────────────────────

    private suspend fun hasPermissions(): Boolean {
        val s = store ?: run {
            Log.w(TAG, "hasPermissions: store null, llama connect() primero")
            return false
        }
        if (sleepPermissions.isEmpty()) return false
        return try {
            val granted = awaitFuture(s.getGrantedPermissionsAsync(sleepPermissions))
            val has = granted.containsAll(sleepPermissions)
            Log.d(TAG, "🩺 hasPermissions=$has")
            has
        } catch (e: Exception) {
            Log.e(TAG, "🩺 hasPermissions ERROR: ${e.message}", e)
            false
        }
    }

    private suspend fun requestPermissions(): Boolean {
        val s = store ?: run {
            Log.w(TAG, "requestPermissions: store null, llama connect() primero")
            return false
        }
        if (sleepPermissions.isEmpty()) return false
        return try {
            val granted = awaitFuture(s.requestPermissionsAsync(sleepPermissions, activity))
            val has = granted.containsAll(sleepPermissions)
            Log.d(TAG, "🩺 requestPermissions → $has")
            has
        } catch (e: Exception) {
            Log.e(TAG, "🩺 requestPermissions ERROR: ${e.message}", e)
            false
        }
    }

    // ─── Lectura de sueño ────────────────────────────────────────────────────

    private suspend fun readSleep(startMs: Long, endMs: Long): List<Map<String, Any>> {
        val s = store ?: run {
            Log.w(TAG, "readSleep: store null, llama connect() primero")
            return emptyList()
        }

        val startInstant = Instant.ofEpochMilli(startMs)
        val endInstant   = Instant.ofEpochMilli(endMs)
        Log.d(TAG, "🩺 readSleep $startInstant → $endInstant")

        return try {
            // InstantTimeFilter.since() = único factory cuyo nombre JVM sobrevive R8.
            val timeFilter = InstantTimeFilter.since(startInstant)
            val request    = DataTypes.SLEEP.readDataRequestBuilder
                .setInstantTimeFilter(timeFilter)
                .build()

            val response = awaitFuture(s.readDataAsync(request))
            val sessions = mutableListOf<Map<String, Any>>()

            for (dataPoint in response.dataList) {
                val pStartMs = dataPoint.startTime?.toEpochMilli() ?: continue
                val pEndMs   = dataPoint.endTime?.toEpochMilli()   ?: continue
                if (pStartMs >= endInstant.toEpochMilli()) continue
                val durationMin = ((pEndMs - pStartMs) / 60_000L).toInt()
                if (durationMin < 30) continue
                Log.d(TAG, "🩺 sesión: ${durationMin}min")
                sessions += mapOf(
                    "startMs"     to pStartMs,
                    "endMs"       to pEndMs,
                    "durationMin" to durationMin,
                )
            }

            Log.d(TAG, "🩺 readSleep: ${sessions.size} sesiones encontradas")
            sessions
        } catch (e: Exception) {
            Log.e(TAG, "🩺 readSleep ERROR: ${e.message}", e)
            emptyList()
        }
    }

    // ─── AsyncSingleFuture → suspend ─────────────────────────────────────────

    private suspend fun <T> awaitFuture(future: AsyncSingleFuture<T>): T =
        suspendCoroutine { cont ->
            future.setCallback(
                executor,
                Consumer { value: T        -> cont.resume(value) },
                Consumer { err: Throwable  -> cont.resumeWithException(err) },
            )
        }
}
