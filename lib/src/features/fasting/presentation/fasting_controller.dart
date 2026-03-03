import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../authentication/application/auth_controller.dart';
import '../domain/fasting_session.dart';
import '../../../core/services/notification_service.dart';
import '../data/fasting_repository.dart';

// Estado del Ayuno
class FastingState {
  final bool isFasting;
  final Duration elapsed;
  final double progress; // 0.0 a 1.0 (o más si excedió la meta)
  final DateTime? startTime;
  final int plannedHours;

  const FastingState({
    required this.isFasting,
    required this.elapsed,
    required this.progress,
    this.startTime,
    this.plannedHours = 16,
  });

  factory FastingState.initial() {
    return const FastingState(
      isFasting: false,
      elapsed: Duration.zero,
      progress: 0.0,
      plannedHours: 16, // Default safety
    );
  }

  FastingState copyWith({
    bool? isFasting,
    Duration? elapsed,
    double? progress,
    DateTime? startTime,
    int? plannedHours,
  }) {
    return FastingState(
      isFasting: isFasting ?? this.isFasting,
      elapsed: elapsed ?? this.elapsed,
      progress: progress ?? this.progress,
      startTime: startTime ?? this.startTime,
      plannedHours: plannedHours ?? this.plannedHours,
    );
  }
}

// Controller
class FastingController extends StateNotifier<AsyncValue<FastingState>> {
  final Ref ref;
  Timer? _timer;
  static const String _keyStartTime = 'fasting_start_time';
  static const String _keyPlannedHours = 'fasting_planned_hours';
  static const String _keyUserUid = 'fasting_user_uid';

  StreamSubscription? _firestoreSubscription;

  FastingController(this.ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    final uid = ref.read(authControllerProvider.notifier).currentUser?.uid;
    if (uid != null) {
      // SUSCRIBIRSE al Stream de Firestore para sincronización en tiempo real
      _firestoreSubscription = ref
          .read(fastingRepositoryProvider)
          .getActiveFastStream(uid)
          .listen((activeFast) {
            
        if (activeFast != null) {
          // CASO 1: Hay un ayuno activo en DB
          final now = DateTime.now();
          final elapsed = now.difference(activeFast.startTime);
          
          state = AsyncValue.data(FastingState(
            isFasting: true,
            elapsed: elapsed,
            progress: _calculateProgress(elapsed, activeFast.plannedDurationHours),
            startTime: activeFast.startTime,
            plannedHours: activeFast.plannedDurationHours,
          ));
          _startTicker(); // Asegurar que el reloj corra
          
        } else {
          // CASO 2: No hay ayuno activo (o se canceló remotamente)
          // Solo reseteamos si LOCALMENTE creíamos que había uno
          if (state.value?.isFasting == true) {
             _timer?.cancel();
             state = AsyncValue.data(FastingState.initial());
          } else if (state.isLoading) {
             // Primera carga, sin ayuno
             state = AsyncValue.data(FastingState.initial());
          }
        }
      }, onError: (err) {
        print("Error en stream de ayuno: $err");
        // Fallback a lógica local si falla la red? 
        // Por ahora solo logueamos.
      });
    } else {
      // Sin usuario logueado, usar estado inicial
      state = AsyncValue.data(FastingState.initial());
    }
  }

  // 2. Iniciar Ayuno
  Future<void> startFast({DateTime? startTime, int hours = 16}) async {
    // Cancelar timer previo por seguridad
    _timer?.cancel();
    
    final now = DateTime.now();
    // Usar la fecha proporcionada o NOW si es nulo
    final start = startTime ?? now;

    // 1. Guardar Persistencia Local INMEDIATA
    final prefs = await SharedPreferences.getInstance();
    final uid = ref.read(authControllerProvider.notifier).currentUser?.uid;
    
    await prefs.setString(_keyStartTime, start.toIso8601String());
    await prefs.setInt(_keyPlannedHours, hours);
    if (uid != null) {
      await prefs.setString(_keyUserUid, uid);
    }

    // 2. Establecer Estado Activo
    state = AsyncValue.data(FastingState(
      isFasting: true,
      elapsed: Duration.zero, // El ticker lo corregirá inmediatamente
      progress: 0.0,
      startTime: start,
      plannedHours: hours,
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
      } catch (e) {
        print("❌ Error crítico guardando ayuno: $e");
        // Aún así continuamos para limpiar la UI
      }
    }

    // 4. Limpiar Local Storage (Rest of the method...)
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStartTime);
    await prefs.remove(_keyUserUid);
    // await prefs.remove(_keyPlannedHours); // Dejamos las horas para la UX de recordatorio

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

  // ... (Rest of methods _startTicker, _updateTickerLogic, updateStartTime, _calculateProgress, setProtocol, dispose) ...
  // Re-pasting them to ensure no code loss during replacement if large block needed. 
  // Actually, I can just target the specific blocks or the end of file.
  // The user instruction implies updating the provider too.

  // 4. Timer Interno (Ticker) - Lógica Revisada
  void _startTicker() {
    _timer?.cancel(); // Siempre cancelar el anterior
    
    // Ejecutar inmediatamente para no esperar 1 segundo
    _updateTickerLogic();
    
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
        _updateTickerLogic();
    });
  }
  
  void _updateTickerLogic() {
      if (!mounted) {
          _timer?.cancel();
          return;
      }
      
      final currentState = state.value;
      if (currentState == null || !currentState.isFasting || currentState.startTime == null) {
          _timer?.cancel();
          return;
      }
      
      // Calcular nueva duración
      final now = DateTime.now();
      final newElapsed = now.difference(currentState.startTime!);
      
      // Actualizar estado (Copia eficiente)
      // STATE NOTIFIER TRIGGER: Esto reconstruye la UI
      state = AsyncValue.data(currentState.copyWith(
          elapsed: newElapsed,
          progress: _calculateProgress(newElapsed, currentState.plannedHours)
      ));
  }

  // 5. Actualizar Hora de Inicio (Edición Manual)
  Future<void> updateStartTime(DateTime newStartTime) async {
    final currentState = state.value;
    if (currentState == null || !currentState.isFasting) return;
    
    // 1. Guardar Persistencia
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
        
    print("✏️ Hora de inicio actualizada a: $newStartTime");
  }


  double _calculateProgress(Duration elapsed, int plannedHours) {
    if (plannedHours <= 0) return 0.0;
    return elapsed.inSeconds / (plannedHours * 3600);
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
          FirebaseFirestore.instance.collection('users').doc(uid).update({
            'fastingProtocol': protocolString
          }).catchError((e) => print("Error update protocol: $e"));
      }

      if (currentState.isFasting && currentState.startTime != null) {
        await NotificationService.scheduleFastingNotifications(
            currentState.startTime!, Duration(hours: newHours));
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _firestoreSubscription?.cancel();
    super.dispose();
  }
}

final fastingControllerProvider =
    StateNotifierProvider.autoDispose<FastingController, AsyncValue<FastingState>>((ref) {
  // Watch auth state to reset controller when user changes
  ref.watch(authStateChangesProvider);
  return FastingController(ref);
});

