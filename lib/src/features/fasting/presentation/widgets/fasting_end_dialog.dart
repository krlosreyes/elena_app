import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../application/fasting_controller.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';

class FastingEndDialog {
  static void show(BuildContext context, WidgetRef ref, FastingState state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0A0A0A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: AppTheme.primary.withValues(alpha: 0.3),
              width: 1,
            ),
          ),
          title: Row(
            children: [
              const Icon(Icons.timer_off_outlined, color: AppTheme.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '¿YA ESTÁS AYUNANDO?',
                  style: GoogleFonts.outfit(
                    color: AppTheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'Tu ventana de alimentación ha expirado. Elena ha detectado que es el momento táctico para reiniciar tu protocolo de ayuno metabólico.',
            style: GoogleFonts.jetBrainsMono(
              color: Colors.white70,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      ref
                          .read(fastingControllerProvider.notifier)
                          .startFast(hours: state.plannedHours);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 8,
                      shadowColor: AppTheme.primary.withValues(alpha: 0.5),
                    ),
                    child: Text(
                      'SÍ, EMPECÉ AHORA',
                      style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: () async {
                      Navigator.pop(context);
                      
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 7)),
                        lastDate: DateTime.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppTheme.primary,
                                onPrimary: Colors.black,
                                surface: Color(0xFF121212),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (date == null) return;
                      if (!context.mounted) return;

                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.now(),
                        builder: (context, child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.dark(
                                primary: AppTheme.primary,
                                onPrimary: Colors.black,
                                surface: Color(0xFF121212),
                                onSurface: Colors.white,
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );

                      if (time != null) {
                        final manualStart = DateTime(
                          date.year,
                          date.month,
                          date.day,
                          time.hour,
                          time.minute,
                        );
                        
                        await ref
                            .read(fastingControllerProvider.notifier)
                            .startFast(hours: state.plannedHours, manualStartTime: manualStart);
                      }
                    },
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.primary.withValues(alpha: 0.3)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'YA EMPECÉ (ELEGIR HORA)',
                      style: GoogleFonts.outfit(
                          color: AppTheme.primary, fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: Text(
                      'TODAVÍA NO... (RECUÉRDAME LUEGO)',
                      style: GoogleFonts.outfit(
                        color: Colors.white24,
                        fontSize: 11,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    ).then((_) {
      ref.read(fastingControllerProvider.notifier).markFeedingEndDialogShown();
    });
  }
}
