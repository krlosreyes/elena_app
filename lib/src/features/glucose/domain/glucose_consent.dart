// Módulo "Tu Glucosa" — consentimiento informado específico del
// protocolo de glucosa (propuesta §7.1 y §8: "el riesgo y el copy son
// distintos" del disclaimer general de salud, así que vive en su
// propio archivo versionado en vez de extender
// auth/domain/health_disclaimer.dart).
//
// Mismo mecanismo exacto que health_disclaimer.dart:
// kHealthDisclaimerVersion + needsDisclaimerReprompt — acá
// kGlucoseConsentVersion + needsGlucoseConsentReprompt. Si el copy
// cambia en el futuro, incrementar la versión reactiva el consentimiento
// para todos los usuarios que ya lo habían aceptado.
//
// Cumplimiento legal (glucosa es un dato de salud sensible — GDPR
// art. 9 / Ley 1581 de Colombia, categoría de "dato sensible"):
// el texto es explícito sobre (a) que no es un diagnóstico, (b) que el
// dato se puede pausar/borrar en cualquier momento, y (c) qué se hace
// con el dato (queda en Firestore del usuario, no se comparte).

const int kGlucoseConsentVersion = 1;

const String kGlucoseConsentTitle =
    'Antes de activar tu seguimiento de glucosa';

const String kGlucoseConsentBody =
    'Vamos a pedirte un registro de glucosa capilar (con tu glucómetro '
    'personal) al despertar, antes de comer o beber algo. Con eso, y con '
    'tus otros hábitos en Elena (ayuno, sueño, ejercicio, nutrición e '
    'hidratación), te vamos a mostrar patrones y sugerencias personalizadas.\n\n'
    'Esto es una herramienta de acompañamiento, no un diagnóstico médico ni '
    'un reemplazo de tu HbA1c o el criterio de tu médico. Los glucómetros '
    'domésticos tienen un margen de error de hasta ±15-20% — tratá cada '
    'valor como una referencia, no como un dato de laboratorio exacto.\n\n'
    'Podés pausar o desactivar este seguimiento cuando quieras desde tu '
    'Perfil, sin perder tu historial. Tus lecturas de glucosa quedan '
    'guardadas de forma privada en tu cuenta — no se comparten con '
    'terceros ni con otros usuarios.';

const String kGlucoseConsentAcceptanceText =
    'Entiendo que este seguimiento no es un diagnóstico ni reemplaza a mi '
    'médico, y que puedo pausarlo cuando quiera.';

/// Determina si el usuario debe ver/aceptar el consentimiento de nuevo.
/// `true` si nunca lo aceptó o si lo aceptó con una versión previa —
/// idéntico a `needsDisclaimerReprompt` de health_disclaimer.dart.
bool needsGlucoseConsentReprompt({
  required bool accepted,
  required int consentVersion,
}) {
  if (!accepted) return true;
  return consentVersion < kGlucoseConsentVersion;
}
