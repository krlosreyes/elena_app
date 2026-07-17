import 'package:flutter/material.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/engine/imr_persistence_provider.dart';
import 'package:elena_app/src/features/analysis/domain/imr_explanation.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';

/// SPEC-116: sin border coloreado. El badge IMR ya comunica el
/// estado clínico.
///
/// SPEC-119: extraído de `_buildIdentityCard` en `profile_screen.dart`
/// (ARCH-03). `_zoneColor(zone)` (un delegador de una línea a
/// `AppColors.imrZoneColor(zone)`) se inlineó — mismo valor, sin
/// cambio de comportamiento.
///
/// 17-jul (Propuesta "un Perfil que da orgullo abrir", P0): el
/// subtítulo mostraba la condición clínica del usuario (ej.
/// "Prediabetes") o, en su defecto, "Expediente metabólico" — lo
/// primero que alguien leía sobre sí mismo era un diagnóstico o una
/// palabra de archivo médico, no algo cálido. Se reemplaza por "Tu
/// perfil metabólico", siempre igual, sin condicionar al estado
/// clínico. Las condiciones médicas (`user.pathologies`) NO se
/// pierden — siguen siendo dato real usado en `fasting_eligibility.dart`
/// para elegibilidad de protocolos — solo se reubicaron como fila de
/// solo-lectura dentro de "Datos biométricos" (ver profile_screen.dart),
/// que es su lugar clínico correcto, no la primera línea de identidad.
class ProfileIdentityCard extends StatelessWidget {
  const ProfileIdentityCard({
    super.key,
    required this.user,
    required this.imrResult,
  });

  final UserModel user;
  final DisplayedImr imrResult;

  @override
  Widget build(BuildContext context) {
    final zoneColor = AppColors.imrZoneColor(imrResult.zone);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.metabolicGreen.withValues(alpha: 0.12),
            ),
            child: const Icon(Icons.person_rounded,
                color: AppColors.metabolicGreen, size: 26),
          ),
          const SizedBox(width: 14),
          // Nombre + patologías
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Tu perfil metabólico',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.45),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // IMR badge
          Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: zoneColor, width: 2),
                ),
                child: Center(
                  child: Text(
                    '${imrResult.score}',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: zoneColor,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                IMRZoneColors.displayLabel(imrResult.zone),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w800,
                  color: zoneColor,
                  letterSpacing: 0.4,
                ),
              ),
              // SPEC-229: badge "datos incompletos" cuando el bloque
              // Estructura usa valores poblacionales (50% del IMR).
              if (imrResult.localFull?.isPartialBiometrics == true)
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: Text(
                    'estimado',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 7.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF59E0B),
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// SPEC-141 §RF-141-13 (2026-06-05): banner visible cuando el badge
/// está mostrando el IMR longitudinal (feature flag ON). Sin firma
/// clínica todavía → mostrar disclaimer transparente.
///
/// SPEC-119: extraído de `_buildLongitudinalDisclaimer` en
/// `profile_screen.dart` (ARCH-03). Sin parámetros, sin cambios.
class ProfileLongitudinalDisclaimer extends StatelessWidget {
  const ProfileLongitudinalDisclaimer({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.30),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.science_outlined,
            color: Color(0xFFF59E0B),
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'IMR longitudinal en validación clínica — '
              'tu número refleja tendencia, no diagnóstico.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.80),
                fontSize: 11,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
