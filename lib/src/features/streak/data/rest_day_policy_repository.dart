// Persistencia de la política de descanso planificado (2026-07-28).
//
// Schema: users/{uid}/streak_meta/rest_policy — documento único, mismo
// patrón que `exercise_meta/profile` (ver exercise_profile_repository_impl.dart)
// y por la misma razón: aislarlo del doc raíz `users/{uid}` para no
// competir por escrituras concurrentes con los mappers que escriben el
// UserModel completo.
//
// NO se guarda en ExerciseProfile pese a que ahí ya vive un concepto de
// descanso (`availableWeekdays`, del que el motor infiere el 7mo día como
// descanso de entrenamiento). Son dos cosas distintas y mezclarlas
// costaría caro: el descanso de ejercicio dice "hoy no entrenas", el de
// la racha dice "hoy no se te exige el protocolo completo". Un usuario
// puede perfectamente querer su descanso de racha un sábado y su descanso
// de entrenamiento un lunes. La pantalla de ajustes SÍ ofrece
// sincronizarlos como sugerencia, pero el dato es independiente.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/streak/domain/rest_day_policy.dart';

abstract class RestDayPolicyRepository {
  Future<void> save(String userId, RestDayPolicy policy);
  Future<RestDayPolicy> fetch(String userId);
  Stream<RestDayPolicy> watch(String userId);
}

class RestDayPolicyRepositoryImpl implements RestDayPolicyRepository {
  final FirebaseFirestore _firestore;

  RestDayPolicyRepositoryImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  DocumentReference<Map<String, dynamic>> _doc(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('streak_meta')
      .doc('rest_policy');

  @override
  Future<void> save(String userId, RestDayPolicy policy) async {
    // Sin `await` sobre el write: patrón offline-first del proyecto (ver
    // feedback_offline_first_pattern) — el SDK encola y reintenta, y la UI
    // no se queda esperando a la red para confirmar una preferencia.
    unawaited(
      _doc(userId).set(policy.toMap(), SetOptions(merge: true)),
    );
  }

  @override
  Future<RestDayPolicy> fetch(String userId) async {
    final snap = await _doc(userId).get();
    final data = snap.data();
    if (data == null) return RestDayPolicy.disabled;
    return RestDayPolicy.fromMap(data);
  }

  @override
  Stream<RestDayPolicy> watch(String userId) {
    return _doc(userId).snapshots().map((snap) {
      final data = snap.data();
      if (data == null) return RestDayPolicy.disabled;
      return RestDayPolicy.fromMap(data);
    });
  }
}

final restDayPolicyRepositoryProvider =
    Provider<RestDayPolicyRepository>((ref) {
  return RestDayPolicyRepositoryImpl();
});

/// Política vigente del usuario autenticado. `RestDayPolicy.disabled`
/// mientras no haya sesión o no exista el documento — el descanso es
/// opt-in y no debe aparecer solo.
///
/// Mismo patrón que `exerciseProfileStreamProvider`: sin StateNotifier
/// propio, porque esto se escribe al elegir el día y ocasionalmente al
/// mover un descanso — no necesita estado optimista.
///
/// SIN `autoDispose`, a diferencia de `exerciseProfileStreamProvider`:
/// `StreakNotifier` lo escucha durante toda la sesión para recalcular la
/// racha visible. Con autoDispose el provider moriría al salir de la
/// pantalla de ajustes y la racha volvería a leerse sin política hasta el
/// siguiente registro de un pilar.
final restDayPolicyProvider = StreamProvider<RestDayPolicy>((ref) {
  final account = ref.watch(authStateProvider).value;
  if (account == null || account.uid.isEmpty) {
    return Stream.value(RestDayPolicy.disabled);
  }
  return ref.watch(restDayPolicyRepositoryProvider).watch(account.uid);
});
