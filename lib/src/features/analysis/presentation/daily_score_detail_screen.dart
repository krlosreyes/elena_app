// SPEC-200: detalle del "Score del Día" — abierto desde el tile de Resultados.
// Muestra el seguimiento día a día del puntaje diario (HOY, 0-100) con
// promedio + mejor/peor. Pantalla delgada: reusa DailyScoreTrendSection.

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/presentation/widgets/daily_score_trend_section.dart';

class DailyScoreDetailScreen extends StatelessWidget {
  const DailyScoreDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundDark,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: InkResponse(
                  onTap: () => context.pop(),
                  radius: 22,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white.withValues(alpha: 0.85),
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const DailyScoreTrendSection(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 2),
                child: Text(
                  'Tu puntaje diario refleja cómo viviste cada día — llega a '
                  '100 cuando cumples los 5 pilares. Es distinto del IMR, que '
                  'mide tu estado metabólico de fondo y se mueve en semanas.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontSize: 13,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
