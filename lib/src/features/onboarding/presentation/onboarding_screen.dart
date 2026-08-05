import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:elena_app/src/core/services/app_logger.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/features/onboarding/application/onboarding_controller.dart';
// SPEC-74: prefill + chip + saludo contextual + telemetría.
import 'package:elena_app/src/features/onboarding/domain/onboarding_prefill.dart';
import 'package:elena_app/src/features/onboarding/presentation/widgets/prefill_chip.dart';
import 'package:elena_app/src/features/auth/application/auth_telemetry.dart';
import 'package:elena_app/src/features/auth/domain/app_account.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
// SPEC-90: calcular % grasa con fórmula US Navy en lugar del default 20.
import 'package:elena_app/src/features/fasting/domain/optimal_schedule.dart';
import 'package:elena_app/src/features/profile/domain/body_fat_calculator.dart';
// SPEC-76: disclaimer canonicalizado + versión.
import 'package:elena_app/src/features/auth/domain/health_disclaimer.dart';
// SPEC-137 F: clasificación del sistema nervioso en onboarding Paso 3.
import 'package:elena_app/src/features/nutrition/domain/nervous_system.dart';
// SPEC-131: pantallas educativas para usuarios cero-contexto.
import 'package:elena_app/src/features/onboarding/presentation/widgets/intro_screens.dart';
// SPEC-132 Bloque E: paso opcional para conectar HealthKit / Health Connect.
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/health_sync/application/health_auto_sync_controller.dart';
import 'package:elena_app/src/features/health_sync/application/health_sync_providers.dart';
import 'package:elena_app/src/core/data/app_state_repository.dart';
import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:elena_app/src/features/health_sync/presentation/onboarding_health_step.dart';
// SPEC-168.0.A: paso final del onboarding — sugerencias de metas
// personalizadas con narrativa coaching. Reutiliza GoalSuggestionCard
// y GoalDraft de la pantalla standalone (`/goals/setup`).
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/features/goals/presentation/goal_setup_screen.dart'
    show GoalSuggestionCard;
// DEBT-01 (auditoría técnica 21-jul, P1): estado + lógica del paso
// "Tus objetivos" extraídos a un controller dedicado.
import 'package:elena_app/src/features/onboarding/application/onboarding_goals_controller.dart';
import 'package:elena_app/src/features/onboarding/presentation/widgets/onboarding_step_ui.dart';
import 'package:elena_app/src/features/streak/domain/fasting_eligibility.dart';
import 'package:elena_app/src/features/glucose/domain/glucose_protocol_eligibility.dart';
// Propuesta módulo Ejercicio (2026-07-21): paso "Tu relación con el
// ejercicio" — captura hábitos/preferencias/equipo/lesiones que hoy no
// se preguntan en ningún punto del onboarding. Ver
// documentacion/propuestas/Propuesta_Modulo_Ejercicio_2026-07-21.docx §4.1.
import 'package:elena_app/src/features/exercise/data/exercise_profile_repository_impl.dart';
import 'package:elena_app/src/features/exercise/domain/exercise_profile.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // SPEC-70.8: aceptación del disclaimer clínico (paso 0). El flujo no
  // avanza al paso 1 hasta que el usuario marque el checkbox.
  bool _disclaimerAccepted = false;

  /// Condiciones del disclaimer declaradas, derivadas de `_pathologies`.
  ///
  /// NO es estado propio: se calcula. La primera versión de esto guardaba
  /// las declaraciones en un Set aparte y las fusionaba con
  /// `_pathologies` solo al guardar, y el resultado fue el bug que este
  /// cambio venía a arreglar — declarabas "Embarazo o lactancia" en el
  /// paso 0 y dos pantallas después la fila decía "Patologías: Ninguna",
  /// porque esa fila lee `_pathologies` directo. El dato persistido
  /// habría sido correcto, pero al usuario se le contradecía en pantalla.
  /// Con una sola fuente, todo lo que lea `_pathologies` ve lo mismo.
  Set<String> get _declaredConditions => kHealthDisclaimerConditions
      .map((c) => c.pathologyFlag)
      .where(_pathologies.contains)
      .toSet();

  /// Avisos de lo que cambia en el protocolo por lo declarado. Lista
  /// vacía si nada de lo marcado afecta al ayuno.
  ///
  /// El texto lo pone `FastingEligibility.efectoSobreElAyuno`, que vive
  /// junto a las reglas — aquí solo se pinta.
  List<Widget> _efectosDeclarados() {
    final efectos = _declaredConditions
        .map(FastingEligibility.efectoSobreElAyuno)
        .whereType<String>()
        .toList();
    if (efectos.isEmpty) return const [];

    const amber = Color(0xFFF59E0B);
    return [
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: amber.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: amber.withValues(alpha: 0.40)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.info_outline_rounded, color: amber, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Qué cambia en tu plan',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: amber,
                      letterSpacing: 0.6,
                    ),
                  ),
                  const SizedBox(height: 6),
                  ...efectos.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '· Por lo que declaraste, $e.',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFCBD5E1),
                          height: 1.45,
                        ),
                      ),
                    ),
                  ),
                  const Text(
                    'Puedes cambiarlo desde tu perfil si tu situación cambia.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: Color(0xFF94A3B8),
                      height: 1.4,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ];
  }

  /// Marca o desmarca una condición del cribado sobre `_pathologies`.
  void _toggleDeclaredCondition(String flag) {
    setState(() {
      if (_pathologies.contains(flag)) {
        _pathologies.remove(flag);
      } else {
        _pathologies
          ..remove(kSinPatologias)
          ..add(flag);
      }
      if (_pathologies.isEmpty) _pathologies = [kSinPatologias];
      // Marcar una condición y "ninguna" a la vez es contradictorio:
      // gana lo último que tocó el usuario.
      _declaredNone = false;
    });
  }

  /// "Ninguna aplica a mí": limpia solo las condiciones del disclaimer.
  /// Lo que el usuario haya marcado en el selector de patologías del
  /// paso 3 no se toca — son listas distintas y ninguna manda sobre la
  /// otra.
  void _toggleDeclaredNone() {
    setState(() {
      _declaredNone = !_declaredNone;
      if (_declaredNone) {
        for (final c in kHealthDisclaimerConditions) {
          _pathologies.remove(c.pathologyFlag);
        }
        if (_pathologies.isEmpty) _pathologies = [kSinPatologias];
      }
    });
  }

  /// Declaración explícita de "ninguna aplica". Se guarda aparte del set
  /// vacío a propósito: sin ella no se puede distinguir "no tengo
  /// ninguna" de "no contesté", y no contestar era exactamente el estado
  /// en el que quedaban todos los usuarios antes de este cambio.
  bool _declaredNone = false;

  // SPEC-74: prefill desde AppAccount.rawProfile (cuenta MR existente).
  // Inicializado en initState, una sola vez por sesión de onboarding.
  OnboardingPrefill _prefill = OnboardingPrefill.empty;
  String? _greetingName;
  bool _isReturningMrUser = false;

  // SPEC-84: pasos activos del onboarding. Por defecto los 4 (0..3),
  // pero algunos se saltan cuando el shape canónico del sitio ya
  // entregó esos datos. _currentStep es un índice DENTRO de
  // _activeSteps (no en la numeración original).
  //   0 = Disclaimer médico
  //   1 = Biometría
  //   2 = Ritmos circadianos
  //   3 = Hábitos
  //
  // SPEC-131: ids ≥ 100 reservados para pantallas educativas que se
  // muestran SOLO a usuarios cero-contexto (profileStatus = newProfile).
  //   100 = Bienvenida (qué es ElenaApp)
  //   101 = Qué es el IMR
  //   102 = Por qué pedimos estos datos
  List<int> _activeSteps = const [0, 1, 2, 3];

  // SPEC-247 (2026-07-07): flujo intro rediseñado con principios de influencia
  // anclados a identidad ElenaApp. 4 pantallas vs 5 anteriores.
  //   100 — Identidad (Unidad + Autoridad)
  //   105 — Protocolo (Compromiso y coherencia) ← NUEVA
  //   101 — Insight personalizado (Reciprocidad) ← sustituye "Tus dos números"
  //   104 — Notificaciones (después de Hábitos, sin cambio de posición)
  // Eliminados: 102 ("Tus datos son tuyos") → privacidad en header Biometría.
  //
  // 103 ("Día Metabólico") RESTAURADO el 28-jul-2026. Se había quitado
  // apuntando a "coaching card post-Day-1 (SPEC-249)", pero ese spec
  // nunca existió: no hay archivo en specs/ ni implementación en lib/.
  // La explicación se retiró y el reemplazo no llegó, mientras el término
  // seguía saliendo en 10 pantallas sin definir.
  //
  // Va después de 101 y antes de 104: la definición habla de "tu ayuno",
  // así que necesita que el protocolo ya esté elegido en 105.
  static const int _kIntroProtocolStepId = 105;
  static const int _kIntroMetabolicDayId = 103;
  static const int _kIntroNotificationsId = 104;
  static const List<int> _kIntroStepIds = [
    100,
    _kIntroProtocolStepId,
    101,
    _kIntroMetabolicDayId,
  ];

  // SPEC-132 Bloque E: id del paso "Conectar Apple Health / Health
  // Connect". Solo aparece en cold install (newProfile) y solo en
  // iOS/Android — se inserta DESPUÉS de habits (case 3).
  static const int _kHealthSyncStepId = 200;

  // SPEC-168.0.A: id del paso final "Tus objetivos". Siempre se inserta
  // como último step — sin importar si es cold install o MR, todo
  // usuario debe terminar el onboarding viendo y confirmando sus
  // metas personalizadas (decisión Carlos: coaching desde día uno).
  static const int _kGoalsStepId = 4;

  // Propuesta módulo Ejercicio (2026-07-21): paso "Tu relación con el
  // ejercicio", siempre activo, insertado justo antes de "Tus objetivos"
  // — así el motor de sugerencia de ejercicio (SPEC-244) ya puede leer
  // este perfil si en el futuro se decide usarlo también ahí.
  //
  // UX-ONBOARD (auditoría técnica 21-jul, P1): la pantalla original
  // empaquetaba 6 secciones de decisión en un solo scroll — el punto de
  // mayor fricción de todo el onboarding. Se parte en 3 pantallas de 2
  // secciones cada una, mismo `ExerciseProfile` final, sin agregar ni
  // quitar ninguna pregunta. `_buildExerciseProfileFromState()` sigue
  // leyendo el mismo estado local (`_exerciseLevel`, etc.) sin importar
  // en cuál de las 3 pantallas se haya tocado cada chip — el submit real
  // ocurre una sola vez en `_finalSubmit`, no por pantalla.
  static const int _kExerciseHabitsStepId = 5; // Nivel actual + experiencia
  static const int _kExerciseHabitsStepId2 = 6; // Equipo + preferencias
  static const int _kExerciseHabitsStepId3 = 7; // Objetivo + lesiones

  // SPEC-168.0.A: el borrador local del step Goals (antes campos
  // `_goalDrafts`/`_goalDraftsInitialized` acá mismo) vive ahora en
  // `OnboardingGoalsController` (DEBT-01, 21-jul). Se sigue
  // inicializando lazy la primera vez que el PageView llega al paso,
  // y el usuario puede mover sliders y togglear cada goal antes de
  // persistir en `_finalSubmit` — mismo comportamiento, otro archivo.

  // --- PASO 1: HARDWARE ---
  DateTime _birthDate = DateTime(1980, 1, 1);
  double _weight = 85.0;
  // true cuando el usuario tocó el picker o vino prefillado desde MR.
  // Bloquea el botón SIGUIENTE del paso Biometría hasta que se confirme
  // el peso real — evita guardar el default 85 kg a Firestore.
  bool _weightTouched = false;
  double _height = 180.0;
  String _gender = 'M';
  double _waist = 94.0;
  double _neck = 40.0;
  int _pantSize = 34;
  String _shirtSize = "L";

  // --- PASO 2: RITMOS ---
  // SPEC-96: los defaults se calculan desde OptimalScheduleCalculator
  // según el protocolo elegido. Cuando el usuario cambia protocolo,
  // los horarios se recalculan automáticamente — salvo que el usuario
  // ya haya tocado manualmente alguno (flag `_userTouchedMealTimes`).
  TimeOfDay _wakeUpTime = const TimeOfDay(hour: 6, minute: 0);
  TimeOfDay _sleepTime = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _firstMealGoal = const TimeOfDay(hour: 12, minute: 30);
  TimeOfDay _lastMealGoal = const TimeOfDay(hour: 20, minute: 30);

  /// SPEC-96: bandera para no pisar la elección manual del usuario.
  /// Si tocó alguno de los pickers, el cambio de protocolo NO regenera
  /// los horarios.
  bool _userTouchedMealTimes = false;

  // --- PASO 3: PROTOCOLO ---
  int _mealsPerDay = 3;
  String _fastingProtocol = "16:8";
  List<String> _pathologies = ["Ninguna"];

  // SPEC-137 F: 5 preguntas del sistema nervioso. Cada índice 0-4
  // corresponde a una pregunta calibrada (§RF-137-08.A). Null hasta
  // que el usuario responda. Si el usuario tap "responder después",
  // _snSkipped pasa a true y el sub-step se colapsa.
  final List<NervousSystemAnswer?> _snAnswers =
      List<NervousSystemAnswer?>.filled(5, null);
  bool _snSkipped = false;
  // Si el usuario está clasificado Excitado y elige 20:4, registramos
  // que aceptó la advertencia para no repetirla en futuros cambios.
  String? _protocolWarningAccepted;

  // SPEC-257 Eje A: las 4 últimas opciones son nuevas — antes las
  // patologías declaradas aquí se guardaban en `UserModel.pathologies`
  // pero no restringían ningún protocolo (ver SPEC-257 §1, "gap más
  // importante"). Ahora `FastingEligibility.assess` las lee para
  // calcular el tope real. Se usan las constantes de
  // `FastingPathologyFlags` como fuente única del string exacto.
  // --- PASO 5: HÁBITOS DE EJERCICIO (propuesta 2026-07-21) ---
  //
  // Ver documentacion/propuestas/Propuesta_Modulo_Ejercicio_2026-07-21.docx
  // §4.1. Nunca se había preguntado nada de esto — es la captura que
  // alimenta a WeeklyExercisePlanEngine (Fase 2) junto con BodyZone y
  // sistema nervioso.
  ExerciseFrequencyLevel _exerciseLevel = ExerciseFrequencyLevel.sedentary;
  ExerciseExperienceLevel _strengthExperience = ExerciseExperienceLevel.none;
  ExerciseEquipment _exerciseEquipment = ExerciseEquipment.bodyweightOnly;
  final Set<ExercisePreferenceTag> _likedActivities = {};
  final Set<InjuryTag> _injuries = {};
  final TextEditingController _injuryNotesController = TextEditingController();
  BodyCompositionGoal _bodyCompositionGoal = BodyCompositionGoal.recomposition;

  /// Auditoría en vivo (22-jul): a diferencia de Goals (que no persiste
  /// nada si el usuario nunca inicializó ese paso — ver
  /// `OnboardingGoalsController.persist()`), `_persistExerciseProfile()`
  /// guardaba SIEMPRE `_buildExerciseProfileFromState()`, aunque el
  /// usuario nunca hubiera visto las 3 pantallas de Ejercicio — quedaban
  /// indistinguibles de una elección real (mismo problema que
  /// `ExerciseProfile.isInitial` ya intentaba resolver, pero
  /// `_buildExerciseProfileFromState()` siempre estampa
  /// `updatedAt: DateTime.now()`, así que ese getter nunca da `true` acá).
  /// Este flag se enciende con la primera interacción real del usuario
  /// con cualquier chip/campo de las 3 pantallas — `_persistExerciseProfile`
  /// se salta el guardado si sigue en `false`, igual que Goals.
  bool _exerciseProfileTouched = false;

  // 23-jul: "Prediabetes"/"Diabetes T2" ahora vienen de
  // GlucosePathologyFlags (glucose/domain/glucose_protocol_eligibility.dart)
  // en vez de literales sueltos — es el mismo string que lee
  // GlucoseProtocolEligibility.assess() para activar el Protocolo de
  // Seguimiento de Glucosa; centralizarlo evita que diverjan por un typo.
  final List<String> _pathologyOptions = [
    "Ninguna",
    GlucosePathologyFlags.prediabetes,
    GlucosePathologyFlags.diabetesT2,
    "Hipertensión",
    "Hígado Graso",
    "Hipotiroidismo",
    "SOP",
    "Anemia",
    "Resistencia Insulina",
    FastingPathologyFlags.embarazoLactancia,
    FastingPathologyFlags.trastornoAlimentario,
    FastingPathologyFlags.diabetesMedicada,
    FastingPathologyFlags.supervisionMedicaActiva,
  ];

  // SPEC-137 F: las 5 preguntas calibradas con sus opciones.
  // Copy aprobado por Carlos (NUTRITION_BIBLIOGRAPHY §5).
  static const List<_SnQuestion> _kSnQuestions = [
    _SnQuestion(
      prompt: 'Cuando suena tu alarma en la mañana, ¿cómo te sientes?',
      passive: _SnOption('🐢', 'Lento, me cuesta levantarme'),
      excited: _SnOption('⚡', 'Alerta, listo para empezar'),
    ),
    _SnQuestion(
      prompt: 'Cuando te acuestas en la noche, ¿qué pasa primero?',
      passive: _SnOption('😴', 'Caigo rendido en menos de 10 minutos'),
      excited: _SnOption('🧠', 'Doy vueltas pensando, tardo en dormirme'),
    ),
    _SnQuestion(
      prompt: 'En la primera hora después de despertar, tu cuerpo te pide:',
      passive: _SnOption('🍳', 'Comida — tengo hambre real'),
      excited: _SnOption('☕', 'Solo agua o café, sin hambre'),
    ),
    _SnQuestion(
      prompt:
          'En un día normal sin nada importante, lo que más notas en ti es:',
      passive: _SnOption('🌊', 'Calma, a veces cansancio'),
      excited: _SnOption('⚡', 'Tensión, prisa, mente acelerada'),
    ),
    _SnQuestion(
      prompt: 'Después de comer una porción de carne roja (res, cerdo o '
          'cordero), te sientes:',
      passive: _SnOption('💪', 'Satisfecho y con energía'),
      excited: _SnOption('😴', 'Pesado, lento o hinchado'),
    ),
  ];

  /// Calcula el resultado del SN basado en las respuestas actuales.
  /// Si el usuario saltó, devuelve unknown.
  NervousSystemScore get _snScore => NervousSystemScore.fromAnswers(
      _snAnswers.whereType<NervousSystemAnswer>().toList());

  NervousSystem get _classifiedNervousSystem =>
      _snSkipped ? NervousSystem.unknown : _snScore.classify();

  bool get _snDeclared =>
      !_snSkipped && _snAnswers.whereType<NervousSystemAnswer>().length >= 3;

  void _inferMedidas() {
    setState(() {
      double baseWaist = _pantSize * 2.54;
      _waist = _gender == 'M' ? baseWaist + 5.0 : baseWaist + 2.0;
      switch (_shirtSize) {
        case "S":
          _neck = 36.0;
          break;
        case "M":
          _neck = 39.0;
          break;
        case "L":
          _neck = 42.0;
          break;
        case "XL":
          _neck = 45.0;
          break;
        default:
          _neck = 40.0;
      }
    });
  }

  DateTime _timeToDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  // SPEC-74 §RF-74-01/04/05/08/09: leer AppAccount.rawProfile UNA vez,
  // construir el prefill, aplicar los valores a los defaults del state
  // antes del primer render, y disparar telemetría de inicio.
  @override
  void initState() {
    super.initState();
    // Diferimos el read del provider al primer post-frame para evitar
    // leer providers en initState (Riverpod recomienda usar ref.read sin
    // listen aquí).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _applyPrefillAndTelemetry();
    });
  }

  void _applyPrefillAndTelemetry() {
    final account = ref.read(authStateProvider).value;
    final telemetry = ref.read(authTelemetryProvider);

    // Telemetría obligatoria: el usuario entró a /onboarding.
    telemetry.onboardingStarted();
    if (account != null) {
      telemetry.appProfileStatusObserved(account.profileStatus);
    }

    if (account == null) return;

    // SPEC-247 fix: prefill se computa ANTES de clasificar al usuario.
    // La distinción MR vs signup directo NO puede basarse en prefill.isEmpty
    // porque prefill.name se llena con {name} del rawProfile del signup,
    // haciendo filledCount=1 para cualquier usuario. La distinción correcta
    // es si el rawProfile contiene datos BIOMÉTRICOS (weight/height/waist/
    // gender/birthYear/etc.) que solo provienen del sitio MR, nunca del signup.
    final prefill = OnboardingPrefill.from(account.rawProfile);
    final hasMrBiometricData = prefill.weight != null ||
        prefill.height != null ||
        prefill.waistCircumference != null ||
        prefill.neckCircumference != null ||
        prefill.pantSize != null ||
        prefill.shirtSize != null ||
        prefill.birthYear != null ||
        prefill.gender != null;

    _isReturningMrUser =
        account.profileStatus == AppProfileStatus.partialProfile &&
            hasMrBiometricData;
    if (_isReturningMrUser) {
      // Primera vez que un usuario MR entra a la app.
      telemetry.mrUserFirstLogin();
    }
    if (prefill.isEmpty &&
        (account.displayName == null || account.displayName!.isEmpty)) {
      return; // nada que mostrar/aplicar
    }

    // SPEC-84: prellenar también lastMealGoal desde habits.lastMealHour
    // o habits.dinnerHour si el shape canónico los trae.
    DateTime? lastMealFromCanonical;
    final habits = account.rawProfile?['habits'];
    if (habits is Map) {
      final h = habits.cast<String, dynamic>();
      final hourFloat = (h['lastMealHour'] ?? h['dinnerHour']);
      if (hourFloat is num) {
        final hf = hourFloat.toDouble();
        final hour = hf.floor();
        final minutes = ((hf - hour) * 60).round();
        if (hour >= 0 && hour < 24) {
          lastMealFromCanonical = DateTime(2026, 1, 1, hour, minutes);
        }
      }
    }

    // SPEC-84: calcular qué pasos saltar.
    //   Skip Disclaimer (0) si el sitio ya capturó la aceptación
    //     (`healthDisclaimerAccepted == true`).
    //   Skip Biometría (1) si el shape canónico aportó los 4 críticos:
    //     weight, height, bodyFat MEDIDO, waist. `bodyFat` medido =
    //     `bio.bodyFatPct` presente en rawProfile (no default 20.0).
    //   Ritmos (2) y Hábitos (3) siempre se muestran porque el sitio
    //     no captura los 4 horarios ni pathologies ni mealsPerDay.
    final raw = account.rawProfile;
    // SPEC-76: el disclaimer del sitio solo cuenta como "ya aceptado"
    // si fue capturado con la versión actual. Si el sitio reporta
    // `healthDisclaimerAccepted` pero la versión es menor (o ausente),
    // forzamos re-aceptación en la app.
    final disclaimerAcceptedRaw = raw?['healthDisclaimerAccepted'] == true;
    final disclaimerVersionRaw =
        (raw?['healthDisclaimerVersion'] as num?)?.toInt() ?? 0;
    final disclaimerNeedsReprompt = needsDisclaimerReprompt(
      accepted: disclaimerAcceptedRaw,
      acceptedVersion: disclaimerVersionRaw,
    );
    final bodyFatMeasured =
        raw?['bio'] is Map && (raw!['bio'] as Map)['bodyFatPct'] != null;
    final biometryComplete = prefill.weight != null &&
        prefill.height != null &&
        prefill.waistCircumference != null &&
        bodyFatMeasured;

    // SPEC-131/247: usuarios cero-contexto ven las pantallas educativas.
    // Cold install = newProfile (sin doc Firestore) O partialProfile SIN datos
    // biométricos de MR. Un signup directo solo trae {id, name, email} en
    // rawProfile → hasMrBiometricData = false → es cold install.
    final isColdInstall =
        account.profileStatus == AppProfileStatus.newProfile ||
            (account.profileStatus == AppProfileStatus.partialProfile &&
                !hasMrBiometricData);

    // SPEC-132: el step de Health solo aplica si la plataforma lo
    // soporta. En Web/Desktop el plugin no funciona, así que lo
    // saltamos directamente — el usuario podrá conectarse desde
    // Perfil cuando abra la app en su teléfono. Solo se ofrece a
    // cold installs (los usuarios MR pueden conectar después).
    final healthSupported =
        ref.read(healthSyncServiceProvider).isPlatformSupported;
    final showHealthStep = isColdInstall && healthSupported;

    final activeSteps = <int>[
      if (isColdInstall) ..._kIntroStepIds,
      if (disclaimerNeedsReprompt) 0,
      if (!biometryComplete) 1,
      2,
      3,
      // SPEC-182 §RF-182-05: pantalla educativa de notificaciones con
      // CTA "Activar coaching" — solo para cold installs, después de
      // capturar hábitos y antes de Health Sync.
      if (isColdInstall) _kIntroNotificationsId,
      if (showHealthStep) _kHealthSyncStepId,
      // Propuesta módulo Ejercicio (2026-07-21): siempre activo, justo
      // antes de "Tus objetivos" — todo usuario (cold install o MR)
      // declara sus hábitos de ejercicio antes de ver sus metas.
      // UX-ONBOARD (21-jul, P1): partido en 3 pantallas — ver nota en
      // la constante `_kExerciseHabitsStepId`.
      _kExerciseHabitsStepId,
      _kExerciseHabitsStepId2,
      _kExerciseHabitsStepId3,
      // SPEC-168.0.A: Tus objetivos — siempre al final.
      _kGoalsStepId,
    ];

    setState(() {
      _prefill = prefill;
      _greetingName = (prefill.name?.isNotEmpty ?? false)
          ? prefill.name
          : account.displayName;

      if (prefill.weight != null) {
        _weight = prefill.weight!;
        _weightTouched = true; // viene de MR — ya es un valor real
      } else {
        // Fallback: leer el peso actual del perfil Firestore del usuario
        // (re-onboarding, usuario existente sin datos MR).
        final existingUser = ref.read(currentUserStreamProvider).valueOrNull;
        if (existingUser != null && existingUser.weight > 0) {
          _weight = existingUser.weight;
          _weightTouched = true;
        }
      }
      if (prefill.height != null) _height = prefill.height!;
      if (prefill.gender != null) _gender = prefill.gender!;
      if (prefill.waistCircumference != null) {
        _waist = prefill.waistCircumference!;
      }
      if (prefill.neckCircumference != null) _neck = prefill.neckCircumference!;
      if (prefill.pantSize != null) _pantSize = prefill.pantSize!;
      if (prefill.shirtSize != null) _shirtSize = prefill.shirtSize!;
      if (prefill.birthYear != null) {
        _birthDate =
            DateTime(prefill.birthYear!, _birthDate.month, _birthDate.day);
      }

      // SPEC-84: prellenar fastingProtocol desde habits.fastingHours.
      final habitsMap = raw?['habits'];
      if (habitsMap is Map) {
        final h = habitsMap.cast<String, dynamic>();
        final fh = h['fastingHours'];
        if (fh is num) {
          switch (fh.toInt()) {
            case 0:
              _fastingProtocol = 'Ninguno';
              break;
            case 16:
              _fastingProtocol = '16:8';
              break;
            case 18:
              _fastingProtocol = '18:6';
              break;
            case 20:
              _fastingProtocol = '20:4';
              break;
          }
        }
      }

      // SPEC-84: prellenar TimeOfDay de última comida si vino del sitio.
      if (lastMealFromCanonical != null) {
        _lastMealGoal = TimeOfDay(
          hour: lastMealFromCanonical.hour,
          minute: lastMealFromCanonical.minute,
        );
      }

      // SPEC-84 / SPEC-76: si el sitio capturó el disclaimer en la
      // versión actual, lo damos por aceptado. Si la versión es
      // distinta (o no existe), el flujo fuerza re-aceptación.
      if (!disclaimerNeedsReprompt) {
        _disclaimerAccepted = true;
      }

      // Las condiciones marcadas se derivan de `_pathologies`, que ya
      // viene rehidratado — no hay nada que copiar.
      //
      // "Ninguna aplica" es distinto: solo se da por respondido si el
      // perfil declaró bajo la versión ACTUAL del disclaimer. Verificado
      // en Simulador (28-jul): sin esta condición, una cuenta creada con
      // v1 llegaba al cribado nuevo con "Ninguna aplica a mí" ya marcado
      // —porque su `pathologies` era `['Ninguna']` por defecto, no por
      // declaración— y bastaba con pulsar continuar para saltárselo
      // entero. Eso vaciaba de sentido el bump de versión, que existe
      // precisamente para que esos perfiles vuelvan a declarar.
      _declaredNone = !disclaimerNeedsReprompt &&
          _declaredConditions.isEmpty &&
          _pathologies.contains(kSinPatologias);

      _activeSteps = activeSteps;
    });
  }

  @override
  void dispose() {
    _injuryNotesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    // DEBT-01: mantiene vivo el Provider.autoDispose de goals mientras
    // esta pantalla esté montada (ver nota en
    // onboarding_goals_controller.dart sobre por qué hace falta un
    // watch, no solo reads puntuales).
    ref.watch(onboardingGoalsControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // SPEC-247: PageView solo con los pasos activos. Los educativos
    // (100, 105, 101) preceden a los tradicionales (0-3) para cold install.
    final pages = _activeSteps.map((index) {
      switch (index) {
        case 100:
          // Identidad: Unidad + Autoridad. Citation pills con NEJM/Levine/AASM.
          return IntroWelcomeStep(isDark: isDark);
        case _kIntroProtocolStepId: // 105
          // Compromiso y coherencia: el usuario elige su protocolo clínico.
          // El callback actualiza _fastingProtocol para pre-poblar paso 3.
          return IntroProtocolStep(
            isDark: isDark,
            selectedProtocol: _fastingProtocol,
            onProtocolSelected: (p) => setState(() => _fastingProtocol = p),
          );
        case 101:
          // Reciprocidad: insight científico personalizado al protocolo elegido.
          return IntroInsightStep(
            isDark: isDark,
            protocol: _fastingProtocol,
          );
        case _kIntroMetabolicDayId: // 103
          // Qué es el Día Metabólico. Recibe el protocolo porque con
          // 'Ninguno' el ciclo SÍ es calendárico y hay que decirlo — es
          // el caso de quien no eligió ayuno y también el de quien lo
          // tiene bloqueado por el cribado médico.
          return IntroMetabolicDayStep(
            isDark: isDark,
            protocol: _fastingProtocol,
          );
        case 104:
          // SPEC-247: Notificaciones. Dos CTAs — activar dispara
          // requestPermissions, "ahora no" avanza. La "prueba social"
          // 78/31% que había aquí se retiró el 27-jul-2026 por ser un
          // dato inventado; ver la nota en IntroNotificationsStep.
          return IntroNotificationsStep(
            isDark: isDark,
            onActivate: _activateNotifications,
            onSkip: _handleNext,
          );
        case 0:
          return _buildStepDisclaimer(isDark);
        case 1:
          return _buildStepBiometry(isDark);
        case 2:
          return _buildStepCircadian(isDark);
        case 3:
          return _buildStepHabits(isDark);
        case _kHealthSyncStepId:
          // SPEC-132 E: paso opcional. `onContinue` dispara el avance
          // del PageView via el mismo flujo que el botón "Siguiente"
          // de los demás pasos.
          return OnboardingHealthStep(
            isDark: isDark,
            onContinue: _handleNext,
          );
        case _kExerciseHabitsStepId:
          // UX-ONBOARD (21-jul, P1): pantalla 1/3 — nivel actual +
          // experiencia con fuerza. Insumo de WeeklyExercisePlanEngine
          // (Fase 2).
          return _buildStepExerciseHabitsPart1(isDark);
        case _kExerciseHabitsStepId2:
          // UX-ONBOARD: pantalla 2/3 — equipo disponible + preferencias.
          return _buildStepExerciseHabitsPart2(isDark);
        case _kExerciseHabitsStepId3:
          // UX-ONBOARD: pantalla 3/3 — objetivo de composición + lesiones.
          return _buildStepExerciseHabitsPart3(isDark);
        case _kGoalsStepId:
          // SPEC-168.0.A: paso final — sugerencias de objetivos
          // personalizadas con narrativa coaching.
          return _buildStepGoals(isDark);
        default:
          return _buildStepHabits(isDark);
      }
    }).toList();

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                // SPEC-84: progreso relativo a los pasos activos (≤ 4).
                child: LinearProgressIndicator(
                  value:
                      pages.isEmpty ? 1.0 : (_currentStep + 1) / pages.length,
                  backgroundColor: isDark ? Colors.white10 : Colors.black12,
                  color: const Color(0xFF10B981),
                  minHeight: 6,
                ),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: pages,
              ),
            ),
            _buildBottomNavigation(state, isDark),
          ],
        ),
      ),
    );
  }

  // --- PASO 0: DISCLAIMER CLÍNICO (SPEC-70.8) ---
  //
  // Pantalla obligatoria antes de cualquier captura de datos. Lista las
  // 5 poblaciones de §11 del IMR_BIBLIOGRAPHY.md donde el IMR no aplica
  // o requiere supervisión médica. El usuario debe marcar el checkbox
  // explícitamente para avanzar.
  Widget _buildStepDisclaimer(bool isDark) {
    final accentColor = isDark ? Colors.amber : Colors.amber[800]!;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary =
        (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.65);

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: accentColor.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: accentColor.withValues(alpha: 0.30)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.medical_information_outlined,
                  color: accentColor, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ANTES DE COMENZAR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: accentColor,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'El IMR está diseñado para adultos sanos. Hay condiciones donde NO debes seguir sus recomendaciones sin supervisión médica.',
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // 27-jul-2026: la lista pasa de informativa a DECLARABLE. Ver la
        // nota larga en `kHealthDisclaimerConditions`: el gate de
        // `FastingEligibility.assess()` ya existía y funcionaba, pero
        // nunca recibía el dato porque esta pantalla solo pedía "he
        // leído".
        Text(
          kHealthDisclaimerPrompt,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 12),

        // SPEC-76: consume la lista canonicalizada de
        // `health_disclaimer.dart`. Cambios al texto pasan por allá.
        ...kHealthDisclaimerConditions.map(
          (c) => DisclaimerItem(
            icon: c.icon,
            title: c.title,
            body: c.body,
            isDark: isDark,
            selected: _declaredConditions.contains(c.pathologyFlag),
            onToggle: () => _toggleDeclaredCondition(c.pathologyFlag),
          ),
        ),

        // Opción explícita de "ninguna". Sin ella, no marcar nada sería
        // ambiguo entre "no tengo ninguna" y "no leí la lista", y ese es
        // justo el estado en el que quedaban TODOS los usuarios antes.
        DisclaimerItem(
          icon: Icons.check_circle_outline,
          title: kHealthDisclaimerNoneText,
          body: 'Ninguna de las condiciones de arriba es mi caso.',
          isDark: isDark,
          selected: _declaredNone,
          onToggle: _toggleDeclaredNone,
        ),

        // Aviso de consecuencia. Ver `FastingEligibility.efectoSobreElAyuno`:
        // el recorte del protocolo ocurre al guardar, así que sin esto el
        // usuario declaraba embarazo, seguía viendo "Ayuno 16:8" el resto
        // del onboarding, y se encontraba el ayuno bloqueado al final sin
        // explicación.
        ..._efectosDeclarados(),

        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color:
                (isDark ? Colors.white : Colors.black).withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            kHealthDisclaimerClosingNote,
            style: TextStyle(
              fontSize: 11.5,
              color: textSecondary,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Checkbox de aceptación
        InkWell(
          onTap: () =>
              setState(() => _disclaimerAccepted = !_disclaimerAccepted),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _disclaimerAccepted
                        ? const Color(0xFF10B981)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _disclaimerAccepted
                          ? const Color(0xFF10B981)
                          : textSecondary,
                      width: 1.5,
                    ),
                  ),
                  child: _disclaimerAccepted
                      ? const Icon(Icons.check, size: 18, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    kHealthDisclaimerAcceptanceText,
                    style: TextStyle(
                      fontSize: 13,
                      color: textPrimary,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // --- PASO 1: BIOMETRÍA ---
  // SPEC-74 §RF-74-02/03/06: saludo contextual + chip de prefill al
  // inicio del paso de captura biométrica. Si el usuario viene del
  // ecosistema MR (PARTIAL_PROFILE), el copy se personaliza y se
  // muestra cuántos campos están pre-llenados.
  Widget _buildStepBiometry(bool isDark) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _greetingHeader(isDark),
          if (_prefill.filledCount > 0)
            PrefillChip(filledCount: _prefill.filledCount),
          OnboardingStepHeader(
              title: "Tu cuerpo hoy",
              sub: "Para calcular tu edad metabólica (IMR)",
              isDark: isDark),
          OnboardingStepHelperLine(
            text: 'Estas medidas nos sirven para estimar tu composición '
                'corporal sin pedirte que adivines tu % de grasa. '
                'Quedan en tu cuenta privada — no se comparten.',
            isDark: isDark,
          ),
          _simpleSelector(
              "Nacimiento", DateFormat('dd/MM/yyyy').format(_birthDate),
              () async {
            final date = await showDatePicker(
                context: context,
                initialDate: _birthDate,
                firstDate: DateTime(1940),
                lastDate: DateTime.now());
            if (date != null) setState(() => _birthDate = date);
          }, isDark),
          _simpleSelector(
              "Sexo",
              _gender == 'M' ? "Masculino" : "Femenino",
              () => _showSimpleOptions("Sexo", ["Masculino", "Femenino"], (v) {
                    setState(() => _gender = v == "Masculino" ? 'M' : 'F');
                    _inferMedidas();
                  }, isDark),
              isDark),
          _pickerSelector(
              label: "Estatura",
              displayValue: "${_height.toInt()} cm",
              isDark: isDark,
              onTap: () => _showNumericPicker(
                    title: "Estatura",
                    value: _height,
                    min: 140,
                    max: 220,
                    unit: " cm",
                    isDark: isDark,
                    onChanged: (v) => setState(() => _height = v),
                  )),
          _pickerSelector(
              label: "Peso *",
              displayValue: _weightTouched
                  ? "${_weight.toInt()} kg"
                  : "Toca para ingresar",
              isDark: isDark,
              onTap: () => _showNumericPicker(
                    title: "Peso",
                    value: _weight,
                    min: 40,
                    max: 200,
                    unit: " kg",
                    isDark: isDark,
                    onChanged: (v) => setState(() {
                      _weight = v;
                      _weightTouched = true;
                    }),
                  )),
          OnboardingSectionTitle(
              title: "TALLAS (SOLO PARA ESTIMAR MEDIDAS)", isDark: isDark),
          Row(children: [
            Expanded(
                child: _pickerSelector(
                    label: "Camisa",
                    displayValue: _shirtSize,
                    isDark: isDark,
                    onTap: () => _showStringPicker(
                          title: "Talla de camisa",
                          options: const ["XS", "S", "M", "L", "XL", "XXL"],
                          current: _shirtSize,
                          isDark: isDark,
                          onChanged: (v) {
                            setState(() => _shirtSize = v);
                            _inferMedidas();
                          },
                        ))),
            const SizedBox(width: 12),
            Expanded(
                child: _pickerSelector(
                    label: "Pant.",
                    displayValue: "$_pantSize",
                    isDark: isDark,
                    onTap: () => _showNumericPicker(
                          title: "Talla de pantalón",
                          value: _pantSize.toDouble(),
                          min: 26,
                          max: 52,
                          unit: "",
                          isDark: isDark,
                          onChanged: (v) {
                            setState(() => _pantSize = v.toInt());
                            _inferMedidas();
                          },
                        ))),
          ]),
          OnboardingSectionTitle(
              title: "LO QUE MÁS AFINA TU IMR", isDark: isDark),
          _pickerSelector(
              label: "Cintura",
              displayValue: "${_waist.toInt()} cm",
              isDark: isDark,
              onTap: () => _showNumericPicker(
                    title: "Cintura",
                    value: _waist,
                    min: 50,
                    max: 150,
                    unit: " cm",
                    isDark: isDark,
                    onChanged: (v) => setState(() => _waist = v),
                  )),
          _pickerSelector(
              label: "Cuello",
              displayValue: "${_neck.toInt()} cm",
              isDark: isDark,
              onTap: () => _showNumericPicker(
                    title: "Cuello",
                    value: _neck,
                    min: 20,
                    max: 60,
                    unit: " cm",
                    isDark: isDark,
                    onChanged: (v) => setState(() => _neck = v),
                  )),
        ],
      );

  // --- PASO 2: RITMOS ---
  Widget _buildStepCircadian(bool isDark) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          OnboardingStepHeader(
              title: "Ritmo Circadiano",
              sub: "Para alinear tu ventana con tus horarios",
              isDark: isDark),
          OnboardingStepHelperLine(
            text: 'Tu reloj biológico decide cuándo el ayuno funciona mejor. '
                'Vamos a alinear tu ventana de comida con tus horarios reales.',
            isDark: isDark,
          ),
          _simpleSelector("Despertar", _wakeUpTime.format(context), () async {
            final time = await showTimePicker(
                context: context, initialTime: _wakeUpTime);
            if (time != null) setState(() => _wakeUpTime = time);
          }, isDark),
          _simpleSelector("Dormir", _sleepTime.format(context), () async {
            final time =
                await showTimePicker(context: context, initialTime: _sleepTime);
            if (time != null) setState(() => _sleepTime = time);
          }, isDark),
          OnboardingSectionTitle(
              title: "VENTANA DE ALIMENTACIÓN", isDark: isDark),
          _simpleSelector("Primera Comida", _firstMealGoal.format(context),
              () async {
            final time = await showTimePicker(
                context: context, initialTime: _firstMealGoal);
            if (time != null) {
              setState(() {
                _firstMealGoal = time;
                // SPEC-96: el usuario tomó control manual; deja de
                // autocalcular al cambiar protocolo.
                _userTouchedMealTimes = true;
              });
            }
          }, isDark),
          _simpleSelector("Última Comida", _lastMealGoal.format(context),
              () async {
            final time = await showTimePicker(
                context: context, initialTime: _lastMealGoal);
            if (time != null) {
              setState(() {
                _lastMealGoal = time;
                _userTouchedMealTimes = true;
              });
            }
          }, isDark),
        ],
      );

  // --- PASO 3: HÁBITOS ---
  Widget _buildStepHabits(bool isDark) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          OnboardingStepHeader(
              title: "Protocolo", sub: "Hábitos metabólicos", isDark: isDark),
          OnboardingStepHelperLine(
            text: 'Ya tenemos tu perfil físico. Ahora vamos a conocerte un '
                'poco más y a elegir cómo quieres ayunar.',
            isDark: isDark,
          ),
          // SPEC-137 F: 3.A — 5 preguntas del sistema nervioso.
          _buildSnSection(isDark),
          const SizedBox(height: 16),
          // SPEC-137 F: 3.B — tarjeta de sugerencia visual según SN.
          _buildSnSuggestionCard(isDark),
          const SizedBox(height: 16),
          _simpleSelector(
              "Ayuno",
              _fastingProtocol,
              () => _showSimpleOptions(
                  "Ayuno",
                  ["Ninguno", "16:8", "18:6", "20:4"],
                  (v) => _handleProtocolChange(v),
                  isDark),
              isDark),
          _pickerSelector(
              label: "Comidas al día",
              displayValue: "$_mealsPerDay",
              isDark: isDark,
              onTap: () => _showNumericPicker(
                    title: "Comidas al día",
                    value: _mealsPerDay.toDouble(),
                    min: 1,
                    max: 6,
                    unit: "",
                    isDark: isDark,
                    onChanged: (v) => setState(() => _mealsPerDay = v.toInt()),
                  )),
          _simpleSelector("Patologías", _pathologies.join(", "),
              () => _showMultiSelectPathologies(isDark), isDark),
        ],
      );

  // --- PASO 5-7: HÁBITOS DE EJERCICIO (propuesta 2026-07-21) ---
  //
  // Ver documentacion/propuestas/Propuesta_Modulo_Ejercicio_2026-07-21.docx
  // §4.1. Chips simples — sin scroll horizontal, todo visible de un
  // vistazo, mismo lenguaje visual que el resto del onboarding.
  //
  // UX-ONBOARD (auditoría técnica 21-jul, P1): las 6 secciones originales
  // vivían en un solo scroll largo — el punto de mayor fricción de todo
  // el onboarding. Se dividen en 3 pantallas de 2 secciones cada una,
  // agrupadas por tema (capacidad actual / condiciones de entrenamiento
  // / objetivo y seguridad). Ningún chip, opción ni pregunta cambia —
  // solo el empaquetado visual. El estado local sigue siendo el mismo
  // (`_exerciseLevel`, `_strengthExperience`, etc.), así que
  // `_buildExerciseProfileFromState()` no necesita ningún cambio.

  /// Pantalla 1/3: capacidad actual (nivel + experiencia con fuerza).
  Widget _buildStepExerciseHabitsPart1(bool isDark) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          OnboardingStepHeader(
            title: "Tu relación con el ejercicio",
            sub: "Para armar TU plan, no uno genérico",
            isDark: isDark,
          ),
          OnboardingStepHelperLine(
            text: 'Con esto Elena arma tu plan semanal de fuerza + cardio '
                '— ajustado a lo que ya haces, no a lo que "deberías" hacer.',
            isDark: isDark,
          ),
          OnboardingSectionTitle(title: "NIVEL ACTUAL", isDark: isDark),
          _chipGroup<ExerciseFrequencyLevel>(
            options: ExerciseFrequencyLevel.values,
            labelOf: (v) => v.label,
            isSelected: (v) => _exerciseLevel == v,
            onTap: (v) => setState(() => _exerciseLevel = v),
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          OnboardingSectionTitle(
              title: "EXPERIENCIA CON FUERZA", isDark: isDark),
          _chipGroup<ExerciseExperienceLevel>(
            options: ExerciseExperienceLevel.values,
            labelOf: (v) => v.label,
            isSelected: (v) => _strengthExperience == v,
            onTap: (v) => setState(() => _strengthExperience = v),
            isDark: isDark,
          ),
        ],
      );

  /// Pantalla 2/3: condiciones de entrenamiento (equipo + preferencias).
  Widget _buildStepExerciseHabitsPart2(bool isDark) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          OnboardingStepHeader(
            title: "Cómo vas a entrenar",
            sub: "Para armar sesiones que sí puedas cumplir",
            isDark: isDark,
          ),
          OnboardingSectionTitle(title: "EQUIPO DISPONIBLE", isDark: isDark),
          _chipGroup<ExerciseEquipment>(
            options: ExerciseEquipment.values,
            labelOf: (v) => v.label,
            isSelected: (v) => _exerciseEquipment == v,
            onTap: (v) => setState(() => _exerciseEquipment = v),
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          OnboardingSectionTitle(
              title: "QUÉ TE GUSTA (opcional, elige las que quieras)",
              isDark: isDark),
          _multiChipGroup<ExercisePreferenceTag>(
            options: ExercisePreferenceTag.values,
            labelOf: (v) => v.label,
            isSelected: (v) => _likedActivities.contains(v),
            onTap: (v) => setState(() {
              if (v == ExercisePreferenceTag.ninguna) {
                _likedActivities
                  ..clear()
                  ..add(v);
              } else {
                _likedActivities.remove(ExercisePreferenceTag.ninguna);
                if (!_likedActivities.remove(v)) _likedActivities.add(v);
              }
            }),
            isDark: isDark,
          ),
        ],
      );

  /// Pantalla 3/3: objetivo de composición corporal + lesiones/límites.
  Widget _buildStepExerciseHabitsPart3(bool isDark) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          OnboardingStepHeader(
            title: "Tu objetivo y tu seguridad",
            sub: "Lo último — para que tu plan te cuide",
            isDark: isDark,
          ),
          OnboardingSectionTitle(
              title: "OBJETIVO DE COMPOSICIÓN CORPORAL", isDark: isDark),
          _chipGroup<BodyCompositionGoal>(
            options: BodyCompositionGoal.values,
            labelOf: (v) => v.label,
            isSelected: (v) => _bodyCompositionGoal == v,
            onTap: (v) => setState(() => _bodyCompositionGoal = v),
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          OnboardingSectionTitle(
              title: "LESIONES O LIMITACIONES (opcional)", isDark: isDark),
          OnboardingStepHelperLine(
            text: 'Nunca te vamos a prescribir carga sobre una lesión '
                'activa — esto solo ayuda a Elena a evitar movimientos '
                'de riesgo en tu plan.',
            isDark: isDark,
          ),
          const SizedBox(height: 8),
          _multiChipGroup<InjuryTag>(
            options: InjuryTag.values,
            labelOf: (v) => v.label,
            isSelected: (v) => _injuries.contains(v),
            onTap: (v) => setState(() {
              if (!_injuries.remove(v)) _injuries.add(v);
            }),
            isDark: isDark,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _injuryNotesController,
            maxLines: 2,
            onChanged: (_) => _exerciseProfileTouched = true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              hintText: 'Detalle opcional (ej: "hernia L4-L5 diagnosticada")',
              hintStyle: TextStyle(
                color: (isDark ? Colors.white : Colors.black).withValues(
                  alpha: 0.35,
                ),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1E293B) : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
                ),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
        ],
      );

  Widget _chipGroup<T>({
    required List<T> options,
    required String Function(T) labelOf,
    required bool Function(T) isSelected,
    required void Function(T) onTap,
    required bool isDark,
  }) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options
          .map((o) => _onboardingChip(
                label: labelOf(o),
                selected: isSelected(o),
                onTap: () {
                  // Auditoría 22-jul: único choke point de las 6 selecciones
                  // de Ejercicio — ver nota en `_exerciseProfileTouched`.
                  _exerciseProfileTouched = true;
                  onTap(o);
                },
                isDark: isDark,
              ))
          .toList(),
    );
  }

  /// Igual que `_chipGroup` pero sin exclusividad — varias opciones
  /// pueden estar seleccionadas a la vez (preferencias, lesiones).
  Widget _multiChipGroup<T>({
    required List<T> options,
    required String Function(T) labelOf,
    required bool Function(T) isSelected,
    required void Function(T) onTap,
    required bool isDark,
  }) =>
      _chipGroup<T>(
        options: options,
        labelOf: labelOf,
        isSelected: isSelected,
        onTap: onTap,
        isDark: isDark,
      );

  Widget _onboardingChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    const accent = Color(0xFF10B981);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? accent.withValues(alpha: 0.16)
              : (isDark ? const Color(0xFF1E293B) : Colors.white),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? accent
                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
            color: selected
                ? accent
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  /// Construye el `ExerciseProfile` a partir del state local del paso 5.
  ExerciseProfile _buildExerciseProfileFromState() {
    return ExerciseProfile(
      currentLevel: _exerciseLevel,
      strengthExperience: _strengthExperience,
      equipment: _exerciseEquipment,
      likedActivities: _likedActivities.toList(),
      availableWeekdays: const [], // sin restricción declarada en v1
      injuries: _injuries.toList(),
      injuryNotes: _injuryNotesController.text.trim(),
      goal: _bodyCompositionGoal,
      updatedAt: DateTime.now(),
    );
  }

  /// Persiste el perfil de ejercicio. Mismo patrón que
  /// `_persistGoalDrafts`: un fallo aquí no debe bloquear el cierre del
  /// onboarding — el usuario puede completar/editar su perfil de
  /// ejercicio después desde Perfil.
  ///
  /// Auditoría en vivo (22-jul): guard agregado para que este método
  /// tenga la MISMA semántica que `OnboardingGoalsController.persist()`
  /// (que no escribe nada si `drafts` nunca se inicializó). Antes se
  /// guardaba siempre, aunque el usuario jamás hubiera visto las 3
  /// pantallas de Ejercicio — dejando defaults de clase (`Sedentario`,
  /// `Ninguna`, `Solo peso corporal`, etc.) indistinguibles de una
  /// elección real. Confirmado en producción: una cuenta de prueba cuyo
  /// onboarding saltó esas 3 pantallas terminó con
  /// `exerciseMinutesPerDay: 20` en Firestore como si el usuario lo
  /// hubiera elegido.
  Future<void> _persistExerciseProfile(String userId) async {
    if (userId.isEmpty) return;
    if (!_exerciseProfileTouched) return;
    await ref
        .read(exerciseProfileRepositoryProvider)
        .save(userId, _buildExerciseProfileFromState());
  }

  /// Rank en la escalera canónica (`FastingEligibility.ladder`) — única
  /// fuente de verdad del orden, compartida con Eje A/B. `-1` para
  /// strings desconocidos (no debería pasar con las opciones de este
  /// selector).
  static int _protocolRank(String protocol) =>
      FastingEligibility.ladder.indexOf(protocol);

  /// SPEC-137 F + SPEC-257 Eje C: maneja el cambio de protocolo. Antes
  /// el guardrail solo cubría el salto exacto a 20:4 con SN=Excitado
  /// declarado — dejaba pasar sin aviso a alguien Excitado que subiera
  /// directo a 18:6, y a quien no respondió las 5 preguntas del SN
  /// (`unknown`) se le trataba como si no hubiera riesgo. SPEC-257 §4
  /// Eje C generaliza: cualquier salto que suba de nivel Y quede por
  /// encima de 16:8 dispara el aviso, y `unknown` se trata como
  /// Excitado (conservador) SOLO para esta decisión — no cambia lo que
  /// se persiste en `nervousSystem`.
  void _handleProtocolChange(String newProtocol) {
    final guardrailNS = _classifiedNervousSystem == NervousSystem.unknown
        ? NervousSystem.excited
        : _classifiedNervousSystem;
    final isUpwardPastSixteenEight =
        _protocolRank(newProtocol) > _protocolRank('16:8') &&
            _protocolRank(newProtocol) > _protocolRank(_fastingProtocol);
    final warningKey = '$newProtocol-on-excited';
    final needsGuardrail = guardrailNS == NervousSystem.excited &&
        isUpwardPastSixteenEight &&
        _protocolWarningAccepted != warningKey;

    if (needsGuardrail) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Theme.of(ctx).brightness == Brightness.dark
              ? AppColors.bgElevated
              : Colors.white,
          title: const Text('🤔 Una sugerencia honesta'),
          content: Text(
            'Las personas con perfil Excitado (sueño superficial, '
            'tensión baseline, apetito matutino bajo) suelen tolerar '
            '$newProtocol mejor después de adaptarse con 16:8 unas semanas.\n\n'
            'Empezar directo con $newProtocol puede aumentar tu tensión, '
            'empeorar tu sueño y romper la adherencia. No es '
            'prohibición — es algo que hemos visto.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _applyProtocolChange('16:8');
              },
              child: const Text('Empezar con 16:8'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _protocolWarningAccepted = warningKey;
                _applyProtocolChange(newProtocol);
              },
              child: Text('Mantener $newProtocol'),
            ),
          ],
        ),
      );
    } else {
      _applyProtocolChange(newProtocol);
    }
  }

  void _applyProtocolChange(String newProtocol) {
    setState(() {
      _fastingProtocol = newProtocol;
      // SPEC-96: recalcular horarios si el usuario no los tocó.
      if (!_userTouchedMealTimes) {
        final optimal = OptimalScheduleCalculator.forProtocol(newProtocol);
        _firstMealGoal = optimal.windowStart;
        _lastMealGoal = optimal.windowEnd;
      }
    });
  }

  /// SPEC-137 F §RF-137-08.A: sección colapsable de 5 preguntas SN.
  Widget _buildSnSection(bool isDark) {
    final bg = isDark ? AppColors.bgSurface : Colors.white;
    final border = isDark ? AppColors.borderDefault : Colors.black12;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Conócete primero',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (!_snSkipped)
                TextButton(
                  onPressed: () => setState(() => _snSkipped = true),
                  child: const Text(
                    'Después →',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            _snSkipped
                ? 'Puedes responder más tarde desde Perfil.'
                : 'Cinco preguntas rápidas para personalizar tu plan.',
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          if (!_snSkipped) ...[
            const SizedBox(height: 14),
            for (var i = 0; i < _kSnQuestions.length; i++)
              _buildSnQuestionTile(i, _kSnQuestions[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildSnQuestionTile(int index, _SnQuestion q) {
    final answered = _snAnswers[index];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${index + 1}. ${q.prompt}',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          _buildSnOptionRow(
            option: q.passive,
            selected: answered == NervousSystemAnswer.classifiesAsPassive,
            onTap: () => setState(() =>
                _snAnswers[index] = NervousSystemAnswer.classifiesAsPassive),
          ),
          const SizedBox(height: 6),
          _buildSnOptionRow(
            option: q.excited,
            selected: answered == NervousSystemAnswer.classifiesAsExcited,
            onTap: () => setState(() =>
                _snAnswers[index] = NervousSystemAnswer.classifiesAsExcited),
          ),
          const SizedBox(height: 6),
          _buildSnOptionRow(
            option: const _SnOption('🤷', 'No estoy seguro'),
            selected: answered == NervousSystemAnswer.unknown,
            onTap: () =>
                setState(() => _snAnswers[index] = NervousSystemAnswer.unknown),
          ),
        ],
      ),
    );
  }

  Widget _buildSnOptionRow({
    required _SnOption option,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final color = selected ? AppColors.metabolicGreen : AppColors.borderDefault;
    return Material(
      color: selected
          ? AppColors.metabolicGreen.withValues(alpha: 0.14)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color, width: selected ? 1.4 : 1),
          ),
          child: Row(
            children: [
              Text(option.emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textPrimary,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// SPEC-137 F §RF-137-08.C: tarjeta de sugerencia visual con tres
  /// variantes (passive / excited / unknown).
  Widget _buildSnSuggestionCard(bool isDark) {
    final ns = _classifiedNervousSystem;
    final (icon, title, lines) = switch (ns) {
      NervousSystem.passive => (
          '🌿',
          'Tu perfil es Pasivo',
          [
            'Protocolo: 16:8 (recomendado) o 18:6',
            'Plato sugerido: 2 a 1 (2 partes A + 1 parte E)',
            'Proteínas rojas permitidas',
            'Café matutino: bienvenido',
          ],
        ),
      NervousSystem.excited => (
          '⚡',
          'Tu perfil es Excitado',
          [
            'Protocolo: 16:8 (no más estricto al empezar)',
            'Plato sugerido: 3 a 1 (3 partes A + 1 parte E)',
            'Proteínas blancas (pollo, pavo, pescado)',
            'Café solo antes del mediodía',
          ],
        ),
      NervousSystem.unknown => (
          '🌱',
          'Aún estamos conociéndote',
          [
            'Plan inicial: 16:8',
            'Plato sugerido: 2 a 1',
            'Puedes refinarlo más adelante desde Perfil.',
          ],
        ),
    };

    final bg = isDark ? AppColors.bgSurface : Colors.white;
    final border = isDark ? AppColors.borderDefault : Colors.black12;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• ',
                      style: TextStyle(color: AppColors.textSecondary)),
                  Expanded(
                    child: Text(
                      line,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ─── SPEC-168.0.A: paso final "Tus objetivos" ─────────────────────────────
  //
  // Render: encabezado coaching + lista de 7 GoalSuggestionCard.
  //
  // El encabezado refuerza la narrativa: "Para ti, recomendamos esto y
  // por qué". El card oculta su slider hasta que el usuario toggle
  // "activar", y cada card tiene un expandible "¿Por qué?" que muestra
  // el rationale personalizado del engine.
  Widget _buildStepGoals(bool isDark) {
    final goalsController = ref.read(onboardingGoalsControllerProvider);
    goalsController.ensureInitialized(_buildUserModelFromState());
    final activeCount =
        goalsController.drafts.values.where((d) => d.isActive).length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
      children: [
        // ── Encabezado coaching ─────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF1ABC9C).withValues(alpha: 0.14),
                const Color(0xFF1ABC9C).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFF1ABC9C).withValues(alpha: 0.30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tus objetivos personalizados',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Calculamos estos objetivos para ti con base en tu '
                'peso, edad y rutina actual. Activa los que quieras '
                'trabajar y, si lo prefieres, ajustalos con el slider.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.55,
                  color: Colors.white.withValues(alpha: 0.72),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Cards de sugerencias ────────────────────────────────────
        ...GoalType.values.map(
          (type) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GoalSuggestionCard(
              draft: goalsController.drafts[type]!,
              onChanged: (updated) =>
                  setState(() => goalsController.updateDraft(type, updated)),
            ),
          ),
        ),

        const SizedBox(height: 8),

        // ── Indicador de cantidad activa (UX feedback) ─────────────
        // SPEC-168.0.A v2: el botón "Omitir por ahora" se eliminó.
        // El CTA principal (FINALIZAR) ya persiste todos los drafts
        // respetando su isActive (las recomendaciones del engine se
        // mantienen incluso si el usuario no tocó nada). Mostramos el
        // contador para que el usuario entienda qué se va a guardar.
        if (activeCount > 0)
          Center(
            child: Text(
              activeCount == 1
                  ? '$activeCount objetivo activo'
                  : '$activeCount objetivos activos',
              style: TextStyle(
                fontSize: 11.5,
                color: const Color(0xFF1ABC9C).withValues(alpha: 0.85),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  /// Edad real a partir de la fecha de nacimiento: resta los años y descuenta
  /// 1 si el cumpleaños aún no ocurrió este año. Antes se usaba solo
  /// `now.year - birth.year`, que daba ±1 de error según el mes/día.
  static int _ageFromBirthDate(DateTime birth, {DateTime? now}) {
    final today = now ?? DateTime.now();
    int age = today.year - birth.year;
    final hadBirthdayThisYear = today.month > birth.month ||
        (today.month == birth.month && today.day >= birth.day);
    if (!hadBirthdayThisYear) age--;
    return age < 0 ? 0 : age;
  }

  /// SPEC-168.0.A: construye el UserModel a partir del state actual del
  /// onboarding. Extraído de `_finalSubmit` para que también pueda
  /// alimentar a `GoalSuggestionEngine.suggest` en el paso Goals (donde
  /// `account` todavía no necesariamente está disponible o no importa).
  ///
  /// Si `account` es null, los campos `id` y `name` quedan vacíos —
  /// el engine de sugerencias no los usa.
  UserModel _buildUserModelFromState({AppAccount? account}) {
    final age = _ageFromBirthDate(_birthDate);

    // SPEC-90: calcular % grasa con la fórmula US Navy desde los
    // inputs que el onboarding ya capturó (cintura, cuello, altura,
    // género). Antes este campo se dejaba caer al @Default(20.0) del
    // UserModel, lo cual contaminaba sistemáticamente el bloque
    // Estructura del IMR para todo usuario nuevo.
    final bool isMale = _gender.toUpperCase() == 'M';
    final double calculatedBodyFat =
        BodyFatCalculator.calculateBodyFatPercentage(
      waistCm: _waist,
      neckCm: _neck,
      heightCm: _height,
      isMale: isMale,
    );
    final bool coherent = calculatedBodyFat > 0 &&
        BodyFatCalculator.isCoherent(
          weight: _weight,
          height: _height,
          calculatedBodyFatPct: calculatedBodyFat,
        );
    // Fallback seguro si el cálculo da resultado incoherente (ej.
    // cintura ≤ cuello). Mejor a usar el viejo default 20.
    final double bodyFatToPersist =
        coherent ? calculatedBodyFat : (isMale ? 15.0 : 25.0);
    final String confidence = coherent ? 'ALTA' : 'MEDIA';

    final rawModel = UserModel(
      id: account?.uid ?? '',
      name: account?.displayName ?? 'Usuario',
      age: age,
      gender: _gender,
      weight: _weight,
      height: _height,
      waistCircumference: _waist,
      neckCircumference: _neck,
      bodyFatPercentage: bodyFatToPersist,
      isMeasurementEstimated: !coherent,
      confidenceLevel: confidence,
      pantSize: _pantSize,
      shirtSize: _shirtSize,
      mealsPerDay: _mealsPerDay,
      fastingProtocol: _fastingProtocol,
      // El cribado del paso 0 y el selector del paso 3 escriben los dos
      // en `_pathologies`, que es fuente única. Ver `_declaredConditions`.
      pathologies: _pathologies,
      // SPEC-70.8 / SPEC-76: persistir aceptación del disclaimer
      // clínico con su versión. La versión permite re-prompt si en
      // el futuro se modifica el texto o las condiciones.
      healthDisclaimerAccepted: _disclaimerAccepted,
      healthDisclaimerAcceptedAt: _disclaimerAccepted ? DateTime.now() : null,
      healthDisclaimerVersion:
          _disclaimerAccepted ? kHealthDisclaimerVersion : 0,
      // SPEC-137 F: persistir clasificación del sistema nervioso.
      // Si el usuario saltó, queda como 'unknown' con declared=false
      // para que el dashboard pueda mostrar banner recordatorio.
      nervousSystem: _classifiedNervousSystem.persistenceKey,
      nervousSystemDeclared: _snDeclared,
      nervousSystemScore: _snScore.toMap(),
      protocolWarningAccepted: _protocolWarningAccepted,
      profile: CircadianProfile(
        wakeUpTime: _timeToDateTime(_wakeUpTime),
        sleepTime: _timeToDateTime(_sleepTime),
        firstMealGoal: _timeToDateTime(_firstMealGoal),
        lastMealGoal: _timeToDateTime(_lastMealGoal),
      ),
    );

    // SPEC-257 Eje A: el paso educativo (105, "IntroProtocolStep") elige
    // `_fastingProtocol` ANTES de que el paso de patologías (3) capture
    // `_pathologies` — así que no se puede gatear en el momento de la
    // elección. Este es el único punto donde ambos ya existen: se
    // calcula la elegibilidad sobre el modelo recién construido y se
    // recorta el protocolo si hace falta, para que Firestore nunca
    // reciba una combinación que el propio gate luego rechazaría.
    final eligibility = FastingEligibility.assess(rawModel);
    final clampedProtocol = eligibility.clamp(rawModel.fastingProtocol);
    return clampedProtocol == rawModel.fastingProtocol
        ? rawModel
        : rawModel.copyWith(fastingProtocol: clampedProtocol);
  }

  void _finalSubmit() async {
    // SPEC-73: authState ahora es AppAccount?. uid en .uid, nombre en
    // .displayName. Si el usuario viene de Metamorfosis Real, rawProfile
    // tiene los campos extra que NO se deben pisar — los mezclamos al
    // construir el UserModel final.
    final account = ref.read(authStateProvider).value;
    if (account == null) return;

    final user = _buildUserModelFromState(account: account);

    try {
      await ref
          .read(onboardingControllerProvider.notifier)
          .completeOnboarding(user);
      // SPEC-168.0.A v2: siempre persistir los drafts del paso 5
      // (Opción B). Si el usuario no inicializó el step (caso edge),
      // drafts está vacío y persist() retorna sin hacer nada. Si lo
      // inicializó pero no tocó nada, se guardan las recomendaciones
      // del engine — el usuario las verá en Perfil. (DEBT-01: la
      // lógica vive ahora en OnboardingGoalsController.)
      try {
        await ref.read(onboardingGoalsControllerProvider).persist();
      } catch (e, stackTrace) {
        // Fallar en goals no debe bloquear el cierre del onboarding —
        // el dashboard puede arrancar sin goals y el usuario los
        // configura desde Perfil.
        AppLogger.warning('Onboarding: persistencia de goals falló: $e');
        AppLogger.error('Goals stack', e, stackTrace);
      }
      // Propuesta módulo Ejercicio (2026-07-21): persistir el perfil de
      // hábitos capturado en el paso 5. Mismo criterio que goals — un
      // fallo aquí no bloquea el cierre del onboarding.
      try {
        await _persistExerciseProfile(account.uid);
      } catch (e, stackTrace) {
        AppLogger.warning(
          'Onboarding: persistencia de exercise profile falló: $e',
        );
        AppLogger.error('ExerciseProfile stack', e, stackTrace);
      }
      // SPEC-74 §RF-74-08: telemetría de cierre. Después del save —
      // antes de la navegación — para que el evento se asocie al
      // funnel del usuario que SÍ completó.
      ref.read(authTelemetryProvider).onboardingCompleted();

      // SPEC-182 §RF-182-06 (2026-06-05): flag local que `main.dart`
      // consulta para decidir si pide permisos de notifs en cold start
      // (antes de tener uid). Se mantiene en SharedPreferences para ese
      // caso específico. SPEC-228: además se escribe en Firestore para
      // que en un nuevo device no aparezca el onboarding de nuevo.
      try {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setBool('onboardingCompleted', true);
        // Firestore cross-device (fire-and-forget).
        final uid = ref.read(authStateProvider).value?.uid;
        if (uid != null) {
          ref.read(appStateRepositoryProvider).setOnboardingCompleted(uid);
        }
      } catch (_) {
        // Si la pref falla no rompemos el cierre del onboarding.
      }
      // PROD-05 fix (21-jul, auditoría técnica): el tour YA NO se activa
      // aquí. `tryActivate()` es guardado por `AppTourNotifier` con
      // `if (state.isActive) return false` para no reiniciarse al
      // navegar — pero eso significaba que esta llamada (mientras
      // TODAVÍA estamos en OnboardingScreen, sin las GlobalKeys del
      // Dashboard montadas) ganaba la carrera, y la llamada correcta en
      // `DashboardScreen.initState` (SPEC-243 BUILD-2 FIX, más abajo en
      // este mismo archivo de features/dashboard) quedaba bloqueada por
      // ese guard. Resultado: el overlay nunca aparecía. Se deja una
      // única fuente de activación en DashboardScreen, que ya cubre
      // explícitamente "cualquier usuario que llegue por primera vez al
      // Dashboard" — incluyendo el que sale de este onboarding.

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      context.go('/dashboard');
    } catch (e, stackTrace) {
      AppLogger.error('Error en Onboarding Submit', e, stackTrace);
    }
  }

  // --- HELPERS UI ---

  // ─── Picker selector (reemplaza steppers +/-) ────────────────────────────

  /// Card tappable que muestra label + valor actual. Al tocar abre un picker.
  Widget _pickerSelector({
    required String label,
    required String displayValue,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : const Color(0xFF475569),
                  fontSize: 14,
                ),
              ),
              Row(
                children: [
                  Text(
                    displayValue,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: isDark ? Colors.white38 : const Color(0xFFCBD5E1),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Picker de rueda (CupertinoPicker) para valores numéricos enteros.
  /// El valor solo se confirma al tocar "Listo".
  void _showNumericPicker({
    required String title,
    required double value,
    required double min,
    required double max,
    required String unit,
    required bool isDark,
    required Function(double) onChanged,
  }) {
    final values = <int>[];
    for (int v = min.toInt(); v <= max.toInt(); v++) {
      values.add(v);
    }

    int initialIndex = values.indexWhere((v) => v == value.toInt());
    if (initialIndex < 0) initialIndex = 0;

    final controller = FixedExtentScrollController(initialItem: initialIndex);
    int selectedIndex = initialIndex;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        final bg =
            isDark ? const Color(0xFF1E293B) : CupertinoColors.systemBackground;
        final fg = isDark ? CupertinoColors.white : CupertinoColors.black;

        return Container(
          height: 320,
          color: bg,
          child: Column(
            children: [
              // Barra de acciones
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: bg,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: isDark
                              ? CupertinoColors.systemGrey
                              : CupertinoColors.systemGrey,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: () {
                        onChanged(values[selectedIndex].toDouble());
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Listo',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Rueda
              Expanded(
                child: CupertinoPicker(
                  scrollController: controller,
                  itemExtent: 44,
                  backgroundColor: bg,
                  selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                    background: const Color(0xFF10B981).withValues(alpha: 0.12),
                  ),
                  onSelectedItemChanged: (idx) => selectedIndex = idx,
                  children: values
                      .map(
                        (v) => Center(
                          child: Text(
                            '$v$unit',
                            style: TextStyle(
                              color: fg,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  /// Picker de rueda para opciones de texto (tallas, categorías).
  void _showStringPicker({
    required String title,
    required List<String> options,
    required String current,
    required bool isDark,
    required Function(String) onChanged,
  }) {
    int initialIndex = options.indexOf(current);
    if (initialIndex < 0) initialIndex = 0;

    final controller = FixedExtentScrollController(initialItem: initialIndex);
    int selectedIndex = initialIndex;

    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) {
        final bg =
            isDark ? const Color(0xFF1E293B) : CupertinoColors.systemBackground;
        final fg = isDark ? CupertinoColors.white : CupertinoColors.black;

        return Container(
          height: 300,
          color: bg,
          child: Column(
            children: [
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: bg,
                  border: Border(
                    bottom: BorderSide(
                      color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: () => Navigator.pop(ctx),
                      child: Text(
                        'Cancelar',
                        style: TextStyle(
                          color: CupertinoColors.systemGrey,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Text(
                      title,
                      style: TextStyle(
                        color: fg,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    CupertinoButton(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      onPressed: () {
                        onChanged(options[selectedIndex]);
                        Navigator.pop(ctx);
                      },
                      child: const Text(
                        'Listo',
                        style: TextStyle(
                          color: Color(0xFF10B981),
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  scrollController: controller,
                  itemExtent: 44,
                  backgroundColor: bg,
                  selectionOverlay: CupertinoPickerDefaultSelectionOverlay(
                    background: const Color(0xFF10B981).withValues(alpha: 0.12),
                  ),
                  onSelectedItemChanged: (idx) => selectedIndex = idx,
                  children: options
                      .map(
                        (opt) => Center(
                          child: Text(
                            opt,
                            style: TextStyle(
                              color: fg,
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Fix overflow 1.9px: el segundo Text se desbordaba cuando `value`
  // era largo (p.ej. lista de patologías). Flexible + ellipsis previene
  // el RenderFlex overflow sin cambiar el layout.
  Widget _simpleSelector(
          String label, String value, VoidCallback onTap, bool isDark) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(
                    value,
                    textAlign: TextAlign.end,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF10B981),
                      fontSize: 15,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

  Widget _buildBottomNavigation(AsyncValue state, bool isDark) {
    // SPEC-70.8 / SPEC-84: el botón SIGUIENTE se deshabilita SOLO
    // cuando el paso activo es el Disclaimer (índice original 0) y
    // todavía no se aceptó. Si el sitio MR ya entregó la aceptación,
    // el disclaimer no aparece en _activeSteps y este chequeo no
    // bloquea.
    final currentOriginalIndex =
        _activeSteps.isNotEmpty ? _activeSteps[_currentStep] : 0;
    // 27-jul-2026: el paso 0 exige además una RESPUESTA al cribado, no
    // solo aceptar el disclaimer. Sin esto se podría seguir sin declarar
    // nada, que es el estado en el que quedaban todos los usuarios y el
    // motivo de que `FastingEligibility.assess()` nunca recibiera datos.
    final cribadoRespondido = _declaredNone || _declaredConditions.isNotEmpty;
    final canProceed = (currentOriginalIndex != 0 ||
            (_disclaimerAccepted && cribadoRespondido)) &&
        (currentOriginalIndex != 1 || _weightTouched);
    final isLastStep = _currentStep == _activeSteps.length - 1;
    final disabledColor = isDark ? Colors.white24 : Colors.grey;
    final activeColor =
        isDark ? const Color(0xFF10B981) : const Color(0xFF0F172A);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F172A) : Colors.white,
        border: Border(
          top: BorderSide(
              color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
        ),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: TextButton(
                onPressed: () {
                  setState(() {
                    _currentStep--;
                    _pageController.animateToPage(
                      _currentStep,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOutExpo,
                    );
                  });
                },
                child: Text(
                  "ATRÁS",
                  style: TextStyle(
                    color: isDark ? Colors.white38 : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: canProceed ? activeColor : disabledColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              onPressed: !canProceed || state.isLoading ? null : _handleNext,
              child: Text(
                isLastStep
                    ? "FINALIZAR"
                    : (currentOriginalIndex == 0 && !canProceed
                        ? "ACEPTA PARA CONTINUAR"
                        : "SIGUIENTE"),
                style: const TextStyle(
                    fontWeight: FontWeight.w900, letterSpacing: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// SPEC-182 §RF-182-05 (2026-06-05): handler del CTA "Activar coaching
  /// por notificaciones" en el paso 104. Dispara el modal nativo iOS de
  /// permisos. Si el usuario rechaza, igual avanza — podrá habilitarlo
  /// luego desde Settings → ElenaApp → Notificaciones.
  Future<void> _activateNotifications() async {
    try {
      await NotificationService.requestPermissions();
    } catch (_) {
      // Si el plugin de notifs falla por una razón inesperada, no
      // bloqueamos el onboarding — el usuario podrá activarlas
      // después.
    }
    _handleNext();
  }

  void _handleNext() async {
    // SPEC-132 E: si el paso actual es el de Health, disparamos la
    // solicitud de permisos ANTES de avanzar. El usuario ve el sheet
    // nativo de iOS/Android; al cerrarlo (acepte o rechace), el flujo
    // continúa — no bloqueamos en caso de rechazo, podrá conectar
    // después desde Perfil > Salud.
    final currentOriginalIndex =
        _activeSteps.isNotEmpty ? _activeSteps[_currentStep] : 0;
    if (currentOriginalIndex == _kHealthSyncStepId) {
      try {
        await ref
            .read(healthAutoSyncControllerProvider.notifier)
            .requestAuthorization();
      } catch (e) {
        AppLogger.warning('Onboarding: requestAuthorization falló: $e');
      }
      if (!mounted) return;
    }

    // SPEC-84: navegación basada en _activeSteps (puede tener entre 1
    // y 4 entradas). El último paso activo dispara el submit.
    if (_currentStep < _activeSteps.length - 1) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOutExpo);
    } else {
      _finalSubmit();
    }
  }

  void _showSimpleOptions(String title, List<String> options,
      Function(String) onSelect, bool isDark) {
    showModalBottomSheet(
        context: context,
        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        builder: (ctx) => Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Text(title,
                  style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              const SizedBox(height: 12),
              ...options.map((opt) => ListTile(
                  title: Center(
                      child: Text(opt,
                          style: TextStyle(
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                              fontWeight: FontWeight.w600))),
                  onTap: () {
                    onSelect(opt);
                    Navigator.pop(ctx);
                  }))
            ])));
  }

  void _showMultiSelectPathologies(bool isDark) {
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
                backgroundColor:
                    isDark ? const Color(0xFF1E293B) : Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24)),
                title: Text("Diagnósticos",
                    style: TextStyle(
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        fontWeight: FontWeight.w900)),
                content: StatefulBuilder(
                    builder: (ctx, setModalState) => SizedBox(
                        width: double.maxFinite,
                        child: ListView(
                            shrinkWrap: true,
                            children: _pathologyOptions
                                .map((p) => CheckboxListTile(
                                    title: Text(p,
                                        style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : const Color(0xFF0F172A))),
                                    value: _pathologies.contains(p),
                                    activeColor: const Color(0xFF10B981),
                                    onChanged: (val) {
                                      setModalState(() {
                                        if (p == "Ninguna") {
                                          _pathologies = ["Ninguna"];
                                        } else {
                                          _pathologies.remove("Ninguna");
                                          val!
                                              ? _pathologies.add(p)
                                              : _pathologies.remove(p);
                                          if (_pathologies.isEmpty) {
                                            _pathologies = ["Ninguna"];
                                          }
                                        }
                                      });
                                      setState(() {});
                                    }))
                                .toList()))),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text("GUARDAR",
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF10B981))))
                ]));
  }

  // SPEC-119: `_header` → OnboardingStepHeader, `_stepHelperLine` →
  // OnboardingStepHelperLine, `_sectionTitle` → OnboardingSectionTitle
  // (widgets/onboarding_step_ui.dart). Extraído en ARCH-03 — eran
  // funciones puras (solo String/bool), sin dependencias de estado.

  // SPEC-74 §RF-74-02/03: header con saludo contextual.
  //   - Usuario MR con displayName: "Hola {nombre}, completemos tu perfil metabólico"
  //   - Usuario nuevo / sin displayName: "Bienvenid@ a ElenaApp"
  // Sub-copy también diferenciado para reforzar el contexto.
  Widget _greetingHeader(bool isDark) {
    final hasGreetingName = _greetingName != null && _greetingName!.isNotEmpty;
    final showMrCopy = _isReturningMrUser && hasGreetingName;

    final title = showMrCopy
        ? 'Hola $_greetingName, completemos tu perfil metabólico'
        : 'Bienvenid@ a ElenaApp';
    final sub = showMrCopy
        ? 'Tu cuenta de Metamorfosis Real ya está vinculada. Solo necesitamos algunos datos biométricos para personalizar tu IMR.'
        : 'En menos de 2 minutos calibramos el sistema con tus datos para empezar a medir tu IMR.';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              letterSpacing: -0.5,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            sub,
            style: TextStyle(
              color: isDark ? Colors.white60 : const Color(0xFF475569),
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // SPEC-119: `_sectionTitle` → OnboardingSectionTitle
  // (widgets/onboarding_step_ui.dart). Extraído en ARCH-03.
}

// SPEC-119: `_DisclaimerItem` → DisclaimerItem (público)
// (widgets/onboarding_step_ui.dart). Extraído en ARCH-03 sin cambios
// de comportamiento.

// SPEC-137 F: estructura de datos para las 5 preguntas SN.
class _SnQuestion {
  final String prompt;
  final _SnOption passive;
  final _SnOption excited;

  const _SnQuestion({
    required this.prompt,
    required this.passive,
    required this.excited,
  });
}

class _SnOption {
  final String emoji;
  final String text;
  const _SnOption(this.emoji, this.text);
}
