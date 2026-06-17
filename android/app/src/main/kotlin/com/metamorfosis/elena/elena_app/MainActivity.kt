package com.metamorfosis.elena.elena_app

import android.os.Bundle
import com.google.firebase.FirebaseApp
import com.google.firebase.appcheck.FirebaseAppCheck
import com.google.firebase.appcheck.playintegrity.PlayIntegrityAppCheckProviderFactory
// SPEC-132: el plugin `health` usa registerForActivityResult para pedir
// permisos a Health Connect. Eso requiere FragmentActivity en lugar de
// FlutterActivity (sin FragmentActivity, las callbacks de permisos en
// Android 14+ tiran IllegalStateException). Ver:
// https://pub.dev/packages/health#android-setup
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {

    private lateinit var samsungHealthBridge: SamsungHealthBridge

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        FirebaseApp.initializeApp(this)
        val firebaseAppCheck = FirebaseAppCheck.getInstance()
        firebaseAppCheck.installAppCheckProviderFactory(
            PlayIntegrityAppCheckProviderFactory.getInstance()
        )
    }

    // SPEC-239: registrar el MethodChannel de Samsung Health Data SDK.
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        samsungHealthBridge = SamsungHealthBridge(this)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            SamsungHealthBridge.CHANNEL,
        ).setMethodCallHandler { call, result ->
            samsungHealthBridge.handle(call, result)
        }
    }
}
