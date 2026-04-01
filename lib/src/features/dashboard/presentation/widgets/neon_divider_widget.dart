import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class NeonDividerWidget extends StatelessWidget {
  const NeonDividerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      height: 0.5,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primary.withValues(alpha: 0.0),
            AppTheme.primary.withValues(alpha: 0.8),
            AppTheme.primary.withValues(alpha: 0.0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.4),
            blurRadius: 4,
            spreadRadius: 1,
            offset: const Offset(0, 0),
          ),
        ],
      ),
    );
  }
}
