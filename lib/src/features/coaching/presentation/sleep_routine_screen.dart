// SPEC-234 Momento B: pantalla de rutina nocturna guiada.
//
// Checklist de 4 items de higiene de sueño (Walker 2017, Huberman 2021):
//   1. Pantallas apagadas (melatonina)
//   2. Última comida hace >2h (Sutton 2018: TRF + sleep quality)
//   3. Habitación fresca (18-20°C, Walker)
//   4. Sin cafeína después de las 14h (Huberman)
//
// NO penaliza. Es una herramienta de acompañamiento. El usuario puede
// completar 0/4 y el coaching dice "cada noche es una oportunidad nueva".
// Se persiste en Firestore (offline-first) para alimentar coaching futuro.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/services/analytics_service.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/coaching/data/sleep_routine_repository.dart';
import 'package:elena_app/src/features/coaching/domain/sleep_routine_check_in.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';

class SleepRoutineScreen extends ConsumerStatefulWidget {
  const SleepRoutineScreen({super.key});

  @override
  ConsumerState<SleepRoutineScreen> createState() => _SleepRoutineScreenState();
}

class _SleepRoutineScreenState extends ConsumerState<SleepRoutineScreen> {
  bool _screensOff = false;
  bool _lastMealOk = false;
  bool _tempCool = false;
  bool _noCaffeine = false;
  bool _saved = false;

  static const _items = [
    _RoutineItem(
      icon: Icons.phone_android_rounded,
      title: 'Pantallas apagadas',
      subtitle: 'La luz azul suprime la melatonina hasta 50% (Walker 2017).',
      field: 'screensOff',
    ),
    _RoutineItem(
      icon: Icons.restaurant_rounded,
      title: 'Última comida hace >2 horas',
      subtitle:
          'Tu cuerpo necesita terminar la digestión para entrar en reposo (Sutton 2018).',
      field: 'lastMealOk',
    ),
    _RoutineItem(
      icon: Icons.thermostat_rounded,
      title: 'Habitación fresca (18-20°C)',
      subtitle: 'El cuerpo necesita bajar ~1°C para iniciar el sueño profundo.',
      field: 'tempCool',
    ),
    _RoutineItem(
      icon: Icons.coffee_rounded,
      title: 'Sin cafeína desde las 14h',
      subtitle:
          'La cafeína tiene vida media de 5-7h y reduce el sueño profundo (Huberman 2021).',
      field: 'noCaffeine',
    ),
  ];

  int get _completedCount =>
      (_screensOff ? 1 : 0) +
      (_lastMealOk ? 1 : 0) +
      (_tempCool ? 1 : 0) +
      (_noCaffeine ? 1 : 0);

  bool _valueFor(String field) => switch (field) {
        'screensOff' => _screensOff,
        'lastMealOk' => _lastMealOk,
        'tempCool' => _tempCool,
        'noCaffeine' => _noCaffeine,
        _ => false,
      };

  void _toggle(String field) {
    setState(() {
      switch (field) {
        case 'screensOff':
          _screensOff = !_screensOff;
        case 'lastMealOk':
          _lastMealOk = !_lastMealOk;
        case 'tempCool':
          _tempCool = !_tempCool;
        case 'noCaffeine':
          _noCaffeine = !_noCaffeine;
      }
    });
  }

  void _save() {
    final user = ref.read(currentUserStreamProvider).valueOrNull;
    if (user == null) return;

    final now = DateTime.now();
    final routine = SleepRoutineCheckIn(
      id: SleepRoutineCheckIn.buildId(user.id, now),
      userId: user.id,
      date: now,
      screensOff: _screensOff,
      lastMealOk: _lastMealOk,
      tempCool: _tempCool,
      noCaffeine: _noCaffeine,
      completedAt: DateTime.now(),
    );

    ref.read(sleepRoutineRepositoryProvider).save(routine);

    AnalyticsService.logEvent(
      'sleep_routine_completed',
      params: {
        'completed_count': _completedCount.toString(),
        'screens_off': _screensOff.toString(),
        'last_meal_ok': _lastMealOk.toString(),
        'temp_cool': _tempCool.toString(),
        'no_caffeine': _noCaffeine.toString(),
      },
    );

    setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.bgBase,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Rutina nocturna',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _saved ? _buildCompletionView(theme) : _buildChecklist(theme),
        ),
      ),
    );
  }

  Widget _buildChecklist(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Prepara tu cuerpo para dormir',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Marca lo que ya hiciste. No hay presión — cada paso cuenta.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 24),
        ...List.generate(_items.length, (i) {
          final item = _items[i];
          final checked = _valueFor(item.field);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _RoutineItemTile(
              item: item,
              checked: checked,
              onTap: () => _toggle(item.field),
            ),
          );
        }),
        const Spacer(),
        // Resumen + botón guardar.
        Center(
          child: Text(
            '$_completedCount de 4 completados',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.pillarSueno,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: _save,
            child: const Text(
              'Guardar y prepararse para dormir',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildCompletionView(ThemeData theme) {
    final message = _completedCount >= 3
        ? '¡Excelente! Tu cuerpo está listo para un sueño reparador.'
        : _completedCount >= 1
            ? 'Cada paso cuenta. Mañana puedes completar uno más.'
            : 'No pasa nada. Cada noche es una oportunidad nueva.';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.nights_stay_rounded,
              color: AppColors.pillarSueno, size: 64),
          const SizedBox(height: 20),
          Text(
            'Buenas noches',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(height: 32),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _RoutineItemTile extends StatelessWidget {
  final _RoutineItem item;
  final bool checked;
  final VoidCallback onTap;

  const _RoutineItemTile({
    required this.item,
    required this.checked,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: checked
              ? AppColors.pillarSueno.withValues(alpha: 0.12)
              : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: checked
                ? AppColors.pillarSueno.withValues(alpha: 0.5)
                : AppColors.borderSubtle,
          ),
        ),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_circle_rounded : item.icon,
              color: checked ? AppColors.pillarSueno : AppColors.textMuted,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: checked
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final String field;
  const _RoutineItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.field,
  });
}
