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

      if (startTimeIso != null) {
        // Restaurar ayuno en progreso
        final startTime = DateTime.parse(startTimeIso);
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
      } else {
        // No hay ayuno activo, pero actualizamos las horas planeadas
        state = AsyncValue.data(FastingState.initial().copyWith(plannedHours: safePlannedHours));
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  // ... (startFast and stopFast remain mostly the same, ensuring plannedHours is used from state)

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
