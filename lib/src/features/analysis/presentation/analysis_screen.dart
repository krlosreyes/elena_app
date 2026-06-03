// SPEC-160: pantalla Análisis reorganizada con 3 tabs por intención
// narrativa.
//
// Layout: AppBar (calendario opcional) → TabBar (Resumen / Pilares /
// Tendencia) → TabBarView con KeepAlive en cada tab → BottomNavigationBar.
//
// Los widgets de cards (PeriodHeroCard, WeeklyCoachingCard, etc.) NO
// se tocan — solo se reorganizan en los 3 tabs.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/presentation/monthly_calendar_screen.dart';
import 'package:elena_app/src/features/analysis/presentation/tabs/analysis_pillars_tab.dart';
import 'package:elena_app/src/features/analysis/presentation/tabs/analysis_summary_tab.dart';
import 'package:elena_app/src/features/analysis/presentation/tabs/analysis_trend_tab.dart';

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    Tab(text: 'Resumen'),
    Tab(text: 'Pilares'),
    Tab(text: 'Tendencia'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: _tabs.length,
      vsync: this,
      initialIndex: 0,
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundDark,
        elevation: 0,
        title: const Text(
          'ANÁLISIS',
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 14,
            letterSpacing: 1.4,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(
              Icons.calendar_month_rounded,
              color: Colors.white,
            ),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const MonthlyCalendarScreen(),
                fullscreenDialog: true,
              ),
            ),
            tooltip: 'Ver mes',
          ),
          const SizedBox(width: 4),
        ],
        // SPEC-160: TabBar como bottom del AppBar para mantenerla
        // pegada al header sin que el contenido del tab tenga que
        // dejarle espacio.
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(46),
          child: Container(
            color: AppColors.backgroundDark,
            child: TabBar(
              controller: _tabController,
              tabs: _tabs,
              labelColor: AppColors.metabolicGreen,
              unselectedLabelColor: Colors.white60,
              indicatorColor: AppColors.metabolicGreen,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const PageScrollPhysics(),
        children: const [
          AnalysisSummaryTab(),
          AnalysisPillarsTab(),
          AnalysisTrendTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: const Color(0xFF0F172A),
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
            label: 'Análisis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
