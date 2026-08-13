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
import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/achievement_showcase_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/alcohol_protocol_entry_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/biometricos_entry_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/exercise_habits_entry_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/glucose_protocol_entry_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/objetivos_entry_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_bottom_nav.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_danger_zone_actions.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_identity_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_legal_section.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_settings_group.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/protocolo_entry_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/ritmos_entry_card.dart';
import 'package:elena_app/src/features/health_sync/presentation/health_sync_card.dart';
import 'package:elena_app/src/features/nutrition/presentation/widgets/alimentacion_minuta_entry_card.dart';
import 'package:elena_app/src/features/profile/presentation/widgets/body_composition_card.dart';
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

        // ── Héroe: identidad + IMR, logros y composición ────────────
        ProfileIdentityCard(user: user, imrResult: badgeImr),
        if (showLongitudinalDisclaimer) ...[
          const SizedBox(height: 8),
          const ProfileLongitudinalDisclaimer(),
        ],
        const SizedBox(height: 16),
        const AchievementShowcaseCard(),
        const SizedBox(height: 16),
        const BodyCompositionCard(),
        const SizedBox(height: 30),

        // ── Tus datos (lista agrupada) ──────────────────────────────
        _sectionTitle('Tus datos'),
        const SizedBox(height: 10),
        const ProfileSettingsGroup(
          children: [
            BiometricosEntryCard(),
            RitmosEntryCard(),
            ProtocoloEntryCard(),
            ObjetivosEntryCard(),
            AlimentacionMinutaEntryCard(),
            ExerciseHabitsEntryCard(),
            AlcoholProtocolEntryCard(),
          ],
        ),
        const SizedBox(height: 26),

        // ── Salud ───────────────────────────────────────────────────
        _sectionTitle('Salud'),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: const HealthSyncCard(),
        ),
        const SizedBox(height: 12),
        const ProfileSettingsGroup(
          children: [
            GlucoseProtocolEntryCard(),
            ProfileHealthConditionsCard(),
          ],
        ),
        const SizedBox(height: 26),

        // ── Legal y ayuda ───────────────────────────────────────────
        _sectionTitle('Legal y ayuda'),
        const SizedBox(height: 10),
        ProfileSettingsGroup(
          children: [
            ProfileRow(
              icon: Icons.privacy_tip_outlined,
              title: 'Política de privacidad',
              onTap: () => context.push('/legal/privacy'),
            ),
            ProfileRow(
              icon: Icons.description_outlined,
              title: 'Términos de uso',
              onTap: () => context.push('/legal/terms'),
            ),
            const ProfileHelpGuideCard(),
          ],
        ),
        const SizedBox(height: 26),

        // ── Acciones destructivas (text buttons sutiles) ────────────
        const ProfileDangerZoneActions(),

        const SizedBox(height: 28),
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

  Widget _sectionTitle(String label) {
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
}
