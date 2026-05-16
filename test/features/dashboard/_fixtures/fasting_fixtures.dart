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
  return firestore.collection('fasting_history').add({
    'userId': userId,
    'startTime': Timestamp.fromDate(startTime),
    'endTime': endTime == null ? null : Timestamp.fromDate(endTime),
    'isFasting': isFasting,
  });
}

/// Comparación de día calendario (ignora hora).
bool isSameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;
