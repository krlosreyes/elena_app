// SPEC-76: disclaimer médico canonicalizado.
//
// Las 5 contraindicaciones que el IMR no cubre y donde el usuario
// requiere supervisión médica. Documentadas en
// `IMR_BIBLIOGRAPHY.md §11`. Versionadas para que cambios futuros
// fuercen re-aceptación.
//
// Si en una SPEC futura cambia el texto o se agrega/quita una
// condición, incrementar `kHealthDisclaimerVersion`. Los usuarios
// existentes con `healthDisclaimerVersion` menor verán el paso 0 de
// nuevo al abrir la app.

import 'package:flutter/material.dart';

/// Versión actual del disclaimer. Incrementar al modificar el copy o
/// la lista de condiciones.
const int kHealthDisclaimerVersion = 1;

/// Lista canónica de poblaciones donde el IMR no aplica sin
/// supervisión médica.
const List<HealthDisclaimerCondition> kHealthDisclaimerConditions = [
  HealthDisclaimerCondition(
    icon: Icons.bloodtype_outlined,
    title: 'Diabetes Tipo 1 / insulinodependiente',
    body:
        'El ayuno prolongado y el ejercicio sin ajuste de insulina pueden inducir hipoglucemia severa.',
  ),
  HealthDisclaimerCondition(
    icon: Icons.psychology_alt_outlined,
    title: 'Historial de TCA (anorexia, bulimia, atracón)',
    body:
        'La gamificación de horas de ayuno y el seguimiento de macros pueden ser triggers de recaída.',
  ),
  HealthDisclaimerCondition(
    icon: Icons.water_drop_outlined,
    title: 'Insuficiencia renal',
    body:
        'Las metas de hidratación y proteína sugeridas pueden no ser apropiadas con restricción hídrica clínica.',
  ),
  HealthDisclaimerCondition(
    icon: Icons.pregnant_woman_outlined,
    title: 'Embarazo o lactancia',
    body:
        'Tu fisiología está en un régimen de crecimiento, no de resiliencia. El IMR no aplica conceptualmente.',
  ),
  HealthDisclaimerCondition(
    icon: Icons.elderly_outlined,
    title: 'Sarcopenia severa o fragilidad (>75 años)',
    body:
        'La restricción de ventanas de comida puede comprometer la ingesta proteica necesaria para preservar masa magra.',
  ),
];

/// Texto de cierre que aparece después de la lista.
const String kHealthDisclaimerClosingNote =
    'Si reconoces alguna de estas condiciones en ti, consulta con tu '
    'médico antes de aplicar las recomendaciones del IMR. La app puede '
    'acompañarte, pero no reemplaza criterio profesional.';

/// Texto del checkbox de aceptación.
const String kHealthDisclaimerAcceptanceText =
    'He leído estas condiciones y entiendo que el IMR no es un '
    'diagnóstico médico. Si alguna aplica a mí, consultaré con mi médico '
    'antes de seguir las recomendaciones de la app.';

class HealthDisclaimerCondition {
  final IconData icon;
  final String title;
  final String body;

  const HealthDisclaimerCondition({
    required this.icon,
    required this.title,
    required this.body,
  });
}

/// Determina si el usuario debe ver/aceptar el disclaimer nuevamente.
/// `true` si nunca lo aceptó o si lo aceptó con una versión previa.
bool needsDisclaimerReprompt({
  required bool accepted,
  required int? acceptedVersion,
}) {
  if (!accepted) return true;
  final v = acceptedVersion ?? 0;
  return v < kHealthDisclaimerVersion;
}
