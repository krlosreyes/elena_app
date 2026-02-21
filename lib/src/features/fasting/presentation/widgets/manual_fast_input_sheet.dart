import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:elena_app/src/features/authentication/data/auth_repository.dart';
import 'package:elena_app/src/features/fasting/data/fasting_repository.dart';
import 'package:elena_app/src/features/fasting/domain/fasting_session.dart';

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
    );
    
    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: initialTime,
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
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Registrar Ayuno Pasado',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
          
          const SizedBox(height: 16),
          
          _buildDateTimePicker(
            label: 'FIN',
            date: _endDate,
            time: _endTime,
            onTap: () => _pickDateTime(isStart: false),
            color: Colors.green,
          ),
          
          const SizedBox(height: 32),
          
          SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveLog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('GUARDAR', style: TextStyle(fontSize: 16, color: Colors.white)),
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
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
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
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  DateFormat('EEE d MMM, yyyy').format(date),
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                time.format(context),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
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
