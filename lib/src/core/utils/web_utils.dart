import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// ✅ UTILIDAD DE SEGURIDAD PARA WEB:
/// Maneja excepciones de autenticación asegurando que el Future solo se complete una vez.
/// Esto previene el error "Bad state: Future already completed" que ocurre a veces
/// en el bridge de Flutter Web con Firebase.
Future<AsyncValue<T>> guardAuthExceptions<T>(
    Future<T> Function() action) async {
  final completer = Completer<AsyncValue<T>>();

  try {
    final result = await action();
    if (!completer.isCompleted) {
      completer.complete(AsyncValue.data(result));
    }
  } catch (e, st) {
    if (!completer.isCompleted) {
      debugPrint('WebAuthGuard: Error capturado -> $e');
      completer.complete(AsyncValue.error(e, st));
    } else {
      debugPrint(
          'WebAuthGuard: Se intentó completar un Future ya resuelto (Redundancia mitigada).');
    }
  }

  return completer.future;
}
