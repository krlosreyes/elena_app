import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme/app_theme.dart';

enum HabitStatus { normal, inProgress, completed }

class HabitCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final HabitStatus status;
  final double progress;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final String? actionLabel;
  final VoidCallback? onAction;

  const HabitCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.status,
    this.progress = 0.0,
    required this.icon,
    this.onTap,
    this.color,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final bool isCompleted = status == HabitStatus.completed;
    final bool isInProgress = status == HabitStatus.inProgress;
    final Color effectColor = color ?? AppTheme.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: LayoutBuilder(builder: (context, constraints) {
        final bool isCompact = constraints.maxWidth < 180;

        return Container(
          decoration: ShapeDecoration(
            color: AppTheme.surface.withValues(alpha: 0.4),
            shape: BeveledRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: isCompleted
                    ? effectColor
                    : AppTheme.outline.withValues(alpha: 0.05),
                width: 1,
              ),
            ),
            shadows: isInProgress
                ? [
                    BoxShadow(
                        color: effectColor.withValues(alpha: 0.05),
                        blurRadius: 10,
                        spreadRadius: 1)
                  ]
                : null,
          ),
          padding: const EdgeInsets.all(10), // Reducido de 12 (15% aprox)
          child: isCompact
              ? _buildCompactContent(isCompleted, isInProgress, effectColor)
              : _buildWideContent(isCompleted, isInProgress, effectColor),
        );
      }),
    );
  }

  Widget _buildWideContent(
      bool isCompleted, bool isInProgress, Color effectColor) {
    return Row(
      children: [
        _buildIcon(isCompleted, isInProgress, effectColor),
        const SizedBox(width: 16),
        Expanded(child: _buildBody(isCompleted, isInProgress, effectColor)),
        const SizedBox(width: 12),
        _buildTrailing(isCompleted, effectColor),
      ],
    );
  }

  Widget _buildCompactContent(
      bool isCompleted, bool isInProgress, Color effectColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildIcon(isCompleted, isInProgress, effectColor,
                size: 32), // Reducido de 36
            _buildTrailing(isCompleted, effectColor),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
            child: _buildBody(isCompleted, isInProgress, effectColor,
                isCompact: true)),
      ],
    );
  }

  Widget _buildIcon(bool isCompleted, bool isInProgress, Color effectColor,
      {double size = 38}) {
    // Reducido de 44
    return Container(
      width: size,
      height: size,
      decoration: ShapeDecoration(
        color: isCompleted ? effectColor : AppTheme.background,
        shape: BeveledRectangleBorder(
          borderRadius: BorderRadius.circular(size * 0.25),
          side: BorderSide(
            color:
                isCompleted ? effectColor : effectColor.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        shadows: isCompleted
            ? [
                BoxShadow(
                    color: effectColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 1)
              ]
            : null,
      ),
      child: Icon(
        icon,
        color: isCompleted
            ? Colors.black
            : (isInProgress ? effectColor : AppTheme.textDim),
        size: size * 0.45,
      ),
    );
  }

  Widget _buildBody(bool isCompleted, bool isInProgress, Color effectColor,
      {bool isCompact = false}) {
    // We use a fixed width container before FittedBox to avoid infinite width errors
    // with LinearProgressIndicator on Android/Web.
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.publicSans(
                fontWeight: FontWeight.bold,
                fontSize: isCompact ? 13 : 15,
                color: Colors.white,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              subtitle.toUpperCase(),
              style: GoogleFonts.jetBrainsMono(
                color: isCompleted ? effectColor : AppTheme.textDim,
                fontSize: 9,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isCompact ? 2 : 4),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 1),
              InkWell(
                onTap: onAction,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: effectColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                    border:
                        Border.all(color: effectColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    actionLabel!.toUpperCase(),
                    style: GoogleFonts.jetBrainsMono(
                      color: effectColor,
                      fontSize: 7.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              SizedBox(height: isCompact ? 2 : 4),
            ],
            _buildProgressBar(isCompleted, isInProgress, effectColor),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar(
      bool isCompleted, bool isInProgress, Color effectColor) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: isCompleted ? 1.0 : progress,
        backgroundColor: AppTheme.outline.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation<Color>(isCompleted || isInProgress
            ? effectColor
            : AppTheme.textDim.withValues(alpha: 0.2)),
        minHeight: 4,
      ),
    );
  }

  Widget _buildTrailing(bool isCompleted, Color effectColor) {
    return Icon(
      isCompleted ? Icons.check_circle : Icons.chevron_right,
      color:
          isCompleted ? effectColor : AppTheme.textDim.withValues(alpha: 0.3),
      size: 18,
    );
  }
}
