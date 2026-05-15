// SPEC-107: helper para clasificar errores de Firestore que ocurren
// durante el logout.
//
// Al cerrar sesión, los listeners de Firestore que aún están activos
// reciben un snapshot final con `permission-denied` porque
// `request.auth` ya se invalidó. Eso NO es un error real — es el
// comportamiento esperado mientras los providers se desuscriben. No
// debe loguearse como warning/error ni reportarse a Crashlytics.
//
// Este helper detecta el caso para que cada notifier pueda degradar
// el log a `debug` cuando aplique.

import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreErrors {
  FirestoreErrors._();

  /// True si el error proviene de Firestore con código
  /// `permission-denied`. Cubre tanto `FirebaseException` tipado como
  /// el caso donde el error llega como string (web SDK a veces).
  static bool isPermissionDenied(Object err) {
    if (err is FirebaseException && err.code == 'permission-denied') {
      return true;
    }
    final s = err.toString().toLowerCase();
    return s.contains('permission-denied') ||
        s.contains('permission_denied');
  }
}
