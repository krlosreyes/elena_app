// SPEC-162 + SPEC-163 + SPEC-164 + SPEC-165: Análisis estilo Apple
// Fitness, función de revisión histórica (NO motivacional — eso vive
// en Hoy).
//
// 17-jul: rediseño a pedido de Carlos — la pantalla mostraba todo el
// contenido inline (tiles de resultados, tiles de hábitos, racha) en un
// solo scroll largo. Se colapsó a 4 cards de entrada (mismo patrón que
// BadgesEntryCard, que ya vivía acá desde el 15-jul): Insignias, Tus
// Resultados, Tus Hábitos, Tu racha. Cada card resume su sección y el
// tap navega a su propia pantalla de detalle (resultados_detail_screen,
// habitos_detail_screen, racha_detail_screen). El contenido de cada
// sección no cambió — solo se movió de archivo y quedó detrás de un tap.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/badges/presentation/widgets/badges_entry_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/habitos_entry_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/racha_entry_card.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/results_entry_card.dart';

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
              // 17-jul: las 4 cards de entrada, en el orden que Carlos
              // pidió — Insignias primero (venía del 15-jul), luego
              // Resultados, Hábitos y Racha.
              const BadgesEntryCard(),
              const SizedBox(height: 12),
              const ResultsEntryCard(),
              const SizedBox(height: 12),
              const HabitosEntryCard(),
              const SizedBox(height: 12),
              const RachaEntryCard(),
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
          if (index == 2) context.go('/profile');
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Progreso',
          style: TextStyle(
            color: Colors.white,
            fontSize: 34,
            fontWeight: FontWeight.w800,
            height: 1.05,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          _todayLabel(),
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.55),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  static const _daysLong = [
    'lunes',
    'martes',
    'miércoles',
    'jueves',
    'viernes',
    'sábado',
    'domingo',
  ];

  static const _monthsLong = [
    'enero',
    'febrero',
    'marzo',
    'abril',
    'mayo',
    'junio',
    'julio',
    'agosto',
    'septiembre',
    'octubre',
    'noviembre',
    'diciembre',
  ];

  String _todayLabel() {
    final n = DateTime.now();
    final day = _daysLong[(n.weekday - 1).clamp(0, 6)];
    final month = _monthsLong[n.month - 1];
    return '$day, ${n.day} de $month';
  }
}
