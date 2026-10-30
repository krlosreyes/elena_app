// Fix notificaciones (2026-10-30): pantalla "Notificaciones" del Perfil.
//
// Un interruptor por tipo de aviso y un límite diario (1–3). Nunca se pueden
// tener activos más tipos que el límite: si el usuario intenta activar uno
// más, se le pide apagar otro primero. La regla dura vive en
// NotificationPolicy; esta pantalla solo la expone.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/providers/notification_provider.dart';
import 'package:elena_app/src/core/services/notification_policy.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  late Set<NotificationKind> _enabled;
  late int _maxPerDay;
  bool _loading = true;

  static const Map<NotificationKind, (IconData, String, String)> _copy = {
    NotificationKind.manana: (
      Icons.wb_sunny_outlined,
      'Resumen de la mañana',
      'Tus objetivos del día, al despertar',
    ),
    NotificationKind.comidas: (
      Icons.restaurant_outlined,
      'Cierre de la ventana de comida',
      '30 minutos antes de cerrar la cocina',
    ),
    NotificationKind.sueno: (
      Icons.nightlight_outlined,
      'Buenas noches',
      'A tu hora de dormir',
    ),
    NotificationKind.ayuno: (
      Icons.hourglass_bottom_rounded,
      'Ayuno de 16 horas',
      'Cuando cumples 16 h de ayuno',
    ),
    NotificationKind.agua: (
      Icons.water_drop_outlined,
      'Recordatorio de agua',
      'Uno solo, a mitad del día',
    ),
  };

  @override
  void initState() {
    super.initState();
    _enabled = NotificationPolicy.enabled;
    _maxPerDay = NotificationPolicy.maxPerDay;
    NotificationPolicy.load().then((_) {
      if (!mounted) return;
      setState(() {
        _enabled = NotificationPolicy.enabled;
        _maxPerDay = NotificationPolicy.maxPerDay;
        _loading = false;
      });
    });
  }

  Future<void> _apply() async {
    await ref.read(notificationSchedulerProvider.notifier).applyPolicy(
          enabled: _enabled,
          maxPerDay: _maxPerDay,
        );
  }

  void _toggle(NotificationKind kind, bool on) {
    if (on && _enabled.length >= _maxPerDay) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Tu límite es de $_maxPerDay ${_maxPerDay == 1 ? 'aviso' : 'avisos'} '
            'al día. Apaga otro primero.',
          ),
        ),
      );
      return;
    }
    setState(() {
      on ? _enabled.add(kind) : _enabled.remove(kind);
    });
    _apply();
  }

  void _setMax(int value) {
    setState(() {
      _maxPerDay = value;
      // Si bajó el límite, se quedan los de mayor prioridad.
      _enabled = NotificationPolicy.effectiveKinds(_enabled, value).toSet();
    });
    _apply();
  }

  @override
  Widget build(BuildContext context) {
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
          'Notificaciones',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
        ),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.metabolicGreen),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
              children: [
                Text(
                  'Elena te avisa solo lo importante. Elige qué avisos quieres '
                  'recibir; nunca más de $kHardMaxPerDay al día.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 18),
                _group([
                  for (final kind in NotificationPolicy.priority)
                    _switchRow(kind),
                ]),
                const SizedBox(height: 18),
                _group([_maxRow()]),
              ],
            ),
    );
  }

  Widget _group(List<Widget> rows) => Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Column(children: rows),
      );

  Widget _switchRow(NotificationKind kind) {
    final (icon, title, subtitle) = _copy[kind]!;
    return SwitchListTile(
      value: _enabled.contains(kind),
      onChanged: (on) => _toggle(kind, on),
      activeThumbColor: AppColors.metabolicGreen,
      activeTrackColor: AppColors.metabolicGreen.withValues(alpha: 0.35),
      secondary: Icon(icon, color: Colors.white.withValues(alpha: 0.75)),
      title: Text(title,
          style: const TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
    );
  }

  Widget _maxRow() {
    return ListTile(
      title: const Text('Límite diario de avisos',
          style: TextStyle(
              color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
      subtitle: Text('Evita la sobrecarga',
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5), fontSize: 12)),
      trailing: DropdownButton<int>(
        value: _maxPerDay,
        dropdownColor: AppColors.surfaceDark,
        underline: const SizedBox.shrink(),
        style: const TextStyle(
            color: AppColors.metabolicGreen,
            fontSize: 14,
            fontWeight: FontWeight.w700),
        items: [
          for (var n = 1; n <= kHardMaxPerDay; n++)
            DropdownMenuItem(value: n, child: Text('$n por día')),
        ],
        onChanged: (v) {
          if (v != null) _setMax(v);
        },
      ),
    );
  }
}
