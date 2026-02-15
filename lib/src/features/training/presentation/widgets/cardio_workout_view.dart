import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';
import '../../domain/entities/daily_workout.dart';

class CardioWorkoutView extends StatefulWidget {
  final DailyWorkout plan;
  final bool isCompleted;

  const CardioWorkoutView({
    super.key,
    required this.plan,
    required this.isCompleted,
  });

  @override
  State<CardioWorkoutView> createState() => _CardioWorkoutViewState();
}

class _CardioWorkoutViewState extends State<CardioWorkoutView> {
  Timer? _timer;
  int _seconds = 0;
  bool _isRunning = false;

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

  void _finish() {
    _timer?.cancel();
    // Here we would call controller to save logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Sesión de Cardio Guardada (Mock)")),
    );
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
            Text("Entrenamiento Completado", style: GoogleFonts.outfit(fontSize: 1, fontWeight: FontWeight.bold)),
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
