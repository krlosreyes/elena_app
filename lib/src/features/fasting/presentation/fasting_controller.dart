import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../authentication/data/auth_repository.dart';
import '../domain/fasting_session.dart';

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
    _init();
  }

  // 1. Inicialización y Restauración
  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final startTimeIso = prefs.getString(_keyStartTime);
      final plannedours = prefs.getInt(_keyPlannedHours) ?? 16;

      if (startTimeIso != null) {
        // Restaurar ayuno en progreso
        final startTime = DateTime.parse(startTimeIso);
        final now = DateTime.now();
        final elapsed = now.difference(startTime);
        
        state = AsyncValue.data(FastingState(
          isFasting: true,
          elapsed: elapsed,
          progress: _calculateProgress(elapsed, plannedours),
          startTime: startTime,
          plannedHours: plannedours,
        ));
        
        _startTimer();
      } else {
        // No hay ayuno activo
        state = AsyncValue.data(FastingState.initial());
      }
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

    _startTimer();
  }

  // 3. Terminar Ayuno
  Future<void> stopFast() async {
    _timer?.cancel();
    
    final currentState = state.value;
    if (currentState == null || !currentState.isFasting || currentState.startTime == null) return;

    final endTime = DateTime.now();
    final uid = ref.read(authRepositoryProvider).currentUser?.uid;

    if (uid != null) {
      final session = FastingSession(
        uid: uid,
        startTime: currentState.startTime!,
        endTime: endTime,
        plannedDurationHours: currentState.plannedHours,
        isCompleted: true,
      );

      // Guardar en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fasting_history')
          .add(session.toJson());
    }

    // Limpiar local
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyStartTime);
    await prefs.remove(_keyPlannedHours);

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
  }

  // 4. Timer Interno
  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      
      state.whenData((currentState) {
        if (!currentState.isFasting || currentState.startTime == null) {
          timer.cancel();
          return;
        }

        final now = DateTime.now();
        final elapsed = now.difference(currentState.startTime!);
        
        // Actualizamos estado sin reconstruir todo si es posible, 
        // pero con Riverpod inmutable emitimos nuevo estado.
        state = AsyncValue.data(currentState.copyWith(
          elapsed: elapsed,
          progress: _calculateProgress(elapsed, currentState.plannedHours),
        ));
      });
    });
  }

  double _calculateProgress(Duration elapsed, int plannedHours) {
    final totalSeconds = plannedHours * 3600;
    if (totalSeconds == 0) return 0;
    return elapsed.inSeconds / totalSeconds;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final fastingControllerProvider =
    StateNotifierProvider<FastingController, AsyncValue<FastingState>>((ref) {
  return FastingController(ref);
});
