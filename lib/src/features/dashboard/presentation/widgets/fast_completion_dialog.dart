import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
      firstDate: widget.startTime.subtract(const Duration(hours: 1)), // Margen de error
      lastDate: DateTime.now(),
    );

    if (date == null) return;

    if (!mounted) return;
    
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_endTime),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        'Terminar Ayuno',
        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Confirma la hora de finalización:', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          
          // Start Time (Read Only)
          _buildTimeRow('Inicio:', dateFormat.format(widget.startTime), false),
          const SizedBox(height: 12),
          
          // End Time (Editable)
          InkWell(
            onTap: _selectEndTime,
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).primaryColor.withOpacity(0.5)),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).primaryColor.withOpacity(0.05),
              ),
              child: _buildTimeRow(
                'Fin:', 
                dateFormat.format(_endTime), 
                true, 
                icon: Icons.edit,
                color: Theme.of(context).primaryColor
              ),
            ),
          ),
          
          const Divider(height: 32),
          
          // Duration
          Text(
            'Duración Total',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.grey[600]),
          ),
          const SizedBox(height: 4),
          Text(
            '${hours}h ${minutes}m',
            style: GoogleFonts.outfit(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          
          // Warning if short
          if (hours < 12) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                   const Icon(Icons.warning_amber_rounded, size: 16, color: Colors.orange),
                   const SizedBox(width: 4),
                   Text(
                     'Ayuno corto (< 12h)',
                     style: GoogleFonts.outfit(fontSize: 12, color: Colors.orange[800]),
                   ),
                ],
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: () {
            widget.onConfirm(_endTime);
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: const Text('Guardar Ayuno', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildTimeRow(String label, String time, bool isEditable, {IconData? icon, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        Row(
          children: [
            Text(
              time, 
              style: TextStyle(
                fontWeight: FontWeight.bold, 
                color: color ?? Colors.black87,
                fontSize: 16
              )
            ),
            if (icon != null) ...[
               const SizedBox(width: 4),
               Icon(icon, size: 14, color: color),
            ]
          ],
        ),
      ],
    );
  }
}
