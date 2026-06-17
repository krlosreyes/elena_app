// SPEC-239: wrapper Dart para el MethodChannel de Samsung Health Data SDK.
//
// Propósito: leer sueño directamente de Samsung Health cuando Health Connect
// devuelve 0 sesiones (caso típico: usuario no-Samsung con Galaxy Watch).
//
// Solo disponible en Android. En iOS y Web siempre devuelve lista vacía.

import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

import 'package:elena_app/src/core/services/app_logger.dart';

class SamsungSleepSession {
  final DateTime start;
  final DateTime end;
  final int durationMinutes;

  const SamsungSleepSession({
    required this.start,
    required this.end,
    required this.durationMinutes,
  });
}

class SamsungHealthService {
  static const _channel = MethodChannel(
    'com.metamorfosisreal.elena/samsung_health',
  );

  bool get _isAndroid => !kIsWeb && Platform.isAndroid;

  // ─── API pública ─────────────────────────────────────────────────

  /// Verifica si Samsung Health está instalado en el dispositivo.
  Future<bool> isAvailable() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('isSamsungHealthAvailable') ?? false;
    } catch (e) {
      AppLogger.debug('SamsungHealth.isAvailable falló: $e');
      return false;
    }
  }

  /// Conecta con Samsung Health. Debe llamarse antes de cualquier operación.
  /// Retorna true si la conexión fue exitosa.
  Future<bool> connect() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('connect') ?? false;
    } catch (e) {
      AppLogger.debug('SamsungHealth.connect falló: $e');
      return false;
    }
  }

  /// Verifica si ya tenemos permiso de lectura de sueño.
  Future<bool> hasPermissions() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('hasPermissions') ?? false;
    } catch (e) {
      AppLogger.debug('SamsungHealth.hasPermissions falló: $e');
      return false;
    }
  }

  /// Solicita permiso de lectura de sueño al usuario.
  /// Muestra el diálogo nativo de Samsung Health.
  /// Retorna true si el permiso fue concedido.
  Future<bool> requestPermissions() async {
    if (!_isAndroid) return false;
    try {
      return await _channel.invokeMethod<bool>('requestPermissions') ?? false;
    } catch (e) {
      AppLogger.debug('SamsungHealth.requestPermissions falló: $e');
      return false;
    }
  }

  /// Lee sesiones de sueño en el rango [start, end].
  /// Solo sesiones ≥ 30 min son relevantes (filtramos ruido en Kotlin
  /// via durationMin, pero el filtro final lo hace el import service).
  Future<List<SamsungSleepSession>> readSleep({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!_isAndroid) return [];
    try {
      final raw = await _channel.invokeMethod<List<dynamic>>('readSleep', {
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      });
      if (raw == null || raw.isEmpty) return [];

      return raw.map((item) {
        final map = Map<String, dynamic>.from(item as Map);
        return SamsungSleepSession(
          start: DateTime.fromMillisecondsSinceEpoch(
            (map['startMs'] as num).toInt(),
          ),
          end: DateTime.fromMillisecondsSinceEpoch(
            (map['endMs'] as num).toInt(),
          ),
          durationMinutes: (map['durationMin'] as num).toInt(),
        );
      }).toList();
    } on PlatformException catch (e) {
      AppLogger.warning('SamsungHealth.readSleep error: ${e.code} ${e.message}');
      return [];
    } catch (e) {
      AppLogger.debug('SamsungHealth.readSleep falló: $e');
      return [];
    }
  }

  /// Flujo completo: connect → permisos → read.
  /// Retorna lista de sesiones, o [] si Samsung Health no está disponible
  /// o si no hay permisos.
  ///
  /// SPEC-239 BLOQUEADO: requiere Samsung Health Partner App Program aprobado.
  /// El SDK retorna AuthorizationException 2003 ("Could not get policy") hasta
  /// que Samsung registre el package com.metamorfosis.elena.elena_app.
  /// Solicitar en: developer.samsung.com/health/data/process.html
  Future<List<SamsungSleepSession>> fetchSleepIfAvailable({
    required DateTime start,
    required DateTime end,
  }) async {
    if (!_isAndroid) return [];

    // 1. ¿Instalado?
    final available = await isAvailable();
    if (!available) return [];

    // 2. Conectar.
    final connected = await connect();
    if (!connected) return [];

    // 3. Permisos (falla con 2003 hasta tener partnership Samsung).
    var hasPerms = await hasPermissions();
    if (!hasPerms) hasPerms = await requestPermissions();
    if (!hasPerms) return [];

    // 4. Leer.
    return readSleep(start: start, end: end);
  }
}
