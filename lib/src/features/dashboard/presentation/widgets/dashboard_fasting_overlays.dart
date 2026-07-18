import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/dashboard/application/fasting_notifier.dart';
import 'package:elena_app/src/features/dashboard/domain/fasting_status.dart';

/// SPEC-119: extraídos de `_buildFastingEndOverlay`,
/// `_buildFeedingEndOverlay`, `_buildBaseOverlay` y
/// `_showManualTimePicker` en `dashboard_screen.dart` (ARCH-03). Lógica
/// y textos intactos, solo se movió la construcción a widgets propios.

/// SPEC-151: dos opciones legítimas. Terminar abre el flujo de cierre
/// (time picker + persistir + abrir ventana). Continuar silencia el
/// overlay y deja el ayuno activo en overtime — el usuario cerrará
/// desde la card normal del dashboard cuando decida.
class FastingEndOverlay extends ConsumerWidget {
  const FastingEndOverlay({super.key, required this.state});

  final FastingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BaseOverlay(
      icon: Icons.emoji_events_rounded,
      iconColor: AppColors.metabolicGreen,
      title: "¡META ALCANZADA!",
      subtitle: "Has completado tus ${state.targetHours}h de ayuno.",
      buttonLabel: "TERMINAR AYUNO",
      isSaving: state.isSaving,
      onConfirm: () => showManualTimePicker(context, ref, isFeeding: false),
      secondaryButtonLabel: "CONTINUAR AYUNANDO",
      onSecondary: () =>
          ref.read(fastingProvider.notifier).continueFastingPastTarget(),
    );
  }
}

class FeedingEndOverlay extends ConsumerWidget {
  const FeedingEndOverlay({super.key, required this.state});

  final FastingState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _BaseOverlay(
      icon: Icons.timer_off_rounded,
      iconColor: Colors.orangeAccent,
      title: "FIN DE VENTANA",
      subtitle: "Tu ventana de alimentación ha terminado.",
      buttonLabel: "CONFIRMAR CIERRE",
      isSaving: state.isSaving,
      onConfirm: () => showManualTimePicker(context, ref, isFeeding: true),
    );
  }
}

// SPEC-234: _buildWakeUpOverlay reemplazado por WakeUpQualityOverlay
// (widget stateful con flujo "¿Ya despertaste?" → "¿Cómo dormiste?").

class _BaseOverlay extends StatelessWidget {
  const _BaseOverlay({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.buttonLabel,
    required this.isSaving,
    required this.onConfirm,
    // SPEC-151: botón secundario opcional. Si ambos labels y callbacks
    // son provistos, se renderiza debajo del primario con estilo
    // outlined para indicar acción alternativa.
    this.secondaryButtonLabel,
    this.onSecondary,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final String buttonLabel;
  final bool isSaving;
  final VoidCallback onConfirm;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondary;

  @override
  Widget build(BuildContext context) {
    final hasSecondary = secondaryButtonLabel != null && onSecondary != null;
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.symmetric(horizontal: 40),
      decoration: BoxDecoration(
          color: const Color(0xFF0F172A).withValues(alpha: 0.98),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: iconColor, width: 2),
          boxShadow: [
            BoxShadow(color: iconColor.withValues(alpha: 0.2), blurRadius: 15)
          ]),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: iconColor, size: 28),
        const SizedBox(height: 12),
        Text(title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13)),
        const SizedBox(height: 8),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 10, color: Colors.white.withValues(alpha: 0.7))),
        const SizedBox(height: 16),
        SizedBox(
            width: double.infinity,
            height: 42,
            child: ElevatedButton(
                onPressed: isSaving ? null : onConfirm,
                style: ElevatedButton.styleFrom(
                    backgroundColor: iconColor,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12))),
                child: isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : Text(buttonLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 12)))),
        if (hasSecondary) ...[
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 42,
            child: OutlinedButton(
              onPressed: isSaving ? null : onSecondary,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: iconColor.withValues(alpha: 0.5),
                  width: 1.5,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                secondaryButtonLabel!,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                  fontSize: 12,
                ),
              ),
            ),
          ),
        ],
      ]),
    );
  }
}

/// SPEC-102 / SPEC-102.1: abre date+time picker para cerrar
/// manualmente el ayuno o la ventana de alimentación.
Future<void> showManualTimePicker(BuildContext context, WidgetRef ref,
    {required bool isFeeding}) async {
  final DateTime now = DateTime.now();
  final fastingState = ref.read(fastingProvider);
  final Color primaryColor =
      isFeeding ? Colors.orangeAccent : AppColors.metabolicGreen;
  final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now.subtract(const Duration(days: 7)),
      lastDate: now.add(const Duration(days: 1)),
      builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(primary: primaryColor),
              dialogTheme:
                  DialogThemeData(backgroundColor: const Color(0xFF1E293B))),
          child: child!));
  if (pickedDate == null) return;
  // flutter analyze (2026-07-11): `context` se reutiliza tras un `await`
  // (el date picker) — si el widget se desmontó mientras estaba abierto
  // (usuario navegó fuera), usar un context stale puede lanzar. Guard
  // estándar antes de la segunda apertura de diálogo.
  if (!context.mounted) return;
  final TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(now),
      builder: (context, child) => Theme(
          data: ThemeData.dark().copyWith(
              colorScheme: ColorScheme.dark(primary: primaryColor),
              dialogTheme:
                  DialogThemeData(backgroundColor: const Color(0xFF1E293B))),
          child: child!));
  if (pickedTime == null) return;
  final DateTime finalDateTime = DateTime(pickedDate.year, pickedDate.month,
      pickedDate.day, pickedTime.hour, pickedTime.minute);
  if (isFeeding) {
    ref.read(fastingProvider.notifier).confirmFeedingEnd(finalDateTime);
  } else {
    if (fastingState.isActive) {
      ref.read(fastingProvider.notifier).confirmManualFastingEnd(finalDateTime);
    } else {
      ref.read(fastingProvider.notifier).startFastingManual(finalDateTime);
    }
  }
}
