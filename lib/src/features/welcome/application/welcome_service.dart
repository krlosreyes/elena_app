// SPEC-20: Guía de Bienvenida Condicional
// Gestiona la bandera que indica si el usuario ya vio el flujo de bienvenida.
//
// CAMBIOS en v2.0:
// - Persiste en Firestore (users/{uid}.hasSeenWelcome) como fuente de verdad
// - SharedPreferences usado como caché local para lecturas rápidas (< 1ms)
// - Firestore es siempre la fuente de verdad para el flag
// - Distinción entre signup (nuevo registro) vs login (usuario existente)
//
// Flujo:
// 1. Signup: hasSeenWelcome = false en Firestore
// 2. Usuario ve guía de bienvenida y la completa/salta
// 3. WelcomeService.markWelcomeSeen() actualiza Firestore + caché local
// 4. Login subsecuentes NO muestran welcome (flag = true en Firestore)
// 5. Reinstalación de app: cache local se limpia pero Firestore persiste

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class WelcomeService {
  const WelcomeService._();

  static String _cacheKey(String userId) => 'has_seen_welcome_$userId';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── API estática (usada en el router sin contexto de Riverpod) ───────────

  /// Lee el flag hasSeenWelcome del usuario desde Firestore (fuente de verdad).
  /// Cachea el resultado en SharedPreferences para evitar reads extra.
  ///
  /// Retorna: true si el usuario ya completó/saltó la guía, false si debe verla.
  static Future<bool> hasSeenWelcome(String userId) async {
    if (userId.isEmpty) return false;

    try {
      // 1. Intentar leer del caché local primero (< 1ms)
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getBool(_cacheKey(userId));
      if (cached != null) {
        return cached;
      }

      // 2. Si no está en caché, leer de Firestore (fuente de verdad)
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        final hasSeenWelcome = (doc.data()?['hasSeenWelcome'] as bool?) ?? false;
        // Actualizar caché local para futuras lecturas
        await prefs.setBool(_cacheKey(userId), hasSeenWelcome);
        return hasSeenWelcome;
      }

      // Si el documento no existe, asumir que no ha visto la guía
      return false;
    } catch (e) {
      // En caso de error de conexión, confiar en caché o default
      try {
        final prefs = await SharedPreferences.getInstance();
        return prefs.getBool(_cacheKey(userId)) ?? false;
      } catch (_) {
        return false;
      }
    }
  }

  /// Marca el flujo de bienvenida como completado para [userId].
  /// Actualiza:
  /// 1. Firestore: hasSeenWelcome = true (fuente de verdad)
  /// 2. SharedPreferences: caché local
  static Future<void> markWelcomeSeen(String userId) async {
    if (userId.isEmpty) return;

    try {
      // 1. Actualizar Firestore (fuente de verdad)
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'hasSeenWelcome': true});

      // 2. Actualizar caché local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_cacheKey(userId), true);
    } catch (e) {
      // Si Firestore falla, al menos actualizar caché para esta sesión
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setBool(_cacheKey(userId), true);
      } catch (_) {
        // Silent fail: la próxima vez que abra la app sincronizará con Firestore
      }
    }
  }

  /// Resetea la bandera de [userId] en Firestore (útil para testing/re-onboarding).
  /// Precaución: solo usar en desarrollo o si sabes lo que haces.
  static Future<void> resetWelcome(String userId) async {
    if (userId.isEmpty) return;

    try {
      // 1. Actualizar Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .update({'hasSeenWelcome': false});

      // 2. Limpiar caché local
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey(userId));
    } catch (e) {
      // Silent fail
    }
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

/// Provider reactivo que lee el flag hasSeenWelcome del usuario desde Firestore.
/// Usado en widgets que necesitan escuchar cambios.
final welcomeSeenProvider = FutureProvider.family<bool, String>((ref, userId) {
  return WelcomeService.hasSeenWelcome(userId);
});
