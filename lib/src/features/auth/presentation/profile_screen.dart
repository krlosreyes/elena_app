// Rediseño Perfil (2026-11-04), coherente con Hoy: 4 bloques — identidad
// (+ IMR), Tu cuerpo (medición semanal), Tu plan y Ajustes. Salud y Ayuda y
// legal pasan a pantallas propias (profile_sections_screens.dart); el
// borrado de cuenta vive en "Cuenta y datos personales".
//
// SPEC-288 (rediseño del Perfil): jerarquía clara + menos ruido.
//
// Antes: identidad, logros, transformación (card vacía cuando no hay datos de
// 30 días — se veía rota y causaba el "scroll infinito"), composición, y luego
// 7 tarjetas de "Configuración" cada una con ícono de un color distinto
// (arcoíris), más Salud/Legal/Ayuda con el mismo peso — sobresaturado.
//
// Ahora: un héroe (identidad + IMR, logros, composición) y, debajo, los
// ajustes en LISTAS AGRUPADAS estilo iOS (una superficie, filas con hairline,
// íconos monocromáticos, valor a la derecha). La card de transformación vacía
// se retira. Ver mockup de la propuesta y `ProfileSettingsGroup`.

import 'package:elena_app/src/core/config/build_info.dart';
import 'package:elena_app/src/core/config/feature_flags.dart';
import 'package:elena_app/src/core/engine/imr_persistence_provider.dart';
import 'package:elena_app/src/core/engine/longitudinal_imr_provider.dart';
import 'package:elena_app/src/core/services/notification_policy.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/exercise_habits_entry_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/objetivos_entry_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_bottom_nav.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_danger_zone_actions.dart';
import 'package:elena_app/src/features/auth/presentation/account_screen.dart'
    show initialsOf;
import 'package:elena_app/src/features/auth/presentation/widgets/profile_identity_card.dart'
    show ProfileLongitudinalDisclaimer;
import 'package:elena_app/src/features/auth/presentation/widgets/profile_settings_group.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/protocolo_entry_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/ritmos_entry_card.dart';
import 'package:elena_app/src/features/nutrition/presentation/widgets/alimentacion_minuta_entry_card.dart';
import 'package:elena_app/src/features/auth/providers/auth_providers.dart';
import 'package:elena_app/src/features/profile/application/biometric_lock_provider.dart';
import 'package:elena_app/src/features/progress/application/progress_notifier.dart';
import 'package:elena_app/src/features/progress/presentation/biometric_checkin_sheet.dart';
import 'package:elena_app/src/features/profile/domain/biometric_lock_service.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/widgets/page_hero.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        toolbarHeight: 0,
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        automaticallyImplyLeading: false,
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
}

// ─────────────────────────────────────────────────────────────────────────────
// Cuerpo principal
// ─────────────────────────────────────────────────────────────────────────────

class _ProfileBody extends ConsumerWidget {
  final UserModel user;
  const _ProfileBody({required this.user});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final displayedImr = ref.watch(displayedImrProvider);

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

    return ListView(
      key: const PageStorageKey<String>('perfil_scroll'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        const PageHero(title: 'Perfil'),
        const SizedBox(height: 16),
        _IdentityHero(user: user, imr: badgeImr),
        if (showLongitudinalDisclaimer) ...[
          const SizedBox(height: 8),
          const ProfileLongitudinalDisclaimer(),
        ],
        const SizedBox(height: 24),
        _BodyBlock(user: user),
        const SizedBox(height: 24),
        _sectionTitle('TU PLAN'),
        const SizedBox(height: 10),
        const ProfileSettingsGroup(
          children: [
            ProtocoloEntryCard(),
            RitmosEntryCard(),
            ObjetivosEntryCard(),
            AlimentacionMinutaEntryCard(),
            ExerciseHabitsEntryCard(),
          ],
        ),
        const SizedBox(height: 24),
        _sectionTitle('AJUSTES'),
        const SizedBox(height: 10),
        ProfileSettingsGroup(
          children: [
            ProfileRow(
              icon: Icons.person_outline_rounded,
              title: 'Cuenta y datos personales',
              onTap: () => context.push('/profile/cuenta'),
            ),
            ProfileRow(
              icon: Icons.notifications_none_rounded,
              title: 'Avisos',
              value: 'Máx. $kHardMaxPerDay al día',
              onTap: () => context.push('/profile/notificaciones'),
            ),
            ProfileRow(
              icon: Icons.favorite_border_rounded,
              title: 'Salud y Apple Salud',
              onTap: () => context.push('/profile/salud'),
            ),
            ProfileRow(
              icon: Icons.help_outline_rounded,
              title: 'Ayuda y legal',
              onTap: () => context.push('/profile/ayuda'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        const ProfileDangerZoneActions(showDelete: false),
        const SizedBox(height: 12),
        Center(
          child: SelectableText(
            BuildInfo.label,
            style: TextStyle(
              fontSize: 11,
              color: Colors.white.withValues(alpha: 0.30),
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

Widget _sectionTitle(String label) {
  return Padding(
    padding: const EdgeInsets.only(left: 4),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Colors.white.withValues(alpha: 0.55),
        letterSpacing: 0.4,
      ),
    ),
  );
}

const _meses = [
  'ene', 'feb', 'mar', 'abr', 'may', 'jun',
  'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
];

/// Identidad + acceso al IMR. El número del IMR NO se muestra aquí a
/// propósito (fix 23-jul: competía con el puntaje del día); se ve al tocar.
class _IdentityHero extends ConsumerWidget {
  const _IdentityHero({required this.user, required this.imr});

  final UserModel user;
  final DisplayedImr imr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final createdAt = ref.watch(authStateProvider).valueOrNull?.createdAt;
    final zoneColor = AppColors.imrZoneColor(imr.zone);
    final subtitle = [
      if (user.fastingProtocol != 'Ninguno') user.fastingProtocol,
      if (createdAt != null)
        'desde ${_meses[createdAt.month - 1]} ${createdAt.year}',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1422),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.metabolicGreen.withValues(alpha: 0.16),
                  border: Border.all(color: AppColors.metabolicGreen, width: 2),
                ),
                child: Text(
                  initialsOf(user.name),
                  style: const TextStyle(
                    color: AppColors.metabolicGreen,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (subtitle.isNotEmpty)
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push('/profile/cuenta'),
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF1A2332),
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.edit_outlined,
                    size: 16, color: Colors.white),
                label: const Text(
                  'Editar',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Material(
            color: const Color(0xFF1A2332),
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: () => context.push('/analysis/resultados'),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: zoneColor.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.query_stats_rounded,
                          color: zoneColor, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TU IMR',
                            style: TextStyle(
                              color: zoneColor,
                              fontSize: 11.5,
                              letterSpacing: 1,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Ver tus resultados metabólicos',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded,
                        color: Colors.white.withValues(alpha: 0.4)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// "Tu cuerpo": última medición + cambio vs. la anterior, con el bloqueo
/// semanal (una medición por semana: peso, cintura y cuello juntos).
class _BodyBlock extends ConsumerWidget {
  const _BodyBlock({required this.user});

  final UserModel user;

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toStringAsFixed(0) : v.toStringAsFixed(1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lock = ref.watch(biometricLockProvider);
    final history = ref.watch(progressProvider.select((s) => s.biometricHistory));
    final manual = history
        .where((e) => BiometricLockService.countsAsMeasurement(e.source))
        .toList()
      ..sort((a, b) =>
          (a.recordedAt ?? a.createdAt).compareTo(b.recordedAt ?? b.createdAt));
    final prev = manual.length >= 2 ? manual[manual.length - 2] : null;

    String? delta(double current, double? before, String unit) {
      if (before == null) return null;
      final d = current - before;
      if (d.abs() < 0.05) return 'sin cambio';
      return '${d > 0 ? '+' : '−'}${_fmt(d.abs())} $unit';
    }

    final last = lock.lastEditAt;
    final String measured;
    if (last == null) {
      measured = 'Sin medición registrada';
    } else {
      final days = DateTime.now().difference(last).inDays;
      measured = days == 0
          ? 'Medido hoy'
          : 'Medido hace $days ${days == 1 ? 'día' : 'días'}';
    }

    final waist = user.waistCircumference;
    final fat = user.bodyFatPercentage;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: _sectionTitle('TU CUERPO')),
            Text(
              measured,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.45),
                fontSize: 12.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _BodyTile(
                label: 'Peso',
                value: '${_fmt(user.weight)} kg',
                delta: delta(user.weight, prev?.weight, 'kg'),
                onTap: () => context.push('/profile/biometricos'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BodyTile(
                label: 'Cintura',
                value: waist == null ? '—' : '${_fmt(waist)} cm',
                delta: waist == null
                    ? null
                    : delta(waist, prev?.waistCircumference, 'cm'),
                onTap: () => context.push('/profile/biometricos'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _BodyTile(
                label: 'Grasa',
                value: fat == null ? '—' : '${fat.toStringAsFixed(0)} %',
                delta: fat == null ? null : 'estimada',
                neutral: true,
                onTap: () => context.push('/profile/biometricos'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed:
                lock.isLocked ? null : () => showBiometricCheckInSheet(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.white.withValues(alpha: 0.14)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: Icon(
              lock.isLocked ? Icons.lock_outline_rounded : Icons.straighten_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: lock.isLocked ? 0.45 : 0.9),
            ),
            label: Text(
              lock.isLocked
                  ? 'Próxima medición: ${lock.unlockLabel.replaceFirst('Disponible el ', '')}'
                  : 'Actualizar medidas',
              style: TextStyle(
                color: Colors.white.withValues(alpha: lock.isLocked ? 0.5 : 1),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _BodyTile extends StatelessWidget {
  const _BodyTile({
    required this.label,
    required this.value,
    required this.onTap,
    this.delta,
    this.neutral = false,
  });

  final String label;
  final String value;
  final String? delta;
  final bool neutral;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final d = delta;
    // Bajar peso o cintura es la dirección buscada → verde; subir, ámbar.
    final Color deltaColor = neutral || d == null || d == 'sin cambio'
        ? Colors.white.withValues(alpha: 0.4)
        : (d.startsWith('−')
            ? AppColors.metabolicGreen
            : const Color(0xFFEF9F27));
    return Material(
      color: const Color(0xFF0C1422),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 14, 10, 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.55),
                      fontSize: 12)),
              const SizedBox(height: 4),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                d ?? ' ',
                style: TextStyle(
                  color: deltaColor,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
