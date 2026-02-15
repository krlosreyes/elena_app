import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../config/theme/app_theme.dart';
import '../../domain/entities/daily_workout.dart';
import 'package:go_router/go_router.dart';
import '../../application/workout_submit_controller.dart';

import '../../domain/enums/workout_enums.dart';

class CardioWorkoutView extends ConsumerStatefulWidget {
  final DailyWorkout plan;
  final bool isCompleted;
  final WorkoutDisplayMode mode;

  const CardioWorkoutView({
    super.key,
    required this.plan,
    required this.isCompleted,
    this.mode = WorkoutDisplayMode.active,
  });

  @override
  ConsumerState<CardioWorkoutView> createState() => _CardioWorkoutViewState();
}

class _CardioWorkoutViewState extends ConsumerState<CardioWorkoutView> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

  bool get _isReadOnly => 
    widget.mode == WorkoutDisplayMode.readOnly || 
    widget.mode == WorkoutDisplayMode.completed;

  void _toggleTimer() {
    if (_isRunning) {
      _timer?.cancel();
    } else {
      _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
        setState(() {
          _seconds++;
        });
      });
    }
    setState(() {
      _isRunning = !_isRunning;
    });
  }

  Future<void> _finish() async {
    _timer?.cancel();
    
    // Calculate a mock score or just pass 0 for cardio for now
    final log = await ref.read(workoutSubmitControllerProvider.notifier)
        .submitWorkout(sessionRir: 0); // 0 or maybe mapped from heart rate in future

    if (mounted && log != null) {
      context.goNamed('workout_summary', extra: log);
    } else if (mounted) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Error guardando sesión.")),
      );
    }
  }

  String get _formattedTime {
    final mins = (_seconds / 60).floor().toString().padLeft(2, '0');
    final secs = (_seconds % 60).toString().padLeft(2, '0');
    return "$mins:$secs";
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isCompleted) {
      return Center(
        child: Column(
          children: [
            const Icon(Icons.check_circle_outline, size: 64, color: Colors.green),
            const SizedBox(height: 16),
            Text("Entrenamiento Completado", style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        children: [
          Text(
            widget.plan.description,
            style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            "Objetivo: ${widget.plan.durationMinutes} Minutos • ${widget.plan.details}",
            style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey.shade600),
          ),
          if (widget.mode == WorkoutDisplayMode.retroactive)
             Padding(
               padding: const EdgeInsets.only(top: 16.0),
               child: Container(
                 padding: const EdgeInsets.all(12),
                 decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(8)),
                 child: Text("Estás registrando una sesión pasada.", style: TextStyle(color: Colors.orange.shade800)),
               ),
             ),

          const Spacer(),
          Container(
            padding: const EdgeInsets.all(40),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: _isReadOnly ? Colors.grey.shade300 : Colors.orange.shade100, width: 4),
            ),
            child: Text(
              _formattedTime,
              style: GoogleFonts.outfit(
                fontSize: 64, 
                fontWeight: FontWeight.bold,
                color: _isReadOnly ? Colors.grey : Colors.black,
                fontFeatures: [const FontFeature.tabularFigures()],
              ),
            ),
          ),
          const Spacer(),
          
          if (!_isReadOnly)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton.large(
                onPressed: _toggleTimer,
                backgroundColor: _isRunning ? Colors.amber : Colors.green,
                child: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
              ),
              if (_seconds > 0 && !_isRunning || widget.mode == WorkoutDisplayMode.retroactive)
                 FloatingActionButton.large(
                  onPressed: _finish,
                  backgroundColor: AppTheme.brandBlue,
                  child: const Icon(Icons.check),
                ),
            ],
          ),
          const Spacer(),
        ],
      ),
    );
  }
}
