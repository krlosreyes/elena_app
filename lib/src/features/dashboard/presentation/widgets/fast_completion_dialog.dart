import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/dark_picker_theme.dart';

class FastCompletionDialog extends StatefulWidget {
  final DateTime startTime;
  final Function(DateTime endTime) onConfirm;

  const FastCompletionDialog({
    super.key,
    required this.startTime,
    required this.onConfirm,
  });

  @override
  State<FastCompletionDialog> createState() => _FastCompletionDialogState();
}

class _FastCompletionDialogState extends State<FastCompletionDialog> {
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    _endTime = DateTime.now();
  }

  Duration get _duration => _endTime.difference(widget.startTime);

  Future<void> _selectEndTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _endTime,
      firstDate: widget.startTime.subtract(const Duration(hours: 1)),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(data: darkPickerTheme(ctx), child: child!),
    );

    if (date == null) return;

    if (!mounted) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime),
      builder: (ctx, child) => Theme(data: darkPickerTheme(ctx), child: child!),
    );

    if (time == null) return;

    final newEndTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (newEndTime.isBefore(widget.startTime)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La hora de fin no puede ser antes del inicio.')),
        );
      }
      return;
    }

    if (newEndTime.isAfter(DateTime.now())) {
       if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La hora de fin no puede ser en el futuro.')),
        );
      }
      return;
    }

    setState(() => _endTime = newEndTime);
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM, HH:mm');
    final duration = _duration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    return AlertDialog(
      backgroundColor: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: Colors.grey[800]!),
      ),
      title: Text(
        'Terminar Ayuno',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Confirma la hora de finalización:', style: TextStyle(color: Colors.grey[400])),
          const SizedBox(height: 20),
          
          // Start Time (Read Only)
          _buildTimeRow('Inicio:', dateFormat.format(widget.startTime), false),
          const SizedBox(height: 12),
          
          // End Time (Editable)
          InkWell(
            onTap: _selectEndTime,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[800]!),
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.3),
              ),
              child: _buildTimeRow(
                'Fin:', 
                dateFormat.format(_endTime), 
                true, 
                icon: Icons.edit,
                color: const Color(0xFF009688) // Teal accent
              ),
            ),
          ),
          
          const Divider(height: 32, color: Colors.white10),
          
          // Duration
          Text(
            'Duración Total',
            style: GoogleFonts.outfit(fontSize: 14, color: Colors.grey[500]),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '${hours}h',
                style: GoogleFonts.outfit(
                  fontSize: 36,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${minutes}m',
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
          
          // Warning if short
          if (hours < 12) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Icon(Icons.warning_amber_rounded, size: 18, color: Colors.orange),
                   const SizedBox(width: 6),
                   Text(
                     'Ayuno corto (< 12h)',
                     style: GoogleFonts.outfit(fontSize: 13, color: Colors.orange, fontWeight: FontWeight.w500),
                   ),
                ],
              ),
            ),
          ],
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      actionsAlignment: MainAxisAlignment.spaceBetween,
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          style: TextButton.styleFrom(foregroundColor: Colors.grey[400]),
          child: const Text('Cancelar', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_endTime);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF009688),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text('Guardar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        ),
      ],
    );
  }

  Widget _buildTimeRow(String label, String time, bool isEditable, {IconData? icon, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
        Row(
          children: [
            Text(
              time, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: color ?? Colors.white,
                fontSize: 16
              )
            ),
            if (icon != null) ...[
               const SizedBox(width: 6),
               Icon(icon, size: 16, color: color),
            ]
          ],
        ),
      ],
    );
  }
}
