package com.metamorfosis.elena.elena_app

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()

FirebaseApp.initializeApp(this)
FirebaseAppCheck.getInstance().installAppCheckProviderFactory(
    PlayIntegrityAppCheckProviderFactory.getInstance()
)