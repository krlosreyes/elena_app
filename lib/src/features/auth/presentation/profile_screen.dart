import 'package:elena_app/src/core/config/build_info.dart';
import 'package:elena_app/src/core/config/feature_flags.dart';
import 'package:elena_app/src/core/engine/imr_persistence_provider.dart';
import 'package:elena_app/src/core/engine/longitudinal_imr_provider.dart';
//import 'package:go_router/go_router.dart';
import 'package:elena_app/src/core/theme/app_theme.dart';
// 17-jul (Propuesta "un Perfil que da orgullo abrir", P2): card de
// transformación 30 días vs hoy — existía desde SPEC-148 pero quedó
// huérfana cuando el tab viejo de Análisis se reemplazó (ver
// project_aprende_con_elena_2026_07_17 en memoria, mismo hallazgo que
// desenterró WeeklyCoachingCard). Encaja en Perfil: es exactamente el
// tipo de "mira cómo cambiaste" que pediste.
import 'package:elena_app/src/features/analysis/presentation/widgets/transformation_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/achievement_showcase_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/biometricos_entry_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/exercise_habits_entry_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/glucose_protocol_entry_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/objetivos_entry_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_bottom_nav.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_danger_zone_actions.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_identity_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/profile_legal_section.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/protocolo_entry_card.dart';
import 'package:elena_app/src/features/auth/presentation/widgets/ritmos_entry_card.dart';
import 'package:elena_app/src/features/health_sync/presentation/health_sync_card.dart';
import 'package:elena_app/src/features/profile/presentation/widgets/body_composition_card.dart';
import 'package:elena_app/src/shared/domain/models/user_model.dart';
import 'package:elena_app/src/shared/providers/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:elena_app/src/core/widgets/page_hero.dart';

// 17-jul (2da vuelta de feedback): "Datos biométricos", "Ritmos
// circadianos", "Protocolo de ayuno" y "Mis objetivos" dejaron de
// vivir expandidos/inline acá — cada uno pasó a una card de entrada
// colapsada (mismo patrón que BadgesEntryCard/ResultsEntryCard, ver
// widgets/*_entry_card.dart) + su propia pantalla de detalle
// (biometricos_detail_screen.dart, ritmos_circadianos_detail_screen.dart,
// protocolo_detail_screen.dart, objetivos_detail_screen.dart). Esto
// simplificó bastante esta pantalla: ya no hay time pickers ni
// handlers de edición biométrica acá — esa lógica se movió completa a
// las pantallas de detalle correspondientes (dueñas de su propio
// estado). `ProfileScreen` pasó de `ConsumerStatefulWidget` a
// `ConsumerWidget` — ya no queda ningún estado local mutable en esta
// pantalla.
class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      // 29-jul: el AppBar tenía el título "Perfil" a 18 · w700 — el
      // MISMO tratamiento que sus propias pantallas hijas (Tus
      // resultados, Tus hábitos, Insignias), así que por el título no
      // se distinguía si estabas en la pestaña o dentro de ella.
      // Ahora el título es un `PageHero` en el cuerpo, como en Progreso
      // y en el Dashboard, y el AppBar queda solo como barra de estado.
      // Sin subtítulo a propósito: la card de identidad que va justo
      // debajo ya dice "Tu perfil metabólico", y repetirlo sería ruido.
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

    // SPEC-116: rediseño del Perfil — premium, simple, jerárquico.
    // 17-jul: 2do rediseño — "Tu identidad" (logros + transformación)
    // arriba, "Configuración" (cards colapsadas) abajo. Ver Propuesta
    // "un Perfil que da orgullo abrir".
    // 29-jul: "scroll infinito" en Perfil, reproducido en Simulador.
    //
    // SÍNTOMA REAL: el mismo arrastre de 300 px da dos resultados
    // opuestos. Recién entrado a Perfil no mueve NADA —el gesto se pierde
    // entero— y con la pantalla asentada salta de golpe casi hasta el
    // final. El usuario lo vive como una lista que no se deja controlar;
    // de ahí "infinito", aunque la lista sí termina.
    //
    // CAUSA: esta pantalla monta cuatro widgets autocontenidos que
    // observan sus propios providers y CRECEN al resolver
    // (AchievementShowcaseCard, TransformationCardLive,
    // BodyCompositionCard, HealthSyncCard). Mientras todos cargan, el
    // ListView se reconstruye varias veces por segundo; sin una key
    // estable, Flutter trata cada reconstrucción como una lista nueva,
    // descarta el ScrollPosition y con él el gesto en curso.
    //
    // El `AnimatedSize` que se puso el 20-jul alrededor de HealthSyncCard
    // suavizaba la animación de UNA card, pero no impedía que la posición
    // se perdiera — por eso el problema siguió vivo nueve días.
    //
    // La PageStorageKey le da identidad a la lista: la posición sobrevive
    // a los rebuilds y, de regalo, también a cambiar de pestaña y volver.
    return ListView(
      key: const PageStorageKey<String>('perfil_scroll'),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      children: [
        const PageHero(title: 'Perfil'),
        const SizedBox(height: 16),
        // ── Identidad + IMR ─────────────────────────────────────────
        ProfileIdentityCard(user: user, imrResult: badgeImr),
        if (showLongitudinalDisclaimer) ...[
          const SizedBox(height: 8),
          const ProfileLongitudinalDisclaimer(),
        ],
        const SizedBox(height: 16),

        // 17-jul (Propuesta "un Perfil que da orgullo abrir", P1 + P2):
        // "Tu identidad" — lo que el usuario YA logró, arriba de
        // cualquier tabla de configuración. Vitrina de insignias/racha
        // primero (lo más reciente que ganó), transformación de 30 días
        // después (cómo cambió). Ambas cards son autocontenidas —
        // observan sus propios providers, no necesitan datos de acá.
        const AchievementShowcaseCard(),
        const SizedBox(height: 16),
        const TransformationCardLive(),
        const SizedBox(height: 24),

        // ── Composición corporal (SPEC-88) ──────────────────────────
        const BodyCompositionCard(),
        const SizedBox(height: 32),

        // 17-jul (P4): a partir de acá, todo es configuración — datos,
        // ritmos, protocolo, objetivos, salud, legal, ayuda. Título
        // propio para que la separación de "quién sos / qué lograste"
        // (arriba) vs "ajustes" (abajo) sea explícita, no solo
        // implícita en el orden.
        //
        // 17-jul (2da vuelta): las 4 secciones de acá abajo eran
        // acordeones/cards siempre expandidas — mucho scroll para
        // llegar al final. Pasan a cards colapsadas de una sola línea,
        // mismo patrón visual que "Insignias" en Progreso.
        _buildSectionTitle('Configuración'),
        const SizedBox(height: 12),
        const BiometricosEntryCard(),
        const SizedBox(height: 12),
        const RitmosEntryCard(),
        const SizedBox(height: 12),
        const ProtocoloEntryCard(),
        const SizedBox(height: 12),
        const ObjetivosEntryCard(),
        const SizedBox(height: 12),
        // Propuesta módulo Ejercicio (2026-07-21): sin esta card, un
        // usuario existente no tiene ningún camino para generar su
        // ExerciseProfile — /onboarding lo rebota al dashboard porque
        // su perfil ya está completo (ver router_redirect.dart).
        const ExerciseHabitsEntryCard(),
        const SizedBox(height: 24),

        // ── SPEC-132: sincronización con Apple Health / Health Connect
        //
        // 20-jul: HealthSyncCard cambia de alto varias veces seguidas
        // apenas se abre Perfil (verificando → conectado → sincronizando
        // → resultado, disparado por refreshPermissionStatus() en su
        // initState). Sin este wrapper, cada cambio de alto reacomoda el
        // ListView de golpe bajo el dedo del usuario si está scrolleando
        // en ese momento — se siente como un "rebote"/scroll infinito.
        // AnimatedSize convierte ese reacomodo brusco en una transición
        // suave, así el gesto de scroll no se pelea con el layout.
        _buildSectionTitle('Salud'),
        const SizedBox(height: 10),
        AnimatedSize(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: const HealthSyncCard(),
        ),
        const SizedBox(height: 12),
        // Módulo "Tu Glucosa" (23-jul): control manual del protocolo —
        // vive en "Salud" junto a HealthSyncCard porque conceptualmente
        // es la misma categoría (datos clínicos sincronizados/medidos),
        // no un ajuste de "Configuración" de un pilar existente.
        const GlucoseProtocolEntryCard(),
        const SizedBox(height: 10),
        // 29-jul: movida desde "Legal". Es una declaración de salud que
        // gatea el ayuno, no un documento informativo.
        const ProfileHealthConditionsCard(),
        const SizedBox(height: 24),

        // ── Legal ───────────────────────────────────────────────────
        // SPEC-117: renombrado de "Cuenta" → "Legal" (los items son
        // documentos informativos, no acciones de cuenta). Bajada
        // sustancial de peso visual: lista plana sin card-border, sin
        // iconos coloreados, tipografía secundaria.
        // 20-jul: "Legal" y "Ayuda" pasaron de lista plana a cards con
        // borde de color, mismo patrón que "Configuración" (pedido de
        // Carlos: coherencia visual de arriba a abajo en Perfil).
        _buildSectionTitle('Legal'),
        const SizedBox(height: 12),
        const ProfileLegalSection(),
        const SizedBox(height: 24),

        // ── Ayuda ────────────────────────────────────────────────────
        _buildSectionTitle('Ayuda'),
        const SizedBox(height: 12),
        const ProfileHelpGuideCard(),
        const SizedBox(height: 24),

        // ── Acciones destructivas (text buttons sutiles) ────────────
        const ProfileDangerZoneActions(),

        // 29-jul: identidad del binario instalado. Deliberadamente
        // discreto y al final de todo — no es información que el
        // usuario busque, pero es lo primero que hay que preguntarle
        // cuando reporte "no me aparece el cambio". Ver build_info.dart.
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

  /// SPEC-116: header de sección en sentence-case, peso w600, sin
  /// tracking exagerado.
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
}
