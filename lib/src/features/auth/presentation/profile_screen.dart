import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/config/feature_flags.dart';
import 'package:elena_app/src/core/engine/imr_persistence_provider.dart';
import 'package:elena_app/src/core/engine/longitudinal_imr_provider.dart';
import 'package:elena_app/src/features/auth/application/profile_controller.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/data_group_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/edit_biometry_value_sheet.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_bottom_nav.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_danger_zone_actions.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_goals_section.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_identity_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_legal_section.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_protocol_card.dart';
import 'package:elena_app/src/features/badges/presentation/widgets/badge_gallery.dart';
import 'package:elena_app/src/features/dashboard/domain/optimal_schedule.dart';
import 'package:elena_app/src/features/health_sync/presentation/health_sync_card.dart';
import 'package:elena_app/src/features/profile/application/biometric_lock_provider.dart';
import 'package:elena_app/src/features/profile/domain/biometric_lock_service.dart';
import 'package:elena_app/src/features/profile/domain/biometry_recalc.dart';
import 'package:elena_app/src/features/profile/presentation/widgets/body_composition_card.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:elena_app/src/features/onboarding/application/app_tour_notifier.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);
    final profileState = ref.watch(profileControllerProvider);

    // Muestra feedback al usuario después de guardar (CA-02-02)
    ref.listen<ProfileEditState>(profileControllerProvider, (prev, next) {
      if (next.savedSuccessfully && !(prev?.savedSuccessfully ?? false)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado correctamente'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
          ),
        );
        ref.read(profileControllerProvider.notifier).clearFeedback();
      }
      if (next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
        ref.read(profileControllerProvider.notifier).clearFeedback();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        // SPEC-116: título en sentence-case, peso w700, sin tracking
        // agresivo. La identidad clínica vive ahora en la card del
        // usuario (subtítulo bajo el nombre).
        title: const Text(
          'Perfil',
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0),
        ),
        centerTitle: false,
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          if (profileState.isSaving)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Color(0xFF10B981)),
                ),
              ),
            ),
        ],
      ),
      body: userAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (user) {
          if (user == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return _ProfileBody(user: user);
        },
      ),
      bottomNavigationBar: const ProfileBottomNav(),
    );
  }

  // SPEC-119: bottom nav → ProfileBottomNav
  // (widgets/profile_bottom_nav.dart). Extraído en ARCH-03.
}

// ─────────────────────────────────────────────────────────────────────────────
// Cuerpo principal (ConsumerStatefulWidget para manejar los time pickers)
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerStatefulWidget {
  final UserModel user;
  const _ProfileBody({required this.user});

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  // Estado local de edición — se inicializa con los valores del usuario
  late TimeOfDay _wakeUpTime;
  late TimeOfDay _sleepTime;
  late TimeOfDay _firstMealGoal;
  late TimeOfDay _lastMealGoal;
  // SPEC-98: `_fastingProtocol` removido. El cambio de protocolo vive
  // en el Dashboard ahora; el Perfil solo lo muestra read-only desde
  // `widget.user.fastingProtocol`.

  @override
  void initState() {
    super.initState();
    _wakeUpTime = TimeOfDay.fromDateTime(widget.user.profile.wakeUpTime);
    _sleepTime = TimeOfDay.fromDateTime(widget.user.profile.sleepTime);
    _firstMealGoal = TimeOfDay.fromDateTime(
        widget.user.profile.firstMealGoal ?? widget.user.profile.wakeUpTime);
    _lastMealGoal = TimeOfDay.fromDateTime(
        widget.user.profile.lastMealGoal ?? widget.user.profile.sleepTime);
  }

  // Convierte TimeOfDay → DateTime usando la fecha de hoy como base
  DateTime _toDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  Future<void> _pickTime(TimeOfDay current, ValueChanged<TimeOfDay> onPicked,
      {bool isMealTimePicker = false}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF10B981),
            surface: Color(0xFF1E293B),
          ),
          dialogTheme:
              DialogThemeData(backgroundColor: const Color(0xFF1E293B)),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;

    // SPEC-96: si el picker corresponde a `lastMealGoal` y el usuario
    // intentó cerrar la ventana ≥ 21:00, bloquear el guardado y
    // mostrar el principio del bloqueo intestinal.
    if (isMealTimePicker &&
        OptimalScheduleCalculator.violatesIntestinalBlock(picked)) {
      await _showIntestinalBlockDialog(picked);
      return;
    }

    setState(() => onPicked(picked));
    _saveCircadianChanges();

    // SPEC-96: warning no bloqueante si la configuración está fuera
    // de tolerancia (>60 min del óptimo). Se evalúa con los valores
    // CURRENTES post-update.
    if (isMealTimePicker) {
      final reason = OptimalScheduleCalculator.lintReason(
        windowStart: _firstMealGoal,
        windowEnd: _lastMealGoal,
        protocol: widget.user.fastingProtocol,
      );
      if (reason != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(reason),
            backgroundColor: Colors.orange.shade800,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  /// SPEC-96: diálogo educativo cuando el usuario intenta cerrar la
  /// ventana después de las 21:00 — viola el bloqueo intestinal.
  Future<void> _showIntestinalBlockDialog(TimeOfDay attempted) async {
    return showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Hora fuera del rango biológico',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        content: const Text(
          'El bloqueo intestinal natural empieza a las 22:00 — comer '
          'después de las 21:00 fuerza al cuerpo a digerir cuando '
          'debería estar reparando tejidos, destruye la calidad del '
          'sueño y baja tu IMR de mañana.\n\n'
          'Si necesitas cerrar más tarde por horario social, considera '
          'cambiar tu protocolo de ayuno a uno más corto.',
          style: TextStyle(color: Color(0xFFB6C3D1), fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text(
              'ENTENDIDO',
              style: TextStyle(
                color: Color(0xFF00C49A),
                fontWeight: FontWeight.w800,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _saveCircadianChanges() {
    ref.read(profileControllerProvider.notifier).updateCircadianProfile(
          currentUser: widget.user,
          wakeUpTime: _toDateTime(_wakeUpTime),
          sleepTime: _toDateTime(_sleepTime),
          firstMealGoal: _toDateTime(_firstMealGoal),
          lastMealGoal: _toDateTime(_lastMealGoal),
        );
  }

  // SPEC-98: `_selectFastingProtocol` se eliminó porque el cambio de
  // protocolo se realiza desde el Dashboard. Aquí en el Perfil el
  // protocolo es read-only.

  // SPEC-88/SPEC-92: helpers de edición biométrica.
  //
  // SPEC-92: cada edit de peso/cintura/cuello DEBE recalcular bodyFat
  // con `BiometryRecalc.recompute` antes de persistir. Si la nueva
  // combinación no es coherente, conservamos el bodyFat anterior y
  // mostramos un snackbar informativo (no bloqueante).
  //
  // El % grasa ya NO se edita manualmente — el tile en el panel es
  // read-only. El usuario lo modifica indirectamente cambiando las
  // medidas que lo derivan.

  void _showIncoherenceNotice() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Las medidas no son coherentes. El % grasa no se actualizó '
          '— revisa cintura, cuello y altura.',
        ),
        backgroundColor: Colors.orange,
        duration: Duration(seconds: 4),
      ),
    );
  }

  // SPEC-BUG7: snackbar educativo cuando el usuario intenta editar
  // biometría durante el período de bloqueo semanal.
  void _showBiometryLockedSnackbar(BiometricLockState lock) {
    final msg = lock.unlocksAt != null
        ? 'Datos biométricos bloqueados — ${lock.unlockLabel}. '
            'Tu IMR Base se estabiliza durante 6 días para reflejar '
            'cambios reales, no fluctuaciones diarias.'
        : 'Datos biométricos bloqueados. Vuelve en 6 días o cierra tu '
            'semana con un Día de Permitidos.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: const Color(0xFF334155),
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// SPEC-92: recalcula bodyFat usando las medidas vigentes + el campo
  /// que se acaba de editar, y persiste ambos campos (editado + bodyFat
  /// recalculado) si la combinación es coherente.
  Future<void> _applyBiometryEdit({
    double? newWeight,
    double? newWaist,
    double? newNeck,
  }) async {
    // SPEC-BUG7: doble-check de seguridad — aunque los botones están
    // deshabilitados visualmente, no aceptamos edits si el lock está activo.
    final lock = ref.read(biometricLockProvider);
    if (lock.isLocked) {
      _showBiometryLockedSnackbar(lock);
      return;
    }
    final user = widget.user;
    final effectiveWeight = newWeight ?? user.weight;
    final effectiveWaist = newWaist ?? user.waistCircumference;
    final effectiveNeck = newNeck ?? user.neckCircumference;

    final recalc = BiometryRecalc.recompute(
      weightKg: effectiveWeight,
      heightCm: user.height,
      waistCm: effectiveWaist,
      neckCm: effectiveNeck,
      gender: user.gender,
    );

    // Caso coherente: persistir campo editado + bodyFat nuevo.
    if (recalc.isCoherent && recalc.bodyFatPercentage != null) {
      await ref.read(profileControllerProvider.notifier).updateBiometry(
            currentUser: user,
            weight: newWeight,
            waistCircumference: newWaist,
            neckCircumference: newNeck,
            bodyFatPercentage: recalc.bodyFatPercentage,
          );
      return;
    }

    // Caso incoherente o sin datos suficientes: solo persistir el
    // campo editado, dejar bodyFat anterior intacto, avisar al usuario.
    await ref.read(profileControllerProvider.notifier).updateBiometry(
          currentUser: user,
          weight: newWeight,
          waistCircumference: newWaist,
          neckCircumference: newNeck,
        );
    if (mounted) _showIncoherenceNotice();
  }

  Future<void> _editWeight() async {
    final value = await EditBiometryValueSheet.show(
      context,
      title: 'Editar peso',
      fieldLabel: 'Peso corporal actual',
      unit: 'kg',
      initialValue: widget.user.weight,
      minValue: 30,
      maxValue: 250,
    );
    if (value != null) {
      await _applyBiometryEdit(newWeight: value);
    }
  }

  Future<void> _editWaist() async {
    final value = await EditBiometryValueSheet.show(
      context,
      title: 'Editar cintura',
      fieldLabel: 'Circunferencia de cintura (medida a la altura del ombligo)',
      unit: 'cm',
      initialValue: widget.user.waistCircumference ?? 80,
      minValue: 50,
      maxValue: 200,
    );
    if (value != null) {
      await _applyBiometryEdit(newWaist: value);
    }
  }

  Future<void> _editNeck() async {
    final value = await EditBiometryValueSheet.show(
      context,
      title: 'Editar cuello',
      fieldLabel: 'Circunferencia del cuello',
      unit: 'cm',
      initialValue: widget.user.neckCircumference ?? 38,
      minValue: 25,
      maxValue: 70,
    );
    if (value != null) {
      await _applyBiometryEdit(newNeck: value);
    }
  }

  /// SPEC-92: muestra explicación de por qué el % grasa no es editable
  /// manualmente. Reemplaza al antiguo `_editBodyFat`.
  void _showBodyFatExplanation() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              '¿Por qué no puedo editar este valor?',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 18,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'El % de grasa corporal se calcula automáticamente a partir '
              'de tu cintura, cuello y altura usando la fórmula US Navy '
              '(validada clínicamente).\n\n'
              'Para actualizarlo, edita cualquiera de esas medidas. Así '
              'evitamos divergencias entre lo que el sistema mide y lo '
              'que el usuario afirma — y el IMR refleja tu estructura '
              'corporal real.',
              style: TextStyle(
                color: Color(0xFFB6C3D1),
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: const Text(
                  'ENTENDIDO',
                  style: TextStyle(
                    color: Color(0xFF00C49A),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // SPEC-52: IMR central desde el provider — sin cálculos locales.
    // SPEC-86: el badge de identidad muestra `displayedImr` que prefiere
    // el persistido cuando el cálculo local solo tiene baseline.
    final displayedImr = ref.watch(displayedImrProvider);

    // SPEC-141 §RF-141-13 (2026-06-05): si `kEnableLongitudinalImr` está
    // ON, el badge pasa a mostrar el IMR longitudinal (40/35/15/10) y
    // se renderiza un disclaimer "Validación clínica pendiente" debajo.
    // Default: false → el badge sigue mostrando el legacy diario sin
    // tocar nada.
    DisplayedImr badgeImr = displayedImr;
    bool showLongitudinalDisclaimer = false;
    if (kEnableLongitudinalImr) {
      final longitudinal = ref.watch(longitudinalImrProvider);
      if (longitudinal.longitudinalScore != null) {
        badgeImr = DisplayedImr(
          score: longitudinal.longitudinalScore!,
          zone: longitudinal.zone,
          localFull: null,
        );
        showLongitudinalDisclaimer = true;
      }
    }

    // SPEC-BUG7: lock semanal de biometría.
    final biometryLock = ref.watch(biometricLockProvider);

    // SPEC-116: rediseño del Perfil — premium, simple, jerárquico.
    // Reemplaza el "muro de tarjetas" por grupos con divisores internos
    // (patrón iOS Settings / Oura / Apple Health). Misma información,
    // misma paleta, menos ruido.
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        // ── Identidad + IMR ─────────────────────────────────────────
        ProfileIdentityCard(user: widget.user, imrResult: badgeImr),
        if (showLongitudinalDisclaimer) ...[
          const SizedBox(height: 8),
          const ProfileLongitudinalDisclaimer(),
        ],
        const SizedBox(height: 24),

        // ── Composición corporal (SPEC-88) ──────────────────────────
        const BodyCompositionCard(),
        const SizedBox(height: 28),

        // ── Datos biométricos (colapsable) ──────────────────────────
        // SPEC-117: disclosure group con preview de 1 línea. El
        // usuario rara vez edita estos datos — quedan accesibles pero
        // no consumen scroll cuando no se necesitan.
        // SPEC-BUG7: preview muestra estado del lock cuando está activo.
        _DisclosureSection(
          title: 'Datos biométricos',
          preview: biometryLock.isLocked
              ? '🔒 ${biometryLock.unlockLabel}'
              : _biometricPreview(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // SPEC-BUG7: banner de lock visible dentro de la sección.
              if (biometryLock.isLocked)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF334155).withValues(alpha: 0.60),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.10),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.lock_outline_rounded,
                            size: 15, color: Color(0xFF94A3B8)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            '${biometryLock.unlockLabel}. El IMR Base se '
                            'estabiliza 6 días para reflejar cambios reales. '
                            'Tu Día de Permitidos también cierra el ciclo.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.60),
                              fontSize: 11,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ProfileDataGroupCard(
                rows: [
                  ProfileDataRow.readonly('Nombre', widget.user.name),
                  ProfileDataRow.readonly('Edad', '${widget.user.age} años'),
                  ProfileDataRow.readonly('Género',
                      widget.user.gender == 'M' ? 'Masculino' : 'Femenino'),
                  ProfileDataRow.readonly(
                      'Estatura', '${widget.user.height.toInt()} cm'),
                  ProfileDataRow.editable(
                    label: 'Peso',
                    value: '${widget.user.weight.toInt()} kg',
                    onTap: biometryLock.isLocked
                        ? () => _showBiometryLockedSnackbar(biometryLock)
                        : _editWeight,
                  ),
                  ProfileDataRow.editable(
                    label: 'Cintura',
                    value:
                        '${widget.user.waistCircumference?.toInt() ?? 0} cm',
                    onTap: biometryLock.isLocked
                        ? () => _showBiometryLockedSnackbar(biometryLock)
                        : _editWaist,
                  ),
                  ProfileDataRow.editable(
                    label: 'Cuello',
                    value:
                        '${widget.user.neckCircumference?.toInt() ?? 0} cm',
                    onTap: biometryLock.isLocked
                        ? () => _showBiometryLockedSnackbar(biometryLock)
                        : _editNeck,
                  ),
                  ProfileDataRow.info(
                    label: '% Grasa est.',
                    value: _formatBodyFat(widget.user.bodyFatPercentage),
                    tag: 'confianza ${widget.user.confidenceLevel}',
                    tagColor: _confidenceColor(widget.user.confidenceLevel),
                    onInfoTap: _showBodyFatExplanation,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Ritmos circadianos (colapsable) ─────────────────────────
        // SPEC-117: configurados una vez al onboarding, casi nunca se
        // revisan. Default colapsado con preview de los anclas
        // (despertar → dormir).
        _DisclosureSection(
          title: 'Ritmos circadianos',
          preview: _circadianPreview(context),
          child: ProfileDataGroupCard(
            rows: [
              ProfileDataRow.icon(
                icon: Icons.wb_sunny_outlined,
                iconColor: const Color(0xFFEAB308),
                label: 'Despertar',
                value: _wakeUpTime.format(context),
                valueColor: const Color(0xFFEAB308),
                onTap: () => _pickTime(_wakeUpTime, (t) => _wakeUpTime = t),
              ),
              ProfileDataRow.icon(
                icon: Icons.nightlight_round,
                iconColor: const Color(0xFF818CF8),
                label: 'Dormir',
                value: _sleepTime.format(context),
                valueColor: const Color(0xFF818CF8),
                onTap: () => _pickTime(_sleepTime, (t) => _sleepTime = t),
              ),
              ProfileDataRow.icon(
                icon: Icons.restaurant_outlined,
                iconColor: const Color(0xFF10B981),
                label: 'Primera comida',
                value: _firstMealGoal.format(context),
                valueColor: const Color(0xFF10B981),
                onTap: () => _pickTime(
                    _firstMealGoal, (t) => _firstMealGoal = t,
                    isMealTimePicker: true),
              ),
              ProfileDataRow.icon(
                icon: Icons.no_meals_outlined,
                iconColor: const Color(0xFFFB923C),
                label: 'Última comida',
                value: _lastMealGoal.format(context),
                valueColor: const Color(0xFFFB923C),
                onTap: () => _pickTime(_lastMealGoal, (t) => _lastMealGoal = t,
                    isMealTimePicker: true),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Protocolo de ayuno (read-only) ──────────────────────────
        // SPEC-98: el selector de protocolo se movió al Dashboard
        // (chip clickable en la card "Ayuno Consciente").
        _buildSectionTitle('Protocolo de ayuno'),
        const SizedBox(height: 10),
        ProfileProtocolCard(protocol: widget.user.fastingProtocol),
        const SizedBox(height: 24),

        // ── SPEC-168.0.B: Mis objetivos ─────────────────────────────
        // Sección que muestra los goals activos del usuario con preview
        // (emoji + valor + unit) y un CTA "Editar objetivos" que
        // navega a /goals/setup. Si no hay goals (usuario que omitió el
        // paso de onboarding o legacy pre-SPEC-168), muestra estado
        // vacío con CTA "Configurar objetivos".
        _buildSectionTitle('Mis objetivos'),
        const SizedBox(height: 10),
        const ProfileGoalsSection(),
        const SizedBox(height: 24),

        // ── Sistema de insignias (2026-07-15) ────────────────────────
        // Propuesta "Sistema de Insignias" §6: galería de identidad,
        // no solo mecánica de progreso — grid de 10 categorías, cada
        // una con su nivel más alto ganado; tocar abre el detalle.
        _buildSectionTitle('Insignias'),
        const SizedBox(height: 10),
        const BadgeGallery(),
        const SizedBox(height: 24),

        // ── SPEC-132: sincronización con Apple Health / Health Connect
        _buildSectionTitle('Salud'),
        const SizedBox(height: 10),
        const HealthSyncCard(),
        const SizedBox(height: 24),

        // ── Legal ───────────────────────────────────────────────────
        // SPEC-117: renombrado de "Cuenta" → "Legal" (los items son
        // documentos informativos, no acciones de cuenta). Bajada
        // sustancial de peso visual: lista plana sin card-border, sin
        // iconos coloreados, tipografía secundaria.
        _buildSectionTitle('Legal'),
        const SizedBox(height: 6),
        const ProfileLegalSection(),
        const SizedBox(height: 28),

        // ── Ayuda ────────────────────────────────────────────────────
        _buildSectionTitle('Ayuda'),
        const SizedBox(height: 6),
        Consumer(
          builder: (ctx, ref, _) => InkWell(
            onTap: () async {
              await ref.read(appTourProvider.notifier).forceReset();
              await ref.read(appTourProvider.notifier).tryActivate();
              if (ctx.mounted) ctx.go('/dashboard');
            },
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Guía de la app',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.70),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Vuelve a ver el tour interactivo',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w400,
                            color: Colors.white.withValues(alpha: 0.34),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withValues(alpha: 0.24),
                    size: 18,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // ── Acciones destructivas (text buttons sutiles) ────────────
        const ProfileDangerZoneActions(),
      ],
    );
  }

  // SPEC-119: card del protocolo de ayuno → ProfileProtocolCard
  // (widgets/profile_protocol_card.dart). Extraído en ARCH-03.

  String _formatBodyFat(double? value) {
    if (value == null) return 'Sin medir';
    return '${value.toStringAsFixed(1)}%';
  }

  /// Preview de 1 línea para el disclosure de "Datos biométricos".
  /// Muestra los dos datos más usados (peso + body fat) cuando está
  /// colapsado, para que el usuario sepa el valor sin expandir.
  String _biometricPreview() {
    final weight = '${widget.user.weight.toInt()} kg';
    final bodyFat = widget.user.bodyFatPercentage;
    if (bodyFat == null) return weight;
    return '$weight · ${bodyFat.toStringAsFixed(1)}% grasa';
  }

  /// Preview de 1 línea para el disclosure de "Ritmos circadianos".
  /// Muestra los anclas del día (despertar → dormir).
  String _circadianPreview(BuildContext context) {
    return '${_wakeUpTime.format(context)} → ${_sleepTime.format(context)}';
  }

  Color _confidenceColor(String level) {
    switch (level) {
      case 'ALTA':
        return AppColors.metabolicGreen;
      case 'MEDIA':
        return const Color(0xFFEAB308);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  // SPEC-119: identity card + longitudinal disclaimer →
  // ProfileIdentityCard + ProfileLongitudinalDisclaimer
  // (widgets/profile_identity_card.dart). Extraído en ARCH-03.
  // `_zoneColor` (delegador de una línea a `AppColors.imrZoneColor`)
  // se inlineó dentro del widget nuevo.

  // SPEC-98: el grid 2×4 y la card "Recomendado para ti" se removieron
  // del Perfil. El protocolo se cambia desde el Dashboard (chip clickable
  // en la card "Ayuno Consciente"). Los métodos `_buildProtocolSelector`,
  // `_buildRecommendedProtocolCard` y `_recommendedProtocol` se eliminaron.

  // SPEC-119: grupo legal → ProfileLegalSection
  // (widgets/profile_legal_section.dart). Extraído en ARCH-03.

  // SPEC-119: logout/delete account (botones + diálogos) →
  // ProfileDangerZoneActions (widgets/profile_danger_zone_actions.dart).
  // Extraído en ARCH-03.

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// SPEC-116: header de sección en sentence-case, peso w600, sin
  /// tracking exagerado. Reemplaza al `_buildSectionLabel` UPPERCASE
  /// w900 que sentía clínico/corporativo.
  Widget _buildSectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white.withValues(alpha: 0.55),
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  // SPEC-119: sección "Mis objetivos" (_buildGoalsSection +
  // _buildGoalsEmptyState + _buildGoalsListCard + _buildGoalRow +
  // _formatGoalValue + `_zoneColor`, delegador de una línea a
  // `AppColors.imrZoneColor`) → ProfileGoalsSection
  // (widgets/profile_goals_section.dart). Extraído en ARCH-03.
}

// SPEC-117: las clases DataGroupCard, DataRow y DataRowKind se
// extrajeron a `widgets/data_group_card.dart` para que sean públicas
// y testeables. Las implementaciones inline anteriores se eliminaron
// (este archivo ya no las contiene — se importan vía el archivo
// público).

// ─────────────────────────────────────────────────────────────────────────────
// SPEC-117: Disclosure section
//
// Sección colapsable con header tipo iOS Settings + preview opcional de 1
// línea + chevron animado. El contenido se anima con AnimatedCrossFade
// (altura + fade) en ~220ms con easeInOutCubic.
//
// Por defecto inicia colapsado. El estado vive en memoria local — no
// se persiste entre aperturas de la pantalla (decisión: el usuario
// vuelve a un estado limpio cada vez que entra al Perfil).
// ─────────────────────────────────────────────────────────────────────────────

class _DisclosureSection extends StatefulWidget {
  /// Título principal de la sección (sentence case, w600).
  final String title;

  /// Resumen de 1 línea visible cuando la sección está colapsada.
  /// Ejemplo: "82 kg · 33.9% grasa". Null oculta el preview.
  final String? preview;

  /// Contenido que se revela al expandir. Suele ser un `_DataGroupCard`.
  final Widget child;

  /// Estado inicial. Por defecto colapsado.
  final bool initiallyExpanded;

  const _DisclosureSection({
    required this.title,
    required this.child,
    this.preview,
    // ignore: unused_element_parameter
    this.initiallyExpanded = false,
  });

  @override
  State<_DisclosureSection> createState() => _DisclosureSectionState();
}

class _DisclosureSectionState extends State<_DisclosureSection>
    with SingleTickerProviderStateMixin {
  late bool _expanded;
  late final AnimationController _chevronCtrl;
  late final Animation<double> _chevronRotation;

  static const Duration _animDuration = Duration(milliseconds: 220);

  @override
  void initState() {
    super.initState();
    _expanded = widget.initiallyExpanded;
    _chevronCtrl = AnimationController(
      vsync: this,
      duration: _animDuration,
      value: _expanded ? 1.0 : 0.0,
    );
    _chevronRotation = Tween<double>(begin: 0.0, end: 0.25).animate(
      CurvedAnimation(parent: _chevronCtrl, curve: Curves.easeInOutCubic),
    );
  }

  @override
  void dispose() {
    _chevronCtrl.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _expanded = !_expanded;
      if (_expanded) {
        _chevronCtrl.forward();
      } else {
        _chevronCtrl.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggle,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.62),
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (widget.preview != null)
                    Expanded(
                      child: Text(
                        widget.preview!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.36),
                          letterSpacing: 0.2,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  RotationTransition(
                    turns: _chevronRotation,
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.45),
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          duration: _animDuration,
          sizeCurve: Curves.easeInOutCubic,
          firstChild: const SizedBox(width: double.infinity, height: 0),
          secondChild: Padding(
            padding: const EdgeInsets.only(top: 8),
            child: widget.child,
          ),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
        ),
      ],
    );
  }
}
