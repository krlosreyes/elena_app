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
import 'package:elena_app/src/features/dashboard/domain/optimal_schedule.dart';
import 'package:elena_app/src/features/profile/domain/body_fat_calculator.dart';
// SPEC-76: disclaimer canonicalizado + versión.
import 'package:elena_app/src/features/auth/domain/health_disclaimer.dart';
// SPEC-137 F: clasificación del sistema nervioso en onboarding Paso 3.
import 'package:elena_app/src/features/nutrition/domain/nervous_system.dart';
// SPEC-131: pantallas educativas para usuarios cero-contexto.
import 'package:elena_app/src/features/onboarding/presentation/widgets/intro_screens.dart';
// SPEC-132 Bloque E: paso opcional para conectar HealthKit / Health Connect.
import 'package:elena_app/src/features/health_sync/application/health_auto_sync_controller.dart';
import 'package:elena_app/src/features/health_sync/application/health_sync_providers.dart';
import 'package:elena_app/src/core/providers/shared_preferences_provider.dart';
import 'package:elena_app/src/core/services/notification_service.dart';
import 'package:elena_app/src/features/health_sync/presentation/onboarding_health_step.dart';
// SPEC-168.0.A: paso final del onboarding — sugerencias de metas
// personalizadas con narrativa coaching. Reutiliza GoalSuggestionCard
// y GoalDraft de la pantalla standalone (`/goals/setup`).
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/goals/application/goal_suggestion_engine.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/features/goals/presentation/goal_setup_screen.dart'
    show GoalDraft, GoalSuggestionCard;

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

  // SPEC-182 (2026-06-05): se agregan 103 (Día Metabólico) al bloque
  // intro y 104 (Notificaciones con respaldo) como paso post-hábitos.
  static const int _kIntroMetabolicDayId = 103;
  static const int _kIntroNotificationsId = 104;
  static const List<int> _kIntroStepIds = [
    100,
    101,
    102,
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

  // SPEC-168.0.A: borrador local del step Goals. Se inicializa lazy la
  // primera vez que el PageView llega al paso (`_ensureGoalDrafts`)
  // usando `GoalSuggestionEngine.suggest` sobre el UserModel construido
  // a partir del state actual del onboarding. El usuario puede mover
  // sliders y togglear cada goal antes de persistir en `_finalSubmit`.
  //
  // SPEC-168.0.A (v2 — feedback Carlos 2026-06-03 Opción B): siempre
  // persistimos los 7 drafts respetando su `isActive`. Si el usuario
  // no tocó nada, el engine ya marcó por shouldActivate cuáles activar
  // (los fuera de rango) y cuáles dejar inactivos pero visibles (los
  // que ya están en zona saludable). El Perfil los muestra todos.
  Map<GoalType, GoalDraft> _goalDrafts = {};
  bool _goalDraftsInitialized = false;

  // --- PASO 1: HARDWARE ---
  DateTime _birthDate = DateTime(1980, 1, 1);
  double _weight = 85.0;
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

  final List<String> _pathologyOptions = [
    "Ninguna",
    "Prediabetes",
    "Diabetes T2",
    "Hipertensión",
    "Hígado Graso",
    "Hipotiroidismo",
    "SOP",
    "Anemia",
    "Resistencia Insulina"
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
  NervousSystemScore get _snScore =>
      NervousSystemScore.fromAnswers(_snAnswers.whereType<NervousSystemAnswer>()
          .toList());

  NervousSystem get _classifiedNervousSystem =>
      _snSkipped ? NervousSystem.unknown : _snScore.classify();

  bool get _snDeclared =>
      !_snSkipped &&
      _snAnswers.whereType<NervousSystemAnswer>().length >= 3;

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

    _isReturningMrUser =
        account.profileStatus == AppProfileStatus.partialProfile;
    if (_isReturningMrUser) {
      // Primera vez que un usuario MR entra a la app.
      telemetry.mrUserFirstLogin();
    }

    final prefill = OnboardingPrefill.from(account.rawProfile);
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

    // SPEC-131: usuarios cero-contexto (newProfile) ven 3 pantallas
    // educativas ANTES del flujo tradicional. Usuarios MR (partialProfile)
    // no las ven — ya conocen el método.
    final isColdInstall =
        account.profileStatus == AppProfileStatus.newProfile;

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
      // SPEC-168.0.A: Tus objetivos — siempre al final.
      _kGoalsStepId,
    ];

    setState(() {
      _prefill = prefill;
      _greetingName = (prefill.name?.isNotEmpty ?? false)
          ? prefill.name
          : account.displayName;

      if (prefill.weight != null) _weight = prefill.weight!;
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

      _activeSteps = activeSteps;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(onboardingControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // SPEC-84 + SPEC-131: PageView solo con los pasos activos. Los
    // educativos (100-102) preceden a los tradicionales (0-3) cuando
    // el usuario es cero-contexto.
    final pages = _activeSteps.map((index) {
      switch (index) {
        case 100:
          return IntroWelcomeStep(isDark: isDark);
        case 101:
          return IntroImrStep(isDark: isDark);
        case 102:
          return IntroDataStep(isDark: isDark);
        case 103:
          // SPEC-182 §RF-182-04: Día Metabólico.
          return IntroMetabolicDayStep(isDark: isDark);
        case 104:
          // SPEC-182 §RF-182-05: Notificaciones con respaldo. Dos CTAs
          // — activar dispara requestPermissions, "más tarde" avanza
          // sin pedirlos.
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

        // SPEC-76: consume la lista canonicalizada de
        // `health_disclaimer.dart`. Cambios al texto pasan por allá.
        ...kHealthDisclaimerConditions.map(
          (c) => _DisclaimerItem(
            icon: c.icon,
            title: c.title,
            body: c.body,
            isDark: isDark,
          ),
        ),

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
          _header("Hardware Base", "Identidad y Antropometría", isDark),
          _stepHelperLine(
            'Estas medidas nos sirven para estimar tu composición '
            'corporal sin pedirte que adivines tu % de grasa.',
            isDark,
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
          _stepperSelector(
              label: "Estatura",
              value: _height,
              unit: " cm",
              min: 140,
              max: 220,
              onChanged: (v) => setState(() => _height = v),
              isDark: isDark),
          _stepperSelector(
              label: "Peso",
              value: _weight,
              unit: " kg",
              min: 40,
              max: 200,
              onChanged: (v) => setState(() => _weight = v),
              isDark: isDark),
          _sectionTitle("TALLAS (INFERENCIA)", isDark),
          Row(children: [
            Expanded(
                child: _simpleSelector(
                    "Camisa",
                    _shirtSize,
                    () => _showSimpleOptions("Camisa", ["S", "M", "L", "XL"],
                            (v) {
                          setState(() => _shirtSize = v);
                          _inferMedidas();
                        }, isDark),
                    isDark)),
            const SizedBox(width: 12),
            Expanded(
                child: _stepperSelector(
                    label: "Pant.",
                    value: _pantSize.toDouble(),
                    unit: "",
                    min: 28,
                    max: 50,
                    onChanged: (v) {
                      setState(() => _pantSize = v.toInt());
                      _inferMedidas();
                    },
                    isDark: isDark)),
          ]),
          _sectionTitle("MEDIDAS CRÍTICAS IMR", isDark),
          _stepperSelector(
              label: "Cintura",
              value: _waist,
              unit: " cm",
              min: 50,
              max: 150,
              onChanged: (v) => setState(() => _waist = v),
              isDark: isDark),
          _stepperSelector(
              label: "Cuello",
              value: _neck,
              unit: " cm",
              min: 20,
              max: 60,
              onChanged: (v) => setState(() => _neck = v),
              isDark: isDark),
        ],
      );

  // --- PASO 2: RITMOS ---
  Widget _buildStepCircadian(bool isDark) => ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _header("Ritmo Circadiano", "Sincronización horaria", isDark),
          _stepHelperLine(
            'Tu reloj biológico decide cuándo el ayuno funciona mejor. '
            'Vamos a alinear tu ventana de comida con tus horarios reales.',
            isDark,
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
          _sectionTitle("VENTANA DE ALIMENTACIÓN", isDark),
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
          _header("Protocolo", "Hábitos metabólicos", isDark),
          _stepHelperLine(
            'Ya tenemos tu perfil físico. Ahora vamos a conocerte un '
            'poco más y a elegir cómo querés ayunar.',
            isDark,
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
          _stepperSelector(
              label: "Comidas al día",
              value: _mealsPerDay.toDouble(),
              unit: "",
              min: 1,
              max: 6,
              onChanged: (v) => setState(() => _mealsPerDay = v.toInt()),
              isDark: isDark),
          _simpleSelector("Patologías", _pathologies.join(", "),
              () => _showMultiSelectPathologies(isDark), isDark),
        ],
      );

  /// SPEC-137 F: maneja el cambio de protocolo. Si el usuario está
  /// clasificado Excitado y elige 20:4, dispara dialog de incongruencia
  /// (§RF-137-08.D) antes de aplicar el cambio.
  void _handleProtocolChange(String newProtocol) {
    final isExcitedPicking20_4 =
        _classifiedNervousSystem == NervousSystem.excited &&
            newProtocol == '20:4' &&
            _protocolWarningAccepted != '20:4-on-excited';

    if (isExcitedPicking20_4) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor:
              Theme.of(ctx).brightness == Brightness.dark
                  ? AppColors.bgElevated
                  : Colors.white,
          title: const Text('🤔 Una sugerencia honesta'),
          content: const Text(
            'Las personas con perfil Excitado (sueño superficial, '
            'tensión baseline, apetito matutino bajo) suelen tolerar '
            '20:4 mejor después de adaptarse con 16:8 unas semanas.\n\n'
            'Empezar directo con 20:4 puede aumentar tu tensión, '
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
                _protocolWarningAccepted = '20:4-on-excited';
                _applyProtocolChange('20:4');
              },
              child: const Text('Mantener 20:4'),
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
                ? 'Podés responder más tarde desde Perfil.'
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
            onTap: () => setState(
                () => _snAnswers[index] = NervousSystemAnswer.unknown),
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
                    fontWeight:
                        selected ? FontWeight.w600 : FontWeight.w400,
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
            'Podés refinarlo más adelante desde Perfil.',
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
    _ensureGoalDraftsInitialized();
    final activeCount = _goalDrafts.values.where((d) => d.isActive).length;

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
                'peso, edad y rutina actual. Activá los que quieras '
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
              draft: _goalDrafts[type]!,
              onChanged: (updated) =>
                  setState(() => _goalDrafts[type] = updated),
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

  /// Lazy-init de `_goalDrafts`: construye un UserModel parcial con el
  /// state actual del onboarding, le pide sugerencias al engine y
  /// arma los drafts. Idempotente — se ejecuta solo la primera vez.
  void _ensureGoalDraftsInitialized() {
    if (_goalDraftsInitialized) return;
    final user = _buildUserModelFromState();
    final suggestions = GoalSuggestionEngine.suggest(user);

    _goalDrafts = {
      for (final type in GoalType.values)
        type: GoalDraft(
          type: type,
          target: suggestions[type]!.suggestedTarget,
          current: suggestions[type]!.currentValue,
          rationale: suggestions[type]!.rationale,
          statusLabel: suggestions[type]!.currentStatusLabel,
          isActive: suggestions[type]!.shouldActivate,
          originalSuggestion: suggestions[type]!.suggestedTarget,
        ),
    };
    _goalDraftsInitialized = true;
  }

  /// SPEC-168.0.A: construye el UserModel a partir del state actual del
  /// onboarding. Extraído de `_finalSubmit` para que también pueda
  /// alimentar a `GoalSuggestionEngine.suggest` en el paso Goals (donde
  /// `account` todavía no necesariamente está disponible o no importa).
  ///
  /// Si `account` es null, los campos `id` y `name` quedan vacíos —
  /// el engine de sugerencias no los usa.
  UserModel _buildUserModelFromState({AppAccount? account}) {
    final age = DateTime.now().year - _birthDate.year;

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

    return UserModel(
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
  }

  /// SPEC-168.0.A v2: persiste TODOS los drafts del paso 5 del
  /// onboarding respetando el `isActive` que cada uno trae (del engine
  /// si el usuario no tocó, o del toggle si sí ajustó).
  ///
  /// Decisión Opción B (Carlos, 2026-06-03): aunque el usuario no
  /// active ninguno explícitamente, las recomendaciones del engine se
  /// guardan en Firestore para que el Perfil pueda mostrarlas. El
  /// estado activo refleja el shouldActivate del engine — los goals
  /// "fuera de rango" se activan; los "en rango" quedan como
  /// referencia inactiva.
  Future<void> _persistGoalDrafts() async {
    if (_goalDrafts.isEmpty) return;
    final goals = <GoalType, UserGoal>{};
    for (final draft in _goalDrafts.values) {
      goals[draft.type] = UserGoal(
        type: draft.type,
        targetValue: draft.target,
        startValue: draft.current,
        isActive: draft.isActive,
        createdAt: DateTime.now(),
      );
    }
    if (goals.isEmpty) return;
    await ref.read(goalsProvider.notifier).saveAll(goals);
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
      // _goalDrafts está vacío y _persistGoalDrafts retorna sin hacer
      // nada. Si lo inicializó pero no tocó nada, se guardan las
      // recomendaciones del engine — el usuario las verá en Perfil.
      try {
        await _persistGoalDrafts();
      } catch (e, stackTrace) {
        // Fallar en goals no debe bloquear el cierre del onboarding —
        // el dashboard puede arrancar sin goals y el usuario los
        // configura desde Perfil.
        AppLogger.warning('Onboarding: persistencia de goals falló: $e');
        AppLogger.error('Goals stack', e, stackTrace);
      }
      // SPEC-74 §RF-74-08: telemetría de cierre. Después del save —
      // antes de la navegación — para que el evento se asocie al
      // funnel del usuario que SÍ completó.
      ref.read(authTelemetryProvider).onboardingCompleted();

      // SPEC-182 §RF-182-06 (2026-06-05): flag local que `main.dart`
      // consulta para decidir si pide permisos de notifs en cold start.
      // Usuarios que pasaron por SPEC-182 (paso 104) NO necesitan el
      // prompt ciego — ya respondieron en momento educativo. Usuarios
      // pre-SPEC-182 que ya tenían cuenta lo seteen acá también al
      // recargar el flow alguna vez.
      try {
        final prefs = ref.read(sharedPreferencesProvider);
        await prefs.setBool('onboardingCompleted', true);
      } catch (_) {
        // Si la pref falla no rompemos el cierre del onboarding.
      }
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      context.go('/dashboard');
    } catch (e, stackTrace) {
      AppLogger.error('Error en Onboarding Submit', e, stackTrace);
    }
  }

  // --- HELPERS UI ---

  Widget _stepperSelector(
      {required String label,
      required double value,
      required String unit,
      required double min,
      required double max,
      required Function(double) onChanged,
      required bool isDark}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? Colors.white10 : const Color(0xFFE2E8F0))),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : const Color(0xFF475569),
                fontSize: 14)),
        Row(children: [
          _circleButton(Icons.remove,
              () => value > min ? onChanged(value - 1) : null, isDark),
          SizedBox(
              width: 65,
              child: Center(
                  child: Text("${value.toInt()}$unit",
                      style: TextStyle(
                          fontWeight: FontWeight.w800,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                          fontSize: 16)))),
          _circleButton(Icons.add,
              () => value < max ? onChanged(value + 1) : null, isDark),
        ])
      ]),
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

  Widget _circleButton(IconData icon, VoidCallback? onTap, bool isDark) =>
      InkWell(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
              child: Icon(icon,
                  size: 18,
                  color: onTap == null
                      ? Colors.grey
                      : (isDark ? Colors.white : const Color(0xFF0F172A)))));

  Widget _buildBottomNavigation(AsyncValue state, bool isDark) {
    // SPEC-70.8 / SPEC-84: el botón SIGUIENTE se deshabilita SOLO
    // cuando el paso activo es el Disclaimer (índice original 0) y
    // todavía no se aceptó. Si el sitio MR ya entregó la aceptación,
    // el disclaimer no aparece en _activeSteps y este chequeo no
    // bloquea.
    final currentOriginalIndex =
        _activeSteps.isNotEmpty ? _activeSteps[_currentStep] : 0;
    final canProceed = currentOriginalIndex != 0 || _disclaimerAccepted;
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

  Widget _header(String title, String sub, bool isDark) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -1)),
        Text(sub,
            style: TextStyle(
                color: isDark ? Colors.white38 : const Color(0xFF64748B),
                fontSize: 15,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 24)
      ]);

  /// SPEC-131: línea explicativa contextual debajo del header de cada
  /// paso. Da contexto al usuario cero-contexto sobre POR QUÉ pedimos
  /// estos datos sin invadir visualmente.
  Widget _stepHelperLine(String text, bool isDark) => Padding(
        padding: const EdgeInsets.only(bottom: 20, top: 0),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.metabolicGreen.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: AppColors.metabolicGreen.withValues(alpha: 0.25),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.lightbulb_outline,
                color: AppColors.metabolicGreen,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: isDark
                        ? AppColors.textSecondary
                        : const Color(0xFF475569),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ),
      );

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

  Widget _sectionTitle(String title, bool isDark) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(title,
          style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF10B981),
              letterSpacing: 1.5)));
}

/// SPEC-70.8: tarjeta individual de cada contraindicación. Reusable para
/// los 5 items listados en el paso 0 del onboarding (T1D, TCA, IRC,
/// embarazo/lactancia, sarcopenia >75).
class _DisclaimerItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final bool isDark;

  const _DisclaimerItem({
    required this.icon,
    required this.title,
    required this.body,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary =
        (isDark ? Colors.white : Colors.black87).withValues(alpha: 0.65);
    final iconColor =
        isDark ? const Color(0xFF10B981) : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            alignment: Alignment.center,
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.45,
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
