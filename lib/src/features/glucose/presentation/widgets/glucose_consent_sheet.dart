// Módulo "Tu Glucosa" — sheet de consentimiento informado (propuesta
// §7.1, regla R2). Mismo lenguaje visual que
// exercise/presentation/widgets/rest_day_prompt_sheet.dart
// (DraggableScrollableSheet + FilledButton/TextButton) — el usuario no
// debe notar que este flujo se diseñó por separado del resto de Elena.
//
// Se muestra: (a) automáticamente la primera vez que
// `glucoseProtocolEligibilityProvider.eligible == true` y el usuario
// todavía no aceptó el consentimiento (ver el gancho en
// dashboard_screen.dart), o (b) cuando el usuario activa el protocolo
// manualmente desde Perfil (§5.2).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/glucose/application/glucose_protocol_controller.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_consent.dart';

Future<void> showGlucoseConsentSheet(
  BuildContext context, {
  String? welcomeReason,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    isDismissible: true,
    builder: (_) => _GlucoseConsentSheet(welcomeReason: welcomeReason),
  );
}

class _GlucoseConsentSheet extends ConsumerStatefulWidget {
  const _GlucoseConsentSheet({this.welcomeReason});

  final String? welcomeReason;

  @override
  ConsumerState<_GlucoseConsentSheet> createState() =>
      _GlucoseConsentSheetState();
}

class _GlucoseConsentSheetState extends ConsumerState<_GlucoseConsentSheet> {
  bool _accepted = false;
  bool _saving = false;

  Future<void> _confirm() async {
    if (!_accepted) return;
    final uid = ref.read(authStateProvider).value?.uid;
    if (uid == null) {
      if (mounted) Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    try {
      await ref.read(glucoseProtocolControllerProvider).acceptConsent(uid);
    } catch (_) {
      // No bloquea el cierre — mismo criterio que el resto de escrituras
      // "de cortesía" en onboarding/exercise (fallo no debe atrapar al
      // usuario en un modal).
    } finally {
      if (mounted) {
        setState(() => _saving = false);
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.5,
      maxChildSize: 0.9,
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
            if (widget.welcomeReason != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.metabolicGreen.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.welcomeReason!,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            const Text(
              kGlucoseConsentTitle,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              kGlucoseConsentBody,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.75),
                fontSize: 13.5,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => setState(() => _accepted = !_accepted),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color:
                        _accepted ? AppColors.metabolicGreen : Colors.white24,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _accepted
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded,
                      color: _accepted
                          ? AppColors.metabolicGreen
                          : Colors.white.withValues(alpha: 0.4),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        kGlucoseConsentAcceptanceText,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: (_accepted && !_saving) ? _confirm : null,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.metabolicGreen,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor:
                      AppColors.metabolicGreen.withValues(alpha: 0.3),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      )
                    : const Text(
                        'Activar seguimiento de glucosa',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: Text(
                  'Ahora no',
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
