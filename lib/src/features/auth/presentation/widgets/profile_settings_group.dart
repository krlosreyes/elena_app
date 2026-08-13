// SPEC-288 (rediseño del Perfil): lista agrupada estilo iOS para los ajustes.
//
// Reemplaza el apilado de tarjetas con borde de color (un ícono de un color
// distinto por card → "arcoíris" ruidoso) por UNA superficie continua con
// filas separadas por un hairline, íconos monocromáticos y el valor alineado
// a la derecha. Menos peso visual, jerarquía más clara.

import 'package:flutter/material.dart';

/// Una fila de ajuste: ícono monocromático + título + valor (opcional) +
/// chevron. Sin fondo ni borde propios — los aporta [ProfileSettingsGroup].
class ProfileRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;

  /// Color del valor (por defecto tenue). Úsalo para estados: p. ej. un ámbar
  /// sutil en "Sin configurar".
  final Color? valueColor;
  final VoidCallback? onTap;

  const ProfileRow({
    super.key,
    required this.icon,
    required this.title,
    this.value,
    this.valueColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 14),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white.withValues(alpha: 0.55)),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (value != null && value!.isNotEmpty) ...[
              const SizedBox(width: 10),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 150),
                child: Text(
                  value!,
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: valueColor ?? Colors.white.withValues(alpha: 0.42),
                    fontSize: 13,
                  ),
                ),
              ),
            ],
            const SizedBox(width: 6),
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: Colors.white.withValues(alpha: 0.28),
            ),
          ],
        ),
      ),
    );
  }
}

/// Contenedor de lista agrupada: una superficie redondeada, con las filas
/// separadas por un hairline (sangrado para alinear bajo el texto, no el ícono).
class ProfileSettingsGroup extends StatelessWidget {
  final List<Widget> children;
  const ProfileSettingsGroup({super.key, required this.children});

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(Divider(
          height: 0.5,
          thickness: 0.5,
          indent: 48,
          color: Colors.white.withValues(alpha: 0.08),
        ));
      }
      rows.add(children[i]);
    }
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Material(
          type: MaterialType.transparency,
          child: Column(children: rows),
        ),
      ),
    );
  }
}
