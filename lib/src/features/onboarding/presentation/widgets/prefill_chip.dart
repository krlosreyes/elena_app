// SPEC-74 §RF-74-06: chip visual que indica al usuario que ciertos
// campos vienen pre-llenados desde su perfil de Metamorfosis Real.
//
// El chip aparece solo cuando OnboardingPrefill.filledCount > 0. Es
// estático (no clickeable) — solo informativo.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

class PrefillChip extends StatelessWidget {
  final int filledCount;

  const PrefillChip({super.key, required this.filledCount});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.metabolicGreen.withValues(alpha: 0.12)
            : AppColors.metabolicGreen.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.metabolicGreen.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.auto_awesome,
            size: 18,
            color: AppColors.metabolicGreen,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              filledCount == 1
                  ? 'Pre-llenamos 1 dato desde tu perfil de Metamorfosis Real.'
                  : 'Pre-llenamos $filledCount datos desde tu perfil de Metamorfosis Real.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.85)
                    : const Color(0xFF0F172A),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
