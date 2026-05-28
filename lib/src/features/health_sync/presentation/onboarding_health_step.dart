// SPEC-132 — Bloque E: pantalla de onboarding que pide permisos para
// HealthKit / Health Connect.
//
// Solo se inserta en el flujo cuando:
//   - cold install (newProfile) — los usuarios MR ya tienen biometría
//     desde el sitio.
//   - plataforma soportada (iOS o Android).
//
// Diseño: solo contenido (sin botones). El flujo "Conectar / Saltar"
// se maneja desde el bottom navigation del onboarding — el botón
// "SIGUIENTE" dispara la solicitud de permisos. Si el usuario rechaza
// el sheet nativo, el flujo igual avanza (no bloqueamos).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

class OnboardingHealthStep extends ConsumerWidget {
  final bool isDark;

  /// Reservado para compatibilidad con el switch del onboarding —
  /// el avance lo dispara el bottom navigation, no este widget.
  final VoidCallback onContinue;

  const OnboardingHealthStep({
    super.key,
    required this.isDark,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accent = AppColors.metabolicGreen;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      children: [
        Center(
          child: Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.favorite_outline, color: accent, size: 48),
          ),
        ),
        const SizedBox(height: 28),
        Text(
          'Conectá tu cuerpo, no tu app',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? AppColors.textPrimary : const Color(0xFF1E293B),
            fontSize: 22,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 20),
        _paragraph(
          'Si usás Apple Health o Health Connect (Samsung Health, Mi '
          'Band, Garmin), ElenaApp puede leer tu peso, sueño y pasos '
          'automáticamente — sin que tengas que ingresarlos a mano.',
          isDark,
        ),
        const SizedBox(height: 12),
        _paragraph(
          'Solo lectura. No escribimos en tu Apple Health ni '
          'compartimos los datos con nadie.',
          isDark,
        ),
        const SizedBox(height: 24),
        Text(
          'Al continuar, vas a ver el diálogo del sistema para elegir '
          'qué datos compartir. Podés saltear este paso y conectar '
          'más tarde desde Perfil > Salud.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: (isDark
                    ? AppColors.textSecondary
                    : const Color(0xFF475569))
                .withValues(alpha: 0.7),
            fontSize: 13,
            height: 1.5,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }

  Widget _paragraph(String text, bool isDark) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: isDark ? AppColors.textSecondary : const Color(0xFF475569),
        fontSize: 15,
        height: 1.55,
      ),
    );
  }
}
