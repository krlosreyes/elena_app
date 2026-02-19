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
  final bool requiresWeight; // Add this prop

  const ExerciseSetRow({
    super.key,
    required this.exerciseId, 
    required this.setIndex,
    required this.targetReps,
    required this.isDone,
    this.requiresWeight = true, // Default true
    this.onToggle,
    this.initialWeight,
    this.initialReps,
  });

  final void Function(double weight, int reps)? onToggle;
  final double? initialWeight;
  final int? initialReps;

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
    final weight = widget.requiresWeight 
        ? (double.tryParse(_weightController.text) ?? 0.0) 
        : 0.0;
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
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          // Set Index (Soft Circle)
          Container(
            width: 32,
            height: 32,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.teal.withOpacity(0.05), // Soft Teal bg
              shape: BoxShape.circle,
            ),
            child: Text(
              "${widget.setIndex}",
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade700,
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Target Reps
          Expanded(
            child: Text(
              "${widget.targetReps}", // Just number, header says "OBJETIVO"
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade700,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // Weight Input (Conditional)
          if (widget.requiresWeight) ...[
             SizedBox(
               width: 58, 
               child: _buildEliteInput(_weightController, isDone, false),
             ),
             const SizedBox(width: 8),
          ],

          // Reps Input (Expanded if no weight)
          SizedBox(
            width: widget.requiresWeight ? 58 : 88, 
            child: _buildEliteInput(_repsController, isDone, true),
          ),
          const SizedBox(width: 12), // Space before Check

          // Check Button (Larger touch target)
          InkWell(
            onTap: _handleToggle,
            borderRadius: BorderRadius.circular(30),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                 shape: BoxShape.circle,
                 color: isDone ? Colors.green : Colors.transparent,
                 border: isDone ? null : Border.all(color: Colors.grey.shade300, width: 2),
              ),
              child: isDone 
                 ? const Icon(Icons.check, color: Colors.white, size: 20)
                 : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEliteInput(TextEditingController controller, bool isDone, bool isReps) {
     return TextField(
       controller: controller,
       keyboardType: const TextInputType.numberWithOptions(decimal: true),
       textAlign: TextAlign.center,
       enabled: !isDone,
       style: GoogleFonts.outfit(
         fontSize: 14, 
         fontWeight: FontWeight.bold,
         color: Colors.black87
       ),
       decoration: InputDecoration(
         contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4), 
         isDense: true,
         filled: true,
         fillColor: isDone ? Colors.grey.shade50 : Colors.white,
         border: OutlineInputBorder(
             borderRadius: BorderRadius.circular(12), // Elite Radius
             borderSide: const BorderSide(color: Color(0xFFE0E0E0)), // Specific color
         ),
         enabledBorder: OutlineInputBorder( // Explicit enabled border
             borderRadius: BorderRadius.circular(12),
             borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
         ),
         focusedBorder: OutlineInputBorder( // Active state
             borderRadius: BorderRadius.circular(12),
             borderSide: const BorderSide(color: Colors.blue, width: 1.5),
         ),
       ),
     );
  }
}
