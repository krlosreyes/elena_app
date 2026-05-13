import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/core/engine/imr_persistence_provider.dart';
import 'package:elena_app/src/features/auth/application/profile_controller.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/edit_biometry_value_sheet.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
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
        title: const Text(
          'EXPEDIENTE METABÓLICO',
          style: TextStyle(
              fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: 1.2),
        ),
        centerTitle: true,
        backgroundColor: AppColors.surfaceDark,
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
            icon: Icon(Icons.grid_view_rounded), label: 'Dashboard'),
        BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded), label: 'Análisis'),
        BottomNavigationBarItem(
            icon: Icon(Icons.person), label: 'Perfil'),
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
  late String _fastingProtocol;

  @override
  void initState() {
    super.initState();
    _wakeUpTime = TimeOfDay.fromDateTime(widget.user.profile.wakeUpTime);
    _sleepTime = TimeOfDay.fromDateTime(widget.user.profile.sleepTime);
    _firstMealGoal = TimeOfDay.fromDateTime(
        widget.user.profile.firstMealGoal ?? widget.user.profile.wakeUpTime);
    _lastMealGoal = TimeOfDay.fromDateTime(
        widget.user.profile.lastMealGoal ?? widget.user.profile.sleepTime);
    _fastingProtocol = widget.user.fastingProtocol;
  }

  // Convierte TimeOfDay → DateTime usando la fecha de hoy como base
  DateTime _toDateTime(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  Future<void> _pickTime(
      TimeOfDay current, ValueChanged<TimeOfDay> onPicked) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      builder: (context, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF10B981),
            surface: Color(0xFF1E293B),
          ),
          dialogBackgroundColor: const Color(0xFF1E293B),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => onPicked(picked));
      _saveCircadianChanges();
    }
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

  void _selectFastingProtocol(String protocol) {
    setState(() => _fastingProtocol = protocol);
    ref.read(profileControllerProvider.notifier).updateFastingProtocol(
          currentUser: widget.user,
          protocol: protocol,
        );
  }

  // SPEC-88: helpers de edición biométrica. Cada uno abre el sheet,
  // recibe el nuevo valor y delega a `ProfileController.updateBiometry`.
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
      await ref.read(profileControllerProvider.notifier).updateBiometry(
            currentUser: widget.user,
            weight: value,
          );
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
      await ref.read(profileControllerProvider.notifier).updateBiometry(
            currentUser: widget.user,
            waistCircumference: value,
          );
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
      await ref.read(profileControllerProvider.notifier).updateBiometry(
            currentUser: widget.user,
            neckCircumference: value,
          );
    }
  }

  Future<void> _editBodyFat() async {
    final value = await EditBiometryValueSheet.show(
      context,
      title: 'Editar % grasa',
      fieldLabel: 'Porcentaje de grasa corporal estimado',
      unit: '%',
      initialValue: widget.user.bodyFatPercentage,
      minValue: 3,
      maxValue: 60,
    );
    if (value != null) {
      await ref.read(profileControllerProvider.notifier).updateBiometry(
            currentUser: widget.user,
            bodyFatPercentage: value,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    // SPEC-52: IMR central desde el provider — sin cálculos locales.
    // SPEC-86: el badge de identidad muestra `displayedImr` que prefiere
    // el persistido cuando el cálculo local solo tiene baseline.
    final displayedImr = ref.watch(displayedImrProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      children: [
        // ── Tarjeta de identidad + IMR ──────────────────────────────
        _buildIdentityCard(displayedImr),
        const SizedBox(height: 20),

        // ── SPEC-88: Composición corporal ────────────────────────────
        const BodyCompositionCard(),
        const SizedBox(height: 28),

        // ── Datos biométricos ───────────────────────────────────────
        _buildSectionLabel('HARDWARE BIOLÓGICO'),
        const SizedBox(height: 12),
        _readOnlyTile('Nombre', widget.user.name),
        _readOnlyTile('Edad', '${widget.user.age} años'),
        _readOnlyTile('Género',
            widget.user.gender == 'M' ? 'Masculino' : 'Femenino'),
        _readOnlyTile('Estatura', '${widget.user.height.toInt()} cm'),
        // SPEC-88: tiles editables (peso, cintura, cuello, %grasa).
        _editableBiometryTile(
          icon: Icons.hourglass_bottom_rounded,
          label: 'Peso',
          value: '${widget.user.weight.toInt()} kg',
          onTap: () => _editWeight(),
        ),
        _editableBiometryTile(
          icon: Icons.straighten_rounded,
          label: 'Cintura',
          value: '${widget.user.waistCircumference?.toInt() ?? 0} cm',
          onTap: () => _editWaist(),
        ),
        _editableBiometryTile(
          icon: Icons.check_circle_outline_rounded,
          label: 'Cuello',
          value: '${widget.user.neckCircumference?.toInt() ?? 0} cm',
          onTap: () => _editNeck(),
        ),
        _editableBiometryTile(
          icon: Icons.show_chart_rounded,
          label: '% Grasa Est.',
          value: '${widget.user.bodyFatPercentage.toStringAsFixed(1)}%',
          onTap: () => _editBodyFat(),
        ),
        const SizedBox(height: 24),

        // ── Ritmo Circadiano (editable) ─────────────────────────────
        _buildSectionLabel('RITMOS CIRCADIANOS'),
        const SizedBox(height: 4),
        _buildSectionSubtitle('Toca cualquier horario para editarlo'),
        const SizedBox(height: 12),
        _editableTile(
          label: 'Despertar',
          value: _wakeUpTime.format(context),
          icon: Icons.wb_sunny_outlined,
          color: const Color(0xFFEAB308),
          onTap: () =>
              _pickTime(_wakeUpTime, (t) => _wakeUpTime = t),
        ),
        _editableTile(
          label: 'Dormir',
          value: _sleepTime.format(context),
          icon: Icons.nightlight_round,
          color: const Color(0xFF818CF8),
          onTap: () =>
              _pickTime(_sleepTime, (t) => _sleepTime = t),
        ),
        _editableTile(
          label: 'Primera Comida',
          value: _firstMealGoal.format(context),
          icon: Icons.restaurant_outlined,
          color: const Color(0xFF10B981),
          onTap: () =>
              _pickTime(_firstMealGoal, (t) => _firstMealGoal = t),
        ),
        _editableTile(
          label: 'Última Comida',
          value: _lastMealGoal.format(context),
          icon: Icons.no_meals_outlined,
          color: const Color(0xFFFB923C),
          onTap: () =>
              _pickTime(_lastMealGoal, (t) => _lastMealGoal = t),
        ),
        const SizedBox(height: 24),

        // ── Protocolo de Ayuno (editable) ───────────────────────────
        _buildSectionLabel('PROTOCOLO DE AYUNO'),
        const SizedBox(height: 12),
        _buildProtocolSelector(),
        const SizedBox(height: 32),

        // ── Acciones de cuenta ──────────────────────────────────────
        _buildSectionLabel('CUENTA'),
        const SizedBox(height: 12),
        _buildLogoutButton(context),
        const SizedBox(height: 12),
        _buildDeleteAccountButton(context),
      ],
    );
  }

  // ── Widgets ──────────────────────────────────────────────────────────────

  Widget _buildIdentityCard(DisplayedImr imrResult) {
    final zoneColor = _zoneColor(imrResult.zone);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: zoneColor.withValues(alpha: 0.25), width: 1.5),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              border:
                  Border.all(color: const Color(0xFF10B981).withValues(alpha: 0.4)),
            ),
            child: const Icon(Icons.person_outline_rounded,
                color: Color(0xFF10B981), size: 28),
          ),
          const SizedBox(width: 16),
          // Nombre + patologías
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.name,
                  style: const TextStyle(
                      fontWeight: FontWeight.w800, fontSize: 16),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.user.pathologies.join(', '),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                ),
              ],
            ),
          ),
          // IMR badge
          Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: zoneColor, width: 2.5),
                ),
                child: Center(
                  child: Text(
                    '${imrResult.score}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: zoneColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                imrResult.zone,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: zoneColor,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // SPEC-88: grid 2×4 con 8 protocolos. Mantiene la misma lógica de
  // selección (`_selectFastingProtocol`) — solo cambia la presentación.
  Widget _buildProtocolSelector() {
    final protocols = const [
      'Ninguno',
      '12:12',
      '14:10',
      '16:8',
      '18:6',
      '20:4',
      '22:2',
      'OMAD',
    ];
    final recommended = _recommendedProtocol();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildRecommendedProtocolCard(recommended),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 4,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: protocols.map((p) {
            final isSelected = _fastingProtocol == p;
            return GestureDetector(
              onTap: () => _selectFastingProtocol(p),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.metabolicGreen
                      : AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.metabolicGreen
                                .withValues(alpha: 0.4),
                            blurRadius: 14,
                            spreadRadius: 0,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  p,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: isSelected
                        ? Colors.white
                        : Colors.white.withValues(alpha: 0.65),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  /// SPEC-88: protocolo recomendado. Por ahora se hereda del
  /// `fastingProtocol` actual del usuario (placeholder simple). Si en
  /// el futuro hay un servicio de recomendación, se inyecta sin
  /// cambiar la UI.
  String _recommendedProtocol() {
    final current = widget.user.fastingProtocol;
    if (current.isNotEmpty && current != 'Ninguno') return current;
    return '18:6';
  }

  Widget _buildRecommendedProtocolCard(String recommended) {
    const Map<String, String> descriptions = {
      'Ninguno':
          'Sin ventana de ayuno. Recomendado para iniciar y construir hábitos básicos.',
      '12:12':
          'Ventana suave. Apropiado para iniciar el ayuno intermitente.',
      '14:10':
          'Ventana corta. Buen punto medio para principiantes con tolerancia adecuada.',
      '16:8':
          'Protocolo clásico. Promueve autofagia ligera y mejora sensibilidad a insulina.',
      '18:6':
          'Ayuno moderado-intenso. Aumenta autofagia sin extremos.',
      '20:4':
          'Ventana muy corta. Indicado para usuarios con experiencia previa.',
      '22:2':
          'Ayuno avanzado. Solo bajo supervisión y con tolerancia confirmada.',
      'OMAD':
          'Una comida al día. Protocolo extremo — supervisión recomendada.',
    };
    final desc = descriptions[recommended] ?? '';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.metabolicGreen.withValues(alpha: 0.5),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.metabolicGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome_rounded,
              color: AppColors.metabolicGreen,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'RECOMENDADO PARA TI',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white.withValues(alpha: 0.5),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  recommended,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.metabolicGreen,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  desc,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _confirmLogout(context),
        icon: const Icon(Icons.logout_rounded, size: 18, color: Colors.white),
        label: const Text(
          'CERRAR SESIÓN',
          style: TextStyle(
              fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF10B981),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 0,
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _confirmDeleteAccount(context),
        icon: const Icon(Icons.delete_forever_rounded,
            size: 18, color: Colors.redAccent),
        label: const Text(
          'ELIMINAR CUENTA',
          style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.redAccent),
        ),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.redAccent, width: 1),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              await ref
                  .read(profileControllerProvider.notifier)
                  .signOut();
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
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent, size: 20),
              SizedBox(width: 8),
              Text('Eliminar cuenta',
                  style: TextStyle(
                      fontWeight: FontWeight.w900, fontSize: 16)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta acción es permanente. Se eliminarán tu cuenta y todos tus datos metabólicos de Firestore.',
                style:
                    TextStyle(color: Color(0xFF94A3B8), fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              const Text(
                'Escribe ELIMINAR para confirmar:',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: confirmController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  hintText: 'ELIMINAR',
                  hintStyle: const TextStyle(
                      color: Color(0xFF475569), fontSize: 13),
                  filled: true,
                  fillColor: AppColors.backgroundDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Color(0xFF334155)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: Colors.redAccent),
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

  Widget _buildSectionLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w900,
        color: Colors.white.withValues(alpha: 0.3),
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildSectionSubtitle(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 11,
        color: Colors.white.withValues(alpha: 0.35),
      ),
    );
  }

  Widget _readOnlyTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 12,
                  fontWeight: FontWeight.w500)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  // SPEC-88: tile biométrico editable con ícono a la izquierda + valor
  // en verde + lápiz visual. Tap abre el sheet de edición.
  Widget _editableBiometryTile({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.metabolicGreen.withValues(alpha: 0.18),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.metabolicGreen, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.metabolicGreen,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.edit_outlined,
              size: 14,
              color: Colors.white.withValues(alpha: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _editableTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: const TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500)),
            ),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: color)),
            const SizedBox(width: 8),
            Icon(Icons.edit_outlined,
                size: 14, color: Colors.white.withValues(alpha: 0.2)),
          ],
        ),
      ),
    );
  }

  Color _zoneColor(String zone) {
    switch (zone) {
      case 'OPTIMIZADO':
        return const Color(0xFF10B981);
      case 'EFICIENTE':
        return const Color(0xFF22BB33);
      case 'FUNCIONAL':
        return const Color(0xFFFFD700);
      case 'INESTABLE':
        return const Color(0xFFFF8C00);
      default:
        return const Color(0xFFFF4444);
    }
  }
}
