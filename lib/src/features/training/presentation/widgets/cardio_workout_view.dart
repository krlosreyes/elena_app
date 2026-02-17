import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../config/theme/app_theme.dart';
import '../../domain/entities/daily_workout.dart';
import 'package:elena_app/src/features/training/application/daily_orchestrator_provider.dart' as orchestrator;
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
  final TextEditingController _minutesController = TextEditingController();

  @override
  void dispose() {
    _timer?.cancel();
    _minutesController.dispose();
    super.dispose();
  }

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

  Future<void> _finish(int durationMinutes) async {
    _timer?.cancel();
    
    final log = await ref.read(workoutSubmitControllerProvider.notifier)
        .submitWorkout(
          sessionRir: 0,
          durationMinutes: durationMinutes,
          workoutType: 'Cardio',
        ); 

    if (mounted && log != null) {
      await context.pushNamed('workout_summary', extra: log);
      ref.invalidate(orchestrator.dailyOrchestratorProvider);
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
          const SizedBox(height: 32),

          // Render based on mode
          Expanded(child: _buildContentByMode(context)),
        ],
      ),
    );
  }

  Widget _buildContentByMode(BuildContext context) {
    switch (widget.mode) {
      case WorkoutDisplayMode.active:
        return _buildActiveTimer();
      case WorkoutDisplayMode.retroactive:
        return _buildRetroactiveForm();
      case WorkoutDisplayMode.readOnly:
      case WorkoutDisplayMode.completed:
        return _buildReadOnlyView();
    }
  }

  Widget _buildActiveTimer() {
    return Column(
      children: [
        const Spacer(),
        Container(
          padding: const EdgeInsets.all(40),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.orange.shade100, width: 4),
          ),
          child: Text(
            _formattedTime,
            style: GoogleFonts.outfit(
              fontSize: 64, 
              fontWeight: FontWeight.bold,
              fontFeatures: [const FontFeature.tabularFigures()],
            ),
          ),
        ),
        const Spacer(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            FloatingActionButton.large(
              onPressed: _toggleTimer,
              backgroundColor: _isRunning ? Colors.amber : Colors.green,
              child: Icon(_isRunning ? Icons.pause : Icons.play_arrow),
            ),
            if (_seconds > 0 && !_isRunning)
               FloatingActionButton.large(
                onPressed: () => _finish((_seconds / 60).round()),
                backgroundColor: AppTheme.brandBlue,
                child: const Icon(Icons.check),
              ),
          ],
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildRetroactiveForm() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            children: [
              Text(
                "¿Realizaste tu sesión de cardio?",
                style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange.shade900),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _minutesController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: "Minutos realizados",
                  suffixText: "min",
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: () {
              final mins = int.tryParse(_minutesController.text) ?? 0;
              if (mins > 0) {
                _finish(mins);
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text("Guardar Registro Pasado", style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.monitor_heart_outlined, size: 80, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          "Planificado: ${widget.plan.durationMinutes} Minutos",
          style: GoogleFonts.outfit(fontSize: 20, color: Colors.grey.shade600, fontWeight: FontWeight.bold),
        ),
        Text(
          "Zona: ${widget.plan.details}",
          style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey),
        ),
      ],
    );
  }
}
