// SPEC-162 + SPEC-163 + SPEC-164 + SPEC-165: Análisis estilo Apple
// Fitness, función de revisión histórica (NO motivacional — eso vive
// en Hoy).
//
// 17-jul: rediseño a pedido de Carlos — la pantalla mostraba todo el
// contenido inline (tiles de resultados, tiles de hábitos, racha) en un
// solo scroll largo. Se colapsó a cards de entrada (mismo patrón que
// BadgesEntryCard, que ya vivía acá desde el 15-jul): Insignias, Tus
// Resultados, Tus Hábitos. Cada card resume su sección y el tap navega
// a su propia pantalla de detalle (resultados_detail_screen,
// habitos_detail_screen). El contenido de cada sección no cambió —
// solo se movió de archivo y quedó detrás de un tap.
//
// 17-jul (3ra vuelta): la card "Tu racha" se quitó de acá — duplicaba
// el badge de racha del header (ElenaHeader), que ahora navega directo
// a RachaDetailScreen (/analysis/racha, sigue existiendo, sigue
// registrada en el router — solo perdió esta segunda entrada). Un solo
// punto de entrada a la racha en toda la app.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/badges/presentation/widgets/badges_entry_card.dart';
// SPEC-300: Progreso pasó de 3 filas-menú idénticas a una pantalla de
// TENDENCIA (lo que Hoy no es): línea del Score + boletín semanal. Resultados
// y Hábitos ya no son filas — su navegación la absorben la card del Score y la
// del boletín respectivamente (ambas son InkWell a su detalle).
import 'package:elena_app/src/features/analysis/presentation/widgets/score_trend_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/weekly_report_card.dart';
// 23-jul: módulo "Tu Glucosa" (propuesta Protocolo de Seguimiento de
// Glucosa) — mismo patrón autocontenido que WeeklyCoachingCard más
// abajo: se oculta sola (SizedBox.shrink) si el usuario no tiene el
// protocolo activo, así que AnalysisScreen no necesita dejar de ser
// StatelessWidget ni saber nada de elegibilidad.
// 17-jul (2da vuelta): WeeklyCoachingCard existía desde SPEC-153 pero
// quedó huérfana cuando SPEC-168.4 reemplazó el diseño de tabs viejo —
// nadie la volvió a enlazar. Se rescata acá para llenar el espacio
// debajo de las 4 cards con contenido real (compara la semana vs la
// anterior por pilar + insight accionable con cita bibliográfica), en
// vez de dejarlo vacío. Autocontenida (ConsumerWidget con su propio
// loading/empty state) — no requiere que AnalysisScreen deje de ser
// StatelessWidget.
import 'package:elena_app/src/core/widgets/page_hero.dart';
import 'package:elena_app/src/features/analysis/application/analysis_range_provider.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_range.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/dashboard_bottom_nav.dart';
import 'package:elena_app/src/features/dashboard/presentation/widgets/today_focus_card.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Rediseño Progreso (2026-10-30): Semana/Mes → tendencia del puntaje →
    // "Tu semana" (X de 7 días por pilar) → Tu foco de hoy (mismo texto que
    // en Hoy) → accesos a Insignias, Retos y el reloj circadiano (que salió
    // de Hoy). Se quitó la card de glucosa.
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const PageHero(title: 'Progreso'),
              const SizedBox(height: 14),
              const _WeekMonthSwitch(),
              const SizedBox(height: 14),
              const ScoreTrendCard(),
              const SizedBox(height: 12),
              const WeeklyReportCard(),
              const SizedBox(height: 12),
              const TodayFocusCard(),
              const SizedBox(height: 12),
              const BadgesEntryCard(),
              const SizedBox(height: 12),
              _EntryRow(
                icon: Icons.emoji_events_outlined,
                color: const Color(0xFFFBBF24),
                title: 'Retos',
                subtitle: 'Constancia con otras personas',
                onTap: () => context.push('/retos'),
              ),
              const SizedBox(height: 12),
              _EntryRow(
                icon: Icons.schedule_rounded,
                color: const Color(0xFF818CF8),
                title: 'Ver tu reloj circadiano',
                subtitle: 'Tu ritmo de vigilia y descanso',
                onTap: () => context.push('/analysis/reloj'),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const DashboardBottomNav(),
    );
  }
}

/// Selector Semana / Mes (los dos rangos que pide el diseño).
class _WeekMonthSwitch extends ConsumerWidget {
  const _WeekMonthSwitch();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(analysisRangeProvider);
    Widget option(String label, AnalysisRange value) {
      final selected = range == value;
      return Expanded(
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => ref.read(analysisRangeProvider.notifier).state = value,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 9),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected ? AppColors.metabolicGreen : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: selected
                    ? const Color(0xFF0B1020)
                    : Colors.white.withValues(alpha: 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          option('Semana', AnalysisRange.w1),
          option('Mes', AnalysisRange.m1),
        ],
      ),
    );
  }
}

class _EntryRow extends StatelessWidget {
  const _EntryRow({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.borderDefault),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.5),
                          fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: Colors.white.withValues(alpha: 0.3)),
          ],
        ),
      ),
    );
  }
}
