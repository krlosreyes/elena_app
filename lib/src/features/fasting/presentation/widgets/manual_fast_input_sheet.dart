import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:elena_app/src/features/authentication/application/auth_controller.dart';
import 'package:elena_app/src/features/fasting/data/fasting_repository.dart';
import 'package:elena_app/src/features/fasting/domain/fasting_session.dart';
import 'package:elena_app/src/core/utils/dark_picker_theme.dart';

class ManualFastInputSheet extends ConsumerStatefulWidget {
  const ManualFastInputSheet({super.key});

  @override
  ConsumerState<ManualFastInputSheet> createState() => _ManualFastInputSheetState();
}

class _ManualFastInputSheetState extends ConsumerState<ManualFastInputSheet> {
  bool _isLoading = false;
  
  late DateTime _startDate;
  late TimeOfDay _startTime;
  
  late DateTime _endDate;
  late TimeOfDay _endTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    // Default: Ended just now, started 16h ago
    _endDate = now;
    _endTime = TimeOfDay.fromDateTime(now);
    
    final start = now.subtract(const Duration(hours: 16));
    _startDate = start;
    _startTime = TimeOfDay.fromDateTime(start);
  }

  Future<void> _pickDateTime({required bool isStart}) async {
    final initialDate = isStart ? _startDate : _endDate;
    final initialTime = isStart ? _startTime : _endTime;

    final date = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(data: darkPickerTheme(ctx), child: child!),
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: initialTime,
        builder: (ctx, child) => Theme(data: darkPickerTheme(ctx), child: child!),
      );
      
      if (time != null) {
        setState(() {
          if (isStart) {
            _startDate = date;
            _startTime = time;
          } else {
            _endDate = date;
            _endTime = time;
          }
        });
      }
    }
  }

  Future<void> _saveLog() async {
    setState(() => _isLoading = true);

    try {
      final start = DateTime(
        _startDate.year, _startDate.month, _startDate.day,
        _startTime.hour, _startTime.minute,
      );
      
      final end = DateTime(
        _endDate.year, _endDate.month, _endDate.day,
        _endTime.hour, _endTime.minute,
      );

      if (end.isBefore(start)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('La fecha final debe ser posterior al inicio')),
        );
        return;
      }
      
      final duration = end.difference(start).inHours;
      if (duration < 1) { // Min 1 hour check
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('El ayuno debe durar al menos 1 hora')),
        );
        return;
      }

      final user = ref.read(authStateChangesProvider).value;
      if (user != null) {
        final session = FastingSession(
          uid: user.uid,
          startTime: start,
          endTime: end,
          plannedDurationHours: 16, // Default or calculated
          isCompleted: true, // Manual logs are always completed
        );

        // Use saveCompletedFast logic from repo
        await ref.read(fastingRepositoryProvider).saveCompletedFast(user.uid, session);
        
        if (mounted) context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: const Border(
          top: BorderSide(color: Color(0xFF2E2E2E), width: 1),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const Text(
            'Registrar Ayuno Pasado',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          _buildDateTimePicker(
            label: 'INICIO',
            date: _startDate,
            time: _startTime,
            onTap: () => _pickDateTime(isStart: true),
            color: Colors.orange,
          ),
          
          const SizedBox(height: 12),
          
          _buildDateTimePicker(
            label: 'FIN',
            date: _endDate,
            time: _endTime,
            onTap: () => _pickDateTime(isStart: false),
            color: const Color(0xFF00BFA5), // Teal
          ),
          
          const SizedBox(height: 28),
          
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009688),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isLoading 
                  ? const SizedBox(
                      width: 22, height: 22,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : const Text(
                      'GUARDAR AYUNO',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimePicker({
    required String label, 
    required DateTime date, 
    required TimeOfDay time, 
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF252525),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEE d MMM, yyyy').format(date),
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: color.withOpacity(0.3)),
              ),
              child: Text(
                time.format(context),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
