import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

// SPEC-224: signing de release. Lee android/key.properties (gitignored).
// Si el archivo no existe (ej. CI sin secretos), cae a null y el build
// de release fallará explícitamente en vez de firmar con debug keys.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.metamorfosis.elena.elena_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlin {
        compilerOptions {
            jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
        }
    }

    kotlinOptions {
        // Suppress Kotlin compiler warnings about deprecated APIs
        freeCompilerArgs = listOf(
            "-Xsuppress-warning=DEPRECATION"
        )
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.metamorfosis.elena.elena_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // SPEC-132: el plugin `health` exige minSdk 26.
        // SPEC-239: Samsung Health Data SDK 1.1.0 exige minSdk 29 (Android 10, 2019).
        // Bump a 29. Impacto: Android 8/9 quedan fuera — cobertura mundial
        // 2026 <3%, en LATAM <4%. Aceptable para el MVP.
        minSdk = 29
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // SPEC-224: firma con la release key real (antes: debug keys).
            signingConfig = signingConfigs.getByName("release")
        }
    }

    lint {
        checkReleaseBuilds = false
    }
}

flutter {
    source = "../.."
}

dependencies {
    //implementation("androidx.multidex:multidex:2.0.1")
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    implementation("com.google.firebase:firebase-appcheck-playintegrity")
    // SPEC-239: Samsung Health Data SDK — lectura directa sin Health Connect.
    implementation(files("libs/samsung-health-data-api-1.1.0.aar"))
    // SPEC-239: kotlinx-coroutines-android para el CoroutineScope del bridge.
    // Normalmente viene como dep transitiva del plugin 'health', pero se declara
    // explícitamente para garantizar disponibilidad.
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.7.3")
}
