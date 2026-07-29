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

import 'package:elena_app/src/features/streak/domain/fasting_eligibility.dart';

/// Versión actual del disclaimer. Incrementar al modificar el copy o
/// la lista de condiciones.
///
/// v2 (27-jul-2026): la pantalla pasa de pedir un acuse de recibo a
/// pedir una declaración — cambia el copy del checkbox y se añade el
/// cribado marcable. El bump es obligado por la regla de la cabecera de
/// este archivo, y además necesario: todo usuario onboardeado con v1
/// tiene `pathologies` SIN VERIFICAR, porque en v1 no había forma de
/// declarar nada desde aquí. Con el bump vuelven a pasar por el paso 0
/// y el gate de `FastingEligibility` recibe por fin datos reales.
const int kHealthDisclaimerVersion = 2;

/// Valor de `pathologies` cuando el usuario declara no tener ninguna.
/// Es el mismo literal que usa el multi-select de onboarding.
const String kSinPatologias = 'Ninguna';

/// Condiciones del disclaimer que NO tienen todavía un flag en
/// `pathologies`, así que se registran con su propio literal.
///
/// No bloquean el ayuno: el riesgo que describe el propio texto del
/// disclaimer es de hidratación y de ingesta proteica, no de ayunar. Lo
/// que sí hacen es quedar declaradas, para que aparezcan en el perfil y
/// para que la revisión clínica externa pendiente (PRODUCTION_HARDENING
/// §7) decida si merecen gate propio en `FastingEligibility.assess()`.
class DisclaimerOnlyFlags {
  DisclaimerOnlyFlags._();

  static const String insuficienciaRenal = 'Insuficiencia renal';
  static const String sarcopeniaSevera = 'Sarcopenia severa o fragilidad';
}

/// Lista canónica de poblaciones donde el IMR no aplica sin
/// supervisión médica.
///
/// EL DATO QUE FALTABA (recorrido en Simulador, 27-jul-2026)
/// ---------------------------------------------------------
/// `FastingEligibility.assess()` es un cribado médico real y ya
/// implementado: lee `pathologies` y con embarazo o trastorno
/// alimentario declarados devuelve `maxProtocol: 'Ninguno'`, bloqueando
/// el ayuno del todo.
///
/// El guardarraíl existía y funcionaba. Lo que fallaba es que **nunca
/// recibía el dato**: esta pantalla solo pedía marcar "he leído", y
/// `pathologies` se quedaba en `['Ninguna']` salvo que el usuario
/// descubriera por su cuenta un selector dos pantallas más adelante,
/// tras una fila que ya mostraba "Ninguna" como si fuera un valor
/// resuelto. Un diabético tipo 1 leía la advertencia, aceptaba, y
/// terminaba el onboarding con "Patologías: Ninguna" guardado.
///
/// Por eso cada condición lleva ahora su [pathologyFlag]: marcarla
/// escribe en el mismo `pathologies` que alimenta el gate. El texto del
/// checkbox ya asumía que el usuario estaba evaluando cuáles le aplican
/// ("Si alguna aplica a mí, consultaré con mi médico") — solo faltaba
/// recoger la respuesta.
const List<HealthDisclaimerCondition> kHealthDisclaimerConditions = [
  HealthDisclaimerCondition(
    icon: Icons.bloodtype_outlined,
    title: 'Diabetes Tipo 1 / insulinodependiente',
    body:
        'El ayuno prolongado y el ejercicio sin ajuste de insulina pueden inducir hipoglucemia severa.',
    pathologyFlag: FastingPathologyFlags.diabetesMedicada,
  ),
  HealthDisclaimerCondition(
    icon: Icons.psychology_alt_outlined,
    title: 'Historial de TCA (anorexia, bulimia, atracón)',
    body:
        'La gamificación de horas de ayuno y el seguimiento de macros pueden ser triggers de recaída.',
    pathologyFlag: FastingPathologyFlags.trastornoAlimentario,
  ),
  HealthDisclaimerCondition(
    icon: Icons.water_drop_outlined,
    title: 'Insuficiencia renal',
    body:
        'Las metas de hidratación y proteína sugeridas pueden no ser apropiadas con restricción hídrica clínica.',
    pathologyFlag: DisclaimerOnlyFlags.insuficienciaRenal,
  ),
  HealthDisclaimerCondition(
    icon: Icons.pregnant_woman_outlined,
    title: 'Embarazo o lactancia',
    body:
        'Tu fisiología está en un régimen de crecimiento, no de resiliencia. El IMR no aplica conceptualmente.',
    pathologyFlag: FastingPathologyFlags.embarazoLactancia,
  ),
  HealthDisclaimerCondition(
    icon: Icons.elderly_outlined,
    title: 'Sarcopenia severa o fragilidad (>75 años)',
    body:
        'La restricción de ventanas de comida puede comprometer la ingesta proteica necesaria para preservar masa magra.',
    pathologyFlag: DisclaimerOnlyFlags.sarcopeniaSevera,
  ),
];

/// Texto de cierre que aparece después de la lista.
const String kHealthDisclaimerClosingNote =
    'Si reconoces alguna de estas condiciones en ti, consulta con tu '
    'médico antes de aplicar las recomendaciones del IMR. La app puede '
    'acompañarte, pero no reemplaza criterio profesional.';

/// Instrucción de la declaración. Sustituye al "he leído": ahora se pide
/// una respuesta, no un acuse de recibo.
const String kHealthDisclaimerPrompt = '¿Alguna de estas aplica a ti?';

/// Opción explícita de "ninguna". Es obligatoria: sin ella, no marcar
/// nada sería ambiguo entre "no tengo ninguna" y "no leí la lista".
const String kHealthDisclaimerNoneText = 'Ninguna aplica a mí';

/// Texto del checkbox de aceptación.
const String kHealthDisclaimerAcceptanceText =
    'Entiendo que el IMR no es un diagnóstico médico. Si alguna de estas '
    'condiciones aplica a mí, consultaré con mi médico antes de seguir '
    'las recomendaciones de la app.';

class HealthDisclaimerCondition {
  final IconData icon;
  final String title;
  final String body;

  /// Literal que se escribe en `UserModel.pathologies` si el usuario
  /// declara esta condición. Es la conexión entre esta pantalla y
  /// `FastingEligibility.assess()`.
  final String pathologyFlag;

  const HealthDisclaimerCondition({
    required this.icon,
    required this.title,
    required this.body,
    required this.pathologyFlag,
  });
}

/// Traduce lo declarado en esta pantalla a valores de `pathologies`.
///
/// Devuelve `['Ninguna']` si no hay ninguna marcada, para no dejar la
/// lista vacía — el resto de la app trata `['Ninguna']` como "declarado
/// sin condiciones", que es distinto de "sin declarar".
///
/// La guarda va sobre el RESULTADO, no sobre la entrada. La versión
/// anterior comprobaba `flagsMarcados.isEmpty` y devolvía la lista tal
/// cual en el resto de casos: si llegaba un flag que no pertenece al
/// disclaimer —un valor legacy o corrupto en Firestore— ninguna condición
/// lo reconocía y salía `[]`, que aguas abajo es ambiguo entre "declaró
/// que no tiene nada" y "nunca declaró". En un campo médico esa
/// ambigüedad no es aceptable: sin esta guarda, la fila de perfil se
/// renderiza vacía y cualquier chequeo de `isEmpty` lee "sin declarar"
/// sobre alguien que sí declaró.
List<String> pathologiesFromDisclaimer(Set<String> flagsMarcados) {
  final reconocidos = kHealthDisclaimerConditions
      .map((c) => c.pathologyFlag)
      .where(flagsMarcados.contains)
      .toList();
  return reconocidos.isEmpty ? const [kSinPatologias] : reconocidos;
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
