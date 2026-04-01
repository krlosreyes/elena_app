import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'secure_storage_service.dart';

part 'secure_storage_provider.g.dart';

/// 🔐 Riverpod Provider para SecureStorageService
///
/// Proporciona acceso singleton a SecureStorageService en toda la app.
/// Mantiene la instancia durante todo el ciclo de vida de la app.
@riverpod
SecureStorageService secureStorage(SecureStorageRef ref) {
  return SecureStorageService();
}
