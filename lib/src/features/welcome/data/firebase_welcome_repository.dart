// SPEC-48: implementación Firebase del WelcomeRepository.
//
// Capa data — encapsula TODO el acceso a Firestore + SharedPreferences.
// Es la única ubicación legítima donde se importa `cloud_firestore` para
// el feature welcome. La capa application/presentation consume el contrato
// abstracto `WelcomeRepository`, nunca esta implementación directamente.

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/features/welcome/domain/welcome_repository.dart';

/// Implementación que usa Firestore como fuente de verdad y
/// SharedPreferences como caché local de lectura rápida.
class FirebaseWelcomeRepository implements WelcomeRepository {
  FirebaseWelcomeRepository({
    required FirebaseFirestore firestore,
    required SharedPreferences prefs,
  })  : _firestore = firestore,
        _prefs = prefs;

  final FirebaseFirestore _firestore;
  final SharedPreferences _prefs;

  static String _cacheKey(String userId) => 'has_seen_welcome_$userId';

  @override
  Future<bool> hasSeenWelcome(String userId) async {
    if (userId.isEmpty) return false;

    try {
      // 1. Cache local primero (< 1ms)
      final cached = _prefs.getBool(_cacheKey(userId));
      if (cached != null) return cached;

      // 2. Firestore como fuente de verdad
      final doc =
          await _firestore.collection('users').doc(userId).get();

      if (doc.exists) {
        final hasSeen = (doc.data()?['hasSeenWelcome'] as bool?) ?? false;
        await _prefs.setBool(_cacheKey(userId), hasSeen);
        return hasSeen;
      }
      return false;
    } catch (_) {
      // Sin red: confiar en caché o asumir usuario nuevo.
      return _prefs.getBool(_cacheKey(userId)) ?? false;
    }
  }

  @override
  Future<void> markWelcomeSeen(String userId) async {
    if (userId.isEmpty) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'hasSeenWelcome': true});
      await _prefs.setBool(_cacheKey(userId), true);
    } catch (_) {
      // Si Firestore falla, al menos la caché de la sesión queda marcada.
      await _prefs.setBool(_cacheKey(userId), true);
    }
  }

  @override
  Future<void> resetWelcome(String userId) async {
    if (userId.isEmpty) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .update({'hasSeenWelcome': false});
      await _prefs.remove(_cacheKey(userId));
    } catch (_) {
      // Silent fail.
    }
  }
}

/// Provider del repositorio. La capa application/presentation lo consume
/// vía `ref.watch(welcomeRepositoryProvider)`.
final welcomeRepositoryProvider = Provider<WelcomeRepository>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return FirebaseWelcomeRepository(
    firestore: FirebaseFirestore.instance,
    prefs: prefs,
  );
});
