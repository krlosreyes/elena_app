import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../config/theme/app_theme.dart';

class ExerciseSetRow extends StatefulWidget {
  final int setIndex;
  final String targetReps;
  final bool isDone;
  final double? initialWeight;
  final int? initialReps;
  final Function(double? weight, int? reps) onToggle;

  const ExerciseSetRow({
    super.key,
    required this.setIndex,
    required this.targetReps,
    required this.isDone,
    required this.onToggle,
    this.initialWeight,
    this.initialReps,
  });

  @override
  State<ExerciseSetRow> createState() => _ExerciseSetRowState();
}

class _ExerciseSetRowState extends State<ExerciseSetRow> {
  late TextEditingController _weightController;
  late TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: widget.initialWeight?.toString().replaceAll(RegExp(r'\.0$'), '') ?? '',
    );
    _repsController = TextEditingController(
      text: widget.initialReps?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _handleToggle() {
    final weight = double.tryParse(_weightController.text);
    final reps = int.tryParse(_repsController.text);
    widget.onToggle(weight, reps);
  }

  @override
  Widget build(BuildContext context) {
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
              enabled: !widget.isDone,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Kg',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                isDense: true,
                filled: true,
                fillColor: widget.isDone ? Colors.grey.shade100 : Colors.white,
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
            width: 50,
            child: TextField(
              controller: _repsController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              enabled: !widget.isDone,
              style: GoogleFonts.outfit(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Reps',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                isDense: true,
                filled: true,
                fillColor: widget.isDone ? Colors.grey.shade100 : Colors.white,
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

          // Check Button
          InkWell(
            onTap: _handleToggle,
            child: Icon(
              widget.isDone ? Icons.check_circle : Icons.circle_outlined,
              color: widget.isDone ? Colors.green : Colors.grey.shade400,
              size: 28,
            ),
          ),
        ],
      ),
    );
  }
}
