/// SPEC-22: BottomSheet de confirmación de inicio de sueño
/// Se muestra cuando el usuario se acerca a la hora de sueño programada.
/// Ofrece: [Sí, dormir ahora] / [No, aún no]

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/features/dashboard/application/sleep_notifier.dart';
import 'package:elena_app/src/features/dashboard/presentation/sleep_input_sheet.dart';

class SleepPromptSheet extends ConsumerStatefulWidget {
  const SleepPromptSheet({super.key});

  @override
  ConsumerState<SleepPromptSheet> createState() => _SleepPromptSheetState();
}

class _SleepPromptSheetState extends ConsumerState<SleepPromptSheet> {
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
                  color: const Color(0xFF818CF8).withOpacity(0.1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF818CF8).withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.bedtime_rounded,
                    size: 32,
                    color: Color(0xFF818CF8),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // ── Título y descripción ────────────────────────────────────────
              Text(
                '¿Vas a dormir ahora?',
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
                'Registra tu hora de sueño para completar el ciclo metabólico y optimizar tus métricas.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.6),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),

              // ── Botones de acción ────────────────────────────────────────────
              // Botón principal: Registrar sueño
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isStarting ? null : _registerSleep,
                  icon: _isStarting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.bedtime_rounded, size: 18),
                  label: Text(
                    _isStarting ? 'Registrando...' : 'Sí, registrar sueño',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF818CF8),
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
                          'Puedes registrar tu sueño cuando estés listo. Aparecerá un recordatorio en el panel de sueño.',
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

  Future<void> _registerSleep() async {
    setState(() => _isStarting = true);

    try {
      // Abre el SleepInputSheet en lugar de confirmación automática
      // para que el usuario pueda ingresar tiempos precisos
      if (mounted) {
        Navigator.pop(context);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const SleepInputSheet(),
        );
      }
    } catch (e) {
      setState(() => _isStarting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error al abrir registro de sueño. Intenta de nuevo.'),
            backgroundColor: Colors.red.withOpacity(0.2),
          ),
        );
      }
    }
  }
}
