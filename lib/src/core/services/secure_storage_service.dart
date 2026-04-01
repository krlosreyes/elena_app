import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// 🔐 SECURE STORAGE SERVICE
/// 
/// Encapsula todas las operaciones de almacenamiento seguro de credenciales.
/// Reemplaza completamente el almacenamiento en memoria de contraseñas y tokens.
/// 
/// FIPS 140-2 compliant en iOS (Keychain)
/// Android: Encriptación AES-256 via EncryptedSharedPreferences
class SecureStorageService {
  static const _instance = FlutterSecureStorage();

  /// Keys de almacenamiento
  static const String _keyAuthToken = 'auth_token';
  static const String _keyRefreshToken = 'refresh_token';
  static const String _keyUserEmail = 'user_email';
  static const String _keyUserUID = 'user_uid';
  static const String _keySessionExpiry = 'session_expiry';

  /// ✅ TASK 1.2.1: Guardar token de autenticación de forma segura
  Future<void> saveAuthToken(String token) async {
    try {
      await _instance.write(
        key: _keyAuthToken,
        value: token,
      );
    } catch (e) {
      throw SecureStorageException('Error guardando auth token: $e');
    }
  }

  /// ✅ TASK 1.2.2: Recuperar token de autenticación
  Future<String?> getAuthToken() async {
    try {
      return await _instance.read(key: _keyAuthToken);
    } catch (e) {
      throw SecureStorageException('Error recuperando auth token: $e');
    }
  }

  /// ✅ TASK 1.2.3: Guardar refresh token
  Future<void> saveRefreshToken(String token) async {
    try {
      await _instance.write(
        key: _keyRefreshToken,
        value: token,
      );
    } catch (e) {
      throw SecureStorageException('Error guardando refresh token: $e');
    }
  }

  /// ✅ TASK 1.2.4: Recuperar refresh token
  Future<String?> getRefreshToken() async {
    try {
      return await _instance.read(key: _keyRefreshToken);
    } catch (e) {
      throw SecureStorageException('Error recuperando refresh token: $e');
    }
  }

  /// ✅ TASK 1.2.5: Guardar información de usuario (no sensible)
  Future<void> saveUserInfo({
    required String email,
    required String uid,
  }) async {
    try {
      await Future.wait([
        _instance.write(
          key: _keyUserEmail,
          value: email,
        ),
        _instance.write(
          key: _keyUserUID,
          value: uid,
        ),
      ]);
    } catch (e) {
      throw SecureStorageException('Error guardando info de usuario: $e');
    }
  }

  /// ✅ TASK 1.2.6: Recuperar email de usuario
  Future<String?> getUserEmail() async {
    try {
      return await _instance.read(key: _keyUserEmail);
    } catch (e) {
      throw SecureStorageException('Error recuperando email: $e');
    }
  }

  /// ✅ TASK 1.2.7: Recuperar UID de usuario
  Future<String?> getUserUID() async {
    try {
      return await _instance.read(key: _keyUserUID);
    } catch (e) {
      throw SecureStorageException('Error recuperando UID: $e');
    }
  }

  /// ✅ TASK 1.2.8: Guardar tiempo de expiración de sesión
  Future<void> saveSessionExpiry(DateTime expiry) async {
    try {
      await _instance.write(
        key: _keySessionExpiry,
        value: expiry.toIso8601String(),
      );
    } catch (e) {
      throw SecureStorageException('Error guardando expiry: $e');
    }
  }

  /// ✅ TASK 1.2.9: Recuperar y validar tiempo de expiración
  Future<bool> isSessionValid() async {
    try {
      final expiryStr = await _instance.read(key: _keySessionExpiry);

      if (expiryStr == null) return false;

      final expiry = DateTime.parse(expiryStr);
      return DateTime.now().isBefore(expiry);
    } catch (e) {
      return false;
    }
  }

  /// ✅ TASK 1.2.10: LIMPIAR TODAS LAS CREDENCIALES (Logout)
  /// 
  /// ⚠️ CRÍTICO: Ejecutar siempre en logout para eliminar datos de usuario
  /// Esto previene que otro usuario en el mismo dispositivo acceda a datos previos
  Future<void> clearAll() async {
    try {
      await _instance.deleteAll();
    } catch (e) {
      throw SecureStorageException('Error limpiando secure storage: $e');
    }
  }

  /// ✅ TASK 1.2.11: Limpiar credencial específica
  Future<void> clearKey(String key) async {
    try {
      await _instance.delete(key: key);
    } catch (e) {
      throw SecureStorageException('Error limpiando clave: $e');
    }
  }

}

/// 🚨 EXCEPTION PERSONALIZADA
class SecureStorageException implements Exception {
  final String message;

  SecureStorageException(this.message);

  @override
  String toString() => 'SecureStorageException: $message';
}
