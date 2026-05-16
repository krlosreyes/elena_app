// SPEC-117: extracción de los widgets _ProfileDataGroupCard y _ProfileDataRow desde
// profile_screen.dart para que sean testeables.
//
// Patrón iOS Settings / Oura: una sola card con filas separadas por
// divisores internos. Reemplaza el "muro de tarjetas" donde cada dato
// tenía su propia card con bordes y padding individuales.

import 'package:flutter/material.dart';

import 'package:elena_app/src/core/theme/app_theme.dart';

/// Card contenedora que agrupa varias `ProfileDataRow` con divisores
/// horizontales sutiles entre filas. Patrón iOS Settings.
class ProfileDataGroupCard extends StatelessWidget {
  final List<ProfileDataRow> rows;

  const ProfileDataGroupCard({super.key, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderDefault),
      ),
      child: Column(
        children: [
          for (int i = 0; i < rows.length; i++) ...[
            rows[i],
            if (i < rows.length - 1)
              Container(
                height: 1,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                color: AppColors.borderSubtle,
              ),
          ],
        ],
      ),
    );
  }
}

enum ProfileDataRowKind { readonly, editable, info, icon }

/// Fila individual dentro de un `ProfileDataGroupCard`. Soporta 4 variantes:
///   - readonly: label izquierda + valor derecha, sin tap.
///   - editable: label + valor coloreado verde + chevron, tap abre editor.
///   - info: label + tag de confianza + valor + info icon, tap abre dialog.
///   - icon: icono coloreado + label + valor coloreado + chevron, tap abre picker.
class ProfileDataRow extends StatelessWidget {
  final ProfileDataRowKind kind;
  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? valueColor;
  final String? tag;
  final Color? tagColor;
  final VoidCallback? onTap;
  final VoidCallback? onInfoTap;

  const ProfileDataRow._({
    required this.kind,
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
    this.valueColor,
    this.tag,
    this.tagColor,
    this.onTap,
    this.onInfoTap,
  });

  factory ProfileDataRow.readonly(String label, String value) => ProfileDataRow._(
        kind: ProfileDataRowKind.readonly,
        label: label,
        value: value,
      );

  factory ProfileDataRow.editable({
    required String label,
    required String value,
    required VoidCallback onTap,
  }) =>
      ProfileDataRow._(
        kind: ProfileDataRowKind.editable,
        label: label,
        value: value,
        valueColor: AppColors.metabolicGreen,
        onTap: onTap,
      );

  factory ProfileDataRow.info({
    required String label,
    required String value,
    required String tag,
    required Color tagColor,
    required VoidCallback onInfoTap,
  }) =>
      ProfileDataRow._(
        kind: ProfileDataRowKind.info,
        label: label,
        value: value,
        tag: tag,
        tagColor: tagColor,
        onInfoTap: onInfoTap,
      );

  factory ProfileDataRow.icon({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required Color valueColor,
    required VoidCallback onTap,
  }) =>
      ProfileDataRow._(
        kind: ProfileDataRowKind.icon,
        label: label,
        value: value,
        icon: icon,
        iconColor: iconColor,
        valueColor: valueColor,
        onTap: onTap,
      );

  @override
  Widget build(BuildContext context) {
    final isInteractive =
        kind == ProfileDataRowKind.editable || kind == ProfileDataRowKind.icon;

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
      child: Row(
        children: _buildChildren(),
      ),
    );

    if (isInteractive) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: content,
        ),
      );
    }
    return content;
  }

  List<Widget> _buildChildren() {
    switch (kind) {
      case ProfileDataRowKind.readonly:
        return [
          Expanded(child: _labelText(label)),
          _valueText(value, color: Colors.white, weight: FontWeight.w600),
        ];

      case ProfileDataRowKind.editable:
        return [
          Expanded(child: _labelText(label)),
          _valueText(
            value,
            color: valueColor ?? AppColors.metabolicGreen,
            weight: FontWeight.w700,
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.30),
            size: 20,
          ),
        ];

      case ProfileDataRowKind.info:
        return [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _labelText(label),
                if (tag != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    tag!,
                    style: TextStyle(
                      color: tagColor ?? Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          _valueText(value, color: Colors.white, weight: FontWeight.w700),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onInfoTap,
            behavior: HitTestBehavior.opaque,
            child: Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: Colors.white.withValues(alpha: 0.45),
            ),
          ),
        ];

      case ProfileDataRowKind.icon:
        return [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(width: 12),
          Expanded(child: _labelText(label)),
          _valueText(
            value,
            color: valueColor ?? Colors.white,
            weight: FontWeight.w700,
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.chevron_right_rounded,
            color: Colors.white.withValues(alpha: 0.30),
            size: 20,
          ),
        ];
    }
  }

  Widget _labelText(String text) {
    return Text(
      text,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.65),
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _valueText(String text,
      {required Color color, required FontWeight weight}) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 14,
        fontWeight: weight,
      ),
    );
  }
}
