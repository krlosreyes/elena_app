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
import 'package:elena_app/src/features/glucose/presentation/widgets/glucose_entry_card.dart';
// 17-jul (2da vuelta): WeeklyCoachingCard existía desde SPEC-153 pero
// quedó huérfana cuando SPEC-168.4 reemplazó el diseño de tabs viejo —
// nadie la volvió a enlazar. Se rescata acá para llenar el espacio
// debajo de las 4 cards con contenido real (compara la semana vs la
// anterior por pilar + insight accionable con cita bibliográfica), en
// vez de dejarlo vacío. Autocontenida (ConsumerWidget con su propio
// loading/empty state) — no requiere que AnalysisScreen deje de ser
// StatelessWidget.
import 'package:elena_app/src/core/widgets/page_hero.dart';

class AnalysisScreen extends StatelessWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // SPEC-197: overview libre para todos los usuarios. El gate vive
    // en las pantallas de detalle de cada pilar (AnalysisPillarDetailScreen
    // y DailyScoreDetailScreen).
    return Scaffold(
      // SPEC-168.4.6 (2026-06-04): mismo fondo que Hoy y Perfil para
      // unidad visual en la app (las cards mantienen su #0C0C0E).
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header in-page estilo Apple.
              _buildPageHeader(context),
              const SizedBox(height: 20),
              // SPEC-300: la TENDENCIA es el héroe (lo que Hoy no muestra).
              // Línea del Score del Día → detalle de Resultados.
              const ScoreTrendCard(),
              const SizedBox(height: 12),
              // Boletín de la semana: nota + pilares (con delta vs semana
              // pasada) + foco → detalle de Hábitos.
              const WeeklyReportCard(),
              const SizedBox(height: 12),
              // Insignias + racha (navegación a la colección completa).
              const BadgesEntryCard(),
              // 23-jul: "Tu Glucosa" — se autooculta si el usuario no tiene el
              // Protocolo de Seguimiento de Glucosa activo. Trae su propio
              // Padding(top:12) cuando SÍ se muestra.
              const GlucoseEntryCard(),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.backgroundDark,
        selectedItemColor: AppColors.metabolicGreen,
        unselectedItemColor: Colors.grey.withValues(alpha: 0.5),
        currentIndex: 1,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 0) context.go('/dashboard');
          if (index == 1) context.go('/analysis');
          if (index == 2) context.go('/retos');
          if (index == 3) context.go('/profile');
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.grid_view_rounded),
            label: 'Hoy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            label: 'Progreso',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.emoji_events_rounded),
            label: 'Retos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }

  Widget _buildPageHeader(BuildContext context) {
    // 15-jul: se quitó el botón de calendario (esquina superior derecha)
    // — Carlos: "no aporta nada". Abría MonthlyCalendarScreen, que no
    // estaba enlazada desde ningún otro lugar de la app; queda el
    // archivo sin uso por si se retoma más adelante, pero sin entry
    // point visible.
    //
    // 29-jul: el estilo del título y las listas de días/meses vivían
    // acá. Al llevar el mismo hero a Perfil y al Dashboard habrían
    // hecho falta tres copias, así que se movieron a `PageHero` y
    // `heroTodayLabel`.
    return PageHero(
      title: 'Progreso',
      subtitle: heroTodayLabel(),
    );
  }
}
