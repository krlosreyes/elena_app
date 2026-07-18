# REL-02 (auditoría pre-producción 2026-07-11): reglas mínimas de keep para
# habilitar R8/ProGuard en el build de release sin romper SDKs que dependen
# de reflection/serialización (Firebase, RevenueCat, el AAR crudo de Samsung
# Health). El código Dart (libapp.so) NO pasa por R8 — estas reglas solo
# protegen el lado Kotlin/Java del APK/AAB.
#
# Antes de un release comercial: generar un AAB con estas reglas y correr un
# smoke test completo (login, HealthKit/Health Connect sync, compra sandbox
# de RevenueCat) para confirmar que nada quedó eliminado por error. Si algo
# falla solo en release (y no en debug), es casi siempre una regla de keep
# faltante — revisar mapping.txt (Play Console > App Bundle Explorer >
# Downloads > "Descargar reglas de ofuscación") para identificar la clase.

# ─── Firebase (Firestore, Auth, Crashlytics, Analytics, App Check) ──────────
# Firebase ya publica sus propias consumer-rules.pro dentro de cada AAR, que
# Gradle mergea automáticamente. Estas reglas son un refuerzo defensivo por
# si alguna versión del BoM no las trae completas.
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Crashlytics necesita los nombres de archivo/línea para simbolizar stack
# traces correctamente.
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception

# ─── RevenueCat (purchases_flutter / purchases_android) ─────────────────────
-keep class com.revenuecat.purchases.** { *; }
-dontwarn com.revenuecat.purchases.**

# ─── Samsung Health Data SDK (AAR crudo, SPEC-239) ──────────────────────────
# Sin consumer-rules.pro propio (es un .aar local en android/app/libs/) — sin
# keep explícito, R8 puede eliminar/renombrar clases que el SDK resuelve por
# reflection internamente, rompiendo la sincronización de sueño en Android
# release sin ningún error visible en debug.
-keep class com.samsung.android.sdk.health.** { *; }
-dontwarn com.samsung.android.sdk.health.**

# ─── health / Health Connect (androidx.health.connect) ──────────────────────
-keep class androidx.health.connect.** { *; }
-dontwarn androidx.health.connect.**

# ─── kotlinx-coroutines (bridge de SamsungHealthService) ────────────────────
-dontwarn kotlinx.coroutines.**

# ─── Kotlin metadata / reflection general ───────────────────────────────────
-keepattributes *Annotation*, InnerClasses, Signature, EnclosingMethod
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
