// Módulo "Tu Glucosa" — sheet de control manual del protocolo desde
// Perfil (propuesta §5.2 "disponibilidad opcional"): cualquier usuario
// puede activar/pausar/reanudar/desactivar el seguimiento de glucosa,
// independientemente de `pathologies` (de solo lectura post-onboarding
// — ver informe de implementación). Mismo lenguaje visual que
// exercise/presentation/widgets/rest_day_prompt_sheet.dart.
//
// Precondición de este sheet: solo se abre cuando el consentimiento YA
// fue aceptado (`GlucoseProtocolEntryCard` decide eso ANTES de abrir
// este sheet — si nunca se aceptó, abre `showGlucoseConsentSheet`
// directamente). Por eso "Activar" acá llama a `activateManually` sin
// re-mostrar el consentimiento: el controller ya garantiza que, si por
// algún motivo el consentimiento no estuviera vigente, cae de nuevo en
// `acceptConsent` (ver glucose_protocol_controller.dart).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/glucose/application/glucose_protocol_controller.dart';
import 'package:elena_app/src/features/glucose/application/glucose_providers.dart';

Future<void> showGlucoseProtocolSettingsSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (_) => const _GlucoseProtocolSettingsSheet(),
  );
}

class _GlucoseProtocolSettingsSheet extends ConsumerStatefulWidget {
  const _GlucoseProtocolSettingsSheet();

  @override
  ConsumerState<_GlucoseProtocolSettingsSheet> createState() =>
      _GlucoseProtocolSettingsSheetState();
}

class _GlucoseProtocolSettingsSheetState
    extends ConsumerState<_GlucoseProtocolSettingsSheet> {
  bool _saving = false;

  static const _color = Color(0xFFE879F9); // mismo fucsia que GlucoseEntryCard.

  Future<void> _run(Future<void> Function(String uid) action) async {
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await action(uid);
    } catch (_) {
      // No bloquea el cierre — mismo criterio que el resto de escrituras
      // "de cortesía" del módulo (consentimiento, registro de lectura).
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final protocolState = ref.watch(glucoseProtocolStateProvider).valueOrNull;
    final active = protocolState?.protocolActive ?? false;
    final paused = protocolState?.paused ?? false;
    final controller = ref.read(glucoseProtocolControllerProvider);

    String description;
    if (active && !paused) {
      description = 'Está activo. Te pedimos un registro en ayunas cada '
          'mañana y lo analizamos junto a tus 5 pilares.';
    } else if (active && paused) {
      description = 'Está en pausa: no vas a ver recordatorios ni la card '
          'en Progreso hasta que lo reanudes. Tu historial se conserva.';
    } else {
      description = 'Podés activarlo aunque no lo tengas marcado como '
          'condición médica en tu perfil. Es un complemento educativo — '
          'no reemplaza el criterio de tu médico ni diagnostica nada.';
    }

    return DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.3,
      maxChildSize: 0.65,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFF0F172A),
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 28),
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.water_drop_outlined,
                      color: _color, size: 22),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Text(
                    'Seguimiento de glucosa',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              description,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 22),
            if (!active) ...[
              _ActionButton(
                label: 'Activar seguimiento',
                color: AppColors.metabolicGreen,
                loading: _saving,
                onTap: _saving
                    ? null
                    : () => _run((uid) => controller.activateManually(uid)),
              ),
            ] else if (paused) ...[
              _ActionButton(
                label: 'Reanudar',
                color: AppColors.metabolicGreen,
                loading: _saving,
                onTap: _saving
                    ? null
                    : () => _run((uid) => controller.resume(uid)),
              ),
              const SizedBox(height: 10),
              _ActionButton(
                label: 'Desactivar',
                color: const Color(0xFFF87171),
                outlined: true,
                loading: false,
                onTap: _saving
                    ? null
                    : () => _run((uid) => controller.deactivate(uid)),
              ),
            ] else ...[
              _ActionButton(
                label: 'Pausar',
                color: Colors.white,
                outlined: true,
                loading: false,
                onTap:
                    _saving ? null : () => _run((uid) => controller.pause(uid)),
              ),
              const SizedBox(height: 10),
              _ActionButton(
                label: 'Desactivar',
                color: const Color(0xFFF87171),
                outlined: true,
                loading: false,
                onTap: _saving
                    ? null
                    : () => _run((uid) => controller.deactivate(uid)),
              ),
            ],
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Cerrar',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool loading;
  final bool outlined;

  const _ActionButton({
    required this.label,
    required this.color,
    required this.onTap,
    required this.loading,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          )
        : Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          );

    if (outlined) {
      return SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: onTap,
          style: OutlinedButton.styleFrom(
            foregroundColor: color,
            side: BorderSide(color: color.withValues(alpha: 0.5)),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: child,
      ),
    );
  }
}
