import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';

class SleepInputSheet extends ConsumerStatefulWidget {
  const SleepInputSheet({super.key});

  @override
  ConsumerState<SleepInputSheet> createState() => _SleepInputSheetState();
}

class _SleepInputSheetState extends ConsumerState<SleepInputSheet> {
  TimeOfDay _bedtime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 7, minute: 0);

  Future<void> _pickBedtime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _bedtime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF818CF8)),
          dialogBackgroundColor: AppColors.surfaceDark,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _bedtime = picked);
  }

  Future<void> _pickWakeTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _wakeTime,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: Color(0xFF818CF8)),
          dialogBackgroundColor: AppColors.surfaceDark,
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _wakeTime = picked);
  }

  void _submit() {
    ref.read(sleepProvider.notifier).saveManualSleep(
      bedtime: _bedtime,
      wakeTime: _wakeTime,
    ).then((_) {
      if (mounted) Navigator.pop(context);
    }).catchError((error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(sleepProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.backgroundDark,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "REGISTRAR SUEÑO",
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, letterSpacing: 1),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("ME ACOOSTÉ AYER A LAS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            subtitle: Text(_bedtime.format(context), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.access_time, color: Color(0xFF818CF8)),
            onTap: _pickBedtime,
          ),
          const Divider(color: Colors.white10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text("ME DESPERTÉ HOY A LAS", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)),
            subtitle: Text(_wakeTime.format(context), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            trailing: const Icon(Icons.wb_sunny_outlined, color: Color(0xFF818CF8)),
            onTap: _pickWakeTime,
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            height: 54,
            child: ElevatedButton(
              onPressed: state.isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1), // Indigo/Purple Sleep color
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: state.isSaving
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text("GUARDAR REGISTRO", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14)),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).viewInsets.bottom + 16),
        ],
      ),
    );
  }
}
