// 17-jul (2da vuelta, rediseño Perfil): "Ritmos circadianos" pasa del
// acordeón inline al patrón de card colapsada + pantalla de detalle —
// ver comentario en biometricos_detail_screen.dart, mismo movimiento.
// Toda la lógica de edición (time pickers + validación de bloqueo
// intestinal) se movió tal cual desde `_ProfileBodyState`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/application/profile_controller.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/data_group_card.dart';
import 'package:elena_app/src/features/fasting/domain/optimal_schedule.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class RitmosCircadianosDetailScreen extends ConsumerWidget {
  const RitmosCircadianosDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);

    // 17-jul: ver comentario equivalente en biometricos_detail_screen.dart
    // — el feedback de guardado se mueve a la pantalla donde ocurre la
    // edición.
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

    final isSaving = ref.watch(
      profileControllerProvider.select((s) => s.isSaving),
    );

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Ritmos circadianos',
          style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 18, letterSpacing: 0),
        ),
        centerTitle: false,
        actions: [
          if (isSaving)
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
          return _Body(user: user);
        },
      ),
    );
  }
}

class _Body extends ConsumerStatefulWidget {
  const _Body({required this.user});
  final UserModel user;

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  late TimeOfDay _wakeUpTime;
  late TimeOfDay _sleepTime;
  late TimeOfDay _firstMealGoal;
  late TimeOfDay _lastMealGoal;

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
      await _showIntestinalBlockDialog();
      return;
    }

    setState(() => onPicked(picked));
    _saveCircadianChanges();

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

  Future<void> _showIntestinalBlockDialog() async {
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

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
        children: [
          ProfileDataGroupCard(
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
        ],
      ),
    );
  }
}
