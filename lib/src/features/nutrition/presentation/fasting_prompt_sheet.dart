/// SPEC-21: BottomSheet de confirmación de inicio de ayuno
/// Se muestra cuando el usuario registra la última comida del día.
/// Ofrece: [Sí, iniciar ayuno] / [No, aún no]

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';

class FastingPromptSheet extends ConsumerStatefulWidget {
  const FastingPromptSheet({super.key});

  @override
  ConsumerState<FastingPromptSheet> createState() => _FastingPromptSheetState();
}

class _FastingPromptSheetState extends ConsumerState<FastingPromptSheet> {
  bool _isStarting = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Header con icon ────────────────────────────────────────────
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.red.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.schedule_rounded,
                    size: 32,
                    color: Color(0xFFC0392B),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Título y descripción ────────────────────────────────────────
              Text(
                'Has completado tus comidas del día',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),

              Text(
                'Tu ventana de alimentación se cierra. ¿Listo para comenzar tu ayuno?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // ── Botones de acción ────────────────────────────────────────────
              // Botón principal: Iniciar ayuno
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isStarting ? null : _startFasting,
                  icon: _isStarting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.play_circle_fill_rounded, size: 18),
                  label: Text(
                    _isStarting ? 'Iniciando...' : 'Sí, iniciar ayuno',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC0392B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Botón secundario: No, aún no
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isStarting ? null : () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Puedes iniciar el ayuno cuando estés listo. Aparecerá un recordatorio en el panel de nutrición.',
                        ),
                        duration: const Duration(seconds: 4),
                        backgroundColor: Colors.white.withOpacity(0.1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white.withOpacity(0.7),
                    side: BorderSide(color: Colors.white.withOpacity(0.15)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'No, aún no',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _startFasting() async {
    setState(() => _isStarting = true);

    try {
      // Inicia el ayuno a través del FastingNotifier
      final fastingNotifier = ref.read(fastingProvider.notifier);
      await fastingNotifier.startFasting();

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✓ Ayuno iniciado. Que comience la quema de grasa.'),
            duration: const Duration(seconds: 3),
            backgroundColor: Colors.green.withOpacity(0.2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isStarting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al iniciar ayuno. Intenta de nuevo.'),
            backgroundColor: Colors.red.withOpacity(0.2),
          ),
        );
      }
    }
  }
}
