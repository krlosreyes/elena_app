// SPEC-163: chips temporales estilo Apple Fitness — pills prominentes.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';
import 'package:elena_app/src/features/analysis/application/analysis_range_provider.dart';
import 'package:elena_app/src/features/analysis/domain/analysis_range.dart';

class RangeSelectorChips extends ConsumerWidget {
  const RangeSelectorChips({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active = ref.watch(analysisRangeProvider);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: AnalysisRange.values.map((r) {
        final isSelected = r == active;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ref.read(analysisRangeProvider.notifier).state = r,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.metabolicGreen.withValues(alpha: 0.20)
                      : Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    r.label,
                    style: TextStyle(
                      color: isSelected
                          ? AppColors.metabolicGreen
                          : Colors.white.withValues(alpha: 0.55),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
