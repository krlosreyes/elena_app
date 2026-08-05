// SPEC-264 (fase 2): push remoto (FCM) para los zumbidos de Retos.
//
// El zumbido lo envía una Cloud Function (functions/src/index.ts,
// onNudgeCreated) al token FCM del rival. Este servicio, del lado de la app,
// se encarga de: pedir permiso, obtener/renovar el token y guardarlo en
// `users/{uid}/fcm_tokens/{token}`. La Function lee esos tokens y despacha.
//
// Foreground: cuando la app está abierta, el "buzz" in-app (nudge_buzz.dart)
// ya llama la atención en la pantalla del reto, así que aquí NO duplicamos un
// banner en primer plano. El valor de FCM es despertar la app en background o
// cerrada — eso lo muestra el SO automáticamente desde el payload `notification`.
//
// iOS: requiere APNs configurado (certificado/clave en Apple Developer + subido
// a Firebase). Sin eso, en iOS no se entregan pushes; Android funciona apenas
// se despliega la Function. Ver docs/SPEC-264_Perlas_Anillos_Zumbidos.md.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import 'package:elena_app/src/core/services/app_logger.dart';

/// Handler de mensajes en segundo plano. Debe ser una función top-level con
/// `@pragma('vm:entry-point')` (se ejecuta en un isolate propio). Los pushes
/// con payload `notification` los muestra el SO solo; no hace falta más.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No-op: la notificación la renderiza el sistema. Existe para cumplir el
  // contrato de onBackgroundMessage.
}

class PushMessagingService {
  PushMessagingService._();

  static String? _lastUid;
  static bool _initialized = false;

  /// Se llama una vez en el arranque. Registra el handler de background y
  /// engancha el ciclo de sesión para (des)registrar el token del usuario.
  static Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // Cuando cambia la sesión, (re)registramos o limpiamos el token.
      FirebaseAuth.instance.idTokenChanges().listen((user) {
        if (user == null) {
          _lastUid = null;
          return;
        }
        if (user.uid == _lastUid) return;
        _lastUid = user.uid;
        // Best-effort: nunca bloquea ni rompe el arranque de sesión.
        _registerToken(user.uid);
      });

      // Token renovado por el SO: reescribir para el usuario actual.
      FirebaseMessaging.instance.onTokenRefresh.listen((token) {
        final uid = _lastUid;
        if (uid != null) _saveToken(uid, token);
      });
    } catch (e, s) {
      AppLogger.error('PushMessagingService.init falló', e, s);
    }
  }

  static Future<void> _registerToken(String uid) async {
    try {
      // Pide permiso (iOS y Android 13+). Idempotente.
      await FirebaseMessaging.instance.requestPermission();
      // En Apple, esperar el token APNs evita un getToken nulo temprano.
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveToken(uid, token);
      }
    } catch (e, s) {
      AppLogger.error('PushMessagingService.register falló', e, s);
    }
  }

  static Future<void> _saveToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fcm_tokens')
          .doc(token)
          .set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e, s) {
      AppLogger.error('PushMessagingService.saveToken falló', e, s);
    }
  }
}
