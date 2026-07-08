// SPEC-118: fixtures compartidos para los tests E2E de ayuno.
//
// Helpers mínimos para los tests del Grupo C. Si futuros tests
// necesitan stubs de `AppAccount` o `UserModel`, agregarlos aquí
// para no duplicar entre archivos.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';

/// Inserta un intervalo de ayuno en el fake Firestore. Si `endTime`
/// es null, queda como ayuno abierto (activo).
Future<DocumentReference<Map<String, dynamic>>> seedFastingInterval(
  FakeFirebaseFirestore firestore, {
  required String userId,
  required DateTime startTime,
  DateTime? endTime,
  bool isFasting = true,
}) {
  // SPEC-255 (2026-07-08): el path plano 'fasting_history' quedó stale
  // desde la migración SPEC-217 (2026-06-14), que movió el source real a
  // la subcolección users/{uid}/fasting_history. Sembrar en el path viejo
  // hacía que el source real (que ya lee del path nuevo) no encontrara
  // nada — 12 tests fallaban con "No hay intervalo abierto"/null pese a
  // que la lógica de negocio era correcta.
  return firestore
      .collection('users')
      .doc(userId)
      .collection('fasting_history')
      .add({
    'userId': userId,
    'startTime': Timestamp.fromDate(startTime),
    'endTime': endTime == null ? null : Timestamp.fromDate(endTime),
    'isFasting': isFasting,
  });
}

/// Comparación de día calendario (ignora hora).
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
