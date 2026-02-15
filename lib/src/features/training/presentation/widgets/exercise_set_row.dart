import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../application/rest_timer_provider.dart';
import '../../application/daily_routine_provider.dart'; // Added import

class ExerciseSetRow extends ConsumerStatefulWidget {
  final String exerciseId; // Added as per strict prompt
  final int setIndex;
  final String targetReps;
  final bool isDone;
  final double? initialWeight;
  final int? initialReps;
  final Function(double? weight, int? reps)? onToggle; // Keeping as optional/legacy or for other uses if needed, but primary logic moves.

  const ExerciseSetRow({
    super.key,
    required this.exerciseId, // Required now
    required this.setIndex,
    required this.targetReps,
    required this.isDone,
    this.onToggle,
    this.initialWeight,
    this.initialReps,
  });

  @override
  ConsumerState<ExerciseSetRow> createState() => _ExerciseSetRowState();
}

class _ExerciseSetRowState extends ConsumerState<ExerciseSetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    double weight = widget.initialWeight ?? 0;
    if (weight == 0) weight = 5;

    _weightController = TextEditingController(
      text: weight.toString().replaceAll(RegExp(r'\.0$'), ''),
    );
    _repsController = TextEditingController(
      text: widget.initialReps?.toString() ?? '',
    );
  }

  @override
  void didUpdateWidget(covariant ExerciseSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // CRITICAL: Sync controller text when Riverpod state changes (e.g. isDone toggled).
    // Only update if the immutable prop actually changed to avoid cursor jumping.
    if (oldWidget.initialWeight != widget.initialWeight) {
      double weight = widget.initialWeight ?? 0;
      if (weight == 0) weight = 5;
      final newText = weight.toString().replaceAll(RegExp(r'\.0$'), '');
      if (_weightController.text != newText) {
        _weightController.text = newText;
      }
    }
    if (oldWidget.initialReps != widget.initialReps) {
      final newText = widget.initialReps?.toString() ?? '';
      if (_repsController.text != newText) {
        _repsController.text = newText;
      }
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    final weight = double.tryParse(_weightController.text) ?? 0.0;
    final reps = int.tryParse(_repsController.text) ?? 0;

    // Call provider directly to update state
    ref.read(dailyRoutineProvider.notifier).toggleSet(
      widget.exerciseId, 
      widget.setIndex, 
      weight, 
      reps
    );

    // Start rest timer if marking as done
    if (!widget.isDone) {
      ref.read(restTimerProvider.notifier).startTimer(90);
    }
  }

  @override
  Widget build(BuildContext context) {
    // CRITICAL: Read isDone from widget prop (immutable from Riverpod), NOT a local variable.
    final isDone = widget.isDone;
    // Enable inputs only if not done (optional, but good UX)
    // The user requested: "El botón de Check DEBE ser un Consumer y leer widget.set.isDone." which is satisfied here.
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Set Index
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              shape: BoxShape.circle,
            ),
            child: Text(
              "${widget.setIndex}",
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Target Reps
          Expanded(
            child: Text(
              "Obj: ${widget.targetReps}",
              style: GoogleFonts.outfit(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
          ),

          // Weight Input
          SizedBox(
            width: 60,
            child: TextField(
              controller: _weightController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              enabled: !isDone,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Peso',
                suffixText: 'kg',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                isDense: true,
                filled: true,
                fillColor: isDone ? Colors.grey.shade100 : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Reps Input
          SizedBox(
            width: 60,
            child: TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              enabled: !isDone,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                labelText: 'Reps',
                floatingLabelBehavior: FloatingLabelBehavior.always,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                isDense: true,
                filled: true,
                fillColor: isDone ? Colors.grey.shade100 : Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Check Button — reads isDone from WIDGET PROP (Riverpod immutable state)
          InkWell(
            onTap: _handleToggle,
            child: Icon(
              isDone ? Icons.check_circle : Icons.circle_outlined,
              color: isDone
                  ? Colors.green
                  : Colors.grey.shade300,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
