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
import 'package:elena_app/src/features/dashboard/domain/optimal_schedule.dart';
import 'package:elena_app/src/features/analysis/domain/imr_explanation.dart';
import 'package:elena_app/src/features/goals/application/goal_notifier.dart';
import 'package:elena_app/src/features/goals/domain/user_goal.dart';
import 'package:elena_app/src/features/goals/presentation/goal_icons.dart';
import 'package:elena_app/src/features/health_sync/presentation/health_sync_card.dart';
import 'package:elena_app/src/features/profile/application/biometric_lock_provider.dart';
import 'package:elena_app/src/features/profile/domain/biometric_lock_service.dart';
import 'package:elena_app/src/features/profile/domain/biometry_recalc.dart';
import 'package:elena_app/src/features/profile/presentation/widgets/body_composition_card.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

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
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return BottomNavigationBar(
      backgroundColor: AppColors.backgroundDark,
      selectedItemColor: const Color(0xFF10B981),
      unselectedItemColor: Colors.grey.withValues(alpha: 0.5),
      currentIndex: 2,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == 0) context.go('/dashboard');
        if (index == 1) context.go('/analysis');
        if (index == 2) context.go('/profile');
      },
      items: const [
        BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded), label: 'Hoy'),
        BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded), label: 'Progreso'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
      ],
    );
  }
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
        _buildIdentityCard(badgeImr),
        if (showLongitudinalDisclaimer) ...[
          const SizedBox(height: 8),
          _buildLongitudinalDisclaimer(),
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
        _buildProtocolCard(context),
        const SizedBox(height: 24),

        // ── SPEC-168.0.B: Mis objetivos ─────────────────────────────
        // Sección que muestra los goals activos del usuario con preview
        // (emoji + valor + unit) y un CTA "Editar objetivos" que
        // navega a /goals/setup. Si no hay goals (usuario que omitió el
        // paso de onboarding o legacy pre-SPEC-168), muestra estado
        // vacío con CTA "Configurar objetivos".
        _buildSectionTitle('Mis objetivos'),
        const SizedBox(height: 10),
        _buildGoalsSection(context),
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
        _buildLegalGroup(context),
        const SizedBox(height: 28),

        // ── Acciones destructivas (text buttons sutiles) ────────────
        _buildLogoutTextButton(context),
        const SizedBox(height: 4),
        _buildDeleteAccountTextButton(context),
      ],
    );
  }

  /// Card del protocolo de ayuno: protocolo activo + detalle inline
  /// (h ayuno · h ventana) + link sutil a la pantalla "Hoy" donde se
  /// edita el protocolo.
  Widget _buildProtocolCard(BuildContext context) {
    final protocol = widget.user.fastingProtocol;
    final parts = protocol.split(':');
    final fastingHours =
        parts.isNotEmpty ? (int.tryParse(parts.first) ?? 16) : 16;
    final feedingHours = parts.length > 1 ? (int.tryParse(parts[1]) ?? 8) : 8;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Activo',
                  style: TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  protocol,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Text(
              '${fastingHours}h ayuno · ${feedingHours}h ventana',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.38),
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            color: AppColors.borderSubtle,
          ),
          InkWell(
            // SPEC-116: query param `pillar=ayuno` para que el
            // Dashboard abra directamente con la card de Ayuno
            // seleccionada (el chip de protocolo vive ahí).
            onTap: () => context.go('/dashboard?pillar=ayuno'),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'Cambiar protocolo',
                    style: TextStyle(
                      color: AppColors.metabolicGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.metabolicGreen.withValues(alpha: 0.8),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

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

  // ── Widgets ──────────────────────────────────────────────────────────────

  Widget _buildIdentityCard(DisplayedImr imrResult) {
    final zoneColor = _zoneColor(imrResult.zone);
    // SPEC-116: sin border coloreado. El badge IMR ya comunica el
    // estado clínico. Subtítulo de la card incluye "Expediente
    // metabólico" como branding clínico recuperado del AppBar.
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
                  widget.user.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  widget.user.pathologies.isEmpty
                      ? 'Expediente metabólico'
                      : widget.user.pathologies.join(' · '),
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

  /// SPEC-141 §RF-141-13 (2026-06-05): banner visible cuando el badge
  /// está mostrando el IMR longitudinal (feature flag ON). Sin firma
  /// clínica todavía → mostrar disclaimer transparente.
  Widget _buildLongitudinalDisclaimer() {
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

  // SPEC-98: el grid 2×4 y la card "Recomendado para ti" se removieron
  // del Perfil. El protocolo se cambia desde el Dashboard (chip clickable
  // en la card "Ayuno Consciente"). Los métodos `_buildProtocolSelector`,
  // `_buildRecommendedProtocolCard` y `_recommendedProtocol` se eliminaron.

  // SPEC-117: grupo legal redesigned como footer plano "presente pero
  // no protagonista". Sin border, sin background coloreado, sin
  // iconos. Solo filas de texto con chevron sutil + divisores
  // delgadísimos. Tipografía secundaria (alpha 0.7) y sub más tenue
  // (alpha 0.4) para que el bloque "respire" abajo en la pantalla.
  Widget _buildLegalGroup(BuildContext context) {
    return Column(
      children: [
        _legalRow(
          context: context,
          title: 'Condiciones médicas',
          subtitle: 'Poblaciones de riesgo del IMR',
          route: '/profile/disclaimer',
        ),
        _legalDivider(),
        _legalRow(
          context: context,
          title: 'Política de privacidad',
          subtitle: 'Cómo manejamos tus datos',
          route: '/legal/privacy',
        ),
        _legalDivider(),
        _legalRow(
          context: context,
          title: 'Términos de uso',
          subtitle: 'Condiciones del servicio',
          route: '/legal/terms',
        ),
      ],
    );
  }

  Widget _legalRow({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String route,
  }) {
    return InkWell(
      onTap: () => context.push(route),
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
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withValues(alpha: 0.70),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
    );
  }

  Widget _legalDivider() {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      color: Colors.white.withValues(alpha: 0.04),
    );
  }

  // SPEC-116: logout y delete account pasan a text buttons sutiles
  // (estilo Apple Settings). El logout era verde sólido — pelea por
  // atención con CTAs primarios. Ahora ambos botones son textuales,
  // ancho completo pero sin fill, con el delete en rojo opaco como
  // señal de acción crítica.
  Widget _buildLogoutTextButton(BuildContext context) {
    return TextButton(
      onPressed: () => _confirmLogout(context),
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: Colors.white.withValues(alpha: 0.85),
      ),
      child: const Text(
        'Cerrar sesión',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildDeleteAccountTextButton(BuildContext context) {
    return TextButton(
      onPressed: () => _confirmDeleteAccount(context),
      style: TextButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        foregroundColor: Colors.redAccent.withValues(alpha: 0.85),
      ),
      child: const Text(
        'Eliminar cuenta',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  // ── Diálogos ─────────────────────────────────────────────────────────────

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión',
            style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text(
          '¿Estás seguro que deseas cerrar sesión?',
          style: TextStyle(color: Color(0xFF94A3B8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('CANCELAR',
                style: TextStyle(color: Color(0xFF94A3B8))),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              // CA-02-03: Firebase cierra sesión y el guard redirige a /login
              await ref.read(profileControllerProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
            child: const Text('CERRAR SESIÓN',
                style: TextStyle(
                    color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  /// Diálogo de doble confirmación con campo de texto "ELIMINAR" (CA-02-04)
  void _confirmDeleteAccount(BuildContext context) {
    final confirmController = TextEditingController();
    bool isEnabled = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => AlertDialog(
          backgroundColor: AppColors.surfaceDark,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text('Eliminar cuenta',
                  style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta acción es permanente. Se eliminarán tu cuenta y todos tus datos metabólicos de Firestore.',
                style: TextStyle(
                    color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              const Text(
                'Escribe ELIMINAR para confirmar:',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'ELIMINAR',
                  hintStyle:
                      const TextStyle(color: Color(0xFF475569), fontSize: 13),
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.redAccent),
                  ),
                ),
                onChanged: (val) {
                  setModalState(() {
                    isEnabled = val.trim().toUpperCase() == 'ELIMINAR';
                  });
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                confirmController.dispose();
                Navigator.pop(ctx);
              },
              child: const Text('CANCELAR',
                  style: TextStyle(color: Color(0xFF94A3B8))),
            ),
            TextButton(
              onPressed: isEnabled
                  ? () async {
                      Navigator.pop(ctx);
                      // SPEC-83 fix: capturar el messenger ANTES del
                      // await para no depender del context tras el
                      // delete (la pantalla deja de existir cuando
                      // currentUserStreamProvider emite null).
                      final messenger = ScaffoldMessenger.of(context);
                      final goRouter = GoRouter.of(context);
                      try {
                        await ref
                            .read(profileControllerProvider.notifier)
                            .deleteAccount();
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Cuenta eliminada. Hasta pronto.',
                            ),
                            backgroundColor: Color(0xFF10B981),
                            duration: Duration(seconds: 3),
                          ),
                        );
                        goRouter.go('/login');
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(e.toString()),
                            backgroundColor: Colors.redAccent,
                            duration: const Duration(seconds: 5),
                          ),
                        );
                      }
                    }
                  : null,
              child: Text(
                'ELIMINAR CUENTA',
                style: TextStyle(
                  color: isEnabled
                      ? Colors.redAccent
                      : Colors.redAccent.withValues(alpha: 0.3),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  // UI #2: color del IMR desde la rampa calma única (sin rojo de alarma).
  Color _zoneColor(String zone) => AppColors.imrZoneColor(zone);

  /// SPEC-168.0.B + SPEC-168.0.A v2 (Opción B, Carlos 2026-06-03):
  /// card de "Mis objetivos" que lista **todos** los goals del usuario
  /// (activos + inactivos) con CTA a /goals/setup. Los inactivos se
  /// renderizan atenuados con badge "Sin activar". El estado vacío
  /// solo aparece cuando el usuario nunca pasó por el step 5 del
  /// onboarding (caso legacy pre-SPEC-168) ni configuró desde Perfil.
  Widget _buildGoalsSection(BuildContext context) {
    final goalsMap = ref.watch(goalsProvider);
    final allGoals = goalsMap.values.toList()
      ..sort((a, b) => a.type.index.compareTo(b.type.index));

    if (allGoals.isEmpty) {
      return _buildGoalsEmptyState(context);
    }
    return _buildGoalsListCard(context, allGoals);
  }

  /// Estado vacío: usuario que omitió onboarding o legacy pre-SPEC-168.
  /// Invita a configurar con narrativa coaching ("Elena tiene
  /// recomendaciones listas").
  Widget _buildGoalsEmptyState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      padding: const EdgeInsets.fromLTRB(18, 22, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Aún no configuraste tus objetivos.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Elena tiene recomendaciones listas basadas en tus datos.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.55),
              fontSize: 13,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/goals/setup'),
              icon: const Icon(Icons.tune_rounded, size: 18),
              label: const Text('Configurar objetivos'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.metabolicGreen,
                side: BorderSide(
                  color: AppColors.metabolicGreen.withValues(alpha: 0.6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Card con lista de goals (activos + inactivos) + CTA "Editar
  /// objetivos" en footer. Sigue el patrón de `_buildProtocolCard`
  /// (header + filas + divisor + InkWell de acción al fondo).
  Widget _buildGoalsListCard(
    BuildContext context,
    List<UserGoal> allGoals,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (int i = 0; i < allGoals.length; i++) ...[
            if (i > 0)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 18),
                color: AppColors.borderSubtle,
              ),
            _buildGoalRow(allGoals[i]),
          ],
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 18),
            color: AppColors.borderSubtle,
          ),
          InkWell(
            onTap: () => context.push('/goals/setup'),
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Row(
                children: [
                  const Text(
                    'Editar objetivos',
                    style: TextStyle(
                      color: AppColors.metabolicGreen,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_rounded,
                    color: AppColors.metabolicGreen.withValues(alpha: 0.8),
                    size: 16,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Fila individual de un goal: emoji + label + valor + unit en línea.
  /// SPEC-168.0.A v2 Opción B: si el goal está inactivo, atenuamos el
  /// row con opacidad reducida y agregamos badge "Sin activar" en
  /// lugar de la unidad. El usuario tap "Editar objetivos" para
  /// activar o ajustar.
  Widget _buildGoalRow(UserGoal goal) {
    final double opacity = goal.isActive ? 1.0 : 0.45;
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
      child: Opacity(
        opacity: opacity,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(goalIcon(goal.type),
                      size: 16, color: Colors.white.withValues(alpha: 0.85)),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      goal.label,
                      style: const TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            if (goal.isActive)
              Text(
                '${_formatGoalValue(goal)} ${goal.unit}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
              )
            else
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${_formatGoalValue(goal)} ${goal.unit}',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Sin activar',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  /// Formateo del valor numérico del goal: enteros sin decimales,
  /// fracciones con 1 decimal. Coherente con la presentación en
  /// `goalsProgressDashboard`.
  String _formatGoalValue(UserGoal goal) {
    final v = goal.targetValue;
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }
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
