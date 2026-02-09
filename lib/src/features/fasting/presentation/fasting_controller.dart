import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/fasting_session.dart';
import '../../../core/services/notification_service.dart';

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

  FastingController(this.ref) : super(const AsyncValue.loading()) {
    checkCurrentStatus();
  }

  // 1. Inicialización y Restauración
  Future<void> checkCurrentStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      var safePlannedHours = 16;
      
      // Intentar recuperar desde Firestore si hay usuario
      final uid = ref.read(authRepositoryProvider).currentUser?.uid;
      if (uid != null) {
        try {
          final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
          if (doc.exists && doc.data() != null) {
             final data = doc.data()!;
             if (data.containsKey('fastingProtocol')) {
               final protocol = data['fastingProtocol'] as String;
               final parts = protocol.split('/');
               if (parts.isNotEmpty) {
                 safePlannedHours = int.tryParse(parts[0]) ?? 16;
                 // Actualizar local también para consistencia
                 await prefs.setInt(_keyPlannedHours, safePlannedHours);
               }
             }
          }
        } catch (e) {
          print('Error fetching protocol from Firestore: $e');
        }
      } else {
        // Fallback a local si no hay red/auth
        safePlannedHours = prefs.getInt(_keyPlannedHours) ?? 16;
      }

      final startTimeIso = prefs.getString(_keyStartTime);

      if (startTimeIso != null && startTimeIso.isNotEmpty) {
        // Restaurar ayuno en progreso
        final startTime = DateTime.tryParse(startTimeIso);
        
        if (startTime != null) {
          final now = DateTime.now();
          final elapsed = now.difference(startTime);
          
          state = AsyncValue.data(FastingState(
            isFasting: true,
            elapsed: elapsed,
            progress: _calculateProgress(elapsed, safePlannedHours),
            startTime: startTime,
            plannedHours: safePlannedHours,
          ));
          
          _startTicker();
          return;
        }
      }
      
      // Si no hay fecha de inicio válida, aseguramos estado inicial (NO ayunando)
      state = AsyncValue.data(FastingState.initial().copyWith(plannedHours: safePlannedHours));
      
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // 2. Iniciar Ayuno
  Future<void> startFast({int hours = 16}) async {
    final now = DateTime.now();
    state = AsyncValue.data(FastingState(
      isFasting: true,
      elapsed: Duration.zero,
      progress: 0.0,
      startTime: now,
      plannedHours: hours,
    ));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStartTime, now.toIso8601String());
    await prefs.setInt(_keyPlannedHours, hours);

    // Programar Notificaciones
    await NotificationService.scheduleFastingNotifications(now, Duration(hours: hours));

    _startTicker();
  }

  // 3. Terminar Ayuno
  Future<void> stopFast() async {
    _timer?.cancel();
    
    // Cancelar Notificaciones
    await NotificationService.cancelAll();
    
    final currentState = state.value;
    if (currentState == null || !currentState.isFasting || currentState.startTime == null) return;

    final endTime = DateTime.now();
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;

    if (uid != null) {
      // Calcular si se completó la meta (con 15 min de tolerancia)
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

      // Guardar en Firestore
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('fasting_history')
            .add(session.toJson());
      } catch (e) {
        // Manejar error de conexión o permisos
        print('Error saving fasting session: $e');
      }
    }

    // Limpiar local
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStartTime);
    await prefs.remove(_keyPlannedHours); // Opcional: mantener horas planeadas

    // FORZAR actualización de estado a inicial
    state = AsyncValue.data(FastingState.initial());
  }

  // 5. Actualizar Hora de Inicio
  Future<void> updateStartTime(DateTime newStartTime) async {
    final currentState = state.value;
    if (currentState == null || !currentState.isFasting) return;

    final now = DateTime.now();
    final elapsed = now.difference(newStartTime);
    
    state = AsyncValue.data(currentState.copyWith(
      startTime: newStartTime,
      elapsed: elapsed,
      progress: _calculateProgress(elapsed, currentState.plannedHours),
    ));

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyStartTime, newStartTime.toIso8601String());

    // Reprogramar Notificaciones
    await NotificationService.scheduleFastingNotifications(newStartTime, Duration(hours: currentState.plannedHours));
  }

  // 4. Timer Interno (Ticker)
  void _startTicker() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateState());
  }

  void _updateState() {
    if (!mounted) {
      _timer?.cancel();
      return;
    }

    state.whenData((currentState) {
      if (!currentState.isFasting || currentState.startTime == null) {
        _timer?.cancel();
        return;
      }

      final now = DateTime.now();
      final elapsed = now.difference(currentState.startTime!);

      // Actualizamos estado
      state = AsyncValue.data(currentState.copyWith(
        elapsed: elapsed,
        progress: _calculateProgress(elapsed, currentState.plannedHours),
      ));
    });
  }

  double _calculateProgress(Duration elapsed, int plannedHours) {
    return elapsed.inSeconds / (plannedHours * 3600);
  }

  // 6. Cambiar Protocolo (Ej: "16/8", "18/6")
  Future<void> setProtocol(String protocolString) async {
    // Extraer horas de ayuno (primer número antes del '/')
    final parts = protocolString.split('/');
    if (parts.isEmpty) return;
    
    final int newHours = int.tryParse(parts[0]) ?? 16;
    
    // Actualizar estado local
    final currentState = state.value;
    if (currentState != null) {
      state = AsyncValue.data(currentState.copyWith(
        plannedHours: newHours,
        // Recalcular progreso con nueva meta
        progress: _calculateProgress(currentState.elapsed, newHours)
      ));

      // Persistir Local
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyPlannedHours, newHours);
      
      // Persistir en Firestore
      final uid = ref.read(authRepositoryProvider).currentUser?.uid;
      if (uid != null) {
          try {
            await FirebaseFirestore.instance.collection('users').doc(uid).update({
              'fastingProtocol': protocolString
            });
          } catch (e) {
             print('Error updating protocol in Firestore: $e');
          }
      }

      // Reprogramar notificaciones con nueva meta
      if (currentState.isFasting && currentState.startTime != null) {
        await NotificationService.scheduleFastingNotifications(
            currentState.startTime!, Duration(hours: newHours));
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final fastingControllerProvider =
    StateNotifierProvider<FastingController, AsyncValue<FastingState>>((ref) {
  // Watch auth state to reset controller when user changes
  ref.watch(authStateChangesProvider);
  return FastingController(ref);
});
