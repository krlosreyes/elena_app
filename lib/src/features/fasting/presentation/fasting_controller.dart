import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../authentication/application/auth_controller.dart';
import '../../progress/domain/measurement_log.dart';
import '../../../core/services/notification_service.dart';
import '../data/fasting_repository.dart';
import '../domain/fasting_session.dart';
import '../../imx/application/imx_provider.dart';

// Estado del Ayuno
class FastingState {
  final DateTime? startTime;
  final Duration elapsed;
  final int plannedHours;
  final bool isFasting;
  final double progress;

  FastingState({
    required this.startTime,
    required this.elapsed,
    required this.plannedHours,
    required this.isFasting,
    required this.progress,
  });

  factory FastingState.initial() {
    return FastingState(
      startTime: null,
      elapsed: Duration.zero,
      plannedHours: 16, // Default
      isFasting: false,
      progress: 0.0,
    );
  }

  FastingState copyWith({
    DateTime? startTime,
    Duration? elapsed,
    int? plannedHours,
    bool? isFasting,
    double? progress,
  }) {
    return FastingState(
      startTime: startTime ?? this.startTime,
      elapsed: elapsed ?? this.elapsed,
      plannedHours: plannedHours ?? this.plannedHours,
      isFasting: isFasting ?? this.isFasting,
      progress: progress ?? this.progress,
    );
  }
}

class FastingController extends AutoDisposeNotifier<AsyncValue<FastingState>> {
  static const String _keyStartTime = 'fasting_start_time';
  static const String _keyPlannedHours = 'fasting_planned_hours';
  static const String _keyUserUid = 'fasting_user_uid';

  Timer? _timer;
  StreamSubscription? _firestoreSubscription;

  @override
  AsyncValue<FastingState> build() {
    // Escuchar el estado de autenticación de forma reactiva
    final authState = ref.watch(authStateChangesProvider);
    
    // Cleanup: Cancel timer and stream subscription when AutoDispose fires (Hot Reload, navigate away, etc.)
    ref.onDispose(() {
      _timer?.cancel();
      _firestoreSubscription?.cancel();
    });
    
    // Si la autenticación está cargando, retornamos loading
    if (authState.isLoading) {
       return const AsyncValue.loading();
    }
    
    // Si no hay usuario logueado
    if (authState.value == null) {
      _timer?.cancel();
      _firestoreSubscription?.cancel();
      return AsyncValue.data(FastingState.initial());
    }

    // Inicializar el estado de forma asíncrona pero retornar un dato síncrono inicial (Carga local)
    _loadState(authState.value!.uid);
    return const AsyncValue.loading(); 
  }

  Future<void> _loadState(String currentUid) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // 1. RESTRICCIÓN DE SEGURIDAD: Validar que el local storage coincida con el usuario actual
      final savedUid = prefs.getString(_keyUserUid);
      if (savedUid != null && savedUid != currentUid) {
        print("⚠️ Usuario cambiado. Limpiando estado local de ayuno antiguo.");
        await prefs.remove(_keyStartTime);
        await prefs.remove(_keyPlannedHours);
        await prefs.remove(_keyUserUid);
      } else if (savedUid == null) {
        // Guardar el uid actual en local para futuras verificaciones
        await prefs.setString(_keyUserUid, currentUid);
      }

      final startTimeStr = prefs.getString(_keyStartTime);
      final plannedHours = prefs.getInt(_keyPlannedHours) ?? 16;
      
      // 2. RECUPERAR ESTADO LOCAL (Respuesta inmediata UI)
      if (startTimeStr != null) {
        final startTime = DateTime.parse(startTimeStr);
        final elapsed = DateTime.now().difference(startTime);
        
        state = AsyncValue.data(FastingState(
          startTime: startTime,
          elapsed: elapsed,
          plannedHours: plannedHours,
          isFasting: true,
          progress: _calculateProgress(elapsed, plannedHours),
        ));
        
        _startTicker();
      } else {
        state = AsyncValue.data(FastingState.initial().copyWith(plannedHours: plannedHours));
      }

      // 3. RECUPERAR ACTIVE SESSION DE FIRESTORE (Robustez de multi-dispositivo)
      _syncWithFirestore(currentUid, prefs);

    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void _syncWithFirestore(String uid, SharedPreferences prefs) {
    _firestoreSubscription?.cancel();
    
    final repo = ref.read(fastingRepositoryProvider);
    _firestoreSubscription = repo.getActiveFastStream(uid).listen((activeSession) async {
      final currentState = state.value;
      
      if (activeSession != null) {
         // Only sync from Firestore if:
         // (a) We have no local state OR
         // (b) We are not currently fasting locally
         // (c) Firestore has a NEWER start time (e.g. edited from another device)
         // We do NOT overwrite if local startTime is NEWER than Firestore — that means user
         // made a local manual edit that hasn't been pushed yet.
         if (currentState == null || 
             !currentState.isFasting) {
             
             print("🔄 Sincronizando sesión de ayuno desde Firestore...");
             
             await prefs.setString(_keyStartTime, activeSession.startTime.toIso8601String());
             await prefs.setInt(_keyPlannedHours, activeSession.plannedDurationHours);
             await prefs.setString(_keyUserUid, uid);

             final elapsed = DateTime.now().difference(activeSession.startTime);
             
             state = AsyncValue.data(FastingState(
                startTime: activeSession.startTime,
                elapsed: elapsed,
                plannedHours: activeSession.plannedDurationHours,
                isFasting: true,
                progress: _calculateProgress(elapsed, activeSession.plannedDurationHours),
             ));
             
             _startTicker();
         }
      } else if (currentState != null && currentState.isFasting) {
          // Si Firebase dice que no hay sesión, pero localmente sí (Posible desincronización)
          // Asumimos Firebase como fuente de verdad si la sesión local lleva mucho rato y Firebase la cortó.
          // Para no matar el de un error offline, podríamos ser conservadores.
          // Por ahora, sincronizamos forzadamente borrando local si firebase está vacío, a menos que llevemos offline.
          // Implementación conservadora: Dejar local hasta que intente guardar.
      }
    });
  }

  // 2. Iniciar Ayuno
  Future<void> startFast({DateTime? startTime, required int hours}) async {
    final start = startTime ?? DateTime.now();
    
    // 1. Guardar Persistencia Local
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStartTime, start.toIso8601String());
    await prefs.setInt(_keyPlannedHours, hours);
    
    final uid = ref.read(authControllerProvider.notifier).currentUser?.uid;
    if (uid != null) {
      await prefs.setString(_keyUserUid, uid);
    }

    // 2. Actualizar Estado Inmediatamente (Optimistic UI)
    state = AsyncValue.data(FastingState(
      startTime: start,
      elapsed: Duration.zero,
      plannedHours: hours,
      isFasting: true,
      progress: 0.0,
    ));

    // 3. Programar Notificaciones
    await NotificationService.scheduleFastingNotifications(start, Duration(hours: hours));

    // 4. PERSISTIR EN FIRESTORE (Evitar pérdida de estado)
    if (uid != null) {
      final session = FastingSession(
        uid: uid,
        startTime: start,
        endTime: null, // Aún no termina
        plannedDurationHours: hours,
        isCompleted: false,
      );
      try {
        await ref.read(fastingRepositoryProvider).startFast(uid, session);
        print("✅ Ayuno iniciado sincronizado en Firestore.");
      } catch (e) {
        print("⚠️ Error sincronizando inicio de ayuno: $e");
      }
    }

    // 5. ARRANCAR TICKER
    _startTicker();
    
    print("✅ Ayuno iniciado: $start para $hours horas.");
  }

  // 3. Terminar Ayuno
  Future<void> stopFast() async {
    print("🛑 Deteniendo ayuno...");
    
    // 1. Detener Timer
    _timer?.cancel();
    
    // 2. Cancelar Notificaciones
    await NotificationService.cancelAll();
    
    final currentState = state.value;
    if (currentState == null || !currentState.isFasting || currentState.startTime == null) {
        print("⚠️ No se puede detener: Estado inválido o no activo.");
        return;
    }

    final endTime = DateTime.now();
    final uid = ref.read(authControllerProvider.notifier).currentUser?.uid;

    // 3. Guardar en Repositorio (Firestore)
    if (uid != null) {
      final elapsedMinutes = endTime.difference(currentState.startTime!).inMinutes;
      final plannedMinutes = currentState.plannedHours * 60;
      final isSuccess = elapsedMinutes >= (plannedMinutes - 15);

      final session = FastingSession(
        uid: uid,
        startTime: currentState.startTime!,
        endTime: endTime,
        plannedDurationHours: currentState.plannedHours,
        isCompleted: isSuccess,
      );

      try {
        final repo = ref.read(fastingRepositoryProvider);
        await repo.saveCompletedFast(uid, session);
        
        // TODO: Re-calcular IMX a través de un orquestador global
        // Escuchando los eventos de ayuno para no acoplar la logica aquí
      } catch (e) {
        print("❌ Error crítico guardando ayuno: $e");
        // Aún así continuamos para limpiar la UI
      }
    }

    // 4. Limpiar Local Storage
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStartTime);
    await prefs.remove(_keyUserUid);

    // 5. FORZAR RESETEO DE UI
    state = AsyncValue.data(FastingState.initial().copyWith(
        plannedHours: currentState.plannedHours // Mantener visualmente la meta anterior
    ));
    
    print("✅ Ayuno detenido y UI reseteada.");
  }

  // 3.5 Terminar Ayuno con Fecha Manual (Retroactivo)
  Future<void> saveManualFast(DateTime startTime, DateTime endTime) async {
    print("💾 Guardando ayuno manual: $startTime -> $endTime");

    _timer?.cancel();
    await NotificationService.cancelAll();

    final uid = ref.read(authControllerProvider.notifier).currentUser?.uid;
    if (uid != null) {
      // Calcular duración real
      final duration = endTime.difference(startTime);
      final elapsedMinutes = duration.inMinutes;

      // Recuperar meta del estado actual o usar default
      final plannedHours = state.value?.plannedHours ?? 16;
      final plannedMinutes = plannedHours * 60;
      
      // Validar éxito (con margen de 15 min)
      final isSuccess = elapsedMinutes >= (plannedMinutes - 15);

      final session = FastingSession(
        uid: uid,
        startTime: startTime,
        endTime: endTime,
        plannedDurationHours: plannedHours,
        isCompleted: isSuccess,
      );

      try {
        final repo = ref.read(fastingRepositoryProvider);
        await repo.saveCompletedFast(uid, session);
      } catch (e) {
        print("❌ Error guardando manual: $e");
      }
    }

    // Limpiar y Resetear UI
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStartTime);
    await prefs.remove(_keyUserUid);

    state = AsyncValue.data(FastingState.initial().copyWith(
        plannedHours: state.value?.plannedHours ?? 16
    ));
  }

  // 4. Timer Interno (Ticker)
  void _startTicker() {
    _timer?.cancel(); // Siempre cancelar el anterior
    
    // Ejecutar inmediatamente para no esperar 1 segundo
    _updateTickerLogic();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateTickerLogic();
    });
  }
  
  void _updateTickerLogic() {
      // El mounted base ya no existe en AutoDisposeNotifier. 
      // Si llegamos aquí y el provider fue descartado, ref lanzará StateError al intentar acceder, pero eso es manejado por Riverpod.
      
      final currentState = state.value;
      if (currentState == null || !currentState.isFasting || currentState.startTime == null) {
          _timer?.cancel();
          return;
      }
      
      // Calcular nueva duración
      final now = DateTime.now();
      final newElapsed = now.difference(currentState.startTime!);
      
      // Actualizar estado (Copia eficiente)
      state = AsyncValue.data(currentState.copyWith(
          elapsed: newElapsed,
          progress: _calculateProgress(newElapsed, currentState.plannedHours)
      ));
  }

  double _calculateProgress(Duration elapsed, int plannedHours) {
    if (plannedHours <= 0) return 0.0;
    return elapsed.inSeconds / (plannedHours * 3600);
  }

  // 5. Actualizar Hora de Inicio (Edición Manual)
  Future<void> updateStartTime(DateTime newStartTime) async {
    final currentState = state.value;
    if (currentState == null || !currentState.isFasting) return;
    
    // 1. Guardar Persistencia LOCAL
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStartTime, newStartTime.toIso8601String());
    
    // 2. Recalcular Estado Inmediato
    final now = DateTime.now();
    final elapsed = now.difference(newStartTime);
    
    // Actualizamos el estado para que la UI reaccione instantáneamente
    state = AsyncValue.data(currentState.copyWith(
      startTime: newStartTime,
      elapsed: elapsed,
      progress: _calculateProgress(elapsed, currentState.plannedHours),
    ));
    
    // 3. Reiniciar ticker para asegurar consistencia
    _startTicker();
    
    // 4. Reprogramar notificaciones
    await NotificationService.scheduleFastingNotifications(
        newStartTime, Duration(hours: currentState.plannedHours));

    // 5. PERSISTIR EN FIRESTORE (Fuente de Verdad para Multi-Dispositivo y Hot Reload)
    final uid = ref.read(authControllerProvider.notifier).currentUser?.uid;
    if (uid != null) {
      await ref.read(fastingRepositoryProvider).updateActiveFastStartTime(uid, newStartTime);
    }
        
    print("✏️ Hora de inicio actualizada a: $newStartTime");
  }

  // 6. Cambiar Protocolo
  Future<void> setProtocol(String protocolString) async {
    final parts = protocolString.split('/');
    if (parts.isEmpty) return;
    
    final int newHours = int.tryParse(parts[0]) ?? 16;
    
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(
        plannedHours: newHours,
        progress: _calculateProgress(currentState.elapsed, newHours)
      ));

      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyPlannedHours, newHours);
      
      final uid = ref.read(authControllerProvider.notifier).currentUser?.uid;
      if (uid != null) {
          try {
            await ref.read(fastingRepositoryProvider).updateProtocol(uid, protocolString);
          } catch (e) {
            print("Error update protocol: $e");
          }
      }

      if (currentState.isFasting && currentState.startTime != null) {
        await NotificationService.scheduleFastingNotifications(
            currentState.startTime!, Duration(hours: newHours));
      }
    }
  }

}

final fastingControllerProvider = AutoDisposeNotifierProvider<FastingController, AsyncValue<FastingState>>(FastingController.new);

