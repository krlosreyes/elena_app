// Módulo "Tu Glucosa" (23-jul) — punto de entrada MANUAL del protocolo
// desde Perfil (propuesta §5.2 "disponibilidad opcional"): a diferencia
// de `pathologies` (activación automática por prediabetes/diabetes,
// pero de solo lectura post-onboarding — ver biometricos_detail_screen
// .dart), esta card permite a CUALQUIER usuario activar/pausar/
// desactivar el seguimiento, sin depender de esa condición médica.
//
// Mismo patrón visual EXACTO que ProtocoloEntryCard/BiometricosEntryCard
// (icono + título + subtítulo + chevron) — a diferencia de
// `GlucoseEntryCard` (Progreso), esta card NUNCA se oculta: es
// precisamente el lugar donde un usuario sin el protocolo activo puede
// descubrirlo y activarlo.
//
// Decisión de navegación: si el consentimiento informado (R2) todavía
// no fue aceptado, el tap abre `showGlucoseConsentSheet` directamente
// (nunca se activa sin ese paso). Si ya fue aceptado alguna vez, el tap
// abre `showGlucoseProtocolSettingsSheet` (pausar/reanudar/desactivar/
// reactivar) — ambos estados son mutuamente excluyentes porque
// `GlucoseProtocolController.acceptConsent` es el único punto que pone
// `protocolActive = true` la primera vez, siempre junto con
// `consentAccepted = true`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/features/auth/presentation/widgets/profile_settings_group.dart';
import 'package:elena_app/src/features/glucose/application/glucose_providers.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_consent.dart';
import 'package:elena_app/src/features/glucose/presentation/widgets/glucose_consent_sheet.dart';
import 'package:elena_app/src/features/glucose/presentation/widgets/glucose_protocol_settings_sheet.dart';

class GlucoseProtocolEntryCard extends ConsumerWidget {
  const GlucoseProtocolEntryCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final protocolState = ref.watch(glucoseProtocolStateProvider).valueOrNull;
    final eligibility = ref.watch(glucoseProtocolEligibilityProvider);

    final needsConsent = protocolState == null ||
        !protocolState.consentAccepted ||
        protocolState.consentVersion < kGlucoseConsentVersion;

    String subtitle;
    if (!needsConsent && protocolState.protocolActive) {
      subtitle = protocolState.paused ? 'Pausado' : 'Activo';
    } else if (eligibility.eligible) {
      // R1: elegible por `pathologies` pero todavía no activó — mismo
      // tono no-alarmista que el resto de la app (nunca "deberías").
      subtitle = 'No activado · Recomendado para tu perfil';
    } else {
      subtitle = 'No activado';
    }

    return ProfileRow(
      icon: Icons.water_drop_outlined,
      title: 'Seguimiento de glucosa',
      value: subtitle,
      onTap: () {
        if (needsConsent) {
          showGlucoseConsentSheet(
            context,
            welcomeReason: 'Activa el seguimiento de glucosa desde tu perfil, '
                'cuando quieras.',
          );
        } else {
          showGlucoseProtocolSettingsSheet(context);
        }
      },
    );
  }
}
