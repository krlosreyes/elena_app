// SPEC-77: textos legales canonicalizados.
//
// IMPORTANTE — PROVISIONAL: el texto que sigue es un primer borrador
// estándar para una app de salud metabólica. Antes de submission a
// App Store / Play, DEBE pasar por revisión legal externa. Cuando se
// finalice, se incrementa la versión correspondiente.
//
// Patrón: las secciones se modelan como `LegalSection {title, body}`
// para que el renderizado UI sea genérico (ver `privacy_policy_screen.dart`
// y `terms_of_service_screen.dart`). Cambios al texto pasan por aquí —
// nunca hardcoded en widgets.

const int kPrivacyPolicyVersion = 3;
const int kTermsOfServiceVersion = 1;

class LegalSection {
  final String title;
  final String body;

  const LegalSection({required this.title, required this.body});
}

// ─────────────────────────────────────────────────────────────────────────
// POLÍTICA DE PRIVACIDAD — PROVISIONAL v1
// ─────────────────────────────────────────────────────────────────────────

const List<LegalSection> kPrivacyPolicySections = [
  LegalSection(
    title: 'Datos que recolectamos',
    body: 'Identidad: correo electrónico y nombre que proporcionas al '
        'registrarte. Si entras con Google o con Apple, recibimos de ese '
        'servicio tu correo (con Apple puede ser una dirección de reenvío '
        'privada) y, si lo autorizas, tu nombre.\n\n'
        'Biometría: peso, altura, circunferencias (cintura, cuello), '
        'porcentaje de grasa corporal estimado mediante fórmula US Navy. '
        'Estos datos los proporcionas en el onboarding o los actualizas '
        'desde Perfil.\n\n'
        'Hábitos metabólicos: registros de comidas (incluyendo '
        'macronutrientes si los ingresas), sueño, ejercicio, hidratación '
        'y ayunos. Cada registro queda asociado a tu cuenta con marca '
        'temporal.\n\n'
        'Condiciones médicas que declares en el onboarding (por ejemplo, '
        'prediabetes o diabetes tipo 2), solo para adaptar las '
        'recomendaciones y activar protecciones de seguridad.\n\n'
        'Datos de la app Salud (opcional): ver la sección "Datos de la '
        'app Salud".\n\n'
        'Datos de uso y diagnóstico: qué pantallas y funciones usas y los '
        'informes de errores de la app, para mejorarla.\n\n'
        'Indicadores derivados: tu Índice Metabólico Real (IMR) y sus '
        'componentes se calculan localmente desde los datos anteriores; '
        'el resultado se persiste para mostrarte tu progreso y para que '
        'la web Metamorfosis Real pueda mostrar tu score.',
  ),
  LegalSection(
    title: 'Para qué usamos tus datos',
    body: 'Para calcular tu IMR y mostrarte recomendaciones personalizadas '
        'sobre los 5 pilares (ayuno, ejercicio, nutrición, sueño, '
        'hidratación).\n\n'
        'Para sincronizar tu cuenta entre la app móvil y el sitio web '
        'Metamorfosis Real (https://metamorfosisreal.com), ambos parte '
        'del mismo ecosistema de salud metabólica.\n\n'
        'Para mejorar nuestros algoritmos. Los datos agregados y '
        'anonimizados pueden usarse para refinar las fórmulas del IMR. '
        'NO usamos datos identificables para esto.\n\n'
        'NO compartimos tus datos con anunciantes ni redes sociales. '
        'NO vendemos información personal a terceros.',
  ),
  LegalSection(
    title: 'Con quién compartimos',
    body: 'Google Firebase (Authentication, Firestore, App Check, '
        'Crashlytics, Analytics, Cloud Messaging): infraestructura de '
        'autenticación, base de datos, informes de errores, estadísticas '
        'de uso de la app y notificaciones. Las estadísticas de uso no se '
        'usan para publicidad ni para rastrearte en otras apps. '
        'Los datos están encriptados en tránsito y reposo. Firebase actúa '
        'como procesador de datos bajo nuestras instrucciones, sujeto a '
        'sus propios términos.\n\n'
        'Google y Apple, solo si eliges entrar con ellos, para verificar '
        'tu identidad.\n\n'
        'Sitio web Metamorfosis Real: comparte el mismo backend Firebase. '
        'Si te registras en uno, podemos crear tu acceso al otro con el '
        'mismo correo.\n\n'
        'No compartimos con terceros más allá de los necesarios para '
        'operar el servicio.',
  ),
  LegalSection(
    title: 'Retención y eliminación',
    body: 'Tus datos se conservan mientras tu cuenta esté activa. Cuando '
        'eliminas tu cuenta desde Perfil → Cuenta y datos personales → '
        'Eliminar cuenta, se borra tu usuario de Firebase Authentication y '
        'se inicia el borrado de todos tus datos en Firestore (perfil, '
        'comidas, sueño, ejercicio, ayunos, medidas, glucosa y datos '
        'importados de la app Salud). Si entraste con Apple, también '
        'revocamos el acceso de Elena a tu Apple ID.\n\n'
        'Datos anonimizados agregados pueden conservarse indefinidamente '
        'para investigación y mejora del IMR. Estos datos NO permiten '
        're-identificarte.',
  ),
  LegalSection(
    title: 'Tus derechos',
    body: 'Acceso: puedes ver todos tus datos desde la app en Perfil y '
        'desde el sitio web.\n\n'
        'Rectificación: puedes editar tu nombre, correo y datos básicos '
        'desde Perfil → Cuenta y datos personales, y tus medidas desde '
        'Perfil → Tu cuerpo.\n\n'
        'Eliminación: usa Perfil → Cuenta y datos personales → Eliminar '
        'cuenta. Acción inmediata e irreversible.\n\n'
        'Portabilidad: contáctanos para exportar tus datos en formato '
        'JSON.\n\n'
        'Para ejercer estos derechos o reportar un problema con tus '
        'datos: contacto@metamorfosisreal.com.',
  ),
  LegalSection(
    title: 'Datos de la app Salud',
    body: 'Si conectas Elena con la app Salud de tu iPhone (Apple '
        'HealthKit), y solo después de que lo autorices en la pantalla de '
        'permisos de Apple, leemos: sueño, pasos, minutos de ejercicio, '
        'entrenamientos y peso. Elena solo lee: no escribe ni modifica '
        'nada en la app Salud.\n\n'
        'Para qué: completar automáticamente tus pilares del día (sueño y '
        'movimiento) y prellenar tu peso. Los datos leídos se guardan en '
        'tu cuenta (Firestore) para mostrarte tu historial.\n\n'
        'Lo que NO hacemos con ellos: no los usamos para publicidad ni '
        'marketing, no los vendemos, no los compartimos con terceros '
        'distintos de la infraestructura listada en "Con quién '
        'compartimos", no los enviamos a herramientas de analítica y no '
        'los guardamos en iCloud.\n\n'
        'Puedes retirar el permiso cuando quieras en Ajustes → Salud → '
        'Acceso a datos y dispositivos → Elena. Los datos ya importados se '
        'borran al eliminar tu cuenta.',
  ),
  LegalSection(
    title: 'Datos de salud sensibles: Glucosa',
    body: 'Módulo "Tu Glucosa" (opcional): si activas el seguimiento de '
        'glucosa —ya sea porque marcaste prediabetes/diabetes tipo 2 en '
        'tus condiciones médicas o porque lo activaste manualmente desde '
        'Perfil— guardamos tus lecturas de glucosa (valor en mg/dL, '
        'momento del día, síntomas que reportes) junto con una '
        'instantánea de tu ayuno, sueño y última comida en el momento del '
        'registro, para poder mostrarte correlaciones con tus 5 pilares.\n\n'
        'Bajo la Ley 1581 de 2012 (Colombia) y el RGPD/GDPR (para '
        'usuarios en la Unión Europea), la glucosa es un dato de salud '
        'sensible. Por eso: (a) el módulo nunca se activa sin tu '
        'consentimiento explícito e informado, mostrado antes del primer '
        'registro; (b) puedes pausarlo o desactivarlo en cualquier momento '
        'desde Perfil → Seguimiento de glucosa, sin perder el resto de tu '
        'cuenta; (c) puedes eliminar lecturas individuales directamente '
        'desde "Tu Glucosa" en Progreso (derecho de supresión); (d) no '
        'usamos estos datos para publicidad ni los compartimos con '
        'terceros distintos a los ya listados en "Con quién compartimos".\n\n'
        'El análisis que hacemos con estos datos es educativo y '
        'estadístico (correlación, no diagnóstico): nunca reemplaza el '
        'criterio de un profesional de la salud, y el motor exige un '
        'mínimo de días de datos reales antes de mostrar cualquier '
        'conclusión — nunca inventa patrones con información insuficiente.',
  ),
  LegalSection(
    title: 'Disclaimer médico',
    body: 'ElenaApp NO es un dispositivo médico. El IMR es un indicador '
        'informativo basado en literatura científica revisada, no un '
        'diagnóstico. Si '
        'tienes alguna condición médica o estás en una de las '
        'poblaciones de riesgo listadas en Perfil → Condiciones médicas, '
        'consulta con tu profesional de salud antes de seguir las '
        'recomendaciones de la app.',
  ),
  LegalSection(
    title: 'Cambios a esta política',
    body: 'Si modificamos esta política sustancialmente, te lo notificaremos '
        'la próxima vez que abras la app. Tu uso continuado constituye '
        'aceptación de la versión actual.\n\n'
        'Versión actual: 3. Última actualización: noviembre 2026 (se '
        'agregaron la sección "Datos de la app Salud", el ingreso con '
        'Apple y Google, las estadísticas de uso y la nueva ruta para '
        'eliminar la cuenta).',
  ),
];

// ─────────────────────────────────────────────────────────────────────────
// TÉRMINOS DE USO — PROVISIONAL v1
// ─────────────────────────────────────────────────────────────────────────

const List<LegalSection> kTermsOfServiceSections = [
  LegalSection(
    title: 'Aceptación',
    body: 'Al crear una cuenta o iniciar sesión en ElenaApp aceptas estos '
        'términos y nuestra Política de Privacidad. Si no estás de '
        'acuerdo con alguna parte, debes dejar de usar la app.',
  ),
  LegalSection(
    title: 'Qué ofrecemos',
    body: 'ElenaApp es una herramienta de seguimiento de salud metabólica '
        'basada en el Índice Metabólico Real (IMR). Combina información '
        'de cinco pilares — ayuno, ejercicio, nutrición, sueño, '
        'hidratación — para mostrarte un único score y recomendaciones '
        'personalizadas.\n\n'
        'La app NO reemplaza atención médica profesional. NO emite '
        'diagnósticos. Las sugerencias son informativas y se basan en '
        'literatura revisada, pero las decisiones de salud son tu '
        'responsabilidad y de tu médico tratante.',
  ),
  LegalSection(
    title: 'Tu cuenta',
    body: 'Eres responsable de mantener la confidencialidad de tu '
        'contraseña. Cualquier actividad ejecutada con tu cuenta se '
        'considera tuya.\n\n'
        'Debes proporcionar información veraz en tu perfil. Datos '
        'falsos producen recomendaciones inválidas.\n\n'
        'Si detectas uso no autorizado, escríbenos inmediatamente a '
        'contacto@metamorfosisreal.com.',
  ),
  LegalSection(
    title: 'Conducta aceptable',
    body: 'No uses la app para fines ilegales. No intentes acceder a '
        'cuentas de otros usuarios. No realices ingeniería inversa, '
        'descompilación o extracción de datos masiva.\n\n'
        'Reserva legal: nos reservamos el derecho de suspender cuentas '
        'que violen estas normas.',
  ),
  LegalSection(
    title: 'Limitación de responsabilidad',
    body: 'ElenaApp se ofrece "tal cual". No garantizamos que el servicio '
        'sea ininterrumpido o libre de errores.\n\n'
        'NO somos responsables de decisiones de salud tomadas con base '
        'en información del app. Consulta siempre con un profesional '
        'cualificado antes de cambios significativos en tu nutrición, '
        'ayuno o ejercicio.\n\n'
        'En la medida permitida por la ley, nuestra responsabilidad '
        'total no excederá el monto que hayas pagado por el servicio en '
        'los últimos doce meses (en este momento la app es gratuita).',
  ),
  LegalSection(
    title: 'Cambios a estos términos',
    body: 'Podemos actualizar estos términos. Las versiones materiales se '
        'notificarán al abrir la app. Tu uso continuado tras la '
        'actualización constituye aceptación.\n\n'
        'Versión actual: 1. Última actualización: mayo 2026.',
  ),
  LegalSection(
    title: 'Ley aplicable',
    body: 'Estos términos se rigen por la legislación colombiana. '
        'Cualquier disputa se resolverá en los tribunales competentes '
        'de Bogotá, Colombia.',
  ),
];
