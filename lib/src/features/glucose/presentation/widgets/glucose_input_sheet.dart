import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:elena_app/src/features/authentication/application/auth_controller.dart';
import 'package:elena_app/src/features/glucose/data/glucose_repository.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_model.dart';

class GlucoseInputSheet extends ConsumerStatefulWidget {
  const GlucoseInputSheet({super.key});

  @override
  ConsumerState<GlucoseInputSheet> createState() => _GlucoseInputSheetState();
}

class _GlucoseInputSheetState extends ConsumerState<GlucoseInputSheet> {
  final _controller = TextEditingController();
  String _selectedTag = 'Ayunas';
  bool _isLoading = false;
  
  // New State for Date/Time
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;

  final List<String> _tags = ['Ayunas', 'Post-comida', 'Antes de dormir'];

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _selectedTime = TimeOfDay.now();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _saveLog() async {
    final value = double.tryParse(_controller.text);
    if (value == null) return;

    setState(() => _isLoading = true);

    try {
      final user = ref.read(authStateChangesProvider).value;
      if (user != null) {
        // Combine Date and Time
        final timestamp = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );

        final log = GlucoseLog(
          id: '', // Firestore generates ID
          value: value,
          timestamp: timestamp,
          tag: _selectedTag,
        );

        await ref.read(glucoseRepositoryProvider).addLog(uid: user.uid, log: log);
        
        if (mounted) context.pop(); // Close sheet
      }
    } catch (e) {
      // Error handling (show snackbar in real app)
      print('Error saving glucose: $e');
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
            'Registrar Glucosa',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          
          // INPUT VALUE
          TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: InputDecoration(
              labelText: 'Nivel (mg/dL)',
              suffixText: 'mg/dL',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 16),

          // DATE & TIME PICKERS
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Colors.blueAccent),
                        const SizedBox(width: 8),
                        Text(
                          DateFormat('dd/MM/yyyy').format(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  onTap: _pickTime,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: Colors.orangeAccent),
                        const SizedBox(width: 8),
                        Text(
                          _selectedTime.format(context),
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 20),
          
          // TAGS
          Wrap(
            spacing: 8,
            alignment: WrapAlignment.center,
            children: _tags.map((tag) {
              final isSelected = _selectedTag == tag;
              return ChoiceChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedTag = tag);
                },
                selectedColor: Colors.blue[100],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.blue[900] : Colors.black,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 20),
          
          // SAVE BUTTON
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
}
